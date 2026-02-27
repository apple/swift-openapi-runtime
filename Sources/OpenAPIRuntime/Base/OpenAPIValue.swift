//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if canImport(FoundationEssentials) && !FullFoundationSupport
import FoundationEssentials
#else
import Foundation
#endif

#if FullFoundationSupport && canImport(CoreFoundation)
import CoreFoundation
#endif

/// A container for a value represented by JSON Schema.
///
/// Contains an untyped JSON value. In some cases, the structure of the data
/// may not be known in advance and must be dynamically iterated at decoding
/// time. This is an advanced feature that requires extra validation of
/// the input before use, and is at a higher risk of a security vulnerability.
///
/// Supported nested Swift types:
/// - `nil`
/// - `String`
/// - `Int`
/// - `Double`
/// - `Bool`
/// - `[Any?]`
/// - `[String: Any?]`
///
/// Where the element type of the array, and the value type of the dictionary
/// must also be supported types.
///
/// - Important: This type is expensive at runtime; try to avoid it.
/// Define the structure of your types in the OpenAPI document instead.
public struct OpenAPIValueContainer: Codable, Hashable, Sendable {

    /// The underlying dynamic value.
    public var value: (any Sendable)?

    /// Creates a new container with the given validated value.
    /// - Parameter value: A value of a JSON-compatible type, such as `String`,
    /// `[Any]`, and `[String: Any]`.
    init(validatedValue value: (any Sendable)?) { self.value = value }

    /// Creates a new container with the given unvalidated value.
    ///
    /// First it validates that the provided value is supported, and throws
    /// otherwise.
    /// - Parameter unvalidatedValue: A value of a JSON-compatible type,
    /// such as `String`, `[Any]`, and `[String: Any]`.
    /// - Throws: When the value is not supported.
    public init(unvalidatedValue: (any Sendable)? = nil) throws {
        try self.init(validatedValue: Self.tryCast(unvalidatedValue))
    }

    // MARK: Private

    /// Returns the specified value cast to a supported type.
    /// - Parameter value: An untyped value.
    /// - Returns: A cast value if supported.
    /// - Throws: When the value is not supported.
    static func tryCast(_ value: (any Sendable)?) throws -> (any Sendable)? {
        guard let value = value else { return nil }
        #if FullFoundationSupport && canImport(Foundation)
        if value is NSNull { return value }
        #endif
        if let array = value as? [(any Sendable)?] { return try array.map(tryCast(_:)) }
        if let dictionary = value as? [String: (any Sendable)?] { return try dictionary.mapValues(tryCast(_:)) }
        if let value = tryCastPrimitiveType(value) { return value }
        throw EncodingError.invalidValue(
            value,
            .init(codingPath: [], debugDescription: "Type '\(type(of: value))' is not a supported OpenAPI value.")
        )
    }

    /// Returns the specified value cast to a supported primitive type.
    /// - Parameter value: An untyped value.
    /// - Returns: A cast value if supported, nil otherwise.
    static func tryCastPrimitiveType(_ value: any Sendable) -> (any Sendable)? {
        switch value {
        case is String, is Int, is Bool, is Double: return value
        default: return nil
        }
    }

    // MARK: Decodable

