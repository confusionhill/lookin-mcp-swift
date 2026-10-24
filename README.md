# lookin-mcp 🔍📱

[![Swift](https://img.shields.io/badge/Swift-5.10%20%7C%206.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013%2B-blue.svg)](https://apple.com)
[![Protocol](https://img.shields.io/badge/Protocol-Model%20Context%20Protocol%20(MCP)-purple.svg)](https://modelcontextprotocol.io)
[![LookinServer](https://img.shields.io/badge/LookinServer-v1.2.8%20%7C%20v7-green.svg)](https://lookin.work)

A standalone **Model Context Protocol (MCP) Server** for [LookinServer](https://lookin.work).

**lookin-mcp** bridges AI coding assistants (such as Claude Code, Cursor, and Google Antigravity) to running iOS apps in the iOS Simulator or on physical USB devices. It empowers AI agents with:
- **Vision & Layout Awareness**: Inspect live view hierarchies, bounds, frames, clipping, and screenshots without recompiling.
- **Runtime State Introspection**: Read ivars, properties, memory addresses, and class inheritance chains.
- **Interactive Live Debugging**: Mutate view properties on the fly (`hidden`, `alpha`, `text`, `userInteractionEnabled`) and execute arbitrary selectors on live objects.

---

## Architecture

```
+-----------------------------------------------------------+
|                        AI Agent                           |
|               (Claude Code / Cursor / Antigravity)        |
+-----------------------------------------------------------+
                             |
                   MCP JSON-RPC over stdio
                             |
+----------------------------v------------------------------+
|                    lookin-mcp                             |
|                                                           |
|  +-----------------------------------------------------+  |
|  | SwiftMCP (@MCPServer, @MCPTool, StdioTransport)     |  |
|  +---------------------------+-------------------------+  |
|                              |                            |
|  +---------------------------v-------------------------+  |
|  | LookinClient (NWConnection, PeerTalk 16B Framing,   |  |
|  |               NSSecureCoding & NSKeyedUnarchiver)   |  |
|  +-----------------------------------------------------+  |
+-----------------------------------------------------------+
                             |
                TCP Loopback (Port 47164..47169)
                or USB via usbmux (Port 47175..47179)
                             |
+----------------------------v------------------------------+
|                     Running iOS App                       |
|                   (LookinServer Pod / SPM)                |
+-----------------------------------------------------------+
```

---

## MCP Tools Reference

### 1. Connection & Device
- **`lookin_connect`**: Connects to LookinServer on the local iOS Simulator (`47164`–`47169`) or physical USB device (`47175`–`47179`).
  - `target` (`"simulator"` | `"usb"`, default `"simulator"`)
  - `customPort` (optional `number`)
- **`lookin_disconnect`**: Closes the active connection.
- **`lookin_ping`**: Tests responsiveness and reports whether the app is active or in background.
- **`lookin_get_app_info`**: Retrieves application name, bundle ID, OS version, device model, screen resolution, scale factor, and optional screenshot.
  - `includeScreenshot` (`boolean`, default `false`)

### 2. UI Hierarchy Inspection
- **`lookin_get_hierarchy`**: Dumps the complete UI hierarchy in compact or detailed JSON format with classes, frames, visibility, and object IDs (`oid`).
  - `maxDepth` (optional `number`): Limit tree depth to conserve LLM context tokens.
  - `visibleOnly` (`boolean`, default `false`): Filter out hidden views (`isHidden == true` or `alpha <= 0`).
  - `detailed` (`boolean`, default `false`): Include bounds and extra layout attributes.
- **`lookin_search_hierarchy`**: Searches the UI hierarchy without dumping the entire tree.
  - `text` (optional `string`): Matches button titles, label text, or custom titles.
  - `className` (optional `string`): Matches or subclasses (e.g. `"UIButton"`, `"UITableView"`).
  - `oid` (optional `number`): Direct lookup.
- **`lookin_get_element_details`**: Retrieves in-depth attributes, layout constraints, and properties for a specific element.
  - `oid` (`number`, required): Target view object ID.
  - `includeScreenshots` (`boolean`, default `false`)

### 3. Visual Verification
- **`lookin_capture_screenshot`**: Captures a visual snapshot of the screen or a specific view.
  - `oid` (optional `number`): View OID (captures view solo/group), or omit for full screen.
  - `savePath` (optional `string`): File path to save PNG. If omitted, returns base64 image data.
- **`lookin_get_image_data`**: Extracts raw bitmap image bytes from a `UIImageView` on screen.
  - `oid` (`number`, required): OID of the `UIImageView`.
  - `savePath` (optional `string`)

### 4. Live Mutation & Introspection
- **`lookin_modify_attribute`**: Live-edits a view property on the running app.
  - `oid` (`number`, required): Target view/layer OID.
  - `property` (`string`, required): e.g. `"hidden"`, `"alpha"`, `"text"`, `"userInteractionEnabled"`, or custom setter.
  - `value` (`string`, required): e.g. `"true"`, `"false"`, `"0.5"`, `"Submit Order"`.
- **`lookin_invoke_method`**: Calls an arbitrary Objective-C selector on a live object in the running app.
  - `oid` (`number`, required): Target object ID.
  - `selector` (`string`, required): e.g. `"reloadData"`, `"setNeedsLayout"`.
- **`lookin_list_methods`**: Introspects all callable selectors available on an object's class or superclasses.
  - `className` (`string`, required): e.g. `"UIView"`, `"UIButton"`.
  - `hasArguments` (`boolean`, default `false`)
- **`lookin_inspect_object`**: Dumps runtime memory layout, ivars, and class inheritance chain of an object.
  - `oid` (`number`, required): Target object ID.

---

## Prerequisites: Integrate LookinServer into Your iOS App

For `lookin-mcp` to connect to your iOS app, the app must have [**LookinServer**](https://github.com/QMUI/LookinServer) integrated into its debug build. LookinServer runs a lightweight in-app server that listens for inspector connections on localhost port `47164` (Simulator) or via usbmux (`47175`, physical devices).

### Integration Options

#### Option A: Swift Package Manager (SPM) - Recommended
1. In Xcode, select **File** > **Add Package Dependencies...**
2. Enter the repository URL:
   ```
   https://github.com/QMUI/LookinServer.git
   ```
3. Add `LookinServer` to your main application target (configure it for **Debug** builds only).

#### Option B: CocoaPods
Add `LookinServer` to your `Podfile` for debug configurations:

```ruby
pod 'LookinServer', :configurations => ['Debug']

# If your project uses Swift and you want Swift extensions:
pod 'LookinServer/Swift', :configurations => ['Debug']
```
Then run `pod install`.

> **Note on Swift Methods**: Lookin inspects views via the Objective-C runtime. If you want custom Swift methods, properties, or tokens to be visible and callable by `lookin-mcp`, annotate them with `@objc` (e.g. `@objc func setBackgroundColorToken(_ color: UIColor)`).

---

## Installation & Setup

### 1. Build from Source

```bash
git clone https://github.com/your-username/lookin-mcp.git
cd lookin-mcp
swift build -c release
```

The compiled binary will be located at `.build/release/lookin-mcp`.

### 2. Configure with AI Agents

#### Claude Code
Add to your project or user configuration:
```bash
claude mcp add lookin-mcp -- /absolute/path/to/lookin-mcp/.build/release/lookin-mcp
```

#### Antigravity / Cursor (`mcp_config.json` or `~/.cursor/mcp.json`)
```json
{
  "mcpServers": {
    "lookin-mcp": {
      "command": "/absolute/path/to/lookin-mcp/.build/release/lookin-mcp"
    }
  }
}
```

---

## Example Agent Workflow

```markdown
User: "The checkout button looks missing or hidden. Can you inspect what's happening on screen?"

Agent:
1. Calls lookin_connect() -> "Connected to LookinServer on port 47164 (simulator)"
2. Calls lookin_search_hierarchy(text: "Checkout") -> Discovers UIButton with oid 1048290 and isHidden: true.
3. Calls lookin_modify_attribute(oid: 1048290, property: "hidden", value: "false") -> Live view updates immediately in simulator!
4. Calls lookin_capture_screenshot(oid: 1048290) -> Verifies visual layout.
5. Edits corresponding view controller in Xcode to fix the visibility logic.
```

---

## Testing

Run unit tests covering PeerTalk 16-byte binary framing, `NSSecureCoding` model archiving/unarchiving, compact tree formatting, and live loopback client networking:

```bash
swift test
```

---

## License

MIT
