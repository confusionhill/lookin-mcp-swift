import Foundation
import SwiftMCP
import LookinClient
import LookinModels

/// LookinMCPServer acts as the thin MCP protocol and dispatch handler layer,
/// routing MCP tool invocations to domain-specific handlers under `Tools/`.
@MCPServer(name: "lookin-mcp", version: "0.1.0")
public final class LookinMCPServer: Sendable {
    private let client: LookinClient
    private let connectionTools: ConnectionTools
    private let hierarchyTools: HierarchyTools
    private let visualTools: VisualTools
    private let mutationTools: MutationTools

    public init() {
        let client = LookinClient()
        self.client = client
        self.connectionTools = ConnectionTools(client: client)
        self.hierarchyTools = HierarchyTools(client: client)
        self.visualTools = VisualTools(client: client)
        self.mutationTools = MutationTools(client: client)
    }

    // MARK: - 1. Device & Connection Management

    /// Connects to LookinServer on the local iOS Simulator or physical USB device.
    @MCPTool(name: "lookin_connect", description: "Connects to LookinServer on the local iOS Simulator or physical USB device.")
    public func lookinConnect(target: String = "simulator", customPort: Int? = nil) async throws -> String {
        try await connectionTools.connect(target: target, customPort: customPort)
    }

    /// Disconnects from LookinServer.
    @MCPTool(name: "lookin_disconnect", description: "Disconnects from LookinServer.")
    public func lookinDisconnect() -> String {
        connectionTools.disconnect()
    }

    /// Pings the connected app to test responsiveness and foreground/background status.
    @MCPTool(name: "lookin_ping", description: "Pings the connected app to test responsiveness and foreground/background status.")
    public func lookinPing() async throws -> String {
        try await connectionTools.ping()
    }

    /// Retrieves host application and device metadata (app name, bundle ID, OS version, screen size).
    @MCPTool(name: "lookin_get_app_info", description: "Retrieves host application and device metadata (app name, bundle ID, OS version, screen size).")
    public func lookinGetAppInfo(includeScreenshot: Bool = false) async throws -> String {
        try await connectionTools.getAppInfo(includeScreenshot: includeScreenshot)
    }

    // MARK: - 2. UI Hierarchy Inspection

    /// Dumps the UI hierarchy tree in compact JSON format with classes, frames, and object IDs (oid).
    @MCPTool(name: "lookin_get_hierarchy", description: "Dumps the UI hierarchy tree in compact JSON format with classes, frames, and object IDs (oid).")
    public func lookinGetHierarchy(maxDepth: Int? = nil, visibleOnly: Bool = false, detailed: Bool = false) async throws -> String {
        try await hierarchyTools.getHierarchy(maxDepth: maxDepth, visibleOnly: visibleOnly, detailed: detailed)
    }

    /// Searches the UI hierarchy for elements matching text, class name, or object ID (oid).
    @MCPTool(name: "lookin_search_hierarchy", description: "Searches the UI hierarchy for elements matching text, class name, or object ID (oid).")
    public func lookinSearchHierarchy(text: String? = nil, className: String? = nil, oid: Int? = nil) async throws -> String {
        try await hierarchyTools.searchHierarchy(text: text, className: className, oid: oid)
    }

    /// Retrieves in-depth attributes and layout constraints for a specific element by OID.
    @MCPTool(name: "lookin_get_element_details", description: "Retrieves in-depth attributes and layout constraints for a specific element by OID.")
    public func lookinGetElementDetails(oid: Int, includeScreenshots: Bool = false) async throws -> String {
        try await hierarchyTools.getElementDetails(oid: oid, includeScreenshots: includeScreenshots)
    }

    // MARK: - 3. Visual Verification

    /// Captures a screenshot of the whole screen or a specific view by OID.
    @MCPTool(name: "lookin_capture_screenshot", description: "Captures a screenshot of the whole screen or a specific view by OID.")
    public func lookinCaptureScreenshot(oid: Int? = nil, savePath: String? = nil) async throws -> String {
        try await visualTools.captureScreenshot(oid: oid, savePath: savePath)
    }

    /// Extracts raw bitmap image bytes from a UIImageView by OID.
    @MCPTool(name: "lookin_get_image_data", description: "Extracts raw bitmap image bytes from a UIImageView by OID.")
    public func lookinGetImageData(oid: Int, savePath: String? = nil) async throws -> String {
        try await visualTools.getImageData(oid: oid, savePath: savePath)
    }

    // MARK: - 4. Live Runtime Mutation & Manipulation

    /// Live-edits a view property on the running app (hidden, alpha, text, userInteractionEnabled, backgroundColor).
    @MCPTool(name: "lookin_modify_attribute", description: "Live-edits a view property on the running app (hidden, alpha, text, userInteractionEnabled).")
    public func lookinModifyAttribute(oid: Int, property: String, value: String) async throws -> String {
        try await mutationTools.modifyAttribute(oid: oid, property: property, value: value)
    }

    /// Calls an arbitrary Objective-C selector on a live object in the running app.
    @MCPTool(name: "lookin_invoke_method", description: "Calls an arbitrary Objective-C selector on a live object in the running app.")
    public func lookinInvokeMethod(oid: Int, selector: String) async throws -> String {
        try await mutationTools.invokeMethod(oid: oid, selector: selector)
    }

    /// Lists all callable selectors available on a given class or its superclasses.
    @MCPTool(name: "lookin_list_methods", description: "Lists all callable selectors available on a given class or its superclasses.")
    public func lookinListMethods(className: String, hasArguments: Bool = false) async throws -> String {
        try await mutationTools.listMethods(className: className, hasArguments: hasArguments)
    }

    /// Dumps runtime memory address, ivars, and class inheritance chain of an object by OID.
    @MCPTool(name: "lookin_inspect_object", description: "Dumps runtime memory address, ivars, and class inheritance chain of an object by OID.")
    public func lookinInspectObject(oid: Int) async throws -> String {
        try await mutationTools.inspectObject(oid: oid)
    }
}