    /// Initializes an `OpenAPIValueContainer` by decoding it from a decoder.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if the decoding process encounters issues or if the data is corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.init(validatedValue: nil)
        } else if let item = try? container.decode(Bool.self) {
            self.init(validatedValue: item)
        } else if let item = try? container.decode(Int.self) {
            self.init(validatedValue: item)
        } else if let item = try? container.decode(Double.self) {
            self.init(validatedValue: item)
        } else if let item = try? container.decode(String.self) {
            self.init(validatedValue: item)
        } else if var container = try? decoder.unkeyedContainer() {
            var items: [(any Sendable)?] = []
            if let count = container.count { items.reserveCapacity(count) }
            while !container.isAtEnd {
                let item = try container.decode(OpenAPIValueContainer.self)
                items.append(item.value)
            }
            self.init(validatedValue: items)
        } else if let container = try? decoder.container(keyedBy: StringKey.self) {
            let keyValuePairs = try container.allKeys.map { key -> (String, (any Sendable)?) in
                let item = try container.decode(OpenAPIValueContainer.self, forKey: key)
                return (key.stringValue, item.value)
            }
            self.init(validatedValue: Dictionary(uniqueKeysWithValues: keyValuePairs))
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "OpenAPIValueContainer cannot be decoded"
            )
        }
    }

    // MARK: Encodable

    /// Encodes the `OpenAPIValueContainer` and writes it to an encoder.
    ///
    /// - Parameter encoder: The encoder to which the value should be encoded.
    /// - Throws: An error if the encoding process encounters issues or if the value is invalid.
    public func encode(to encoder: any Encoder) throws {
        guard let value = value else {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
            return
        }
        #if FullFoundationSupport && canImport(Foundation)
        if value is NSNull {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
            return
        }
        #if canImport(CoreFoundation)
        if let nsNumber = value as? NSNumber {
            var container = encoder.singleValueContainer()
            try encode(nsNumber, to: &container)
            return
        }
        #endif
        #endif
        switch value {
        case let value as Bool:
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case let value as Int:
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case let value as Double:
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case let value as String:
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case let value as [(any Sendable)?]:
            var container = encoder.unkeyedContainer()
            for item in value {
                let containerItem = OpenAPIValueContainer(validatedValue: item)
                try container.encode(containerItem)
            }
        case let value as [String: (any Sendable)?]:
            var container = encoder.container(keyedBy: StringKey.self)
            for (itemKey, itemValue) in value {
                try container.encode(OpenAPIValueContainer(validatedValue: itemValue), forKey: StringKey(itemKey))
            }
        default:
            throw EncodingError.invalidValue(
                value,
                .init(codingPath: encoder.codingPath, debugDescription: "OpenAPIValueContainer cannot be encoded")
            )
        }
    }
    #if FullFoundationSupport && canImport(CoreFoundation)
    /// Encodes the provided NSNumber based on its internal representation.
    /// - Parameters:
    ///   - value: The NSNumber that boxes one of possibly many different types of values.
    ///   - container: The container to encode the value in.
    /// - Throws: An error if the encoding process encounters issues or if the value is invalid.
    private func encode(_ value: NSNumber, to container: inout any SingleValueEncodingContainer) throws {
        if value === kCFBooleanTrue {
            try container.encode(true)
        } else if value === kCFBooleanFalse {
            try container.encode(false)
        } else {
            #if canImport(ObjectiveC)
            let nsNumber = value as CFNumber
            #else
            let nsNumber = unsafeBitCast(value, to: CFNumber.self)
            #endif
            let type = CFNumberGetType(nsNumber)
            switch type {
            case .sInt8Type, .charType: try container.encode(value.int8Value)
            case .sInt16Type, .shortType: try container.encode(value.int16Value)
            case .sInt32Type, .intType: try container.encode(value.int32Value)
            case .sInt64Type, .longLongType: try container.encode(value.int64Value)
            case .float32Type, .floatType: try container.encode(value.floatValue)
            case .float64Type, .doubleType, .cgFloatType: try container.encode(value.doubleValue)
            case .nsIntegerType, .longType, .cfIndexType: try container.encode(value.intValue)
            default:
                throw EncodingError.invalidValue(
                    value,
                    .init(
                        codingPath: container.codingPath,
                        debugDescription: "OpenAPIValueContainer cannot encode NSNumber of the underlying type: \(type)"
                    )
                )
            }
        }
    }
    #endif

    // MARK: Equatable

    /// Compares two `OpenAPIValueContainer` instances for equality.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side `OpenAPIValueContainer` to compare.
    ///   - rhs: The right-hand side `OpenAPIValueContainer` to compare.
    /// - Returns: `true` if the two instances are equal, `false` otherwise.
    public static func == (lhs: OpenAPIValueContainer, rhs: OpenAPIValueContainer) -> Bool {
        switch (lhs.value, rhs.value) {
        case (nil, nil), is (Void, Void): return true
        case let (lhs as Bool, rhs as Bool): return lhs == rhs
        case let (lhs as Int, rhs as Int): return lhs == rhs
        case let (lhs as Int64, rhs as Int64): return lhs == rhs
        case let (lhs as Int32, rhs as Int32): return lhs == rhs
        case let (lhs as Float, rhs as Float): return lhs == rhs
        case let (lhs as Double, rhs as Double): return lhs == rhs
        case let (lhs as String, rhs as String): return lhs == rhs
        case let (lhs as [(any Sendable)?], rhs as [(any Sendable)?]):
            guard lhs.count == rhs.count else { return false }
            return zip(lhs, rhs)
                .allSatisfy { lhs, rhs in
                    OpenAPIValueContainer(validatedValue: lhs) == OpenAPIValueContainer(validatedValue: rhs)
                }
        case let (lhs as [String: (any Sendable)?], rhs as [String: (any Sendable)?]):
            guard lhs.count == rhs.count else { return false }
            guard Set(lhs.keys) == Set(rhs.keys) else { return false }
            for key in lhs.keys {
                guard
                    OpenAPIValueContainer(validatedValue: lhs[key]!) == OpenAPIValueContainer(validatedValue: rhs[key]!)
                else { return false }
            }
            return true
        default: return false
        }
    }

    // MARK: Hashable

    /// Hashes the `OpenAPIValueContainer` instance into a hasher.
    ///
    /// - Parameter hasher: The hasher used to compute the hash value.
    public func hash(into hasher: inout Hasher) {
        switch value {
        case let value as Bool: hasher.combine(value)
        case let value as Int: hasher.combine(value)
        case let value as Double: hasher.combine(value)
        case let value as String: hasher.combine(value)
        case let value as [(any Sendable)?]:
            for item in value { hasher.combine(OpenAPIValueContainer(validatedValue: item)) }
        case let value as [String: (any Sendable)?]:
            for (key, itemValue) in value {
                hasher.combine(key)
                hasher.combine(OpenAPIValueContainer(validatedValue: itemValue))
            }
        default: break
        }
    }
}

