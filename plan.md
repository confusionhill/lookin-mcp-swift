# Lookin MCP Server — Project Plan & Architecture

This document outlines the architectural blueprint, functionality specification, technology stack choices, and implementation phases for building a standalone **Model Context Protocol (MCP) Server** for **LookinServer**.

This MCP server enables AI agents (such as Claude Code, Antigravity, or Cursor) to inspect, debug, and interact in real-time with running iOS apps in the Simulator or on physical devices.

---

## 1. Vision & Core Value Proposition

When developing or debugging iOS apps, AI coding agents are traditionally blind to the runtime state—they can only read source code and compiler logs. 

By bridging the AI agent to LookinServer via MCP, the agent gains:
- **Vision & Layout Awareness**: Inspect live view hierarchies, bounds, frames, clipping, and screenshots.
- **Runtime State Introspection**: Read ivars, properties, memory addresses, and class inheritance chains.
- **Interactive Debugging**: Modify view properties on the fly (alpha, hidden, colors, text) and execute selectors directly on live objects without recompiling.

---

## 2. Technical Feasibility & Framework Selection

From [contract.md](file:///Users/dika/Documents/github/LookinServer/contract.md), LookinServer uses:
1. **Transport**: Raw TCP over loopback (`127.0.0.1`), ports `47164`–`47169` (Simulator) or `47175`–`47179` (USB via `usbmuxd`).
2. **Wire Framing**: PeerTalk 16-byte binary header (`version: uint32`, `type: uint32`, `tag: uint32`, `payloadSize: uint32`).
3. **Serialization**: Apple's proprietary **`NSKeyedArchiver` / `NSSecureCoding`** binary plist format.

### Technology Stack & MCP Framework Choice

To communicate with LookinServer, we need native handling of Apple's binary `NSKeyedArchiver` archives and low-level networking (`Network.framework`). 

We will build the server as a standalone **Swift command-line executable** powered by **[SwiftMCP](https://github.com/Cocoanetics/SwiftMCP)** by Cocoanetics.

#### Why SwiftMCP?
- **Swift Macro Tooling (`@MCPServer`, `@MCPTool`)**: Automatically synthesizes JSON-RPC schemas and tool registration from native Swift functions, argument types, and docstrings.
- **Built-in `StdioServerTransport`**: Native STDIO transport required by AI agents (Claude Code, Antigravity, Cursor) out of the box.
- **100% Cocoa Native**: Direct access to `Foundation`, `Network`, `NSKeyedUnarchiver`, and `NSSecureCoding` with zero bridge overhead or serialization loss.
- **Single Static/Compiled Binary**: Easy distribution via Homebrew or `swift build -c release`.

---

## 3. Architecture Overview

```
+-----------------------------------------------------------+
|                        AI Agent                           |
|               (Claude Code / Antigravity)                 |
+-----------------------------------------------------------+
                             |
                   MCP JSON-RPC over stdio
                             |
+----------------------------v------------------------------+
|            lookin-mcp-server (Swift + SwiftMCP)           |
|                                                           |
|  +-----------------------------------------------------+  |
|  | SwiftMCP (@MCPServer, @MCPTool, StdioTransport)     |  |
|  +---------------------------+-------------------------+  |
|                              |                            |
|  +---------------------------v-------------------------+  |
|  | LookinClient (NWConnection, PeerTalk 16B Framing,   |  |
|  |               NSKeyedArchiver / NSSecureCoding)     |  |
|  +-----------------------------------------------------+  |
+-----------------------------------------------------------+
                             |
               TCP Loopback (Port 47164..47169)
               or USB via usbmux (Port 47175..47179)
                             |
+----------------------------v------------------------------+
|                     Running iOS App                       |
|                   (LookinServer Pod)                      |
+-----------------------------------------------------------+
```

---

## 4. MCP Tools & Functionalities

The MCP server will expose clean, agent-friendly tools designed for LLM comprehension:

### 4.1. Device & Connection Management

#### `lookin_connect`
- **Description**: Connects to LookinServer on the local iOS Simulator or physical USB device. Automatically scans the port range (`47164`–`47169` or `47175`–`47179`).
- **Inputs**:
  - `target` (`"simulator"` | `"usb"`, default `"simulator"`)
  - `customPort` (optional `number`)
- **Returns**: Connection status, target port, protocol version, and latency.

#### `lookin_ping`
- **Description**: Pings the connected app to test responsiveness and detect whether the app is active in foreground or backgrounded.
- **Returns**: Alive status, `appIsInBackground` flag.

#### `lookin_get_app_info`
- **Description**: Retrieves application and device metadata.
- **Inputs**:
  - `includeScreenshot` (`boolean`, optional, default `false`)
- **Returns**: App name, Bundle ID, OS version, device model, screen resolution, scale factor, and optional base64 screenshot.

---

### 4.2. UI Hierarchy Inspection (Agent Eyes)

#### `lookin_get_hierarchy`
- **Description**: Dumps the complete UI hierarchy. Returns a compact, structured tree format with view classes, frames, visibility, and object IDs (`oid`).
- **Inputs**:
  - `maxDepth` (`number`, optional): Limit tree depth to reduce token usage.
  - `visibleOnly` (`boolean`, optional, default `false`): Filter out hidden views (`isHidden == true` or `alpha == 0`).
  - `format` (`"compact"` | `"detailed"`, default `"compact"`).
- **Returns**:
  ```json
  [
    {
      "oid": 10592384,
      "class": "UIWindow",
      "frame": [0, 0, 393, 852],
      "subviews": [
        {
          "oid": 10593420,
          "class": "UINavigationController",
          "subviews": [
            {
              "oid": 10594110,
              "class": "UIButton",
              "frame": [20, 100, 150, 44],
              "text": "Submit",
              "userInteractionEnabled": true
            }
          ]
        }
      ]
    }
  ]
  ```

#### `lookin_search_hierarchy`
- **Description**: Finds elements in the UI tree matching specific criteria without dumping the whole tree.
- **Inputs**:
  - `text` (optional `string`): Matches button titles, label text, or custom display titles.
  - `className` (optional `string`): Matches or subclasses (e.g. `"UITableView"`, `"UIButton"`).
  - `oid` (optional `number`): Direct lookup.
- **Returns**: Array of matched elements with full path and frame details.

#### `lookin_get_element_details`
- **Description**: Retrieves in-depth attributes and layout constraints for a specific element.
- **Inputs**:
  - `oid` (`number`, required): Element object ID from hierarchy.
  - `includeScreenshots` (`boolean`, optional): Fetch solo/group screenshots of this view.
- **Returns**: Attribute groups (Colors, Fonts, AutoLayout constraints, Layer properties, Gestures).

---

### 4.3. Visual Verification

#### `lookin_capture_screenshot`
- **Description**: Captures a visual snapshot of the whole app screen or a specific view.
- **Inputs**:
  - `oid` (optional `number`): If omitted, captures full screen. If specified, captures that view solo or with subviews.
  - `savePath` (optional `string`): File path to save PNG. If omitted, returns base64 image artifact.
- **Returns**: File path and dimensions, or image data.

#### `lookin_get_image_data`
- **Description**: Extracts raw bitmap image bytes from a `UIImageView` on screen.
- **Inputs**:
  - `oid` (`number`, required): OID of the `UIImageView`.
- **Returns**: Image metadata (size, format) and saved image path.

---

### 4.4. Live Runtime Mutation & Manipulation

#### `lookin_modify_attribute`
- **Description**: Live-edits a view property on the running app.
- **Inputs**:
  - `oid` (`number`, required): Target view/layer OID.
  - `property` (`string`, required): e.g. `"hidden"`, `"alpha"`, `"backgroundColor"`, `"frame"`.
  - `value` (`any`, required): e.g. `true`, `0.5`, `"#FF0000"`, `{"x": 0, "y": 0, "width": 100, "height": 100}`.
- **Returns**: Updated view status and confirmation.

#### `lookin_invoke_method`
- **Description**: Calls an arbitrary Objective-C selector on a live object in the running app.
- **Inputs**:
  - `oid` (`number`, required): Target object ID.
  - `selector` (`string`, required): Selector name (e.g. `"reloadData"`, `"setNeedsLayout"`, `"refresh"`).
- **Returns**: Method execution result description and return value representation.

#### `lookin_list_methods`
- **Description**: Introspects and lists all callable selectors available on an object's class or superclasses.
- **Inputs**:
  - `className` (`string`, required): Target class name.
  - `hasArguments` (`boolean`, optional, default `false`).
- **Returns**: Array of selector strings.

#### `lookin_inspect_object`
- **Description**: Dumps runtime memory layout, ivars, and class inheritance chain of an object.
- **Inputs**:
  - `oid` (`number`, required): Target object ID.
- **Returns**: Memory address, class chain (`["MyCustomView", "UIView", "UIResponder", "NSObject"]`), and ivar traces.

---

## 5. Repository Structure & SwiftMCP Integration

Recommended structure for the new standalone repo (`lookin-mcp`):

```
lookin-mcp/
├── Package.swift
├── README.md
├── LICENSE
├── Sources/
│   ├── LookinMCP/                     # Main MCP Executable
│   │   ├── main.swift                 # Entry point, StdioServerTransport execution
│   │   ├── LookinMCPServer.swift      # @MCPServer definition & tool registration
│   │   └── Tools/                     # Tool implementations
│   │       ├── DeviceTools.swift      # Ping, Connect, App Info
│   │       ├── HierarchyTools.swift   # Hierarchy retrieval & fuzzy search
│   │       ├── VisualTools.swift      # Screenshot capture & image extraction
│   │       ├── MutationTools.swift    # Attribute modification
│   │       └── IntrospectionTools.swift # Method invocation, object inspection
│   ├── LookinClient/                  # Transport & Lookin Protocol Client
│   │   ├── LookinConnection.swift     # NWConnection socket manager & port discovery
│   │   ├── PeerTalkProtocol.swift     # 16-byte frame pack/unpack (Big-Endian)
│   │   └── RequestDispatcher.swift    # Async request/response correlation by tag
│   └── LookinModels/                  # Deserialization & Codable / NSSecureCoding models
│       ├── LookinDefines.swift        # Enums & constants (from contract.md)
│       ├── LookinAppInfo.swift
│       ├── LookinHierarchyInfo.swift
│       ├── LookinDisplayItem.swift
│       └── LookinDisplayItemDetail.swift
└── Tests/
    └── LookinClientTests/
```

### 5.1. `Package.swift` Setup

```swift
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "lookin-mcp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "lookin-mcp", targets: ["LookinMCP"])
    ],
    dependencies: [
        .package(url: "https://github.com/Cocoanetics/SwiftMCP.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "LookinMCP",
            dependencies: [
                .product(name: "SwiftMCP", package: "SwiftMCP"),
                "LookinClient",
                "LookinModels"
            ]
        ),
        .target(
            name: "LookinClient",
            dependencies: ["LookinModels"]
        ),
        .target(
            name: "LookinModels"
        ),
        .testTarget(
            name: "LookinClientTests",
            dependencies: ["LookinClient"]
        )
    ]
)
```

### 5.2. Tool Declaration Pattern with SwiftMCP

Using `SwiftMCP`'s `@MCPServer` and `@MCPTool` macros, tools are declared declaratively and type-safely:

```swift
import Foundation
import SwiftMCP

@MCPServer
public final class LookinMCPServer {
    private let client = LookinClient()

    public init() {}

    /// Connect to LookinServer on iOS Simulator (47164-47169) or USB Device (47175-47179)
    @MCPTool
    public func lookinConnect(target: String = "simulator") async throws -> String {
        let isSim = (target.lowercased() == "simulator")
        let port = try await client.connect(mode: isSim ? .simulator : .usb)
        return "Connected to LookinServer on port \(port)"
    }

    /// Retrieve the current UI hierarchy tree in compact JSON format
    @MCPTool
    public func lookinGetHierarchy(maxDepth: Int? = nil, visibleOnly: Bool = false) async throws -> String {
        let hierarchy = try await client.fetchHierarchy()
        let compactTree = hierarchy.toCompactJSON(maxDepth: maxDepth, visibleOnly: visibleOnly)
        return compactTree
    }

    /// Live-modify an attribute of a view or layer
    @MCPTool
    public func lookinModifyAttribute(oid: Int, property: String, value: String) async throws -> String {
        try await client.modifyAttribute(oid: UInt(oid), property: property, value: value)
        return "Successfully modified \(property) on object \(oid)"
    }
}
```

And in `main.swift`:

```swift
import SwiftMCP

let server = LookinMCPServer()
let transport = StdioServerTransport()
try await server.start(transport: transport)
```

---

## 6. Implementation Roadmap

### Phase 1: Transport & Wire Protocol Foundation
- [ ] Initialize Swift Package with `platforms: [.macOS(.v13)]`.
- [ ] Implement TCP client socket with `NWConnection` (`Network.framework`).
- [ ] Implement port scanner across `47164`–`47169` (Simulator) and `47175`–`47179` (USB).
- [ ] Implement PeerTalk 16-byte binary frame packing and unpacking (`htonl`/`ntohl`).
- [ ] Test roundtrip `LookinRequestTypePing` (`200`) and verify heartbeat response.

### Phase 2: Deserialization & Model Mapping
- [ ] Set up `NSKeyedUnarchiver` bridge to deserialize `LookinConnectionResponseAttachment`.
- [ ] Port/import core data models from `LookinShared` (`LookinAppInfo`, `LookinHierarchyInfo`, `LookinDisplayItem`, `LookinDisplayItemDetail`).
- [ ] Implement `LookinRequestTypeApp` (`201`) and `LookinRequestTypeHierarchy` (`202`).
- [ ] Convert hierarchical display items into concise JSON trees optimized for LLM token limits.

### Phase 3: SwiftMCP Server Integration
- [ ] Add `SwiftMCP` dependency from `https://github.com/Cocoanetics/SwiftMCP.git`.
- [ ] Wire up `@MCPServer` and initialize `StdioServerTransport` in `main.swift`.
- [ ] Annotate tool methods with `@MCPTool` docstrings and input schemas.
- [ ] Register inspection tools: `lookin_connect`, `lookin_ping`, `lookin_get_app_info`, `lookin_get_hierarchy`, `lookin_search_hierarchy`.
- [ ] Register screenshot tools: `lookin_capture_screenshot`, `lookin_get_image_data`.

### Phase 4: Mutation & Runtime Introspection
- [ ] Implement `LookinRequestTypeInbuiltAttrModification` (`204`).
- [ ] Implement `LookinRequestTypeInvokeMethod` (`206`) and `LookinRequestTypeAllSelectorNames` (`213`).
- [ ] Implement `LookinRequestTypeFetchObject` (`207`).
- [ ] Add mutation safety checks (prevent crashing the host app during method invocation).

### Phase 5: Verification & Developer Experience
- [ ] Test end-to-end integration against `LookinDemo` iOS project.
- [ ] Test integration with Claude Code (`claude mcp add`) and Antigravity IDE (`mcp_config.json`).
- [ ] Document installation, CLI arguments, and sample prompts for agents.

---

## 7. Sample Agent Use Cases

Once installed, your AI agent can perform workflows like:

```markdown
User: "The login button on the checkout screen looks misaligned. Check what's going on."
Agent: 
1. Calls `lookin_search_hierarchy(text: "Login")` -> discovers OID `1048290`.
2. Calls `lookin_get_element_details(oid: 1048290)` -> inspects AutoLayout constraints.
3. Notices `trailingConstraint` is missing, causing frame width to collapse to zero.
4. Calls `lookin_modify_attribute(oid: 1048290, property: "frame", value: ...)` to verify visual fix on-screen.
5. Edits the corresponding Swift code in Xcode project.
```
