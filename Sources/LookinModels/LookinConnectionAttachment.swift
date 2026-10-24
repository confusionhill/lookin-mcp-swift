import Foundation

@objc(LookinConnectionAttachment)
public class LookinConnectionAttachment: NSObject, NSSecureCoding {
    public class var supportsSecureCoding: Bool { true }

    @objc public var dataType: Int = 0
    @objc public var data: Any?

    public override init() {
        super.init()
    }

    public init(dataType: Int = 0, data: Any? = nil) {
        self.dataType = dataType
        self.data = data
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.dataType = coder.containsValue(forKey: "1") ? coder.decodeInteger(forKey: "1") : coder.decodeInteger(forKey: "dataType")
        self.data = coder.decodeObject(forKey: "0") ?? coder.decodeObject(forKey: "data")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(dataType, forKey: "1")
        coder.encode(dataType, forKey: "dataType")
        if let data = data {
            coder.encode(data, forKey: "0")
            coder.encode(data, forKey: "data")
        }
    }
}

@objc(LookinConnectionResponseAttachment)
public final class LookinConnectionResponseAttachment: LookinConnectionAttachment {
    public override class var supportsSecureCoding: Bool { true }

    @objc public var lookinServerVersion: Int32 = 0
    @objc public var error: NSError?
    @objc public var appIsInBackground: Bool = false
    @objc public var dataTotalCount: UInt = 0
    @objc public var currentDataCount: UInt = 0

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.lookinServerVersion = coder.decodeInt32(forKey: "lookinServerVersion")
        self.error = coder.decodeObject(forKey: "error") as? NSError
        self.appIsInBackground = coder.decodeBool(forKey: "appIsInBackground")

        if let num = coder.decodeObject(forKey: "dataTotalCount") as? NSNumber {
            self.dataTotalCount = num.uintValue
        } else {
            self.dataTotalCount = UInt(coder.decodeInteger(forKey: "dataTotalCount"))
        }

        if let num = coder.decodeObject(forKey: "currentDataCount") as? NSNumber {
            self.currentDataCount = num.uintValue
        } else {
            self.currentDataCount = UInt(coder.decodeInteger(forKey: "currentDataCount"))
        }

        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(lookinServerVersion, forKey: "lookinServerVersion")
        if let error = error {
            coder.encode(error, forKey: "error")
        }
        coder.encode(appIsInBackground, forKey: "appIsInBackground")
        coder.encode(NSNumber(value: dataTotalCount), forKey: "dataTotalCount")
        coder.encode(NSNumber(value: currentDataCount), forKey: "currentDataCount")
    }
}
