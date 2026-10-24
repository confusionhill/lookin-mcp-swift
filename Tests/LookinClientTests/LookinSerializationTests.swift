import XCTest
@testable import LookinModels

final class LookinSerializationTests: XCTestCase {
    func testResponseAttachmentSerialization() throws {
        let attachment = LookinConnectionResponseAttachment()
        attachment.lookinServerVersion = 7
        attachment.appIsInBackground = false
        attachment.dataTotalCount = 5
        attachment.currentDataCount = 1
        attachment.data = "Test Data" as NSString

        let data = try NSKeyedArchiver.archivedData(withRootObject: attachment, requiringSecureCoding: false)
        XCTAssertFalse(data.isEmpty)

        guard let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data) else {
            XCTFail("Failed to create unarchiver")
            return
        }
        unarchiver.requiresSecureCoding = false
        let decoded = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? LookinConnectionResponseAttachment
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.lookinServerVersion, 7)
        XCTAssertEqual(decoded?.appIsInBackground, false)
        XCTAssertEqual(decoded?.dataTotalCount, 5)
        XCTAssertEqual(decoded?.currentDataCount, 1)
        XCTAssertEqual(decoded?.data as? String, "Test Data")
    }

    func testAppInfoSerialization() throws {
        let appInfo = LookinAppInfo()
        appInfo.serverVersion = 7
        appInfo.serverReadableVersion = "1.2.8"
        appInfo.appName = "LookinDemo"
        appInfo.appBundleIdentifier = "com.lookin.demo"
        appInfo.deviceDescription = "iPhone 15 Pro"
        appInfo.deviceType = 0
        appInfo.screenWidth = 393
        appInfo.screenHeight = 852
        appInfo.screenScale = 3.0

        let data = try NSKeyedArchiver.archivedData(withRootObject: appInfo, requiringSecureCoding: false)
        XCTAssertFalse(data.isEmpty)

        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = false
        let decoded = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? LookinAppInfo
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.appName, "LookinDemo")
        XCTAssertEqual(decoded?.appBundleIdentifier, "com.lookin.demo")
        XCTAssertEqual(decoded?.deviceDescription, "iPhone 15 Pro")
        XCTAssertEqual(decoded?.screenWidth, 393)
        XCTAssertEqual(decoded?.screenHeight, 852)
        XCTAssertEqual(decoded?.screenScale, 3.0)
    }

    func testHierarchyInfoSerialization() throws {
        let windowItem = LookinDisplayItem()
        windowItem.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        let windowObj = LookinObject()
        windowObj.oid = 1001
        windowObj.rawClassName = "UIWindow"
        windowObj.memoryAddress = "0x12345678"
        windowObj.classChainList = ["UIWindow", "UIView", "UIResponder", "NSObject"]
        windowItem.viewObject = windowObj

        let buttonItem = LookinDisplayItem()
        buttonItem.frame = CGRect(x: 20, y: 100, width: 120, height: 44)
        let buttonObj = LookinObject()
        buttonObj.oid = 1002
        buttonObj.rawClassName = "UIButton"
        buttonObj.memoryAddress = "0x87654321"
        buttonObj.classChainList = ["UIButton", "UIControl", "UIView", "UIResponder", "NSObject"]
        buttonItem.viewObject = buttonObj
        buttonItem.customDisplayTitle = "Submit Button"

        windowItem.subitems = [buttonItem]

        let hierarchy = LookinHierarchyInfo()
        hierarchy.serverVersion = 7
        hierarchy.displayItems = [windowItem]

        let data = try NSKeyedArchiver.archivedData(withRootObject: hierarchy, requiringSecureCoding: false)
        XCTAssertFalse(data.isEmpty)

        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = false
        let decoded = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? LookinHierarchyInfo
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.displayItems?.count, 1)

        let rootItem = decoded?.displayItems?.first
        XCTAssertEqual(rootItem?.oid, 1001)
        XCTAssertEqual(rootItem?.className, "UIWindow")
        XCTAssertEqual(rootItem?.subitems?.count, 1)

        let childItem = rootItem?.subitems?.first
        XCTAssertEqual(childItem?.oid, 1002)
        XCTAssertEqual(childItem?.className, "UIButton")
        XCTAssertEqual(childItem?.customDisplayTitle, "Submit Button")

        let flat = LookinDisplayItem.flatten(items: decoded?.displayItems ?? [])
        XCTAssertEqual(flat.count, 2)
    }

    func testAttributeModificationSerialization() throws {
        let mod = LookinAttributeModification(
            targetOid: 1002,
            setterSelector: "setHidden:",
            getterSelector: "isHidden",
            attrType: 1,
            value: NSNumber(value: true)
        )

        let data = try NSKeyedArchiver.archivedData(withRootObject: mod, requiringSecureCoding: false)
        XCTAssertFalse(data.isEmpty)

        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = false
        let decoded = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? LookinAttributeModification
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.targetOid, 1002)
        XCTAssertEqual(decoded?.setterSelector, "setHidden:")
        XCTAssertEqual(decoded?.getterSelector, "isHidden")
        XCTAssertEqual((decoded?.value as? NSNumber)?.boolValue, true)
    }
}
