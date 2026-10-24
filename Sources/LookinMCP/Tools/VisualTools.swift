import Foundation
import LookinClient
import LookinModels
#if canImport(AppKit)
import AppKit
#endif

public final class VisualTools: Sendable {
    private let client: LookinClient

    public init(client: LookinClient) {
        self.client = client
    }

    public func captureScreenshot(oid: Int? = nil, savePath: String? = nil) async throws -> String {
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
            guard let data = Self.extractImageData(from: img) else {
                throw LookinClientError.decodingFailed("Failed to extract image data from view screenshot.")
            }
            pngData = data
        } else {
            let appInfo = try await client.fetchAppInfo(needImages: true)
            guard let img = appInfo.screenshot, let data = Self.extractImageData(from: img) else {
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

    public func getImageData(oid: Int, savePath: String? = nil) async throws -> String {
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

    public static func extractImageData(from imageObj: Any) -> Data? {
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
