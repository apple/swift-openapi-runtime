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
public struct OpenAPIValueContainer: Codable, Equatable, Hashable, Sendable {

    /// The underlying dynamic value.
    public var value: Sendable?

    /// Creates a new container with the given validated value.
    /// - Parameter value: A value of a JSON-compatible type, such as `String`,
    /// `[Any]`, and `[String: Any]`.
    init(validatedValue value: Sendable?) {
        self.value = value
    }

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
    static func tryCast(_ value: (any Sendable)?) throws -> Sendable? {
        guard let value = value else {
            return nil
        }
        if let array = value as? [(any Sendable)?] {
            return try array.map(tryCast(_:))
        }
        if let dictionary = value as? [String: (any Sendable)?] {
            return try dictionary.mapValues(tryCast(_:))
        }
        if let value = tryCastPrimitiveType(value) {
            return value
        }
        throw EncodingError.invalidValue(
            value,
            .init(
                codingPath: [],
                debugDescription: "Type '\(type(of: value))' is not a supported OpenAPI value."
            )
        )
    }

    /// Returns the specified value cast to a supported primitive type.
    /// - Parameter value: An untyped value.
    /// - Returns: A cast value if supported, nil otherwise.
    static func tryCastPrimitiveType(_ value: any Sendable) -> (any Sendable)? {
        switch value {
        case is String, is Int, is Bool, is Double:
            return value
        default:
            return nil
        }
    }

    // MARK: Decodable

    public init(from decoder: Decoder) throws {
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
        } else if let item = try? container.decode([OpenAPIValueContainer].self) {
            self.init(validatedValue: item.map(\.value))
        } else if let item = try? container.decode([String: OpenAPIValueContainer].self) {
            self.init(validatedValue: item.mapValues(\.value))
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "OpenAPIValueContainer cannot be decoded"
            )
        }
    }

    // MARK: Encodable

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        guard let value = value else {
            try container.encodeNil()
            return
        }
        switch value {
        case let value as Bool:
            try container.encode(value)
        case let value as Int:
            try container.encode(value)
        case let value as Double:
            try container.encode(value)
        case let value as String:
            try container.encode(value)
        case let value as [OpenAPIValueContainer?]:
            try container.encode(value.map(OpenAPIValueContainer.init(validatedValue:)))
        case let value as [String: OpenAPIValueContainer?]:
            try container.encode(value.mapValues(OpenAPIValueContainer.init(validatedValue:)))
        default:
            throw EncodingError.invalidValue(
                value,
                .init(codingPath: container.codingPath, debugDescription: "OpenAPIValueContainer cannot be encoded")
            )
        }
    }

    // MARK: Equatable

    public static func == (lhs: OpenAPIValueContainer, rhs: OpenAPIValueContainer) -> Bool {
        switch (lhs.value, rhs.value) {
        case (nil, nil), is (Void, Void):
            return true
        case let (lhs as Bool, rhs as Bool):
            return lhs == rhs
        case let (lhs as Int, rhs as Int):
            return lhs == rhs
        case let (lhs as Int64, rhs as Int64):
            return lhs == rhs
        case let (lhs as Int32, rhs as Int32):
            return lhs == rhs
        case let (lhs as Float, rhs as Float):
            return lhs == rhs
        case let (lhs as Double, rhs as Double):
            return lhs == rhs
        case let (lhs as String, rhs as String):
            return lhs == rhs
        case let (lhs as [Sendable?], rhs as [Sendable?]):
            guard lhs.count == rhs.count else {
                return false
            }
            return zip(lhs, rhs)
                .allSatisfy { lhs, rhs in
                    OpenAPIValueContainer(validatedValue: lhs) == OpenAPIValueContainer(validatedValue: rhs)
                }
        case let (lhs as [String: Sendable?], rhs as [String: Sendable?]):
            guard lhs.count == rhs.count else {
                return false
            }
            guard Set(lhs.keys) == Set(rhs.keys) else {
                return false
            }
            for key in lhs.keys {
                guard
                    OpenAPIValueContainer(validatedValue: lhs[key]!) == OpenAPIValueContainer(validatedValue: rhs[key]!)
                else {
                    return false
                }
            }
            return true
        default:
            return false
        }
    }

    // MARK: Hashable

    public func hash(into hasher: inout Hasher) {
        switch value {
        case let value as Bool:
            hasher.combine(value)
        case let value as Int:
            hasher.combine(value)
        case let value as Double:
            hasher.combine(value)
        case let value as String:
            hasher.combine(value)
        case let value as [Sendable]:
            for item in value {
                hasher.combine(OpenAPIValueContainer(validatedValue: item))
            }
        case let value as [String: Sendable]:
            for (key, itemValue) in value {
                hasher.combine(key)
                hasher.combine(OpenAPIValueContainer(validatedValue: itemValue))
            }
        default:
            break
        }
    }
}

