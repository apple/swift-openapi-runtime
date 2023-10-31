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

/// An unkeyed container used by `URIValueFromNodeDecoder`.
struct URIUnkeyedDecodingContainer {

    /// The associated decoder.
    let decoder: URIValueFromNodeDecoder

    /// The underlying array.
    let values: URIParsedValueArray

    /// The index of the item being currently decoded.
    private var index: Int

    /// Creates a new unkeyed container ready to decode the first key.
    /// - Parameters:
    ///   - decoder: The underlying decoder.
    ///   - values: The underlying array.
    init(decoder: URIValueFromNodeDecoder, values: URIParsedValueArray) {
        self.decoder = decoder
        self.values = values
        self.index = values.startIndex
    }
}

extension URIUnkeyedDecodingContainer {

    /// Returns the result from the provided closure run on the current
    /// item in the underlying array and increments the index.
    /// - Parameter work: The closure of work to run for the current item.
    /// - Returns: The result of the closure.
    /// - Throws: An error if the container ran out of items.
    private mutating func _decodingNext<R>(in work: () throws -> R) throws -> R {
        guard !isAtEnd else { throw URIValueFromNodeDecoder.GeneralError.reachedEndOfUnkeyedContainer }
        defer { values.formIndex(after: &index) }
        return try work()
    }

    /// Returns the current item in the underlying array and increments
    /// the index.
    /// - Returns: The next value found.
    /// - Throws: An error if the container ran out of items.
    private mutating func _decodeNext() throws -> URIParsedValue {
        try _decodingNext { [values, index] in values[index] }
    }

    /// Returns the next value converted to the provided type.
    ///
    /// - Parameter _: The `BinaryFloatingPoint` type to convert the value to.
    /// - Returns: The converted value.
    /// - Throws: An error if the container ran out of items or if
    ///   the conversion failed.
    private mutating func _decodeNextBinaryFloatingPoint<T: BinaryFloatingPoint>(_: T.Type = T.self) throws -> T {
        guard let double = Double(try _decodeNext()) else {
            throw DecodingError.typeMismatch(
                T.self,
                .init(codingPath: codingPath, debugDescription: "Failed to convert to Double.")
            )
        }
        return T(double)
    }

    /// Returns the next value converted to the provided type.
    ///
    /// - Parameter _: The `FixedWidthInteger` type to convert the value to.
    /// - Returns: The converted value.
    /// - Throws: An error if the container ran out of items or if
    ///   the conversion failed.
    private mutating func _decodeNextFixedWidthInteger<T: FixedWidthInteger>(_: T.Type = T.self) throws -> T {
        guard let parsedValue = T(try _decodeNext()) else {
            throw DecodingError.typeMismatch(
                T.self,
                .init(codingPath: codingPath, debugDescription: "Failed to convert to the requested type.")
            )
        }
        return parsedValue
    }

    /// Returns the next value converted to the provided type.
    ///
    /// - Parameter _: The `LosslessStringConvertible` type to convert the value to.
    /// - Returns: The converted value.
    /// - Throws: An error if the container ran out of items or if
    ///   the conversion failed.
    private mutating func _decodeNextLosslessStringConvertible<T: LosslessStringConvertible>(_: T.Type = T.self) throws
        -> T
    {
        guard let parsedValue = T(String(try _decodeNext())) else {
            throw DecodingError.typeMismatch(
                T.self,
                .init(codingPath: codingPath, debugDescription: "Failed to convert to the requested type.")
            )
        }
        return parsedValue
    }
}

extension URIUnkeyedDecodingContainer: UnkeyedDecodingContainer {

    var count: Int? { values.count }

    var isAtEnd: Bool { index == values.endIndex }

    var currentIndex: Int { index }

    var codingPath: [any CodingKey] { decoder.codingPath }

    func decodeNil() -> Bool { false }

    mutating func decode(_ type: Bool.Type) throws -> Bool { try _decodeNextLosslessStringConvertible() }

    mutating func decode(_ type: String.Type) throws -> String { String(try _decodeNext()) }

    mutating func decode(_ type: Double.Type) throws -> Double { try _decodeNextBinaryFloatingPoint() }

    mutating func decode(_ type: Float.Type) throws -> Float { try _decodeNextBinaryFloatingPoint() }

    mutating func decode(_ type: Int.Type) throws -> Int { try _decodeNextFixedWidthInteger() }

    mutating func decode(_ type: Int8.Type) throws -> Int8 { try _decodeNextFixedWidthInteger() }

    mutating func decode(_ type: Int16.Type) throws -> Int16 { try _decodeNextFixedWidthInteger() }

    mutating func decode(_ type: Int32.Type) throws -> Int32 { try _decodeNextFixedWidthInteger() }

    mutating func decode(_ type: Int64.Type) throws -> Int64 { try _decodeNextFixedWidthInteger() }

    mutating func decode(_ type: UInt.Type) throws -> UInt { try _decodeNextFixedWidthInteger() }

    mutating func decode(_ type: UInt8.Type) throws -> UInt8 { try _decodeNextFixedWidthInteger() }

    mutating func decode(_ type: UInt16.Type) throws -> UInt16 { try _decodeNextFixedWidthInteger() }

    mutating func decode(_ type: UInt32.Type) throws -> UInt32 { try _decodeNextFixedWidthInteger() }

    mutating func decode(_ type: UInt64.Type) throws -> UInt64 { try _decodeNextFixedWidthInteger() }

    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        switch type {
        case is Bool.Type: return try decode(Bool.self) as! T
        case is String.Type: return try decode(String.self) as! T
        case is Double.Type: return try decode(Double.self) as! T
        case is Float.Type: return try decode(Float.self) as! T
        case is Int.Type: return try decode(Int.self) as! T
        case is Int8.Type: return try decode(Int8.self) as! T
        case is Int16.Type: return try decode(Int16.self) as! T
        case is Int32.Type: return try decode(Int32.self) as! T
        case is Int64.Type: return try decode(Int64.self) as! T
        case is UInt.Type: return try decode(UInt.self) as! T
        case is UInt8.Type: return try decode(UInt8.self) as! T
        case is UInt16.Type: return try decode(UInt16.self) as! T
        case is UInt32.Type: return try decode(UInt32.self) as! T
        case is UInt64.Type: return try decode(UInt64.self) as! T
        case is Date.Type: return try decoder.dateTranscoder.decode(String(_decodeNext())) as! T
        default:
            return try _decodingNext { [decoder, currentIndex] in
                try decoder.push(.init(intValue: currentIndex))
                defer { decoder.pop() }
                return try type.init(from: decoder)
            }
        }
    }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey>
    where NestedKey: CodingKey { throw URIValueFromNodeDecoder.GeneralError.nestedContainersNotSupported }

    mutating func nestedUnkeyedContainer() throws -> any UnkeyedDecodingContainer {
        throw URIValueFromNodeDecoder.GeneralError.nestedContainersNotSupported
    }

    mutating func superDecoder() throws -> any Decoder { decoder }
}
