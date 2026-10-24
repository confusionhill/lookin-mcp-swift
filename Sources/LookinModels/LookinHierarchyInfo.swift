import Foundation

@objc(LookinHierarchyInfo)
public final class LookinHierarchyInfo: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    @objc public var displayItems: [LookinDisplayItem]?
    @objc public var colorAlias: [String: Any]?
    @objc public var collapsedClassList: [String]?
    @objc public var appInfo: LookinAppInfo?
    @objc public var serverVersion: Int32 = 0

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        if let items = coder.decodeObject(of: [NSArray.self, LookinDisplayItem.self], forKey: "displayItems") as? [LookinDisplayItem] {
            self.displayItems = items
        }
        self.colorAlias = coder.decodeObject(of: [NSDictionary.self, NSString.self, NSObject.self], forKey: "colorAlias") as? [String: Any]
        if let collapsed = coder.decodeObject(of: [NSArray.self, NSString.self], forKey: "collapsedClassList") as? [String] {
            self.collapsedClassList = collapsed
        }
        self.appInfo = coder.decodeObject(of: LookinAppInfo.self, forKey: "appInfo")
        self.serverVersion = coder.decodeInt32(forKey: "serverVersion")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        if let displayItems = displayItems {
            coder.encode(displayItems as NSArray, forKey: "displayItems")
        }
        if let colorAlias = colorAlias {
            coder.encode(colorAlias as NSDictionary, forKey: "colorAlias")
        }
        if let collapsedClassList = collapsedClassList {
            coder.encode(collapsedClassList as NSArray, forKey: "collapsedClassList")
        }
        if let appInfo = appInfo {
            coder.encode(appInfo, forKey: "appInfo")
        }
        coder.encode(serverVersion, forKey: "serverVersion")
    }
}
