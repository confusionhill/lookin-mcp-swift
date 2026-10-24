import XCTest
import Network
@testable import LookinClient
@testable import LookinModels

final class LookinClientTests: XCTestCase {
    private var listener: NWListener?
    private var serverConnection: NWConnection?
    private let testPort: UInt16 = 58234
    private let queue = DispatchQueue(label: "test.mock.server")

    override func tearDown() {
        serverConnection?.cancel()
        serverConnection = nil
        listener?.cancel()
        listener = nil
        super.tearDown()
    }

    private func startMockServer() throws {
        let params = NWParameters.tcp
        params.preferNoProxies = true
        let listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: testPort)!)
        self.listener = listener

        listener.newConnectionHandler = { [weak self] newConn in
            self?.serverConnection = newConn
            newConn.start(queue: self!.queue)
            self?.readFrame(from: newConn)
        }

        listener.start(queue: queue)
    }

    private func readFrame(from conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 16, maximumLength: 65536) { [weak self] content, _, isComplete, _ in
            guard let self = self, let data = content, data.count >= 16 else { return }

            do {
                if let (frame, _) = try PeerTalkFrame.unpack(from: data) {
                    self.handleMockFrame(frame, over: conn)
                }
            } catch {
                XCTFail("Failed to unpack frame on mock server: \(error)")
            }

            if !isComplete {
                self.readFrame(from: conn)
            }
        }
    }

    private func handleMockFrame(_ frame: PeerTalkFrame, over conn: NWConnection) {
        let respAttachment = LookinConnectionResponseAttachment()
        respAttachment.lookinServerVersion = 7

        if frame.type == LookinRequestType.ping.rawValue {
            respAttachment.appIsInBackground = false
        } else if frame.type == LookinRequestType.app.rawValue {
            let appInfo = LookinAppInfo()
            appInfo.appName = "MockLookinApp"
            appInfo.appBundleIdentifier = "com.mock.lookin"
            appInfo.deviceDescription = "iPhone Simulator"
            respAttachment.data = appInfo
        } else if frame.type == LookinRequestType.invokeMethod.rawValue {
            respAttachment.data = ["description": "invoked_mock" as NSString]
        }

        let payloadData = (try? NSKeyedArchiver.archivedData(withRootObject: respAttachment, requiringSecureCoding: false)) ?? Data()
        let respFrame = PeerTalkFrame(
            version: 1,
            type: frame.type,
            tag: frame.tag,
            payload: payloadData
        )
        let bytes = respFrame.pack()
        conn.send(content: bytes, completion: .contentProcessed({ _ in }))
    }

    func testMockServerRoundtrip() async throws {
        try startMockServer()
        // Wait briefly for listener to be active
        try await Task.sleep(nanoseconds: 200_000_000)

        let client = LookinClient()
        let connectedPort = try await client.connect(customPort: testPort)
        XCTAssertEqual(connectedPort, testPort)
        XCTAssertTrue(client.isConnected)

        // Test Ping
        let pingResult = try await client.ping()
        XCTAssertTrue(pingResult.alive)
        XCTAssertFalse(pingResult.inBackground)

        // Test AppInfo
        let appInfo = try await client.fetchAppInfo()
        XCTAssertEqual(appInfo.appName, "MockLookinApp")
        XCTAssertEqual(appInfo.appBundleIdentifier, "com.mock.lookin")

        // Test InvokeMethod
        let invokeResult = try await client.invokeMethod(oid: 100, selector: "reloadData")
        XCTAssertEqual(invokeResult["description"] as? String, "invoked_mock")

        client.disconnect()
        XCTAssertFalse(client.isConnected)
    }

    func testNotConnectedThrowsError() async {
        let client = LookinClient()
        do {
            _ = try await client.ping()
            XCTFail("Should have thrown notConnected error")
        } catch let error as LookinClientError {
            if case .notConnected = error {
                // Expected
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