extension OpenAPIValueContainer: ExpressibleByBooleanLiteral {
    /// Creates an `OpenAPIValueContainer` with the provided boolean value.
    ///
    /// - Parameter value: The boolean value to store in the container.
    public init(booleanLiteral value: BooleanLiteralType) { self.init(validatedValue: value) }
}

extension OpenAPIValueContainer: ExpressibleByStringLiteral {
    /// Creates an `OpenAPIValueContainer` with the provided string value.
    ///
    /// - Parameter value: The string value to store in the container.
    public init(stringLiteral value: String) { self.init(validatedValue: value) }
}

extension OpenAPIValueContainer: ExpressibleByNilLiteral {
    /// Creates an `OpenAPIValueContainer` with a `nil` value.
    ///
    /// - Parameter nilLiteral: The `nil` literal.
    public init(nilLiteral: ()) { self.init(validatedValue: nil) }
}

extension OpenAPIValueContainer: ExpressibleByIntegerLiteral {
    /// Creates an `OpenAPIValueContainer` with the provided integer value.
    ///
    /// - Parameter value: The integer value to store in the container.
    public init(integerLiteral value: Int) { self.init(validatedValue: value) }
}

extension OpenAPIValueContainer: ExpressibleByFloatLiteral {
    /// Creates an `OpenAPIValueContainer` with the provided floating-point value.
    ///
    /// - Parameter value: The floating-point value to store in the container.
    public init(floatLiteral value: Double) { self.init(validatedValue: value) }
}

