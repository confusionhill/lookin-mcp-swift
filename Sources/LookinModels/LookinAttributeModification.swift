import Foundation

@objc(LookinAttributeModification)
public final class LookinAttributeModification: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    @objc public var targetOid: UInt = 0
    @objc public var setterSelector: String = ""
    @objc public var getterSelector: String?
    @objc public var attrType: Int = 0
    @objc public var value: Any?

    @objc public var clientReadableVersion: String? = LookinDefines.serverReadableVersion

    public override init() {
        super.init()
    }

    public init(targetOid: UInt, setterSelector: String, getterSelector: String? = nil, attrType: Int = 0, value: Any? = nil, clientReadableVersion: String? = LookinDefines.serverReadableVersion) {
        self.targetOid = targetOid
        self.setterSelector = setterSelector
        self.getterSelector = getterSelector
        self.attrType = attrType
        self.value = value
        self.clientReadableVersion = clientReadableVersion
        super.init()
    }

    public required init?(coder: NSCoder) {
        if let num = coder.decodeObject(forKey: "targetOid") as? NSNumber {
            self.targetOid = num.uintValue
        } else {
            self.targetOid = UInt(coder.decodeInteger(forKey: "targetOid"))
        }
        self.setterSelector = coder.decodeObject(forKey: "setterSelector") as? String ?? ""
        self.getterSelector = coder.decodeObject(forKey: "getterSelector") as? String
        self.attrType = coder.decodeInteger(forKey: "attrType")
        self.value = coder.decodeObject(forKey: "value")
        self.clientReadableVersion = coder.decodeObject(forKey: "clientReadableVersion") as? String
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(NSNumber(value: targetOid), forKey: "targetOid")
        coder.encode(setterSelector as NSString, forKey: "setterSelector")
        if let getterSelector = getterSelector {
            coder.encode(getterSelector as NSString, forKey: "getterSelector")
        }
        coder.encode(attrType, forKey: "attrType")
        if let value = value {
            coder.encode(value, forKey: "value")
        }
        if let clientReadableVersion = clientReadableVersion {
            coder.encode(clientReadableVersion as NSString, forKey: "clientReadableVersion")
        }
    }
}

@objc(LookinStaticAsyncUpdateTask)
public final class LookinStaticAsyncUpdateTask: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    @objc public var oid: UInt = 0
    @objc public var taskType: UInt = 0 // 0: NoScreenshot, 1: SoloScreenshot, 2: GroupScreenshot
    @objc public var attrRequest: UInt = 0 // 0: Auto, 1: Need, 2: NotNeed
    @objc public var needBasisVisualInfo: Bool = false
    @objc public var needSubitems: Bool = false
    @objc public var clientReadableVersion: String?

    public override init() {
        super.init()
    }

    public init(oid: UInt, taskType: UInt = 0, attrRequest: UInt = 0, needBasisVisualInfo: Bool = false, needSubitems: Bool = false, clientReadableVersion: String? = LookinDefines.serverReadableVersion) {
        self.oid = oid
        self.taskType = taskType
        self.attrRequest = attrRequest
        self.needBasisVisualInfo = needBasisVisualInfo
        self.needSubitems = needSubitems
        self.clientReadableVersion = clientReadableVersion
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.oid = UInt(coder.decodeInteger(forKey: "oid"))
        self.taskType = UInt(coder.decodeInteger(forKey: "taskType"))
        self.attrRequest = UInt(coder.decodeInteger(forKey: "attrRequest"))
        self.needBasisVisualInfo = coder.decodeBool(forKey: "needBasisVisualInfo")
        self.needSubitems = coder.decodeBool(forKey: "needSubitems")
        self.clientReadableVersion = coder.decodeObject(of: NSString.self, forKey: "clientReadableVersion") as String?
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(Int(oid), forKey: "oid")
        coder.encode(Int(taskType), forKey: "taskType")
        coder.encode(Int(attrRequest), forKey: "attrRequest")
        coder.encode(needBasisVisualInfo, forKey: "needBasisVisualInfo")
        coder.encode(needSubitems, forKey: "needSubitems")
        coder.encode(clientReadableVersion as NSString?, forKey: "clientReadableVersion")
    }
}

@objc(LookinStaticAsyncUpdateTasksPackage)
public final class LookinStaticAsyncUpdateTasksPackage: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    @objc public var tasks: [LookinStaticAsyncUpdateTask]?

    public override init() {
        super.init()
    }

    public init(tasks: [LookinStaticAsyncUpdateTask]) {
        self.tasks = tasks
        super.init()
    }

    public required init?(coder: NSCoder) {
        if let tasks = coder.decodeObject(of: [NSArray.self, LookinStaticAsyncUpdateTask.self], forKey: "tasks") as? [LookinStaticAsyncUpdateTask] {
            self.tasks = tasks
        }
        super.init()
    }

    public func encode(with coder: NSCoder) {
        if let tasks = tasks {
            coder.encode(tasks as NSArray, forKey: "tasks")
        }
    }
}
