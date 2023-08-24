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

import Foundation

/// A type that encodes an `Encodable` objects to a string, if it conforms
/// to `CustomStringConvertible`.
struct StringEncoder: Sendable {}

extension StringEncoder {

    /// Attempt to encode a value into a string using `CustomStringConvertible`.
    ///
    /// - Parameters:
    ///     - value: The value to encode.
    /// - Returns: The string.
    func encode(_ value: some Encodable) throws -> String {
        let encoder = CustomStringConvertibleEncoder()
        try value.encode(to: encoder)
        return try encoder.nonNilEncodedString()
    }
}

private final class CustomStringConvertibleEncoder {
    private(set) var encodedString: String?
}

extension CustomStringConvertibleEncoder {
    enum EncoderError: Swift.Error {
        case valueNotSet
        case nilNotSupported
        case containersNotSupported
        case cannotEncodeMultipleValues
    }

    func setEncodedString(_ value: String) throws {
        guard encodedString == nil else {
            throw EncoderError.cannotEncodeMultipleValues
        }
        encodedString = value
    }

    func nonNilEncodedString() throws -> String {
        guard let encodedString else {
            throw EncoderError.valueNotSet
        }
        return encodedString
    }
}

extension CustomStringConvertibleEncoder: Encoder {

    var codingPath: [any CodingKey] {
        []
    }

    var userInfo: [CodingUserInfoKey: Any] {
        [:]
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        KeyedEncodingContainer(CustomStringConvertibleEncoder.KeyedContainer(encoder: self))
    }

    func unkeyedContainer() -> any UnkeyedEncodingContainer {
        CustomStringConvertibleEncoder.UnkeyedContainer(encoder: self)
    }

    func singleValueContainer() -> any SingleValueEncodingContainer {
        SingleValueContainer(encoder: self)
    }
}

extension CustomStringConvertibleEncoder {

    struct SingleValueContainer: SingleValueEncodingContainer {
        let encoder: CustomStringConvertibleEncoder

        var codingPath: [any CodingKey] {
            []
        }

        mutating func encodeNil() throws {
            throw CustomStringConvertibleEncoder.EncoderError.nilNotSupported
        }

        mutating func _encodeCustomStringConvertible(_ value: some CustomStringConvertible) throws {
            try encoder.setEncodedString(value.description)
        }

        mutating func encode(_ value: Bool) throws {
            try _encodeCustomStringConvertible(value)
        }

        mutating func encode(_ value: String) throws {
            try _encodeCustomStringConvertible(value)
        }

        mutating func encode(_ value: Double) throws {
            try _encodeCustomStringConvertible(value)
        }

        mutating func encode(_ value: Float) throws {
            try _encodeCustomStringConvertible(value)
        }

        mutating func encode(_ value: Int) throws {
            try _encodeCustomStringConvertible(value)
        }

        mutating func encode(_ value: Int8) throws {
            try _encodeCustomStringConvertible(value)
        }

        mutating func encode(_ value: Int16) throws {
            try _encodeCustomStringConvertible(value)
        }

        mutating func encode(_ value: Int32) throws {
            try _encodeCustomStringConvertible(value)
        }

        mutating func encode(_ value: Int64) throws {
            try _encodeCustomStringConvertible(value)
        }

        mutating func encode(_ value: UInt) throws {
            try _encodeCustomStringConvertible(value)
        }

        mutating func encode(_ value: UInt8) throws {
            try _encodeCustomStringConvertible(value)
        }

        mutating func encode(_ value: UInt16) throws {
            try _encodeCustomStringConvertible(value)
        }

        mutating func encode(_ value: UInt32) throws {
            try _encodeCustomStringConvertible(value)
        }

        mutating func encode(_ value: UInt64) throws {
            try _encodeCustomStringConvertible(value)
        }

        mutating func encode<T>(_ value: T) throws where T: Encodable {
            switch value {
            case let value as UInt8:
                try encode(value)
            case let value as Int8:
                try encode(value)
            case let value as UInt16:
                try encode(value)
            case let value as Int16:
                try encode(value)
            case let value as UInt32:
                try encode(value)
            case let value as Int32:
                try encode(value)
            case let value as UInt64:
                try encode(value)
            case let value as Int64:
                try encode(value)
            case let value as Int:
                try encode(value)
            case let value as UInt:
                try encode(value)
            case let value as Float:
                try encode(value)
            case let value as Double:
                try encode(value)
            case let value as String:
                try encode(value)
            case let value as Bool:
                try encode(value)
            default:
                guard let customStringConvertible = value as? any CustomStringConvertible else {
                    throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
                }
                try _encodeCustomStringConvertible(customStringConvertible)
            }
        }
    }

    struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        let encoder: CustomStringConvertibleEncoder

        var codingPath: [any CodingKey] {
            []
        }

        mutating func superEncoder() -> any Encoder {
            encoder
        }

        mutating func encodeNil(forKey key: Key) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: Bool, forKey key: Key) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: String, forKey key: Key) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: Double, forKey key: Key) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: Float, forKey key: Key) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: Int, forKey key: Key) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: Int8, forKey key: Key) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: Int16, forKey key: Key) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: Int32, forKey key: Key) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: Int64, forKey key: Key) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: UInt, forKey key: Key) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: UInt8, forKey key: Key) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: UInt16, forKey key: Key) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: UInt32, forKey key: Key) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: UInt64, forKey key: Key) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func nestedContainer<NestedKey>(
            keyedBy keyType: NestedKey.Type,
            forKey key: Key
        ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            encoder.container(keyedBy: NestedKey.self)
        }

        mutating func nestedUnkeyedContainer(forKey key: Key) -> any UnkeyedEncodingContainer {
            encoder.unkeyedContainer()
        }

        mutating func superEncoder(forKey key: Key) -> any Encoder {
            encoder
        }
    }

    struct UnkeyedContainer: UnkeyedEncodingContainer {

        let encoder: CustomStringConvertibleEncoder

        var codingPath: [any CodingKey] {
            []
        }

        var count: Int {
            0
        }

        mutating func encodeNil() throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: Bool) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: String) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: Double) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: Float) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: Int) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: Int8) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: Int16) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: Int32) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: Int64) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: UInt) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: UInt8) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: UInt16) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: UInt32) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode(_ value: UInt64) throws {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func encode<T>(_ value: T) throws where T: Encodable {
            throw CustomStringConvertibleEncoder.EncoderError.containersNotSupported
        }

        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey>
        where NestedKey: CodingKey {
            encoder.container(keyedBy: NestedKey.self)
        }

        mutating func nestedUnkeyedContainer() -> any UnkeyedEncodingContainer {
            encoder.unkeyedContainer()
        }

        mutating func superEncoder() -> any Encoder {
            encoder
        }
    }
}