/// A container for a dictionary with values represented by JSON Schema.
///
/// Contains a dictionary of untyped JSON values. In some cases, the structure
/// of the data may not be known in advance and must be dynamically iterated
/// at decoding time. This is an advanced feature that requires extra
/// validation of the input before use, and is at a higher risk of a security
/// vulnerability.
///
/// Supported nested Swift types:
/// - `nil`
/// - `String`
/// - `Int`
/// - `Double`
/// - `Bool`
/// - `[Any?]`
/// - `[String: Any?]`
///
/// Where the element type of the array, and the value type of the dictionary
/// must also be supported types.
///
/// - Important: This type is expensive at runtime; try to avoid it.
/// Define the structure of your types in the OpenAPI document instead.
public struct OpenAPIObjectContainer: Codable, Hashable, Sendable {

    /// The underlying dynamic dictionary value.
    public var value: [String: (any Sendable)?]

    /// Creates a new container with the given validated dictionary.
    /// - Parameter value: A dictionary value.
    init(validatedValue value: [String: (any Sendable)?]) { self.value = value }

    /// Creates a new empty container.
    public init() { self.init(validatedValue: [:]) }

    /// Creates a new container with the given unvalidated value.
    ///
    /// First it validates that the values of the provided dictionary
    /// are supported, and throws otherwise.
    /// - Parameter unvalidatedValue: A dictionary with values of
    /// JSON-compatible types.
    /// - Throws: When the value is not supported.
    public init(unvalidatedValue: [String: (any Sendable)?]) throws {
        try self.init(validatedValue: Self.tryCast(unvalidatedValue))
    }

    // MARK: Private

    /// Returns the specified value cast to a supported dictionary.
    /// - Parameter value: A dictionary with untyped values.
    /// - Returns: A cast dictionary if values are supported.
    /// - Throws: If an unsupported value is found.
    static func tryCast(_ value: [String: (any Sendable)?]) throws -> [String: (any Sendable)?] {
        try value.mapValues(OpenAPIValueContainer.tryCast(_:))
    }

    // MARK: Decodable

    // swift-format-ignore: AllPublicDeclarationsHaveDocumentation
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: StringKey.self)
        let keyValuePairs = try container.allKeys.map { key -> (String, (any Sendable)?) in
            let item = try container.decode(OpenAPIValueContainer.self, forKey: key)
            return (key.stringValue, item.value)
        }
        self.init(validatedValue: Dictionary(uniqueKeysWithValues: keyValuePairs))
    }

    // MARK: Encodable

    // swift-format-ignore: AllPublicDeclarationsHaveDocumentation
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: StringKey.self)
        for (itemKey, itemValue) in value {
            try container.encode(OpenAPIValueContainer(validatedValue: itemValue), forKey: StringKey(itemKey))
        }
    }

    // MARK: Equatable

    // swift-format-ignore: AllPublicDeclarationsHaveDocumentation
    public static func == (lhs: OpenAPIObjectContainer, rhs: OpenAPIObjectContainer) -> Bool {
        let lv = lhs.value
        let rv = rhs.value
        guard lv.count == rv.count else { return false }
        guard Set(lv.keys) == Set(rv.keys) else { return false }
        for key in lv.keys {
            guard OpenAPIValueContainer(validatedValue: lv[key]!) == OpenAPIValueContainer(validatedValue: rv[key]!)
            else { return false }
        }
        return true
    }

    // MARK: Hashable

    // swift-format-ignore: AllPublicDeclarationsHaveDocumentation
    public func hash(into hasher: inout Hasher) {
        for (key, itemValue) in value {
            hasher.combine(key)
            hasher.combine(OpenAPIValueContainer(validatedValue: itemValue))
        }
    }
}

