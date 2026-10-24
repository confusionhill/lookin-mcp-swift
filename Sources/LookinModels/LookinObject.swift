import Foundation

@objc(LookinIvarTrace)
public final class LookinIvarTrace: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    @objc public var ivarName: String?
    @objc public var ivarType: String?
    @objc public var ivarValue: String?

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.ivarName = coder.decodeObject(forKey: "ivarName") as? String
        self.ivarType = coder.decodeObject(forKey: "ivarType") as? String
        self.ivarValue = coder.decodeObject(forKey: "ivarValue") as? String
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(ivarName as NSString?, forKey: "ivarName")
        coder.encode(ivarType as NSString?, forKey: "ivarType")
        coder.encode(ivarValue as NSString?, forKey: "ivarValue")
    }
}

@objc(LookinObject)
public final class LookinObject: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    @objc public var oid: UInt = 0
    @objc public var memoryAddress: String?
    @objc public var classChainList: [String]?
    @objc public var ivarTraces: [LookinIvarTrace]?
    @objc public var specialTrace: String?

    private var _rawClassName: String?
    @objc public var rawClassName: String? {
        get { _rawClassName ?? classChainList?.first }
        set {
            _rawClassName = newValue
            if classChainList == nil, let val = newValue {
                classChainList = [val]
            }
        }
    }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        if let num = coder.decodeObject(forKey: "oid") as? NSNumber {
            self.oid = num.uintValue
        } else {
            self.oid = UInt(coder.decodeInteger(forKey: "oid"))
        }
        self.memoryAddress = coder.decodeObject(forKey: "memoryAddress") as? String
        self.classChainList = coder.decodeObject(forKey: "classChainList") as? [String]
        self.ivarTraces = coder.decodeObject(forKey: "ivarTraces") as? [LookinIvarTrace]
        self.specialTrace = coder.decodeObject(forKey: "specialTrace") as? String
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(NSNumber(value: oid), forKey: "oid")
        coder.encode(memoryAddress as NSString?, forKey: "memoryAddress")
        if let classChainList = classChainList {
            coder.encode(classChainList as NSArray, forKey: "classChainList")
        }
        if let ivarTraces = ivarTraces {
            coder.encode(ivarTraces as NSArray, forKey: "ivarTraces")
        }
        coder.encode(specialTrace as NSString?, forKey: "specialTrace")
    }
}
