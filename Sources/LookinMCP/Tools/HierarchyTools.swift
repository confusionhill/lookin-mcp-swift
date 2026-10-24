import Foundation
import LookinClient
import LookinModels

public final class HierarchyTools: Sendable {
    private let client: LookinClient
    private let formatter: CompactHierarchyFormatter

    public init(client: LookinClient, formatter: CompactHierarchyFormatter = CompactHierarchyFormatter()) {
        self.client = client
        self.formatter = formatter
    }

    public func getHierarchy(maxDepth: Int? = nil, visibleOnly: Bool = false, detailed: Bool = false) async throws -> String {
        let hierarchy = try await client.fetchHierarchy()
        guard let items = hierarchy.displayItems, !items.isEmpty else {
            return "[]"
        }
        return try formatter.toJSONString(items: items, maxDepth: maxDepth, visibleOnly: visibleOnly, detailed: detailed)
    }

    public func searchHierarchy(text: String? = nil, className: String? = nil, oid: Int? = nil) async throws -> String {
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

    public func getElementDetails(oid: Int, includeScreenshots: Bool = false) async throws -> String {
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
            if let pngData = VisualTools.extractImageData(from: img) {
                result["soloScreenshotBase64"] = pngData.base64EncodedString()
            }
        }

        let jsonData = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
        return String(data: jsonData, encoding: .utf8) ?? "{}"
    }
}
