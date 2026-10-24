import Foundation
import CoreGraphics

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
        if let sub = coder.decodeObject(of: [NSArray.self, LookinDisplayItem.self], forKey: "subitems") as? [LookinDisplayItem] {
            self.subitems = sub
        }
        self.isHidden = coder.decodeBool(forKey: "isHidden")
        self.alpha = coder.decodeFloat(forKey: "alpha")
        self.frame = coder.decodeRect(forKey: "frame")
        self.bounds = coder.decodeRect(forKey: "bounds")
        self.soloScreenshot = coder.decodeObject(forKey: "soloScreenshot")
        self.groupScreenshot = coder.decodeObject(forKey: "groupScreenshot")
        self.viewObject = coder.decodeObject(of: LookinObject.self, forKey: "viewObject")
        self.layerObject = coder.decodeObject(of: LookinObject.self, forKey: "layerObject")
        self.hostViewControllerObject = coder.decodeObject(of: LookinObject.self, forKey: "hostViewControllerObject")
        if let attrs = coder.decodeObject(of: [NSArray.self, LookinAttributesGroup.self], forKey: "attributesGroupList") as? [LookinAttributesGroup] {
            self.attributesGroupList = attrs
        }
        if let customAttrs = coder.decodeObject(of: [NSArray.self, LookinAttributesGroup.self], forKey: "customAttrGroupList") as? [LookinAttributesGroup] {
            self.customAttrGroupList = customAttrs
        }
        self.representedAsKeyWindow = coder.decodeBool(forKey: "representedAsKeyWindow")
        self.backgroundColor = coder.decodeObject(forKey: "backgroundColor")
        self.shouldCaptureImage = coder.decodeBool(forKey: "shouldCaptureImage")
        self.customDisplayTitle = coder.decodeObject(of: NSString.self, forKey: "customDisplayTitle") as String?
        super.init()
    }

    public func encode(with coder: NSCoder) {
        if let subitems = subitems {
            coder.encode(subitems as NSArray, forKey: "subitems")
        }
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
