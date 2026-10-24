import Foundation
import CoreGraphics

public struct CompactHierarchyNode: Codable, Sendable {
    public var oid: UInt
    public var className: String
    public var frame: [Double]
    public var bounds: [Double]?
    public var isHidden: Bool?
    public var alpha: Double?
    public var title: String?
    public var subviews: [CompactHierarchyNode]?

    enum CodingKeys: String, CodingKey {
        case oid
        case className = "class"
        case frame
        case bounds
        case isHidden = "hidden"
        case alpha
        case title
        case subviews
    }

    public init(
        oid: UInt,
        className: String,
        frame: [Double],
        bounds: [Double]? = nil,
        isHidden: Bool? = nil,
        alpha: Double? = nil,
        title: String? = nil,
        subviews: [CompactHierarchyNode]? = nil
    ) {
        self.oid = oid
        self.className = className
        self.frame = frame
        self.bounds = bounds
        self.isHidden = isHidden
        self.alpha = alpha
        self.title = title
        self.subviews = subviews
    }
}

public final class CompactHierarchyFormatter: Sendable {
    public init() {}

    public func format(
        items: [LookinDisplayItem],
        maxDepth: Int? = nil,
        visibleOnly: Bool = false,
        detailed: Bool = false,
        currentDepth: Int = 1
    ) -> [CompactHierarchyNode] {
        var results: [CompactHierarchyNode] = []

        for item in items {
            if visibleOnly && (item.isHidden || item.alpha <= 0.001) {
                continue
            }

            let frameArr: [Double] = [
                Double((item.frame.origin.x * 10).rounded() / 10),
                Double((item.frame.origin.y * 10).rounded() / 10),
                Double((item.frame.size.width * 10).rounded() / 10),
                Double((item.frame.size.height * 10).rounded() / 10)
            ]

            let boundsArr: [Double]? = detailed ? [
                Double((item.bounds.origin.x * 10).rounded() / 10),
                Double((item.bounds.origin.y * 10).rounded() / 10),
                Double((item.bounds.size.width * 10).rounded() / 10),
                Double((item.bounds.size.height * 10).rounded() / 10)
            ] : nil

            let shouldIncludeChildren: Bool
            if let maxDepth = maxDepth {
                shouldIncludeChildren = currentDepth < maxDepth
            } else {
                shouldIncludeChildren = true
            }

            var childrenNodes: [CompactHierarchyNode]? = nil
            if shouldIncludeChildren, let children = item.subitems, !children.isEmpty {
                let formattedChildren = format(
                    items: children,
                    maxDepth: maxDepth,
                    visibleOnly: visibleOnly,
                    detailed: detailed,
                    currentDepth: currentDepth + 1
                )
                if !formattedChildren.isEmpty {
                    childrenNodes = formattedChildren
                }
            }

            let node = CompactHierarchyNode(
                oid: item.oid,
                className: item.className,
                frame: frameArr,
                bounds: boundsArr,
                isHidden: item.isHidden ? true : nil,
                alpha: item.alpha < 0.999 ? Double((item.alpha * 100).rounded() / 100) : nil,
                title: item.customDisplayTitle,
                subviews: childrenNodes
            )
            results.append(node)
        }

        return results
    }

    public func toJSONString(
        items: [LookinDisplayItem],
        maxDepth: Int? = nil,
        visibleOnly: Bool = false,
        detailed: Bool = false,
        prettyPrinted: Bool = true
    ) throws -> String {
        let nodes = format(items: items, maxDepth: maxDepth, visibleOnly: visibleOnly, detailed: detailed)
        let encoder = JSONEncoder()
        if prettyPrinted {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        } else {
            encoder.outputFormatting = [.sortedKeys]
        }
        let data = try encoder.encode(nodes)
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    public func search(
        items: [LookinDisplayItem],
        text: String? = nil,
        className: String? = nil,
        oid: UInt? = nil
    ) -> [CompactHierarchyNode] {
        let allItems = LookinDisplayItem.flatten(items: items)
        var matches: [LookinDisplayItem] = []

        let cleanText = text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanClass = className?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        for item in allItems {
            var isMatch = true

            if let targetOid = oid {
                if item.oid != targetOid {
                    isMatch = false
                }
            }

            if isMatch, let targetClass = cleanClass, !targetClass.isEmpty {
                let itemClass = item.className.lowercased()
                let chain = item.displayingObject?.classChainList?.map { $0.lowercased() } ?? []
                if !itemClass.contains(targetClass) && !chain.contains(where: { $0.contains(targetClass) }) {
                    isMatch = false
                }
            }

            if isMatch, let targetText = cleanText, !targetText.isEmpty {
                let titleMatch = item.customDisplayTitle?.lowercased().contains(targetText) ?? false
                let classMatch = item.className.lowercased().contains(targetText)
                if !titleMatch && !classMatch {
                    isMatch = false
                }
            }

            if isMatch {
                matches.append(item)
            }
        }

        return format(items: matches, maxDepth: 1, visibleOnly: false, detailed: true)
    }
}
