import Foundation

@objc(LookinDisplayItemDetail)
public final class LookinDisplayItemDetail: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    @objc public var displayItemOid: UInt = 0
    @objc public var soloScreenshot: Any?
    @objc public var groupScreenshot: Any?
    @objc public var attributesGroupList: [LookinAttributesGroup]?
    @objc public var customAttrGroupList: [LookinAttributesGroup]?
    @objc public var customDisplayTitle: String?
    @objc public var failureCode: Int = 0

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.displayItemOid = UInt(coder.decodeInteger(forKey: "displayItemOid"))
        self.soloScreenshot = coder.decodeObject(forKey: "soloScreenshot")
        self.groupScreenshot = coder.decodeObject(forKey: "groupScreenshot")
        if let attrs = coder.decodeObject(of: [NSArray.self, LookinAttributesGroup.self], forKey: "attributesGroupList") as? [LookinAttributesGroup] {
            self.attributesGroupList = attrs
        }
        if let customAttrs = coder.decodeObject(of: [NSArray.self, LookinAttributesGroup.self], forKey: "customAttrGroupList") as? [LookinAttributesGroup] {
            self.customAttrGroupList = customAttrs
        }
        self.customDisplayTitle = coder.decodeObject(of: NSString.self, forKey: "customDisplayTitle") as String?
        self.failureCode = coder.decodeInteger(forKey: "failureCode")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(Int(displayItemOid), forKey: "displayItemOid")
        if let soloScreenshot = soloScreenshot {
            coder.encode(soloScreenshot, forKey: "soloScreenshot")
        }
        if let groupScreenshot = groupScreenshot {
            coder.encode(groupScreenshot, forKey: "groupScreenshot")
        }
        if let attributesGroupList = attributesGroupList {
            coder.encode(attributesGroupList as NSArray, forKey: "attributesGroupList")
        }
        if let customAttrGroupList = customAttrGroupList {
            coder.encode(customAttrGroupList as NSArray, forKey: "customAttrGroupList")
        }
        coder.encode(customDisplayTitle as NSString?, forKey: "customDisplayTitle")
        coder.encode(failureCode, forKey: "failureCode")
    }
}
