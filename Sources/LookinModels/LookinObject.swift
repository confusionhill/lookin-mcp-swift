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
        self.ivarName = coder.decodeObject(of: NSString.self, forKey: "ivarName") as String?
        self.ivarType = coder.decodeObject(of: NSString.self, forKey: "ivarType") as String?
        self.ivarValue = coder.decodeObject(of: NSString.self, forKey: "ivarValue") as String?
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
    @objc public var rawClassName: String?
    @objc public var memoryAddress: String?
    @objc public var classChainList: [String]?
    @objc public var ivarTraces: [LookinIvarTrace]?
    @objc public var specialTrace: String?

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.oid = UInt(coder.decodeInteger(forKey: "oid"))
        self.rawClassName = coder.decodeObject(of: NSString.self, forKey: "rawClassName") as String?
        self.memoryAddress = coder.decodeObject(of: NSString.self, forKey: "memoryAddress") as String?
        if let chain = coder.decodeObject(of: [NSArray.self, NSString.self], forKey: "classChainList") as? [String] {
            self.classChainList = chain
        }
        if let traces = coder.decodeObject(of: [NSArray.self, LookinIvarTrace.self], forKey: "ivarTraces") as? [LookinIvarTrace] {
            self.ivarTraces = traces
        }
        self.specialTrace = coder.decodeObject(of: NSString.self, forKey: "specialTrace") as String?
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(Int(oid), forKey: "oid")
        coder.encode(rawClassName as NSString?, forKey: "rawClassName")
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
