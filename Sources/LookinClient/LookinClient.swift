import Foundation
import Network
import LookinModels

public enum LookinTarget: String, Sendable {
    case simulator
    case usb
}

public enum LookinClientError: LocalizedError, Sendable {
    case notConnected
    case connectionFailed(String)
    case timeout
    case serverError(code: Int, message: String)
    case decodingFailed(String)
    case invalidResponse
    case objectNotFound(UInt)

    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to LookinServer. Call lookin_connect first."
        case .connectionFailed(let reason):
            return "Failed to connect to LookinServer: \(reason)"
        case .timeout:
            return "Request to LookinServer timed out."
        case .serverError(let code, let message):
            return "LookinServer returned error [\(code)]: \(message)"
        case .decodingFailed(let reason):
            return "Failed to decode LookinServer response: \(reason)"
        case .invalidResponse:
            return "Received invalid or empty response from LookinServer."
        case .objectNotFound(let oid):
            return "Target object with OID \(oid) not found (it may have been deallocated)."
        }
    }
}

public final class LookinClient: @unchecked Sendable {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "work.lookin.mcp.client", qos: .userInitiated)
    private var isRunning = false
    private var receiveBuffer = Data()

    private var nextTag: UInt32 = 1
    private let tagLock = NSLock()

    // Continuations waiting for response by tag
    private var pendingRequests: [UInt32: (CheckedContinuation<LookinConnectionResponseAttachment, Error>, [LookinDisplayItemDetail])] = [:]
    private let requestsLock = NSLock()

    public private(set) var connectedPort: UInt16?
    public var isConnected: Bool {
        return connection != nil && isRunning
    }

    public init() {}

    deinit {
        disconnect()
    }

    private func allocateTag() -> UInt32 {
        tagLock.lock()
        defer { tagLock.unlock() }
        let tag = nextTag
        nextTag += 1
        if nextTag == 0 { nextTag = 1 }
        return tag
    }

    // MARK: - Connection Management

    public func connect(target: LookinTarget = .simulator, customPort: UInt16? = nil) async throws -> UInt16 {
        disconnect()

        let portsToTry: [UInt16]
        if let custom = customPort {
            portsToTry = [custom]
        } else {
            switch target {
            case .simulator:
                portsToTry = Array(LookinDefines.simulatorPortRange)
            case .usb:
                portsToTry = Array(LookinDefines.usbPortRange)
            }
        }

        for port in portsToTry {
            if let nwConn = try? await attemptConnection(host: "127.0.0.1", port: port, timeoutSeconds: 0.5) {
                self.connection = nwConn
                self.connectedPort = port
                self.isRunning = true
                self.receiveBuffer = Data()
                startReceiving()
                return port
            }
        }

        throw LookinClientError.connectionFailed(
            "Could not connect to LookinServer on any port in range \(portsToTry.first ?? 0)...\(portsToTry.last ?? 0). Is your app running with LookinServer enabled?"
        )
    }

    private final class ResumeState: @unchecked Sendable {
        private var flag = false
        private let lock = NSLock()
        func tryResume() -> Bool {
            lock.lock()
            defer { lock.unlock() }
            if flag { return false }
            flag = true
            return true
        }
    }

    private func attemptConnection(host: String, port: UInt16, timeoutSeconds: Double) async throws -> NWConnection {
        return try await withCheckedThrowingContinuation { continuation in
            let endpoint = NWEndpoint.hostPort(
                host: NWEndpoint.Host(host),
                port: NWEndpoint.Port(rawValue: port)!
            )
            let params = NWParameters.tcp
            params.preferNoProxies = true
            let conn = NWConnection(to: endpoint, using: params)
            let resumeState = ResumeState()

            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.schedule(deadline: .now() + timeoutSeconds)
            timer.setEventHandler {
                if resumeState.tryResume() {
                    conn.cancel()
                    continuation.resume(throwing: LookinClientError.timeout)
                }
            }
            timer.resume()

            conn.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    if resumeState.tryResume() {
                        timer.cancel()
                        continuation.resume(returning: conn)
                    }
                case .failed(let err):
                    if resumeState.tryResume() {
                        timer.cancel()
                        conn.cancel()
                        continuation.resume(throwing: err)
                    }
                case .cancelled:
                    if resumeState.tryResume() {
                        timer.cancel()
                        continuation.resume(throwing: LookinClientError.connectionFailed("Cancelled"))
                    }
                default:
                    break
                }
            }

            conn.start(queue: queue)
        }
    }

    public func disconnect() {
        requestsLock.lock()
        for (_, (continuation, _)) in pendingRequests {
            continuation.resume(throwing: LookinClientError.notConnected)
        }
        pendingRequests.removeAll()
        requestsLock.unlock()

        isRunning = false
        connectedPort = nil
        if let conn = connection {
            conn.cancel()
            connection = nil
        }
        receiveBuffer = Data()
    }

    // MARK: - Frame Receiving Loop

    private func startReceiving() {
        guard let conn = connection, isRunning else { return }

        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            guard let self = self else { return }

            if let data = content, !data.isEmpty {
                self.receiveBuffer.append(data)
                self.processReceiveBuffer()
            }

            if isComplete || error != nil {
                self.disconnect()
                return
            }

            if self.isRunning {
                self.startReceiving()
            }
        }
    }

    private func processReceiveBuffer() {
        while isRunning {
            do {
                guard let (frame, bytesConsumed) = try PeerTalkFrame.unpack(from: receiveBuffer) else {
                    break
                }
                receiveBuffer.removeSubrange(0..<bytesConsumed)
                dispatchFrame(frame)
            } catch {
                disconnect()
                break
            }
        }
    }

    private func dispatchFrame(_ frame: PeerTalkFrame) {
        let tag = frame.tag
        guard tag > 0 else {
            // Tag 0: push notification or unrequested event
            return
        }

        // Unarchive payload
        let attachment: LookinConnectionResponseAttachment
        if frame.payload.isEmpty {
            attachment = LookinConnectionResponseAttachment()
        } else {
            do {
                let unarchiver = try NSKeyedUnarchiver(forReadingFrom: frame.payload)
                unarchiver.requiresSecureCoding = false
                if let decoded = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? LookinConnectionResponseAttachment {
                    attachment = decoded
                } else if let genericAttach = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? LookinConnectionAttachment {
                    let resp = LookinConnectionResponseAttachment()
                    resp.data = genericAttach.data
                    resp.dataType = genericAttach.dataType
                    attachment = resp
                } else if let rawObj = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) {
                    let resp = LookinConnectionResponseAttachment()
                    resp.data = rawObj
                    attachment = resp
                } else {
                    attachment = LookinConnectionResponseAttachment()
                }
            } catch {
                requestsLock.lock()
                if let (continuation, _) = pendingRequests.removeValue(forKey: tag) {
                    requestsLock.unlock()
                    continuation.resume(throwing: LookinClientError.decodingFailed(error.localizedDescription))
                    return
                }
                requestsLock.unlock()
                return
            }
        }

        requestsLock.lock()
        guard let (continuation, accumulatedDetails) = pendingRequests[tag] else {
            requestsLock.unlock()
            return
        }

        // Handle chunked / streaming response (e.g. LookinRequestTypeHierarchyDetails)
        if attachment.dataTotalCount > 0 {
            var updatedDetails = accumulatedDetails
            if let details = attachment.data as? [LookinDisplayItemDetail] {
                updatedDetails.append(contentsOf: details)
            } else if let singleDetail = attachment.data as? LookinDisplayItemDetail {
                updatedDetails.append(singleDetail)
            }

            if updatedDetails.count >= Int(attachment.dataTotalCount) {
                pendingRequests.removeValue(forKey: tag)
                requestsLock.unlock()
                attachment.data = updatedDetails
                continuation.resume(returning: attachment)
            } else {
                pendingRequests[tag] = (continuation, updatedDetails)
                requestsLock.unlock()
            }
            return
        }

        pendingRequests.removeValue(forKey: tag)
        requestsLock.unlock()
        continuation.resume(returning: attachment)
    }

    // MARK: - Sending Requests

    public func sendRequest(type: LookinRequestType, payloadObject: Any? = nil, timeoutSeconds: Double = 10.0) async throws -> LookinConnectionResponseAttachment {
        guard let conn = connection, isRunning else {
            throw LookinClientError.notConnected
        }

        let tag = allocateTag()
        let payloadData: Data
        if let obj = payloadObject {
            payloadData = try NSKeyedArchiver.archivedData(withRootObject: obj, requiringSecureCoding: false)
        } else {
            payloadData = Data()
        }

        let frame = PeerTalkFrame(
            version: PeerTalkFrame.defaultVersion,
            type: type.rawValue,
            tag: tag,
            payload: payloadData
        )
        let frameBytes = frame.pack()

        return try await withCheckedThrowingContinuation { continuation in
            requestsLock.lock()
            pendingRequests[tag] = (continuation, [])
            requestsLock.unlock()

            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.schedule(deadline: .now() + timeoutSeconds)
            timer.setEventHandler { [weak self] in
                guard let self = self else { return }
                self.requestsLock.lock()
                if let (pendingContinuation, _) = self.pendingRequests.removeValue(forKey: tag) {
                    self.requestsLock.unlock()
                    pendingContinuation.resume(throwing: LookinClientError.timeout)
                } else {
                    self.requestsLock.unlock()
                }
            }
            timer.resume()

            conn.send(content: frameBytes, completion: .contentProcessed { [weak self] error in
                if let err = error {
                    timer.cancel()
                    self?.requestsLock.lock()
                    if let (pendingContinuation, _) = self?.pendingRequests.removeValue(forKey: tag) {
                        self?.requestsLock.unlock()
                        pendingContinuation.resume(throwing: err)
                    } else {
                        self?.requestsLock.unlock()
                    }
                }
            })
        }
    }

    // MARK: - High-Level APIs

    public func ping() async throws -> (alive: Bool, inBackground: Bool) {
        let response = try await sendRequest(type: .ping, timeoutSeconds: 3.0)
        if let err = response.error {
            throw LookinClientError.serverError(code: err.code, message: err.localizedDescription)
        }
        return (alive: true, inBackground: response.appIsInBackground)
    }

    public func fetchAppInfo(needImages: Bool = false) async throws -> LookinAppInfo {
        let params: [String: Any] = [
            "needImages": NSNumber(value: needImages),
            "local": [NSNumber]()
        ]
        let response = try await sendRequest(type: .app, payloadObject: params)
        if let err = response.error {
            throw LookinClientError.serverError(code: err.code, message: err.localizedDescription)
        }
        guard let appInfo = response.data as? LookinAppInfo else {
            throw LookinClientError.invalidResponse
        }
        return appInfo
    }

    public func fetchHierarchy(clientVersion: String = LookinDefines.serverReadableVersion) async throws -> LookinHierarchyInfo {
        let params: [String: Any] = [
            "clientVersion": clientVersion
        ]
        let response = try await sendRequest(type: .hierarchy, payloadObject: params)
        if let err = response.error {
            throw LookinClientError.serverError(code: err.code, message: err.localizedDescription)
        }
        guard let hierarchyInfo = response.data as? LookinHierarchyInfo else {
            throw LookinClientError.invalidResponse
        }
        return hierarchyInfo
    }

    public func fetchHierarchyDetails(tasks: [LookinStaticAsyncUpdateTask]) async throws -> [LookinDisplayItemDetail] {
        guard !tasks.isEmpty else { return [] }
        let package = LookinStaticAsyncUpdateTasksPackage(tasks: tasks)
        let response = try await sendRequest(type: .hierarchyDetails, payloadObject: [package])
        if let err = response.error {
            throw LookinClientError.serverError(code: err.code, message: err.localizedDescription)
        }
        if let details = response.data as? [LookinDisplayItemDetail] {
            return details
        } else if let single = response.data as? LookinDisplayItemDetail {
            return [single]
        }
        return []
    }

    public func modifyAttribute(
        targetOid: UInt,
        setterSelector: String,
        getterSelector: String? = nil,
        attrType: Int = 0,
        value: Any? = nil
    ) async throws -> LookinDisplayItemDetail? {
        let mod = LookinAttributeModification(
            targetOid: targetOid,
            setterSelector: setterSelector,
            getterSelector: getterSelector,
            attrType: attrType,
            value: value
        )
        let response = try await sendRequest(type: .inbuiltAttrModification, payloadObject: mod)
        if let err = response.error {
            if err.code == LookinErrorCode.objectNotFound.rawValue {
                throw LookinClientError.objectNotFound(targetOid)
            }
            throw LookinClientError.serverError(code: err.code, message: err.localizedDescription)
        }
        return response.data as? LookinDisplayItemDetail
    }

    public func invokeMethod(oid: UInt, selector: String) async throws -> [String: Any] {
        let params: [String: Any] = [
            "oid": NSNumber(value: oid),
            "text": selector
        ]
        let response = try await sendRequest(type: .invokeMethod, payloadObject: params)
        if let err = response.error {
            if err.code == LookinErrorCode.objectNotFound.rawValue {
                throw LookinClientError.objectNotFound(oid)
            }
            throw LookinClientError.serverError(code: err.code, message: err.localizedDescription)
        }
        if let dict = response.data as? [String: Any] {
            return dict
        }
        return ["status": "invoked"]
    }

    public func fetchAllSelectorNames(className: String, hasArg: Bool = false) async throws -> [String] {
        let params: [String: Any] = [
            "className": className,
            "hasArg": NSNumber(value: hasArg)
        ]
        let response = try await sendRequest(type: .allSelectorNames, payloadObject: params)
        if let err = response.error {
            throw LookinClientError.serverError(code: err.code, message: err.localizedDescription)
        }
        if let names = response.data as? [String] {
            return names
        }
        return []
    }

    public func fetchObject(oid: UInt) async throws -> LookinObject {
        let response = try await sendRequest(type: .fetchObject, payloadObject: NSNumber(value: oid))
        if let err = response.error {
            if err.code == LookinErrorCode.objectNotFound.rawValue {
                throw LookinClientError.objectNotFound(oid)
            }
            throw LookinClientError.serverError(code: err.code, message: err.localizedDescription)
        }
        guard let obj = response.data as? LookinObject else {
            throw LookinClientError.invalidResponse
        }
        return obj
    }

    public func fetchImageViewImage(oid: UInt) async throws -> Data {
        let response = try await sendRequest(type: .fetchImageViewImage, payloadObject: NSNumber(value: oid))
        if let err = response.error {
            if err.code == LookinErrorCode.objectNotFound.rawValue {
                throw LookinClientError.objectNotFound(oid)
            }
            throw LookinClientError.serverError(code: err.code, message: err.localizedDescription)
        }
        if let data = response.data as? Data {
            return data
        }
        throw LookinClientError.invalidResponse
    }
}
