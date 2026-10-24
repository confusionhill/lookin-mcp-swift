import Foundation
import SwiftMCP
import Logging

var logger = Logging.Logger(label: "work.lookin.mcp.server") {
    StreamLogHandler.standardError(label: $0)
}
logger.logLevel = .notice

let server = LookinMCPServer()
fputs("Lookin MCP Server (v0.1.0) ready on stdio transport\n", stderr)
try await server.serve(over: [StdioTransport()], logger: logger)
