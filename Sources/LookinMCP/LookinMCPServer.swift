import Foundation
import SwiftMCP
import LookinClient
import LookinModels
#if canImport(AppKit)
import AppKit
#endif

@MCPServer(name: "lookin-mcp", version: "1.0.0")
public final class LookinMCPServer: Sendable {
    private let client = LookinClient()
    private let formatter = CompactHierarchyFormatter()

    public init() {}

    // MARK: - 1. Device & Connection Management

    /// Connects to LookinServer on the local iOS Simulator or physical USB device.
    /// - Parameters:
    ///   - target: Connection target: "simulator" (ports 47164-47169) or "usb" (ports 47175-47179). Default is "simulator".
    ///   - customPort: Optional specific TCP port to connect to.
    /// - Returns: Connection status message with connected port.
    @MCPTool(name: "lookin_connect", description: "Connects to LookinServer on the local iOS Simulator or physical USB device.")
    public func lookinConnect(target: String = "simulator", customPort: Int? = nil) async throws -> String {
        let isSim = (target.lowercased() == "simulator")
        let portUInt16 = customPort.map { UInt16($0) }
        let connectedPort = try await client.connect(target: isSim ? .simulator : .usb, customPort: portUInt16)
        return "Connected to LookinServer on port \(connectedPort) (\(target))."
    }

    /// Disconnects from LookinServer.
    /// - Returns: Confirmation message.
    @MCPTool(name: "lookin_disconnect", description: "Disconnects from LookinServer.")
    public func lookinDisconnect() -> String {
        client.disconnect()
        return "Disconnected from LookinServer."
    }

    /// Pings the connected app to test responsiveness and detect whether the app is active in foreground or background.
    /// - Returns: Ping status and whether app is in background.
    @MCPTool(name: "lookin_ping", description: "Pings the connected app to test responsiveness and foreground/background status.")
    public func lookinPing() async throws -> String {
        let result = try await client.ping()
        return "Pong: app is responsive (appIsInBackground: \(result.inBackground))"
    }

    /// Retrieves host application and device metadata (app name, bundle ID, OS version, device model, screen size).
    /// - Parameter includeScreenshot: Whether to include a full-screen screenshot representation. Default is false.
    /// - Returns: JSON formatted metadata.
    @MCPTool(name: "lookin_get_app_info", description: "Retrieves host application and device metadata (app name, bundle ID, OS version, screen size).")
    public func lookinGetAppInfo(includeScreenshot: Bool = false) async throws -> String {
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
            if let pngData = extractImageData(from: img) {
                dict["screenshotBase64"] = pngData.base64EncodedString()
            }
        }

