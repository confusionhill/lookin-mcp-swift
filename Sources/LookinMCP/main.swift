import Foundation
import SwiftMCP
import Logging

@main
struct LookinMCPMain {
    private static let lifecycleLogger: Logging.Logger = {
        var logger = Logging.Logger(label: "work.lookin.mcp.server") {
            StreamLogHandler.standardError(label: $0)
        }
        logger.logLevel = .notice
        return logger
    }()

    static func main() async throws {
        let server = LookinMCPServer()
        fputs("Lookin MCP Server (v1.0.0) ready on stdio transport\n", stderr)
        try await server.serve(over: [StdioTransport()], logger: lifecycleLogger)
    }
}
