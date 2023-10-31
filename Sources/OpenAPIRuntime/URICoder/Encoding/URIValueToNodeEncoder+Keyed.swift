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

/// A keyed container used by `URIValueToNodeEncoder`.
struct URIKeyedEncodingContainer<Key: CodingKey> {

    /// The associated encoder.
    let encoder: URIValueToNodeEncoder
}

extension URIKeyedEncodingContainer {

    /// Inserts the provided node into the underlying dictionary at
    /// the provided key.
    /// - Parameters:
    ///   - node: The child node to insert.
    ///   - key: The key for the child node.
    /// - Throws: An error if inserting the child node into the underlying dictionary at the provided key fails.
    private func _insertValue(_ node: URIEncodedNode, atKey key: Key) throws {
        try encoder.currentStackEntry.storage.insert(node, atKey: key)
    }

    /// Inserts the provided primitive value into the underlying dictionary at
    /// the provided key.
    /// - Parameters:
    ///   - node: The primitive value to insert.
    ///   - key: The key for the value.
    /// - Throws: An error if inserting the primitive value into the underlying dictionary at the provided key fails.
    private func _insertValue(_ node: URIEncodedNode.Primitive, atKey key: Key) throws {
        try _insertValue(.primitive(node), atKey: key)
    }

    /// Inserts the provided value into the underlying dictionary at
    /// the provided key.
    /// - Parameters:
    ///   - value: The value to insert.
    ///   - key: The key for the value.
    /// - Throws: An error if inserting the value into the underlying dictionary at the provided key fails.
    private func _insertBinaryFloatingPoint(_ value: some BinaryFloatingPoint, atKey key: Key) throws {
        try _insertValue(.double(Double(value)), atKey: key)
    }

    /// Inserts the provided value into the underlying dictionary at
    /// the provided key.
    /// - Parameters:
    ///   - value: The value to insert.
    ///   - key: The key for the value.
    /// - Throws: An error if the provided value is outside the valid range for an integer,
    /// or if inserting the value into the underlying dictionary at the provided key fails.
    private func _insertFixedWidthInteger(_ value: some FixedWidthInteger, atKey key: Key) throws {
        guard let validatedValue = Int(exactly: value) else {
            throw URIValueToNodeEncoder.GeneralError.integerOutOfRange
        }
        try _insertValue(.integer(validatedValue), atKey: key)
    }
}

extension URIKeyedEncodingContainer: KeyedEncodingContainerProtocol {

    var codingPath: [any CodingKey] { encoder.codingPath }

    mutating func encodeNil(forKey key: Key) throws {
        // Setting a nil value is equivalent to not encoding the value at all.
    }

    mutating func encode(_ value: Bool, forKey key: Key) throws { try _insertValue(.bool(value), atKey: key) }

    mutating func encode(_ value: String, forKey key: Key) throws { try _insertValue(.string(value), atKey: key) }

    mutating func encode(_ value: Double, forKey key: Key) throws { try _insertBinaryFloatingPoint(value, atKey: key) }

    mutating func encode(_ value: Float, forKey key: Key) throws { try _insertBinaryFloatingPoint(value, atKey: key) }

    mutating func encode(_ value: Int, forKey key: Key) throws { try _insertFixedWidthInteger(value, atKey: key) }

    mutating func encode(_ value: Int8, forKey key: Key) throws { try _insertFixedWidthInteger(value, atKey: key) }

    mutating func encode(_ value: Int16, forKey key: Key) throws { try _insertFixedWidthInteger(value, atKey: key) }

    mutating func encode(_ value: Int32, forKey key: Key) throws { try _insertFixedWidthInteger(value, atKey: key) }

    mutating func encode(_ value: Int64, forKey key: Key) throws { try _insertFixedWidthInteger(value, atKey: key) }

    mutating func encode(_ value: UInt, forKey key: Key) throws { try _insertFixedWidthInteger(value, atKey: key) }

    mutating func encode(_ value: UInt8, forKey key: Key) throws { try _insertFixedWidthInteger(value, atKey: key) }

    mutating func encode(_ value: UInt16, forKey key: Key) throws { try _insertFixedWidthInteger(value, atKey: key) }

    mutating func encode(_ value: UInt32, forKey key: Key) throws { try _insertFixedWidthInteger(value, atKey: key) }

    mutating func encode(_ value: UInt64, forKey key: Key) throws { try _insertFixedWidthInteger(value, atKey: key) }

    mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        switch value {
        case let value as UInt8: try encode(value, forKey: key)
        case let value as Int8: try encode(value, forKey: key)
        case let value as UInt16: try encode(value, forKey: key)
        case let value as Int16: try encode(value, forKey: key)
        case let value as UInt32: try encode(value, forKey: key)
        case let value as Int32: try encode(value, forKey: key)
        case let value as UInt64: try encode(value, forKey: key)
        case let value as Int64: try encode(value, forKey: key)
        case let value as Int: try encode(value, forKey: key)
        case let value as UInt: try encode(value, forKey: key)
        case let value as Float: try encode(value, forKey: key)
        case let value as Double: try encode(value, forKey: key)
        case let value as String: try encode(value, forKey: key)
        case let value as Bool: try encode(value, forKey: key)
        case let value as Date: try _insertValue(.date(value), atKey: key)
        default:
            encoder.push(key: .init(key), newStorage: .unset)
            try value.encode(to: encoder)
            try encoder.pop()
        }
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key)
        -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey
    { encoder.container(keyedBy: NestedKey.self) }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> any UnkeyedEncodingContainer { encoder.unkeyedContainer() }

    mutating func superEncoder() -> any Encoder { encoder }

    mutating func superEncoder(forKey key: Key) -> any Encoder { encoder }
}
