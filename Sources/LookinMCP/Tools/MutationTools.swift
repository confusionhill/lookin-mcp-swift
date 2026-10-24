import Foundation
import LookinClient
import LookinModels

public final class MutationTools: Sendable {
    private let client: LookinClient

    public init(client: LookinClient) {
        self.client = client
    }

    public func modifyAttribute(oid: Int, property: String, value: String) async throws -> String {
        let prop = property.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let targetOid = UInt(oid)

        let setterSelector: String
        let getterSelector: String?
        let attrType: Int
        let rawValue: Any

        switch prop {
        case "hidden", "ishidden":
            setterSelector = "setHidden:"
            getterSelector = "isHidden"
            attrType = LookinAttrType.bool.rawValue
            rawValue = NSNumber(value: value.lowercased() == "true" || value == "1")
        case "alpha":
            setterSelector = "setAlpha:"
            getterSelector = "alpha"
            attrType = LookinAttrType.float.rawValue
            let floatVal = Float(value) ?? 1.0
            rawValue = NSNumber(value: floatVal)
        case "userinteractionenabled", "isuserinteractionenabled":
            setterSelector = "setUserInteractionEnabled:"
            getterSelector = "isUserInteractionEnabled"
            attrType = LookinAttrType.bool.rawValue
            rawValue = NSNumber(value: value.lowercased() == "true" || value == "1")
        case "text":
            setterSelector = "setText:"
            getterSelector = "text"
            attrType = LookinAttrType.string.rawValue
            rawValue = value as NSString
        case "backgroundcolor", "bgcolor":
            setterSelector = "setBackgroundColor:"
            getterSelector = "backgroundColor"
            attrType = LookinAttrType.color.rawValue
            rawValue = Self.parseColorValue(value)
        case "textcolor":
            setterSelector = "setTextColor:"
            getterSelector = "textColor"
            attrType = LookinAttrType.color.rawValue
            rawValue = Self.parseColorValue(value)
        default:
            // Custom selector pass-through
            setterSelector = property.hasSuffix(":") ? property : "\(property):"
            getterSelector = nil
            if let boolVal = Bool(value) {
                attrType = LookinAttrType.bool.rawValue
                rawValue = NSNumber(value: boolVal)
            } else if let numVal = Double(value) {
                attrType = LookinAttrType.double.rawValue
                rawValue = NSNumber(value: numVal)
            } else {
                attrType = LookinAttrType.string.rawValue
                rawValue = value as NSString
            }
        }

        _ = try await client.modifyAttribute(
            targetOid: targetOid,
            setterSelector: setterSelector,
            getterSelector: getterSelector,
            attrType: attrType,
            value: rawValue
        )

        return "Successfully modified '\(property)' to '\(value)' on object \(oid)"
    }

    public func invokeMethod(oid: Int, selector: String) async throws -> String {
        let result = try await client.invokeMethod(oid: UInt(oid), selector: selector)
        let desc = result["description"] as? String ?? "executed"
        return "Invoked '\(selector)' on object \(oid): \(desc)"
    }

    public func listMethods(className: String, hasArguments: Bool = false) async throws -> String {
        let names = try await client.fetchAllSelectorNames(className: className, hasArg: hasArguments)
        let data = try JSONSerialization.data(withJSONObject: names, options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    public func inspectObject(oid: Int) async throws -> String {
        let obj = try await client.fetchObject(oid: UInt(oid))
        var dict: [String: Any] = [
            "oid": obj.oid,
            "rawClassName": obj.rawClassName ?? "Unknown",
            "memoryAddress": obj.memoryAddress ?? "0x0",
            "classChainList": obj.classChainList ?? []
        ]
        if let traces = obj.ivarTraces {
            let ivars = traces.map { [
                "name": $0.ivarName ?? "",
                "type": $0.ivarType ?? "",
                "value": $0.ivarValue ?? ""
            ] }
            dict["ivarTraces"] = ivars
        }
        if let special = obj.specialTrace {
            dict["specialTrace"] = special
        }
        let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    public static func parseColorValue(_ value: String) -> NSArray {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch trimmed {
        case "purple":
            return [NSNumber(value: 0.5), NSNumber(value: 0.0), NSNumber(value: 0.5), NSNumber(value: 1.0)]
        case "red":
            return [NSNumber(value: 1.0), NSNumber(value: 0.0), NSNumber(value: 0.0), NSNumber(value: 1.0)]
        case "green":
            return [NSNumber(value: 0.0), NSNumber(value: 1.0), NSNumber(value: 0.0), NSNumber(value: 1.0)]
        case "blue":
            return [NSNumber(value: 0.0), NSNumber(value: 0.0), NSNumber(value: 1.0), NSNumber(value: 1.0)]
        case "yellow":
            return [NSNumber(value: 1.0), NSNumber(value: 1.0), NSNumber(value: 0.0), NSNumber(value: 1.0)]
        case "cyan":
            return [NSNumber(value: 0.0), NSNumber(value: 1.0), NSNumber(value: 1.0), NSNumber(value: 1.0)]
        case "magenta":
            return [NSNumber(value: 1.0), NSNumber(value: 0.0), NSNumber(value: 1.0), NSNumber(value: 1.0)]
        case "orange":
            return [NSNumber(value: 1.0), NSNumber(value: 0.5), NSNumber(value: 0.0), NSNumber(value: 1.0)]
        case "black":
            return [NSNumber(value: 0.0), NSNumber(value: 0.0), NSNumber(value: 0.0), NSNumber(value: 1.0)]
        case "white":
            return [NSNumber(value: 1.0), NSNumber(value: 1.0), NSNumber(value: 1.0), NSNumber(value: 1.0)]
        case "clear":
            return [NSNumber(value: 0.0), NSNumber(value: 0.0), NSNumber(value: 0.0), NSNumber(value: 0.0)]
        default:
            if trimmed.hasPrefix("#") {
                let hex = String(trimmed.dropFirst())
                let scanner = Scanner(string: hex)
                var rgbValue: UInt64 = 0
                if scanner.scanHexInt64(&rgbValue) {
                    if hex.count == 6 {
                        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
                        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
                        let b = Double(rgbValue & 0x0000FF) / 255.0
                        return [NSNumber(value: r), NSNumber(value: g), NSNumber(value: b), NSNumber(value: 1.0)]
                    } else if hex.count == 8 {
                        let r = Double((rgbValue & 0xFF000000) >> 24) / 255.0
                        let g = Double((rgbValue & 0x00FF0000) >> 16) / 255.0
                        let b = Double((rgbValue & 0x0000FF00) >> 8) / 255.0
                        let a = Double(rgbValue & 0x000000FF) / 255.0
                        return [NSNumber(value: r), NSNumber(value: g), NSNumber(value: b), NSNumber(value: a)]
                    }
                }
            }
            let parts = trimmed.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
            if parts.count >= 3 {
                let r = parts[0] > 1.0 ? parts[0] / 255.0 : parts[0]
                let g = parts[1] > 1.0 ? parts[1] / 255.0 : parts[1]
                let b = parts[2] > 1.0 ? parts[2] / 255.0 : parts[2]
                let a = parts.count >= 4 ? (parts[3] > 1.0 ? parts[3] / 255.0 : parts[3]) : 1.0
                return [NSNumber(value: r), NSNumber(value: g), NSNumber(value: b), NSNumber(value: a)]
            }
            return [NSNumber(value: 0.5), NSNumber(value: 0.0), NSNumber(value: 0.5), NSNumber(value: 1.0)]
        }
    }
}
