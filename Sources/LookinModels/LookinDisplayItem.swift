import Foundation
import CoreGraphics
#if canImport(AppKit)
import AppKit
#endif

@objc(LookinDisplayItem)
public final class LookinDisplayItem: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    @objc public var subitems: [LookinDisplayItem]?
    @objc public var isHidden: Bool = false
    @objc public var alpha: Float = 1.0
    @objc public var frame: CGRect = .zero
    @objc public var bounds: CGRect = .zero
    @objc public var soloScreenshot: Any?
    @objc public var groupScreenshot: Any?
    @objc public var viewObject: LookinObject?
    @objc public var layerObject: LookinObject?
    @objc public var hostViewControllerObject: LookinObject?
    @objc public var attributesGroupList: [LookinAttributesGroup]?
    @objc public var customAttrGroupList: [LookinAttributesGroup]?
    @objc public var representedAsKeyWindow: Bool = false
    @objc public var backgroundColor: Any?
    @objc public var shouldCaptureImage: Bool = true
    @objc public var customDisplayTitle: String?

    public var displayingObject: LookinObject? {
        return viewObject ?? layerObject
    }

    public var oid: UInt {
        return displayingObject?.oid ?? 0
    }

    public override var className: String {
        return viewObject?.rawClassName ?? layerObject?.rawClassName ?? "Unknown"
    }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        if let sub = (coder.decodeObject(forKey: "subitems") as? [LookinDisplayItem]) {
            self.subitems = sub
        }
        self.isHidden = coder.containsValue(forKey: "hidden") ? coder.decodeBool(forKey: "hidden") : coder.decodeBool(forKey: "isHidden")
        self.alpha = coder.containsValue(forKey: "alpha") ? coder.decodeFloat(forKey: "alpha") : 1.0

        self.frame = coder.decodeRect(forKey: "frame")
        self.bounds = coder.decodeRect(forKey: "bounds")

        let solo = coder.decodeObject(forKey: "soloScreenshot")
        if let data = solo as? Data {
            #if canImport(AppKit)
            self.soloScreenshot = NSImage(data: data) ?? data
            #else
            self.soloScreenshot = data
            #endif
        } else {
            self.soloScreenshot = solo
        }

        let group = coder.decodeObject(forKey: "groupScreenshot")
        if let data = group as? Data {
            #if canImport(AppKit)
            self.groupScreenshot = NSImage(data: data) ?? data
            #else
            self.groupScreenshot = data
            #endif
        } else {
            self.groupScreenshot = group
        }

        self.viewObject = coder.decodeObject(forKey: "viewObject") as? LookinObject
        self.layerObject = coder.decodeObject(forKey: "layerObject") as? LookinObject
        self.hostViewControllerObject = coder.decodeObject(forKey: "hostViewControllerObject") as? LookinObject
        self.attributesGroupList = coder.decodeObject(forKey: "attributesGroupList") as? [LookinAttributesGroup]
        self.customAttrGroupList = coder.decodeObject(forKey: "customAttrGroupList") as? [LookinAttributesGroup]
        self.representedAsKeyWindow = coder.decodeBool(forKey: "representedAsKeyWindow")
        self.backgroundColor = coder.decodeObject(forKey: "backgroundColor")
        self.shouldCaptureImage = coder.containsValue(forKey: "shouldCaptureImage") ? coder.decodeBool(forKey: "shouldCaptureImage") : true
        self.customDisplayTitle = coder.decodeObject(forKey: "customDisplayTitle") as? String
        super.init()
    }

    public func encode(with coder: NSCoder) {
        if let subitems = subitems {
            coder.encode(subitems as NSArray, forKey: "subitems")
        }
        coder.encode(isHidden, forKey: "hidden")
        coder.encode(isHidden, forKey: "isHidden")
        coder.encode(alpha, forKey: "alpha")
        coder.encode(frame, forKey: "frame")
        coder.encode(bounds, forKey: "bounds")
        if let soloScreenshot = soloScreenshot {
            coder.encode(soloScreenshot, forKey: "soloScreenshot")
        }
        if let groupScreenshot = groupScreenshot {
            coder.encode(groupScreenshot, forKey: "groupScreenshot")
        }
        if let viewObject = viewObject {
            coder.encode(viewObject, forKey: "viewObject")
        }
        if let layerObject = layerObject {
            coder.encode(layerObject, forKey: "layerObject")
        }
        if let hostViewControllerObject = hostViewControllerObject {
            coder.encode(hostViewControllerObject, forKey: "hostViewControllerObject")
        }
        if let attributesGroupList = attributesGroupList {
            coder.encode(attributesGroupList as NSArray, forKey: "attributesGroupList")
        }
        if let customAttrGroupList = customAttrGroupList {
            coder.encode(customAttrGroupList as NSArray, forKey: "customAttrGroupList")
        }
        coder.encode(representedAsKeyWindow, forKey: "representedAsKeyWindow")
        if let backgroundColor = backgroundColor {
            coder.encode(backgroundColor, forKey: "backgroundColor")
        }
        coder.encode(shouldCaptureImage, forKey: "shouldCaptureImage")
        coder.encode(customDisplayTitle as NSString?, forKey: "customDisplayTitle")
    }

    /// Recursively flattens all hierarchy items into a flat list
    public static func flatten(items: [LookinDisplayItem]) -> [LookinDisplayItem] {
        var result: [LookinDisplayItem] = []
        for item in items {
            result.append(item)
            if let children = item.subitems, !children.isEmpty {
                result.append(contentsOf: flatten(items: children))
            }
        }
        return result
    }
}