        let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
        return String(data: jsonData, encoding: .utf8) ?? "{}"
    }

    // MARK: - 2. UI Hierarchy Inspection

    /// Dumps the UI hierarchy tree in compact or detailed JSON format with classes, frames, visibility, and object IDs (oid).
    /// - Parameters:
    ///   - maxDepth: Optional maximum depth of the tree to inspect (reduces token usage).
    ///   - visibleOnly: If true, filters out hidden views (isHidden == true or alpha == 0). Default is false.
    ///   - detailed: If true, includes bounds and extra layout attributes. Default is false.
    /// - Returns: JSON formatted hierarchy tree.
    @MCPTool(name: "lookin_get_hierarchy", description: "Dumps the UI hierarchy tree in compact JSON format with classes, frames, and object IDs (oid).")
    public func lookinGetHierarchy(maxDepth: Int? = nil, visibleOnly: Bool = false, detailed: Bool = false) async throws -> String {
        let hierarchy = try await client.fetchHierarchy()
        guard let items = hierarchy.displayItems, !items.isEmpty else {
            return "[]"
        }
        return try formatter.toJSONString(items: items, maxDepth: maxDepth, visibleOnly: visibleOnly, detailed: detailed)
    }

    /// Searches the UI hierarchy for elements matching text (label/button title), class name, or object ID (oid).
    /// - Parameters:
    ///   - text: Search query matching button titles, label text, or custom display titles.
    ///   - className: Class name or substring to match (e.g. 'UIButton', 'UITableView').
    ///   - oid: Target object ID to locate.
    /// - Returns: JSON list of matched elements with frame and hierarchy details.
    @MCPTool(name: "lookin_search_hierarchy", description: "Searches the UI hierarchy for elements matching text, class name, or object ID (oid).")
    public func lookinSearchHierarchy(text: String? = nil, className: String? = nil, oid: Int? = nil) async throws -> String {
        let hierarchy = try await client.fetchHierarchy()
        guard let items = hierarchy.displayItems, !items.isEmpty else {
            return "[]"
        }
        let matched = formatter.search(items: items, text: text, className: className, oid: oid.map { UInt($0) })
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(matched)
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    /// Retrieves in-depth attributes and layout constraints for a specific element.
    /// - Parameters:
    ///   - oid: Target element object ID (oid) from the hierarchy.
    ///   - includeScreenshots: Whether to fetch solo/group screenshots of this view. Default is false.
    /// - Returns: JSON formatted element details including attribute groups.
    @MCPTool(name: "lookin_get_element_details", description: "Retrieves in-depth attributes and layout constraints for a specific element by OID.")
    public func lookinGetElementDetails(oid: Int, includeScreenshots: Bool = false) async throws -> String {
        let taskType: UInt = includeScreenshots ? 1 : 0
        let task = LookinStaticAsyncUpdateTask(
            oid: UInt(oid),
            taskType: taskType,
            attrRequest: 1,
            needBasisVisualInfo: true,
            needSubitems: false
        )
        let details = try await client.fetchHierarchyDetails(tasks: [task])
        guard let detail = details.first else {
            return "{\"error\": \"No details found for oid \(oid)\"}"
        }

        var result: [String: Any] = [
            "oid": detail.displayItemOid,
            "customDisplayTitle": detail.customDisplayTitle ?? "",
            "failureCode": detail.failureCode
        ]

        var groupsList: [[String: Any]] = []
        if let groups = detail.attributesGroupList {
            for group in groups {
                var groupDict: [String: Any] = ["groupName": group.groupName ?? "Attributes"]
                var items: [[String: Any]] = []
                if let attrList = group.attrList {
                    for attr in attrList {
                        var attrDict: [String: Any] = [
                            "title": attr.title ?? "",
                            "attrId": attr.attrId ?? ""
                        ]
                        if let val = attr.value {
                            attrDict["value"] = "\(val)"
                        }
                        items.append(attrDict)
                    }
                }
                groupDict["attributes"] = items
                groupsList.append(groupDict)
            }
        }
        result["attributeGroups"] = groupsList

        if includeScreenshots, let img = detail.soloScreenshot {
            if let pngData = extractImageData(from: img) {
                result["soloScreenshotBase64"] = pngData.base64EncodedString()
            }
        }

        let jsonData = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
        return String(data: jsonData, encoding: .utf8) ?? "{}"
    }

    // MARK: - 3. Visual Verification

    /// Captures a screenshot of the entire screen or a specific view.
    /// - Parameters:
    ///   - oid: Optional view object ID (oid). If omitted, captures full screen.
    ///   - savePath: Optional file path to save the PNG image. If omitted, returns base64 image data.
    /// - Returns: Confirmation with file path or base64 image data.
    @MCPTool(name: "lookin_capture_screenshot", description: "Captures a screenshot of the whole screen or a specific view by OID.")
    public func lookinCaptureScreenshot(oid: Int? = nil, savePath: String? = nil) async throws -> String {
        let pngData: Data

        if let targetOid = oid {
            let task = LookinStaticAsyncUpdateTask(
                oid: UInt(targetOid),
                taskType: 2, // Group screenshot
                attrRequest: 0,
                needBasisVisualInfo: true
            )
            let details = try await client.fetchHierarchyDetails(tasks: [task])
            guard let detail = details.first, let img = detail.groupScreenshot ?? detail.soloScreenshot else {
                throw LookinClientError.invalidResponse
            }
            guard let data = extractImageData(from: img) else {
                throw LookinClientError.decodingFailed("Failed to extract image data from view screenshot.")
            }
            pngData = data
        } else {
            let appInfo = try await client.fetchAppInfo(needImages: true)
            guard let img = appInfo.screenshot, let data = extractImageData(from: img) else {
                throw LookinClientError.decodingFailed("Failed to extract screen screenshot from appInfo.")
            }
            pngData = data
        }

        if let path = savePath, !path.isEmpty {
            let fileURL = URL(fileURLWithPath: path)
            try pngData.write(to: fileURL)
            return "Screenshot saved to \(path) (\(pngData.count) bytes)"
        } else {
            let base64 = pngData.base64EncodedString()
            return "{\"format\": \"png\", \"bytes\": \(pngData.count), \"base64\": \"\(base64)\"}"
        }
    }

    /// Extracts raw bitmap image bytes from a UIImageView on screen.
    /// - Parameters:
    ///   - oid: Target UIImageView object ID (oid).
    ///   - savePath: Optional file path to save the image. If omitted, returns base64 data.
    /// - Returns: File path confirmation or base64 image data.
    @MCPTool(name: "lookin_get_image_data", description: "Extracts raw bitmap image bytes from a UIImageView by OID.")
    public func lookinGetImageData(oid: Int, savePath: String? = nil) async throws -> String {
        let imgData = try await client.fetchImageViewImage(oid: UInt(oid))

        if let path = savePath, !path.isEmpty {
            let fileURL = URL(fileURLWithPath: path)
            try imgData.write(to: fileURL)
            return "Image data saved to \(path) (\(imgData.count) bytes)"
        } else {
            let base64 = imgData.base64EncodedString()
            return "{\"bytes\": \(imgData.count), \"base64\": \"\(base64)\"}"
        }
    }

    // MARK: - 4. Live Runtime Mutation & Manipulation

    /// Live-edits a view property on the running app (e.g. 'hidden', 'alpha', 'text', 'userInteractionEnabled').
    /// - Parameters:
    ///   - oid: Target view or layer object ID (oid).
    ///   - property: Property name to modify: 'hidden', 'alpha', 'text', 'userInteractionEnabled', or a custom setter selector like 'setBackgroundColor:'.
    ///   - value: New value as string (e.g. 'true', 'false', '0.5', 'Submit').
    /// - Returns: Confirmation message of the modification.
    @MCPTool(name: "lookin_modify_attribute", description: "Live-edits a view property on the running app (hidden, alpha, text, userInteractionEnabled).")
    public func lookinModifyAttribute(oid: Int, property: String, value: String) async throws -> String {
        let prop = property.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let targetOid = UInt(oid)

        let setterSelector: String
        let getterSelector: String?
        let attrType: Int
        let rawValue: Any

        switch prop {
        case "hidden", "ishidden":
            setterSelector = "setHidden:"
            getterSelector = "isHidden"
            attrType = 1
            rawValue = NSNumber(value: value.lowercased() == "true" || value == "1")
        case "alpha":
            setterSelector = "setAlpha:"
            getterSelector = "alpha"
            attrType = 2
            let floatVal = Float(value) ?? 1.0
            rawValue = NSNumber(value: floatVal)
        case "userinteractionenabled", "isuserinteractionenabled":
            setterSelector = "setUserInteractionEnabled:"
            getterSelector = "isUserInteractionEnabled"
            attrType = 1
            rawValue = NSNumber(value: value.lowercased() == "true" || value == "1")
        case "text":
            setterSelector = "setText:"
            getterSelector = "text"
            attrType = 4
            rawValue = value as NSString
        default:
            // Custom selector pass-through
            setterSelector = property.hasSuffix(":") ? property : "\(property):"
            getterSelector = nil
            attrType = 0
            if let boolVal = Bool(value) {
                rawValue = NSNumber(value: boolVal)
            } else if let numVal = Double(value) {
                rawValue = NSNumber(value: numVal)
            } else {
                rawValue = value as NSString
            }
        }

        _ = try await client.modifyAttribute(
            targetOid: targetOid,
            setterSelector: setterSelector,
            getterSelector: getterSelector,
            attrType: attrType,
            value: rawValue
        )

        return "Successfully modified '\(property)' to '\(value)' on object \(oid)"
    }

    /// Calls an arbitrary Objective-C selector on a live object in the running app (e.g. 'reloadData', 'setNeedsLayout').
    /// - Parameters:
    ///   - oid: Target object ID (oid).
    ///   - selector: Selector name to invoke (e.g. 'reloadData', 'setNeedsLayout', 'refresh').
    /// - Returns: Method execution result description.
    @MCPTool(name: "lookin_invoke_method", description: "Calls an arbitrary Objective-C selector on a live object in the running app.")
    public func lookinInvokeMethod(oid: Int, selector: String) async throws -> String {
        let result = try await client.invokeMethod(oid: UInt(oid), selector: selector)
        let desc = result["description"] as? String ?? "executed"
        return "Invoked '\(selector)' on object \(oid): \(desc)"
    }

    /// Introspects and lists all callable selectors available on a given class or its superclasses.
    /// - Parameters:
    ///   - className: Class name to introspect (e.g. 'UIView', 'UIButton', 'UITableView').
    ///   - hasArguments: If true, returns methods that take arguments; otherwise returns zero-argument methods. Default is false.
    /// - Returns: JSON array of selector names.
    @MCPTool(name: "lookin_list_methods", description: "Lists all callable selectors available on a given class or its superclasses.")
    public func lookinListMethods(className: String, hasArguments: Bool = false) async throws -> String {
        let names = try await client.fetchAllSelectorNames(className: className, hasArg: hasArguments)
        let data = try JSONSerialization.data(withJSONObject: names, options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    /// Dumps runtime memory layout, ivars, and class inheritance chain of an object by its OID.
    /// - Parameter oid: Target object ID (oid).
    /// - Returns: JSON formatted object inspection details.
    @MCPTool(name: "lookin_inspect_object", description: "Dumps runtime memory address, ivars, and class inheritance chain of an object by OID.")
    public func lookinInspectObject(oid: Int) async throws -> String {
        let obj = try await client.fetchObject(oid: UInt(oid))
        var dict: [String: Any] = [
            "oid": obj.oid,
            "rawClassName": obj.rawClassName ?? "Unknown",
            "memoryAddress": obj.memoryAddress ?? "0x0",
            "classChainList": obj.classChainList ?? []
        ]
        if let traces = obj.ivarTraces {
            let ivars = traces.map { [
                "name": $0.ivarName ?? "",
                "type": $0.ivarType ?? "",
                "value": $0.ivarValue ?? ""
            ] }
            dict["ivarTraces"] = ivars
        }
        if let special = obj.specialTrace {
            dict["specialTrace"] = special
        }
        let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    // MARK: - Helper

    private func extractImageData(from imageObj: Any) -> Data? {
        if let data = imageObj as? Data {
            return data
        }
        #if canImport(AppKit)
        if let nsImage = imageObj as? NSImage {
            guard let tiff = nsImage.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff) else {
                return nil
            }
            return rep.representation(using: .png, properties: [:])
        }
        #endif
        return nil
    }
}
