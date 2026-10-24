import Foundation
#if canImport(AppKit)
import AppKit
#endif

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
        if let num = coder.decodeObject(forKey: "displayItemOid") as? NSNumber {
            self.displayItemOid = num.uintValue
        } else {
            self.displayItemOid = UInt(coder.decodeInteger(forKey: "displayItemOid"))
        }

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

        self.attributesGroupList = coder.decodeObject(forKey: "attributesGroupList") as? [LookinAttributesGroup]
        self.customAttrGroupList = coder.decodeObject(forKey: "customAttrGroupList") as? [LookinAttributesGroup]
        self.customDisplayTitle = coder.decodeObject(forKey: "customDisplayTitle") as? String
        self.failureCode = coder.decodeInteger(forKey: "failureCode")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(NSNumber(value: displayItemOid), forKey: "displayItemOid")
        if let soloScreenshot = soloScreenshot {
            #if canImport(AppKit)
            if let img = soloScreenshot as? NSImage, let tiff = img.tiffRepresentation {
                coder.encode(tiff, forKey: "soloScreenshot")
            } else {
                coder.encode(soloScreenshot, forKey: "soloScreenshot")
            }
            #else
            coder.encode(soloScreenshot, forKey: "soloScreenshot")
            #endif
        }
        if let groupScreenshot = groupScreenshot {
            #if canImport(AppKit)
            if let img = groupScreenshot as? NSImage, let tiff = img.tiffRepresentation {
                coder.encode(tiff, forKey: "groupScreenshot")
            } else {
                coder.encode(groupScreenshot, forKey: "groupScreenshot")
            }
            #else
            coder.encode(groupScreenshot, forKey: "groupScreenshot")
            #endif
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
