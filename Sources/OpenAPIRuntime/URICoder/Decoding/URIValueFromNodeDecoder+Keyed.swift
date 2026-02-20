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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A keyed container used by `URIValueFromNodeDecoder`.
struct URIKeyedDecodingContainer<Key: CodingKey> {

    /// The associated decoder.
    let decoder: URIValueFromNodeDecoder
}

extension URIKeyedDecodingContainer {

    /// Returns the value found for the provided key in the underlying
    /// dictionary.
    /// - Parameter key: The key for which to return the value.
    /// - Returns: The value found for the provided key.
    /// - Throws: An error if no value for the key was found.
    private func _decodeValue(forKey key: Key) throws -> URIParsedValue {
        guard let value = try decoder.nestedElementInCurrentDictionary(forKey: key.stringValue) else {
            throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "Key not found."))
        }
        return value
    }

    /// Returns the value found for the provided key in the underlying
    /// dictionary converted to the provided type.
    /// - Parameters:
    ///  - _: The `BinaryFloatingPoint` type to convert the value to.
    ///  - key: The key for which to return the value.
    /// - Returns: The converted value found for the provided key.
    /// - Throws: An error if no value for the key was found or if the
    ///   conversion failed.
    private func _decodeBinaryFloatingPoint<T: BinaryFloatingPoint>(_: T.Type = T.self, forKey key: Key) throws -> T {
        guard let double = Double(try _decodeValue(forKey: key)) else {
            throw DecodingError.typeMismatch(
                T.self,
                .init(codingPath: codingPath, debugDescription: "Failed to convert to Double.")
            )
        }
        return T(double)
    }

    /// Returns the value found for the provided key in the underlying
    /// dictionary converted to the provided type.
    /// - Parameters:
    ///  - _: The fixed-width integer type to convert the value to.
    ///  - key: The key for which to return the value.
    /// - Returns: The converted value found for the provided key.
    /// - Throws: An error if no value for the key was found or if the
    ///   conversion failed.
    private func _decodeFixedWidthInteger<T: FixedWidthInteger>(_: T.Type = T.self, forKey key: Key) throws -> T {
        guard let parsedValue = T(try _decodeValue(forKey: key)) else {
            throw DecodingError.typeMismatch(
                T.self,
                .init(codingPath: codingPath, debugDescription: "Failed to convert to the requested type.")
            )
        }
        return parsedValue
    }

    /// Returns the value found for the provided key in the underlying
    /// dictionary converted to the provided type.
    /// - Parameters:
    ///   - _: The type to convert the value to.
    ///   - key: The key for which to return the value.
    /// - Returns: The converted value found for the provided key.
    /// - Throws: An error if no value for the key was found or if the
    ///   conversion failed.
    private func _decodeNextLosslessStringConvertible<T: LosslessStringConvertible>(_: T.Type = T.self, forKey key: Key)
        throws -> T
    {
        guard let parsedValue = T(String(try _decodeValue(forKey: key))) else {
            throw DecodingError.typeMismatch(
                T.self,
                .init(codingPath: codingPath, debugDescription: "Failed to convert to the requested type.")
            )
        }
        return parsedValue
    }
}

extension URIKeyedDecodingContainer: KeyedDecodingContainerProtocol {

    var allKeys: [Key] { decoder.elementKeysInCurrentDictionary().compactMap { .init(stringValue: $0) } }

    func contains(_ key: Key) -> Bool { decoder.containsElementInCurrentDictionary(forKey: key.stringValue) }

    var codingPath: [any CodingKey] { decoder.codingPath }

    func decodeNil(forKey key: Key) -> Bool { false }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        try _decodeNextLosslessStringConvertible(forKey: key)
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String { String(try _decodeValue(forKey: key)) }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double { try _decodeBinaryFloatingPoint(forKey: key) }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float { try _decodeBinaryFloatingPoint(forKey: key) }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int { try _decodeFixedWidthInteger(forKey: key) }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 { try _decodeFixedWidthInteger(forKey: key) }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 { try _decodeFixedWidthInteger(forKey: key) }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 { try _decodeFixedWidthInteger(forKey: key) }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 { try _decodeFixedWidthInteger(forKey: key) }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt { try _decodeFixedWidthInteger(forKey: key) }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 { try _decodeFixedWidthInteger(forKey: key) }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { try _decodeFixedWidthInteger(forKey: key) }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { try _decodeFixedWidthInteger(forKey: key) }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { try _decodeFixedWidthInteger(forKey: key) }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        switch type {
        case is Bool.Type: return try decode(Bool.self, forKey: key) as! T
        case is String.Type: return try decode(String.self, forKey: key) as! T
        case is Double.Type: return try decode(Double.self, forKey: key) as! T
        case is Float.Type: return try decode(Float.self, forKey: key) as! T
        case is Int.Type: return try decode(Int.self, forKey: key) as! T
        case is Int8.Type: return try decode(Int8.self, forKey: key) as! T
        case is Int16.Type: return try decode(Int16.self, forKey: key) as! T
        case is Int32.Type: return try decode(Int32.self, forKey: key) as! T
        case is Int64.Type: return try decode(Int64.self, forKey: key) as! T
        case is UInt.Type: return try decode(UInt.self, forKey: key) as! T
        case is UInt8.Type: return try decode(UInt8.self, forKey: key) as! T
        case is UInt16.Type: return try decode(UInt16.self, forKey: key) as! T
        case is UInt32.Type: return try decode(UInt32.self, forKey: key) as! T
        case is UInt64.Type: return try decode(UInt64.self, forKey: key) as! T
        case is Date.Type: return try decoder.dateTranscoder.decode(String(_decodeValue(forKey: key))) as! T
        default:
            decoder.push(.init(key))
            defer { decoder.pop() }
            return try type.init(from: decoder)
        }
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<
        NestedKey
    > where NestedKey: CodingKey { throw URIValueFromNodeDecoder.GeneralError.nestedContainersNotSupported }

    func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
        throw URIValueFromNodeDecoder.GeneralError.nestedContainersNotSupported
    }

    func superDecoder(forKey key: Key) throws -> any Decoder { decoder }

    func superDecoder() throws -> any Decoder { decoder }
}