extension OpenAPIValueContainer: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) {
        self.init(validatedValue: value)
    }
}

extension OpenAPIValueContainer: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(validatedValue: value)
    }
}

extension OpenAPIValueContainer: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self.init(validatedValue: nil)
    }
}

extension OpenAPIValueContainer: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(validatedValue: value)
    }
}

extension OpenAPIValueContainer: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self.init(validatedValue: value)
    }
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
public struct OpenAPIObjectContainer: Codable, Equatable, Hashable, Sendable {

    /// The underlying dynamic dictionary value.
    public var value: [String: Sendable?]

    /// Creates a new container with the given validated dictionary.
    /// - Parameter value: A dictionary value.
    init(validatedValue value: [String: Sendable?]) {
        self.value = value
    }

    /// Creates a new empty container.
    public init() {
        self.init(validatedValue: [:])
    }

    /// Creates a new container with the given unvalidated value.
    ///
    /// First it validates that the values of the provided dictionary
    /// are supported, and throws otherwise.
    /// - Parameter unvalidatedValue: A dictionary with values of
    /// JSON-compatible types.
    /// - Throws: When the value is not supported.
    public init(unvalidatedValue: [String: Any?]) throws {
        try self.init(validatedValue: Self.tryCast(unvalidatedValue))
    }

    // MARK: Private

    /// Returns the specified value cast to a supported dictionary.
    /// - Parameter value: A dictionary with untyped values.
    /// - Returns: A cast dictionary if values are supported.
    /// - Throws: If an unsupported value is found.
    static func tryCast(_ value: [String: Any?]) throws -> [String: Sendable?] {
        return try value.mapValues(OpenAPIValueContainer.tryCast(_:))
    }

    // MARK: Decodable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let item = try container.decode([String: OpenAPIValueContainer].self)
        self.init(validatedValue: item.mapValues(\.value))
    }

    // MARK: Encodable

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value.mapValues(OpenAPIValueContainer.init(validatedValue:)))
    }

    // MARK: Equatable

    public static func == (lhs: OpenAPIObjectContainer, rhs: OpenAPIObjectContainer) -> Bool {
        let lv = lhs.value
        let rv = rhs.value
        guard lv.count == rv.count else {
            return false
        }
        guard Set(lv.keys) == Set(rv.keys) else {
            return false
        }
        for key in lv.keys {
            guard OpenAPIValueContainer(validatedValue: lv[key]!) == OpenAPIValueContainer(validatedValue: rv[key]!)
            else {
                return false
            }
        }
        return true
    }

    // MARK: Hashable

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
public struct OpenAPIArrayContainer: Codable, Equatable, Hashable, Sendable {

    /// The underlying dynamic array value.
    public var value: [Sendable?]

    /// Creates a new container with the given validated array.
    /// - Parameter value: An array value.
    init(validatedValue value: [Sendable?]) {
        self.value = value
    }

    /// Creates a new empty container.
    public init() {
        self.init(validatedValue: [])
    }

    /// Creates a new container with the given unvalidated value.
    ///
    /// First it validates that the provided value is supported, and throws
    /// otherwise.
    /// - Parameter unvalidatedValue: An array with values of JSON-compatible
    /// types.
    /// - Throws: When the value is not supported.
    public init(unvalidatedValue: [Any?]) throws {
        try self.init(validatedValue: Self.tryCast(unvalidatedValue))
    }

    // MARK: Private

    /// Returns the specified value cast to an array of supported values.
    /// - Parameter value: An array with untyped values.
    /// - Returns: A cast value if values are supported, nil otherwise.
    static func tryCast(_ value: [Any?]) throws -> [Sendable?] {
        return try value.map(OpenAPIValueContainer.tryCast(_:))
    }

    // MARK: Decodable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let item = try container.decode([OpenAPIValueContainer].self)
        self.init(validatedValue: item.map(\.value))
    }

    // MARK: Encodable

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value.map(OpenAPIValueContainer.init(validatedValue:)))
    }

    // MARK: Equatable

    public static func == (lhs: OpenAPIArrayContainer, rhs: OpenAPIArrayContainer) -> Bool {
        let lv = lhs.value
        let rv = rhs.value
        guard lv.count == rv.count else {
            return false
        }
        return zip(lv, rv)
            .allSatisfy { lhs, rhs in
                OpenAPIValueContainer(validatedValue: lhs) == OpenAPIValueContainer(validatedValue: rhs)
            }
    }

    // MARK: Hashable

    public func hash(into hasher: inout Hasher) {
        for item in value {
            hasher.combine(OpenAPIValueContainer(validatedValue: item))
        }
    }
}
