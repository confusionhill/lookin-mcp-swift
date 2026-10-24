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
        let items = coder.decodeObject(forKey: "1") ?? coder.decodeObject(forKey: "displayItems")
        if let displayItems = items as? [LookinDisplayItem] {
            self.displayItems = displayItems
        }

        let app = coder.decodeObject(forKey: "2") ?? coder.decodeObject(forKey: "appInfo")
        if let appInfo = app as? LookinAppInfo {
            self.appInfo = appInfo
        }

        let alias = coder.decodeObject(forKey: "3") ?? coder.decodeObject(forKey: "colorAlias")
        if let colorAlias = alias as? [String: Any] {
            self.colorAlias = colorAlias
        }

        let collapsed = coder.decodeObject(forKey: "4") ?? coder.decodeObject(forKey: "collapsedClassList")
        if let collapsedList = collapsed as? [String] {
            self.collapsedClassList = collapsedList
        }

        self.serverVersion = coder.decodeInt32(forKey: "serverVersion")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        if let displayItems = displayItems {
            coder.encode(displayItems as NSArray, forKey: "1")
            coder.encode(displayItems as NSArray, forKey: "displayItems")
        }
        if let appInfo = appInfo {
            coder.encode(appInfo, forKey: "2")
            coder.encode(appInfo, forKey: "appInfo")
        }
        if let colorAlias = colorAlias {
            coder.encode(colorAlias as NSDictionary, forKey: "3")
            coder.encode(colorAlias as NSDictionary, forKey: "colorAlias")
        }
        if let collapsedClassList = collapsedClassList {
            coder.encode(collapsedClassList as NSArray, forKey: "4")
            coder.encode(collapsedClassList as NSArray, forKey: "collapsedClassList")
        }
        coder.encode(serverVersion, forKey: "serverVersion")
    }
}
