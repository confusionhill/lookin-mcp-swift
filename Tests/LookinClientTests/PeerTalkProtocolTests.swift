import XCTest
@testable import LookinClient
@testable import LookinModels

final class PeerTalkProtocolTests: XCTestCase {
    func testHeaderPackingAndUnpacking() throws {
        let frame = PeerTalkFrame(
            version: 1,
            type: LookinRequestType.ping.rawValue,
            tag: 42,
            payload: Data()
        )
        let packed = frame.pack()
        XCTAssertEqual(packed.count, 16)

        let unpacked = try PeerTalkFrame.unpack(from: packed)
        XCTAssertNotNil(unpacked)
        XCTAssertEqual(unpacked?.bytesConsumed, 16)
        XCTAssertEqual(unpacked?.frame.version, 1)
        XCTAssertEqual(unpacked?.frame.type, 200)
        XCTAssertEqual(unpacked?.frame.tag, 42)
        XCTAssertEqual(unpacked?.frame.payload.count, 0)
    }

    func testPayloadPackingAndUnpacking() throws {
        let samplePayload = "Hello Lookin".data(using: .utf8)!
        let frame = PeerTalkFrame(
            version: 1,
            type: LookinRequestType.app.rawValue,
            tag: 101,
            payload: samplePayload
        )
        let packed = frame.pack()
        XCTAssertEqual(packed.count, 16 + samplePayload.count)

        let unpacked = try PeerTalkFrame.unpack(from: packed)
        XCTAssertNotNil(unpacked)
        XCTAssertEqual(unpacked?.bytesConsumed, 16 + samplePayload.count)
        XCTAssertEqual(unpacked?.frame.version, 1)
        XCTAssertEqual(unpacked?.frame.type, 201)
        XCTAssertEqual(unpacked?.frame.tag, 101)
        XCTAssertEqual(unpacked?.frame.payload, samplePayload)
    }

    func testPartialDataReturnsNil() throws {
        let headerOnly = Data(count: 15) // less than 16
        XCTAssertNil(try PeerTalkFrame.unpack(from: headerOnly))

        // Header says payload is 10 bytes, but only 5 are provided
        var incomplete = Data()
        var version = UInt32(1).bigEndian
        var type = UInt32(200).bigEndian
        var tag = UInt32(1).bigEndian
        var payloadSize = UInt32(10).bigEndian
        incomplete.append(Data(bytes: &version, count: 4))
        incomplete.append(Data(bytes: &type, count: 4))
        incomplete.append(Data(bytes: &tag, count: 4))
        incomplete.append(Data(bytes: &payloadSize, count: 4))
        incomplete.append(Data([1, 2, 3, 4, 5])) // 5 bytes instead of 10

        XCTAssertNil(try PeerTalkFrame.unpack(from: incomplete))
    }

    func testMultipleFramesInBuffer() throws {
        let frame1 = PeerTalkFrame(version: 1, type: 200, tag: 1, payload: Data([0xAA, 0xBB]))
        let frame2 = PeerTalkFrame(version: 1, type: 202, tag: 2, payload: Data([0xCC]))

        var buffer = Data()
        buffer.append(frame1.pack())
        buffer.append(frame2.pack())

        let unpacked1 = try PeerTalkFrame.unpack(from: buffer)
        XCTAssertNotNil(unpacked1)
        XCTAssertEqual(unpacked1?.frame.tag, 1)
        XCTAssertEqual(unpacked1?.frame.payload, Data([0xAA, 0xBB]))

        let remaining = buffer.advanced(by: unpacked1!.bytesConsumed)
        let unpacked2 = try PeerTalkFrame.unpack(from: remaining)
        XCTAssertNotNil(unpacked2)
        XCTAssertEqual(unpacked2?.frame.tag, 2)
        XCTAssertEqual(unpacked2?.frame.payload, Data([0xCC]))
    }
}
