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

struct URIKeyedEncodingContainer<Key: CodingKey> {
    let translator: URIValueToNodeEncoder
}

extension URIKeyedEncodingContainer {
    private func _insertValue(_ node: URIEncodableNode, atKey key: Key) throws {
        try translator.currentStackEntry.storage.insert(node, atKey: key)
    }

    private func _insertValue(_ node: URIEncodableNode.Primitive, atKey key: Key) throws {
        try _insertValue(.primitive(node), atKey: key)
    }

    private func _insertBinaryFloatingPoint(
        _ value: some BinaryFloatingPoint,
        atKey key: Key
    ) throws {
        try _insertValue(.double(Double(value)), atKey: key)
    }

    private func _insertFixedWidthInteger(
        _ value: some FixedWidthInteger,
        atKey key: Key
    ) throws {
        guard let validatedValue = Int(exactly: value) else {
            throw URIValueToNodeEncoder.GeneralError.integerOutOfRange
        }
        try _insertValue(.integer(validatedValue), atKey: key)
    }
}

extension URIKeyedEncodingContainer: KeyedEncodingContainerProtocol {

    var codingPath: [any CodingKey] {
        translator.codingPath
    }

    mutating func encodeNil(forKey key: Key) throws {
        // Setting a nil value is equivalent to not encoding the value at all.
    }

    mutating func encode(_ value: Bool, forKey key: Key) throws {
        try _insertValue(.bool(value), atKey: key)
    }

    mutating func encode(_ value: String, forKey key: Key) throws {
        try _insertValue(.string(value), atKey: key)
    }

    mutating func encode(_ value: Double, forKey key: Key) throws {
        try _insertBinaryFloatingPoint(value, atKey: key)
    }

    mutating func encode(_ value: Float, forKey key: Key) throws {
        try _insertBinaryFloatingPoint(value, atKey: key)
    }

    mutating func encode(_ value: Int, forKey key: Key) throws {
        try _insertFixedWidthInteger(value, atKey: key)
    }

    mutating func encode(_ value: Int8, forKey key: Key) throws {
        try _insertFixedWidthInteger(value, atKey: key)
    }

    mutating func encode(_ value: Int16, forKey key: Key) throws {
        try _insertFixedWidthInteger(value, atKey: key)
    }

    mutating func encode(_ value: Int32, forKey key: Key) throws {
        try _insertFixedWidthInteger(value, atKey: key)
    }

    mutating func encode(_ value: Int64, forKey key: Key) throws {
        try _insertFixedWidthInteger(value, atKey: key)
    }

    mutating func encode(_ value: UInt, forKey key: Key) throws {
        try _insertFixedWidthInteger(value, atKey: key)
    }

    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        try _insertFixedWidthInteger(value, atKey: key)
    }

    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        try _insertFixedWidthInteger(value, atKey: key)
    }

    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        try _insertFixedWidthInteger(value, atKey: key)
    }

    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        try _insertFixedWidthInteger(value, atKey: key)
    }

    mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        switch value {
        case let value as UInt8:
            try encode(value, forKey: key)
        case let value as Int8:
            try encode(value, forKey: key)
        case let value as UInt16:
            try encode(value, forKey: key)
        case let value as Int16:
            try encode(value, forKey: key)
        case let value as UInt32:
            try encode(value, forKey: key)
        case let value as Int32:
            try encode(value, forKey: key)
        case let value as UInt64:
            try encode(value, forKey: key)
        case let value as Int64:
            try encode(value, forKey: key)
        case let value as Int:
            try encode(value, forKey: key)
        case let value as UInt:
            try encode(value, forKey: key)
        case let value as Float:
            try encode(value, forKey: key)
        case let value as Double:
            try encode(value, forKey: key)
        case let value as String:
            try encode(value, forKey: key)
        case let value as Bool:
            try encode(value, forKey: key)
        default:
            translator.push(key: .init(key), newStorage: .unset)
            try value.encode(to: translator)
            try translator.pop()
        }
    }

    mutating func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        translator.container(keyedBy: NestedKey.self)
    }

    mutating func nestedUnkeyedContainer(
        forKey key: Key
    ) -> any UnkeyedEncodingContainer {
        translator.unkeyedContainer()
    }

    mutating func superEncoder() -> any Encoder {
        translator
    }

    mutating func superEncoder(forKey key: Key) -> any Encoder {
        translator
    }
}
