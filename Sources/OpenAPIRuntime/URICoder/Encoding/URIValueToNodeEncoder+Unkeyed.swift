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

/// An unkeyed container used by `URIValueToNodeEncoder`.
struct URIUnkeyedEncodingContainer {

    /// The associated encoder.
    let encoder: URIValueToNodeEncoder
}

extension URIUnkeyedEncodingContainer {

    /// Appends the provided node to the underlying array.
    /// - Parameter node: The node to append.
    private func _appendValue(_ node: URIEncodedNode) throws {
        try encoder.currentStackEntry.storage.append(node)
    }

    /// Appends the provided primitive value as a node to the underlying array.
    /// - Parameter node: The value to append.
    private func _appendValue(_ node: URIEncodedNode.Primitive) throws {
        try _appendValue(.primitive(node))
    }

    /// Appends the provided value as a node to the underlying array.
    /// - Parameter node: The value to append.
    private func _appendBinaryFloatingPoint(_ value: some BinaryFloatingPoint) throws {
        try _appendValue(.double(Double(value)))
    }

    /// Appends the provided value as a node to the underlying array.
    /// - Parameter node: The value to append.
    private func _appendFixedWidthInteger(_ value: some FixedWidthInteger) throws {
        guard let validatedValue = Int(exactly: value) else {
            throw URIValueToNodeEncoder.GeneralError.integerOutOfRange
        }
        try _appendValue(.integer(validatedValue))
    }
}

extension URIUnkeyedEncodingContainer: UnkeyedEncodingContainer {

    var codingPath: [any CodingKey] {
        encoder.codingPath
    }

    var count: Int {
        switch encoder.currentStackEntry.storage {
        case .array(let array):
            return array.count
        case .unset:
            return 0
        default:
            fatalError("Cannot have an unkeyed container at \(encoder.currentStackEntry).")
        }
    }

    func nestedUnkeyedContainer() -> any UnkeyedEncodingContainer {
        encoder.unkeyedContainer()
    }

    func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type
    ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        encoder.container(keyedBy: NestedKey.self)
    }

    func superEncoder() -> any Encoder {
        encoder
    }

    func encodeNil() throws {
        throw URIValueToNodeEncoder.GeneralError.nilNotSupported
    }

    func encode(_ value: Bool) throws {
        try _appendValue(.bool(value))
    }

    func encode(_ value: String) throws {
        try _appendValue(.string(value))
    }

    func encode(_ value: Double) throws {
        try _appendBinaryFloatingPoint(value)
    }

    func encode(_ value: Float) throws {
        try _appendBinaryFloatingPoint(value)
    }

    func encode(_ value: Int) throws {
        try _appendFixedWidthInteger(value)
    }

    func encode(_ value: Int8) throws {
        try _appendFixedWidthInteger(value)
    }

    func encode(_ value: Int16) throws {
        try _appendFixedWidthInteger(value)
    }

    func encode(_ value: Int32) throws {
        try _appendFixedWidthInteger(value)
    }

    func encode(_ value: Int64) throws {
        try _appendFixedWidthInteger(value)
    }

    func encode(_ value: UInt) throws {
        try _appendFixedWidthInteger(value)
    }

    func encode(_ value: UInt8) throws {
        try _appendFixedWidthInteger(value)
    }

    func encode(_ value: UInt16) throws {
        try _appendFixedWidthInteger(value)
    }

    func encode(_ value: UInt32) throws {
        try _appendFixedWidthInteger(value)
    }

    func encode(_ value: UInt64) throws {
        try _appendFixedWidthInteger(value)
    }

    func encode<T>(_ value: T) throws where T: Encodable {
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
        case let value as Date:
            try _appendValue(.date(value))
        default:
            encoder.push(key: .init(intValue: count), newStorage: .unset)
            try value.encode(to: encoder)
            try encoder.pop()
        }
    }
}