/// A container for an array with values represented by JSON Schema.
///
/// Contains an array of untyped JSON values. In some cases, the structure
/// of the data may not be known in advance and must be dynamically iterated
/// at decoding time. This is an advanced feature that requires extra
/// validation of the input before use, and is at a higher risk of a security
/// vulnerability.
///
/// Supported nested Swift types:
/// - `nil`
/// - `String`
/// - `Int`
/// - `Double`
/// - `Bool`
/// - `[Any?]`
/// - `[String: Any?]`
///
/// Where the element type of the array, and the value type of the dictionary
/// must also be supported types.
///
/// - Important: This type is expensive at runtime; try to avoid it.
/// Define the structure of your types in the OpenAPI document instead.
public struct OpenAPIArrayContainer: Codable, Hashable, Sendable {

    /// The underlying dynamic array value.
    public var value: [(any Sendable)?]

    /// Creates a new container with the given validated array.
    /// - Parameter value: An array value.
    init(validatedValue value: [(any Sendable)?]) { self.value = value }

    /// Creates a new empty container.
    public init() { self.init(validatedValue: []) }

    /// Creates a new container with the given unvalidated value.
    ///
    /// First it validates that the provided value is supported, and throws
    /// otherwise.
    /// - Parameter unvalidatedValue: An array with values of JSON-compatible
    /// types.
    /// - Throws: When the value is not supported.
    public init(unvalidatedValue: [(any Sendable)?]) throws {
        try self.init(validatedValue: Self.tryCast(unvalidatedValue))
    }

    // MARK: Private

    /// Returns the specified value cast to an array of supported values.
    /// - Parameter value: An array with untyped values.
    /// - Returns: A cast value if values are supported, nil otherwise.
    /// - Throws: An error if casting to supported values fails for any element.
    static func tryCast(_ value: [(any Sendable)?]) throws -> [(any Sendable)?] {
        try value.map(OpenAPIValueContainer.tryCast(_:))
    }

    // MARK: Decodable

    /// Initializes a new instance by decoding a validated array of values from a decoder.
    ///
    /// - Parameter decoder: The decoder to use for decoding the array of values.
    /// - Throws: An error if the decoding process fails or if the decoded values cannot be validated.
    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var items: [(any Sendable)?] = []
        if let count = container.count { items.reserveCapacity(count) }
        while !container.isAtEnd {
            let item = try container.decode(OpenAPIValueContainer.self)
            items.append(item.value)
        }
        self.init(validatedValue: items)
    }

    // MARK: Encodable

    /// Encodes the array of validated values and stores the result in the given encoder.
    ///
    /// - Parameter encoder: The encoder to use for encoding the array of values.
    /// - Throws: An error if the encoding process fails.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        for item in value {
            let containerItem = OpenAPIValueContainer(validatedValue: item)
            try container.encode(containerItem)
        }
    }

    // MARK: Equatable

    /// Compares two `OpenAPIArrayContainer` instances for equality.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side `OpenAPIArrayContainer` to compare.
    ///   - rhs: The right-hand side `OpenAPIArrayContainer` to compare.
    /// - Returns: `true` if the two `OpenAPIArrayContainer` instances are equal, `false` otherwise.
    public static func == (lhs: OpenAPIArrayContainer, rhs: OpenAPIArrayContainer) -> Bool {
        let lv = lhs.value
        let rv = rhs.value
        guard lv.count == rv.count else { return false }
        return zip(lv, rv)
            .allSatisfy { lhs, rhs in
                OpenAPIValueContainer(validatedValue: lhs) == OpenAPIValueContainer(validatedValue: rhs)
            }
    }

    // MARK: Hashable

    /// Hashes the `OpenAPIArrayContainer` instance into a hasher.
    ///
    /// - Parameter hasher: The hasher used to compute the hash value.
    public func hash(into hasher: inout Hasher) {
        for item in value { hasher.combine(OpenAPIValueContainer(validatedValue: item)) }
    }
}
