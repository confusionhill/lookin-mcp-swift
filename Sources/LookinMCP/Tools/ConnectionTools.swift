import Foundation
import LookinClient
import LookinModels

public final class ConnectionTools: Sendable {
    private let client: LookinClient

    public init(client: LookinClient) {
        self.client = client
    }

    public func connect(target: String = "simulator", customPort: Int? = nil) async throws -> String {
        let isSim = (target.lowercased() == "simulator")
        let portUInt16 = customPort.map { UInt16($0) }
        let connectedPort = try await client.connect(target: isSim ? .simulator : .usb, customPort: portUInt16)
        return "Connected to LookinServer on port \(connectedPort) (\(target))."
    }

    public func disconnect() -> String {
        client.disconnect()
        return "Disconnected from LookinServer."
    }

    public func ping() async throws -> String {
        let result = try await client.ping()
        return "Pong: app is responsive (appIsInBackground: \(result.inBackground))"
    }

    public func getAppInfo(includeScreenshot: Bool = false) async throws -> String {
        let info = try await client.fetchAppInfo(needImages: includeScreenshot)
        var dict: [String: Any] = [
            "appName": info.appName ?? "Unknown",
            "appBundleIdentifier": info.appBundleIdentifier ?? "Unknown",
            "deviceDescription": info.deviceDescription ?? "Unknown",
            "deviceType": info.deviceType == 0 ? "Simulator" : (info.deviceType == 1 ? "iPad" : "iPhone"),
            "osDescription": info.osDescription ?? "Unknown",
            "screenWidth": info.screenWidth,
            "screenHeight": info.screenHeight,
            "screenScale": info.screenScale,
            "serverVersion": info.serverVersion,
            "serverReadableVersion": info.serverReadableVersion ?? LookinDefines.serverReadableVersion
        ]

        if includeScreenshot, let img = info.screenshot {
            if let pngData = VisualTools.extractImageData(from: img) {
                dict["screenshotBase64"] = pngData.base64EncodedString()
            }
        }

        let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
        return String(data: jsonData, encoding: .utf8) ?? "{}"
    }
}
