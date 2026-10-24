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
        self.dataType = coder.decodeInteger(forKey: "dataType")
        self.data = coder.decodeObject(forKey: "data")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(dataType, forKey: "dataType")
        if let data = data {
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
        self.error = coder.decodeObject(of: NSError.self, forKey: "error")
        self.appIsInBackground = coder.decodeBool(forKey: "appIsInBackground")
        self.dataTotalCount = UInt(coder.decodeInteger(forKey: "dataTotalCount"))
        self.currentDataCount = UInt(coder.decodeInteger(forKey: "currentDataCount"))
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(lookinServerVersion, forKey: "lookinServerVersion")
        if let error = error {
            coder.encode(error, forKey: "error")
        }
        coder.encode(appIsInBackground, forKey: "appIsInBackground")
        coder.encode(Int(dataTotalCount), forKey: "dataTotalCount")
        coder.encode(Int(currentDataCount), forKey: "currentDataCount")
    }
}
