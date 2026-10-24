import Foundation
#if canImport(AppKit)
import AppKit
#endif

@objc(LookinAppInfo)
public final class LookinAppInfo: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    @objc public var appInfoIdentifier: UInt = 0
    @objc public var shouldUseCache: Bool = false
    @objc public var serverVersion: Int32 = 0
    @objc public var serverReadableVersion: String?
    @objc public var swiftEnabledInLookinServer: Int32 = 0
    @objc public var appName: String?
    @objc public var appBundleIdentifier: String?
    @objc public var deviceDescription: String?
    @objc public var deviceType: UInt = 0 // 0: Simulator, 1: iPad, 2: Others/iPhone
    @objc public var osDescription: String?
    @objc public var osMainVersion: UInt = 0
    @objc public var screenWidth: Double = 0
    @objc public var screenHeight: Double = 0
    @objc public var screenScale: Double = 1.0
    @objc public var screenshot: Any?
    @objc public var appIcon: Any?

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.appInfoIdentifier = UInt(coder.decodeInteger(forKey: "appInfoIdentifier"))
        self.shouldUseCache = coder.decodeBool(forKey: "shouldUseCache")
        self.serverVersion = coder.decodeInt32(forKey: "serverVersion")
        self.serverReadableVersion = coder.decodeObject(of: NSString.self, forKey: "serverReadableVersion") as String?
        self.swiftEnabledInLookinServer = coder.decodeInt32(forKey: "swiftEnabledInLookinServer")
        self.appName = coder.decodeObject(of: NSString.self, forKey: "appName") as String?
        self.appBundleIdentifier = coder.decodeObject(of: NSString.self, forKey: "appBundleIdentifier") as String?
        self.deviceDescription = coder.decodeObject(of: NSString.self, forKey: "deviceDescription") as String?
        self.deviceType = UInt(coder.decodeInteger(forKey: "deviceType"))
        self.osDescription = coder.decodeObject(of: NSString.self, forKey: "osDescription") as String?
        self.osMainVersion = UInt(coder.decodeInteger(forKey: "osMainVersion"))
        self.screenWidth = coder.decodeDouble(forKey: "screenWidth")
        self.screenHeight = coder.decodeDouble(forKey: "screenHeight")
        self.screenScale = coder.decodeDouble(forKey: "screenScale")
        self.screenshot = coder.decodeObject(forKey: "screenshot")
        self.appIcon = coder.decodeObject(forKey: "appIcon")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(Int(appInfoIdentifier), forKey: "appInfoIdentifier")
        coder.encode(shouldUseCache, forKey: "shouldUseCache")
        coder.encode(serverVersion, forKey: "serverVersion")
        coder.encode(serverReadableVersion as NSString?, forKey: "serverReadableVersion")
        coder.encode(swiftEnabledInLookinServer, forKey: "swiftEnabledInLookinServer")
        coder.encode(appName as NSString?, forKey: "appName")
        coder.encode(appBundleIdentifier as NSString?, forKey: "appBundleIdentifier")
        coder.encode(deviceDescription as NSString?, forKey: "deviceDescription")
        coder.encode(Int(deviceType), forKey: "deviceType")
        coder.encode(osDescription as NSString?, forKey: "osDescription")
        coder.encode(Int(osMainVersion), forKey: "osMainVersion")
        coder.encode(screenWidth, forKey: "screenWidth")
        coder.encode(screenHeight, forKey: "screenHeight")
        coder.encode(screenScale, forKey: "screenScale")
        if let screenshot = screenshot {
            coder.encode(screenshot, forKey: "screenshot")
        }
        if let appIcon = appIcon {
            coder.encode(appIcon, forKey: "appIcon")
        }
    }
}
