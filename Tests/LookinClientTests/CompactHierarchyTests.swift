import XCTest
import CoreGraphics
@testable import LookinModels

final class CompactHierarchyTests: XCTestCase {
    func makeSampleHierarchy() -> LookinDisplayItem {
        let window = LookinDisplayItem()
        window.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        let winObj = LookinObject()
        winObj.oid = 100
        winObj.rawClassName = "UIWindow"
        window.viewObject = winObj

        let nav = LookinDisplayItem()
        nav.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        let navObj = LookinObject()
        navObj.oid = 101
        navObj.rawClassName = "UINavigationBar"
        nav.viewObject = navObj

        let button = LookinDisplayItem()
        button.frame = CGRect(x: 20, y: 100, width: 120, height: 44)
        let btnObj = LookinObject()
        btnObj.oid = 102
        btnObj.rawClassName = "UIButton"
        button.viewObject = btnObj
        button.customDisplayTitle = "Login Button"

        let hiddenLabel = LookinDisplayItem()
        hiddenLabel.frame = CGRect(x: 20, y: 160, width: 100, height: 20)
        let lblObj = LookinObject()
        lblObj.oid = 103
        lblObj.rawClassName = "UILabel"
        hiddenLabel.viewObject = lblObj
        hiddenLabel.isHidden = true
        hiddenLabel.customDisplayTitle = "Error Message"

        window.subitems = [nav, button, hiddenLabel]
        return window
    }

    func testCompactTreeSerialization() throws {
        let root = makeSampleHierarchy()
        let formatter = CompactHierarchyFormatter()
        let nodes = formatter.format(items: [root], maxDepth: nil, visibleOnly: false, detailed: false)

        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].oid, 100)
        XCTAssertEqual(nodes[0].className, "UIWindow")
        XCTAssertEqual(nodes[0].subviews?.count, 3)

        let json = try formatter.toJSONString(items: [root])
        XCTAssertTrue(json.contains("UIWindow"))
        XCTAssertTrue(json.contains("UIButton"))
        XCTAssertTrue(json.contains("Login Button"))
        XCTAssertTrue(json.contains("Error Message"))
    }

    func testVisibleOnlyFilter() throws {
        let root = makeSampleHierarchy()
        let formatter = CompactHierarchyFormatter()
        let nodes = formatter.format(items: [root], maxDepth: nil, visibleOnly: true, detailed: false)

        XCTAssertEqual(nodes.count, 1)
        // Hidden label should be omitted
        XCTAssertEqual(nodes[0].subviews?.count, 2)
        let subOids = nodes[0].subviews?.map(\.oid) ?? []
        XCTAssertTrue(subOids.contains(101))
        XCTAssertTrue(subOids.contains(102))
        XCTAssertFalse(subOids.contains(103))
    }

    func testMaxDepthLimit() throws {
        let root = makeSampleHierarchy()
        let formatter = CompactHierarchyFormatter()
        let nodes = formatter.format(items: [root], maxDepth: 1, visibleOnly: false, detailed: false)

        XCTAssertEqual(nodes.count, 1)
        XCTAssertNil(nodes[0].subviews)
    }

    func testSearchHierarchy() throws {
        let root = makeSampleHierarchy()
        let formatter = CompactHierarchyFormatter()

        // Search by text
        let matchText = formatter.search(items: [root], text: "Login", className: nil, oid: nil)
        XCTAssertEqual(matchText.count, 1)
        XCTAssertEqual(matchText[0].oid, 102)

        // Search by class name
        let matchClass = formatter.search(items: [root], text: nil, className: "UIButton", oid: nil)
        XCTAssertEqual(matchClass.count, 1)
        XCTAssertEqual(matchClass[0].oid, 102)

        // Search by OID
        let matchOid = formatter.search(items: [root], text: nil, className: nil, oid: 101)
        XCTAssertEqual(matchOid.count, 1)
        XCTAssertEqual(matchOid[0].className, "UINavigationBar")
    }
}
