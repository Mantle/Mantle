import Foundation

/// Conform a `Decodable` model to this to run custom validation right after `JSONAdapter` decodes it,
/// mirroring `MTLJSONAdapter`'s call to `-validate:`.
public protocol JSONValidating {
    func validate() throws
}

public enum JSONAdapterError: Error {
    /// The model encoded to valid JSON, but not to an object at the top level.
    case notAJSONDictionary
}

/// A minimal, cross-platform (macOS/iOS/tvOS/watchOS/Linux/Windows) stand-in for `MTLJSONAdapter`,
/// built on `Codable` instead of the Objective-C runtime so it has no dependency on `Mantle`/`extobjc`.
public enum JSONAdapter {
    public static func model<T: Decodable>(
        of type: T.Type,
        fromJSONDictionary dictionary: [String: Any],
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        let model = try decoder.decode(T.self, from: data)
        if let validating = model as? JSONValidating {
            try validating.validate()
        }
        return model
    }

    public static func models<T: Decodable>(
        of type: T.Type,
        fromJSONArray array: [[String: Any]],
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> [T] {
        try array.map { try model(of: T.self, fromJSONDictionary: $0, decoder: decoder) }
    }

    public static func jsonDictionary<T: Encodable>(
        from model: T,
        encoder: JSONEncoder = JSONEncoder()
    ) throws -> [String: Any] {
        let data = try encoder.encode(model)
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw JSONAdapterError.notAJSONDictionary
        }
        return dictionary
    }

    public static func jsonArray<T: Encodable>(
        from models: [T],
        encoder: JSONEncoder = JSONEncoder()
    ) throws -> [[String: Any]] {
        try models.map { try jsonDictionary(from: $0, encoder: encoder) }
    }
}
