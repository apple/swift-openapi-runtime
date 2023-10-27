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

@_spi(Generated)
extension Decoder {

    // MARK: - Coding SPI

    /// Validates that no undocumented keys are present.
    ///
    /// - Throws: When at least one undocumented key is found.
    /// - Parameter knownKeys: A set of known and already decoded keys.
    public func ensureNoAdditionalProperties(knownKeys: Set<String>) throws {
        let (unknownKeys, container) = try unknownKeysAndContainer(
            knownKeys: knownKeys
        )
        guard unknownKeys.isEmpty else {
            let key = unknownKeys.sorted().first!
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: container,
                debugDescription:
                    "Additional properties are disabled, but found \(unknownKeys.count) unknown keys during decoding"
            )
        }
    }

    /// Returns decoded additional properties.
    ///
    /// The included properties are those still present in the decoder but
    /// not already decoded and passed in as known keys.
    /// - Parameter knownKeys: Known and already decoded keys.
    /// - Returns: A container with the decoded undocumented properties.
    /// - Throws: An error if decoding additional properties fails.
    public func decodeAdditionalProperties(
        knownKeys: Set<String>
    ) throws -> OpenAPIObjectContainer {
        let (unknownKeys, container) = try unknownKeysAndContainer(
            knownKeys: knownKeys
        )
        guard !unknownKeys.isEmpty else {
            return .init()
        }
        let keyValuePairs: [(String, (any Sendable)?)] = try unknownKeys.map { key in
            (
                key.stringValue,
                try container.decode(
                    OpenAPIValueContainer.self,
                    forKey: key
                )
                .value
            )
        }
        return .init(
            validatedValue: Dictionary(uniqueKeysWithValues: keyValuePairs)
        )
    }

    /// Returns decoded additional properties.
    ///
    /// The included properties are those still present in the decoder but
    /// not already decoded and passed in as known keys.
    /// - Parameter knownKeys: Known and already decoded keys.
    /// - Returns: A container with the decoded undocumented properties.
    /// - Throws: An error if there are issues with decoding the additional properties.
    public func decodeAdditionalProperties<T: Decodable>(
        knownKeys: Set<String>
    ) throws -> [String: T] {
        let (unknownKeys, container) = try unknownKeysAndContainer(
            knownKeys: knownKeys
        )
        guard !unknownKeys.isEmpty else {
            return .init()
        }
        let keyValuePairs: [(String, T)] = try unknownKeys.compactMap { key in
            return (key.stringValue, try container.decode(T.self, forKey: key))
        }
        return .init(uniqueKeysWithValues: keyValuePairs)
    }

    /// Returns the decoded value by using a single value container.
    /// - Parameter type: The type to decode.
    /// - Returns: The decoded value.
    /// - Throws: An error if there are issues with decoding the value from the single value container.
    public func decodeFromSingleValueContainer<T: Decodable>(
        _ type: T.Type = T.self
    ) throws -> T {
        let container = try singleValueContainer()
        return try container.decode(T.self)
    }

    // MARK: - Private

    /// Returns the keys in the given decoder that are not present
    /// in the `knownKeys` set.
    ///
    /// This is used to implement the `additionalProperties` feature.
    /// - Parameter knownKeys: A set of known keys that have already been decoded.
    /// - Returns: A tuple containing two values: a set of unknown keys and a keyed decoding container
    ///            for further decoding of the unknown properties.
    /// - Throws: An error if there are issues with creating the decoding container or identifying
    ///           the unknown keys.
    private func unknownKeysAndContainer(
        knownKeys: Set<String>
    ) throws -> (Set<StringKey>, KeyedDecodingContainer<StringKey>) {
        let container = try container(keyedBy: StringKey.self)
        let unknownKeys = Set(container.allKeys)
            .subtracting(knownKeys.map(StringKey.init(_:)))
        return (unknownKeys, container)
    }
}

@_spi(Generated)
extension Encoder {
    /// Encodes additional properties into the encoder.
    ///
    /// The properties are encoded directly into the encoder, rather that
    /// into a nested container.
    /// - Parameter additionalProperties: A container of additional properties.
    /// - Throws: An error if there are issues with encoding the additional properties.
    public func encodeAdditionalProperties(
        _ additionalProperties: OpenAPIObjectContainer
    ) throws {
        guard !additionalProperties.value.isEmpty else {
            return
        }
        var container = container(keyedBy: StringKey.self)
        for (key, value) in additionalProperties.value {
            try container.encode(
                OpenAPIValueContainer(unvalidatedValue: value),
                forKey: .init(key)
            )
        }
    }

    /// Encodes additional properties into the encoder.
    ///
    /// The properties are encoded directly into the encoder, rather that
    /// into a nested container.
    /// - Parameter additionalProperties: A container of additional properties.
    /// - Throws: An error if there are issues with encoding the additional properties.
    public func encodeAdditionalProperties<T: Encodable>(
        _ additionalProperties: [String: T]
    ) throws {
        guard !additionalProperties.isEmpty else {
            return
        }
        var container = container(keyedBy: StringKey.self)
        for (key, value) in additionalProperties {
            try container.encode(value, forKey: .init(key))
        }
    }

    /// Encodes the value into the encoder using a single value container.
    /// - Parameter value: The value to encode.
    /// - Throws: An error if there are issues with encoding the value.
    public func encodeToSingleValueContainer<T: Encodable>(
        _ value: T
    ) throws {
        var container = singleValueContainer()
        try container.encode(value)
    }

    /// Encodes the first non-nil value from the provided array into
    /// the encoder using a single value container.
    /// - Parameter values: An array of optional values.
    /// - Throws: An error if there are issues with encoding the value.
    public func encodeFirstNonNilValueToSingleValueContainer(
        _ values: [(any Encodable)?]
    ) throws {
        for value in values {
            if let value {
                try encodeToSingleValueContainer(value)
                return
            }
        }
    }
}

/// A freeform String coding key for decoding undocumented values.
struct StringKey: CodingKey, Hashable, Comparable {

    var stringValue: String
    var intValue: Int? {
        Int(stringValue)
    }

    init(_ string: String) {
        self.stringValue = string
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
    }

    static func < (lhs: StringKey, rhs: StringKey) -> Bool {
        lhs.stringValue < rhs.stringValue
    }
}
