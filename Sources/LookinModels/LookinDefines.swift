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
