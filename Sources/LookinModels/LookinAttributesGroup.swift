import Foundation

@objc(LookinAttribute)
public final class LookinAttribute: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    @objc public var attrId: String?
    @objc public var title: String?
    @objc public var valueType: Int = 0
    @objc public var value: Any?

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.attrId = coder.decodeObject(of: NSString.self, forKey: "attrId") as String?
        self.title = coder.decodeObject(of: NSString.self, forKey: "title") as String?
        self.valueType = coder.decodeInteger(forKey: "valueType")
        self.value = coder.decodeObject(forKey: "value")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(attrId as NSString?, forKey: "attrId")
        coder.encode(title as NSString?, forKey: "title")
        coder.encode(valueType, forKey: "valueType")
        if let value = value {
            coder.encode(value, forKey: "value")
        }
    }
}

@objc(LookinAttributesSection)
public final class LookinAttributesSection: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    @objc public var title: String?
    @objc public var attributes: [LookinAttribute]?

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.title = coder.decodeObject(of: NSString.self, forKey: "title") as String?
        if let attrs = coder.decodeObject(of: [NSArray.self, LookinAttribute.self], forKey: "attributes") as? [LookinAttribute] {
            self.attributes = attrs
        }
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(title as NSString?, forKey: "title")
        if let attributes = attributes {
            coder.encode(attributes as NSArray, forKey: "attributes")
        }
    }
}

@objc(LookinAttributesGroup)
public final class LookinAttributesGroup: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    @objc public var groupName: String?
    @objc public var sections: [LookinAttributesSection]?
    @objc public var attrList: [LookinAttribute]?

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.groupName = coder.decodeObject(of: NSString.self, forKey: "groupName") as String?
        if let sec = coder.decodeObject(of: [NSArray.self, LookinAttributesSection.self], forKey: "sections") as? [LookinAttributesSection] {
            self.sections = sec
        }
        if let list = coder.decodeObject(of: [NSArray.self, LookinAttribute.self], forKey: "attrList") as? [LookinAttribute] {
            self.attrList = list
        }
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(groupName as NSString?, forKey: "groupName")
        if let sections = sections {
            coder.encode(sections as NSArray, forKey: "sections")
        }
        if let attrList = attrList {
            coder.encode(attrList as NSArray, forKey: "attrList")
        }
    }
}
