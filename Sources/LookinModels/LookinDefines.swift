import Foundation

public enum LookinDefines {
    public static let serverVersion: Int32 = 7
    public static let serverReadableVersion: String = "1.2.8"
    public static let clientVersion: Int32 = 7
    public static let supportedServerMin: Int32 = 7
    public static let supportedServerMax: Int32 = 7

    public static let simulatorPortRange: ClosedRange<UInt16> = 47164...47169
    public static let usbPortRange: ClosedRange<UInt16> = 47175...47179

    public static let defaultSimulatorPort: UInt16 = 47164
    public static let defaultUSBPort: UInt16 = 47175
}

public enum LookinRequestType: UInt32, Sendable {
    case ping = 200
    case app = 201
    case hierarchy = 202
    case hierarchyDetails = 203
    case inbuiltAttrModification = 204
    case attrModificationPatch = 205
    case invokeMethod = 206
    case fetchObject = 207
    case fetchImageViewImage = 208
    case modifyRecognizerEnable = 209
    case allAttrGroups = 210
    case allSelectorNames = 213
    case customAttrModification = 214
    case cancelHierarchyDetails = 304
}

public enum LookinErrorCode: Int, Sendable {
    case `default` = -400
    case inner = -401
    case peerTalk = -402
    case noConnect = -403
    case pingFailForTimeout = -404
    case timeout = -405
    case discard = -406
    case pingFailForBackgroundState = -407

    case objectNotFound = -500
    case modifyValueTypeInvalid = -501
    case exception = -502

    case serverVersionTooHigh = -600
    case serverVersionTooLow = -601

    case unsupportedFileType = -700
}

public enum LookinAttrType: Int, Sendable {
    case none = 0
    case void = 1
    case char = 2
    case int = 3
    case short = 4
    case long = 5
    case longLong = 6
    case unsignedChar = 7
    case unsignedInt = 8
    case unsignedShort = 9
    case unsignedLong = 10
    case unsignedLongLong = 11
    case float = 12
    case double = 13
    case bool = 14
    case sel = 15
    case `class` = 16
    case point = 17
    case vector = 18
    case size = 19
    case rect = 20
    case affineTransform = 21
    case edgeInsets = 22
    case offset = 23
    case string = 24
    case enumInt = 25
    case enumLong = 26
    case color = 27
    case customObj = 28
    case enumString = 29
    case shadow = 30
    case json = 31
}
