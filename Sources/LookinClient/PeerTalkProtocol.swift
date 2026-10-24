import Foundation

public struct PeerTalkFrame: Sendable, Equatable {
    public static let headerSize: Int = 16
    public static let defaultVersion: UInt32 = 1

    public var version: UInt32
    public var type: UInt32
    public var tag: UInt32
    public var payload: Data

    public init(version: UInt32 = defaultVersion, type: UInt32, tag: UInt32 = 0, payload: Data = Data()) {
        self.version = version
        self.type = type
        self.tag = tag
        self.payload = payload
    }

    /// Packs the frame into a 16-byte Big-Endian header followed by the payload data
    public func pack() -> Data {
        var data = Data(capacity: Self.headerSize + payload.count)
        var beVersion = version.bigEndian
        var beType = type.bigEndian
        var beTag = tag.bigEndian
        var bePayloadSize = UInt32(payload.count).bigEndian

        withUnsafeBytes(of: &beVersion) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &beType) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &beTag) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &bePayloadSize) { data.append(contentsOf: $0) }

        if !payload.isEmpty {
            data.append(payload)
        }
        return data
    }

    /// Attempts to unpack a frame from the given data buffer.
    /// Returns nil if the buffer does not yet contain a complete frame.
    public static func unpack(from data: Data) throws -> (frame: PeerTalkFrame, bytesConsumed: Int)? {
        guard data.count >= headerSize else {
            return nil
        }

        let beVersion = data.prefix(4).withUnsafeBytes { $0.load(as: UInt32.self) }
        let beType = data.subdata(in: 4..<8).withUnsafeBytes { $0.load(as: UInt32.self) }
        let beTag = data.subdata(in: 8..<12).withUnsafeBytes { $0.load(as: UInt32.self) }
        let bePayloadSize = data.subdata(in: 12..<16).withUnsafeBytes { $0.load(as: UInt32.self) }

        let version = UInt32(bigEndian: beVersion)
        let type = UInt32(bigEndian: beType)
        let tag = UInt32(bigEndian: beTag)
        let payloadSize = Int(UInt32(bigEndian: bePayloadSize))

        let totalLength = headerSize + payloadSize
        guard data.count >= totalLength else {
            return nil
        }

        let payloadData: Data
        if payloadSize > 0 {
            payloadData = data.subdata(in: headerSize..<totalLength)
        } else {
            payloadData = Data()
        }

        let frame = PeerTalkFrame(
            version: version,
            type: type,
            tag: tag,
            payload: payloadData
        )
        return (frame, totalLength)
    }
}
