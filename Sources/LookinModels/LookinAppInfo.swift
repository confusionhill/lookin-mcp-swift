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
        self.serverVersion = coder.decodeInt32(forKey: "serverVersion")
        self.serverReadableVersion = (coder.decodeObject(forKey: "serverReadableVersion") as? String)
        self.swiftEnabledInLookinServer = coder.decodeInt32(forKey: "swiftEnabledInLookinServer")

        // Keys "1" and "2" are NSData in LookinServer
        let rawScreenshot = coder.decodeObject(forKey: "2") ?? coder.decodeObject(forKey: "screenshot")
        if let data = rawScreenshot as? Data {
            #if canImport(AppKit)
            self.screenshot = NSImage(data: data) ?? data
            #else
            self.screenshot = data
            #endif
        } else {
            self.screenshot = rawScreenshot
        }

        let rawIcon = coder.decodeObject(forKey: "1") ?? coder.decodeObject(forKey: "appIcon")
        if let data = rawIcon as? Data {
            #if canImport(AppKit)
            self.appIcon = NSImage(data: data) ?? data
            #else
            self.appIcon = data
            #endif
        } else {
            self.appIcon = rawIcon
        }

        self.appName = (coder.decodeObject(forKey: "5") ?? coder.decodeObject(forKey: "appName")) as? String
        self.appBundleIdentifier = (coder.decodeObject(forKey: "appBundleIdentifier")) as? String
        self.deviceDescription = (coder.decodeObject(forKey: "3") ?? coder.decodeObject(forKey: "deviceDescription")) as? String
        self.osDescription = (coder.decodeObject(forKey: "4") ?? coder.decodeObject(forKey: "osDescription")) as? String
        self.osMainVersion = UInt(coder.decodeInteger(forKey: "osMainVersion"))

        let devType = (coder.containsValue(forKey: "8") ? coder.decodeInteger(forKey: "8") : coder.decodeInteger(forKey: "deviceType"))
        self.deviceType = UInt(devType)

        self.screenWidth = coder.containsValue(forKey: "6") ? coder.decodeDouble(forKey: "6") : coder.decodeDouble(forKey: "screenWidth")
        self.screenHeight = coder.containsValue(forKey: "7") ? coder.decodeDouble(forKey: "7") : coder.decodeDouble(forKey: "screenHeight")
        self.screenScale = coder.decodeDouble(forKey: "screenScale")
        self.appInfoIdentifier = UInt(coder.decodeInteger(forKey: "appInfoIdentifier"))
        self.shouldUseCache = coder.decodeBool(forKey: "shouldUseCache")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(serverVersion, forKey: "serverVersion")
        coder.encode(serverReadableVersion as NSString?, forKey: "serverReadableVersion")
        coder.encode(swiftEnabledInLookinServer, forKey: "swiftEnabledInLookinServer")

        if let screenshot = screenshot {
            #if canImport(AppKit)
            if let img = screenshot as? NSImage, let tiff = img.tiffRepresentation {
                coder.encode(tiff, forKey: "2")
            } else {
                coder.encode(screenshot, forKey: "2")
            }
            #else
            coder.encode(screenshot, forKey: "2")
            #endif
        }

        if let appIcon = appIcon {
            #if canImport(AppKit)
            if let img = appIcon as? NSImage, let tiff = img.tiffRepresentation {
                coder.encode(tiff, forKey: "1")
            } else {
                coder.encode(appIcon, forKey: "1")
            }
            #else
            coder.encode(appIcon, forKey: "1")
            #endif
        }

        coder.encode(appName as NSString?, forKey: "5")
        coder.encode(appName as NSString?, forKey: "appName")
        coder.encode(appBundleIdentifier as NSString?, forKey: "appBundleIdentifier")
        coder.encode(deviceDescription as NSString?, forKey: "3")
        coder.encode(osDescription as NSString?, forKey: "4")
        coder.encode(Int(osMainVersion), forKey: "osMainVersion")
        coder.encode(Int(deviceType), forKey: "8")
        coder.encode(screenWidth, forKey: "6")
        coder.encode(screenHeight, forKey: "7")
        coder.encode(screenScale, forKey: "screenScale")
        coder.encode(Int(appInfoIdentifier), forKey: "appInfoIdentifier")
        coder.encode(shouldUseCache, forKey: "shouldUseCache")
    }
}
