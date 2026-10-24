import Foundation

@objc(LookinAttribute)
public final class LookinAttribute: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    @objc public var identifier: String?
    @objc public var displayTitle: String?
    @objc public var attrType: Int = 0
    @objc public var value: Any?
    @objc public var extraValue: Any?
    @objc public var customSetterID: String?

    @objc public var attrId: String? {
        get { identifier }
        set { identifier = newValue }
    }
    @objc public var title: String? {
        get { displayTitle }
        set { displayTitle = newValue }
    }
    @objc public var valueType: Int {
        get { attrType }
        set { attrType = newValue }
    }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.displayTitle = (coder.decodeObject(forKey: "displayTitle") as? String) ?? (coder.decodeObject(forKey: "title") as? String)
        self.identifier = (coder.decodeObject(forKey: "identifier") as? String) ?? (coder.decodeObject(forKey: "attrId") as? String)
        if coder.containsValue(forKey: "attrType") {
            self.attrType = coder.decodeInteger(forKey: "attrType")
        } else {
            self.attrType = coder.decodeInteger(forKey: "valueType")
        }
        self.value = coder.decodeObject(forKey: "value")
        self.extraValue = coder.decodeObject(forKey: "extraValue")
        self.customSetterID = coder.decodeObject(forKey: "customSetterID") as? String
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(displayTitle as NSString?, forKey: "displayTitle")
        coder.encode(identifier as NSString?, forKey: "identifier")
        coder.encode(attrType, forKey: "attrType")
        if let value = value {
            coder.encode(value, forKey: "value")
        }
        if let extraValue = extraValue {
            coder.encode(extraValue, forKey: "extraValue")
        }
        if let customSetterID = customSetterID {
            coder.encode(customSetterID as NSString?, forKey: "customSetterID")
        }
    }
}

@objc(LookinAttributesSection)
public final class LookinAttributesSection: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    @objc public var identifier: String?
    @objc public var attributes: [LookinAttribute]?

    @objc public var title: String? {
        get { identifier }
        set { identifier = newValue }
    }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.identifier = (coder.decodeObject(forKey: "identifier") as? String) ?? (coder.decodeObject(forKey: "title") as? String)
        self.attributes = coder.decodeObject(forKey: "attributes") as? [LookinAttribute]
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(identifier as NSString?, forKey: "identifier")
        if let attributes = attributes {
            coder.encode(attributes as NSArray, forKey: "attributes")
        }
    }
}

@objc(LookinAttributesGroup)
public final class LookinAttributesGroup: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    @objc public var userCustomTitle: String?
    @objc public var identifier: String?
    @objc public var attrSections: [LookinAttributesSection]?

    @objc public var groupName: String? {
        get { userCustomTitle ?? identifier }
        set { userCustomTitle = newValue }
    }
    @objc public var sections: [LookinAttributesSection]? {
        get { attrSections }
        set { attrSections = newValue }
    }
    @objc public var attrList: [LookinAttribute]? {
        get {
            attrSections?.compactMap { $0.attributes }.flatMap { $0 }
        }
        set {
            if let list = newValue {
                let sec = LookinAttributesSection()
                sec.attributes = list
                attrSections = [sec]
            }
        }
    }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.userCustomTitle = (coder.decodeObject(forKey: "userCustomTitle") as? String) ?? (coder.decodeObject(forKey: "groupName") as? String)
        self.identifier = coder.decodeObject(forKey: "identifier") as? String
        self.attrSections = (coder.decodeObject(forKey: "attrSections") as? [LookinAttributesSection]) ?? (coder.decodeObject(forKey: "sections") as? [LookinAttributesSection])
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(userCustomTitle as NSString?, forKey: "userCustomTitle")
        coder.encode(identifier as NSString?, forKey: "identifier")
        if let attrSections = attrSections {
            coder.encode(attrSections as NSArray, forKey: "attrSections")
        }
    }
}
