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

/// A type that decodes a `Decodable` objects from a string
/// using `LosslessStringConvertible`.
struct StringDecoder: Sendable {

    /// The coder used to serialize Date values.
    let dateTranscoder: any DateTranscoder
}

extension StringDecoder {

    /// Attempt to decode an object from a string.
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - data: The encoded string.
    /// - Returns: The decoded value.
    func decode<T: Decodable>(
        _ type: T.Type = T.self,
        from data: String
    ) throws -> T {
        let decoder = LosslessStringConvertibleDecoder(
            dateTranscoder: dateTranscoder,
            encodedString: data
        )
        // We have to catch the special values early, otherwise we fall
        // back to their Codable implementations, which don't give us
        // a chance to customize the coding in the containers.
        let value: T
        switch type {
        case is Date.Type:
            value = try decoder.singleValueContainer().decode(Date.self) as! T
        default:
            value = try T.init(from: decoder)
        }
        return value
    }
}

/// The decoder used by `StringDecoder`.
private struct LosslessStringConvertibleDecoder {

    /// The coder used to serialize Date values.
    let dateTranscoder: any DateTranscoder

    /// The underlying encoded string.
    let encodedString: String
}

extension LosslessStringConvertibleDecoder {

    /// A decoder error.
    enum DecoderError: Swift.Error {

        /// The `LosslessStringConvertible` initializer returned nil for the
        /// provided raw string.
        case failedToDecodeValue

        /// The decoder tried to decode a nested container, which are not
        /// supported.
        case containersNotSupported
    }
}

extension LosslessStringConvertibleDecoder: Decoder {

    var codingPath: [any CodingKey] {
        []
    }

    var userInfo: [CodingUserInfoKey: Any] {
        [:]
    }

    func container<Key>(
        keyedBy type: Key.Type
    ) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        KeyedDecodingContainer(KeyedContainer(decoder: self))
    }

    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        UnkeyedContainer(decoder: self)
    }

    func singleValueContainer() throws -> any SingleValueDecodingContainer {
        SingleValueContainer(decoder: self)
    }
}

extension LosslessStringConvertibleDecoder {

    /// A single value container used by `LosslessStringConvertibleDecoder`.
    struct SingleValueContainer {

        /// The underlying decoder.
        let decoder: LosslessStringConvertibleDecoder

        /// Decodes a value of type conforming to `LosslessStringConvertible`.
        /// - Returns: The decoded value.
        private func _decodeLosslessStringConvertible<T: LosslessStringConvertible>(
            _: T.Type = T.self
        ) throws -> T {
            guard let parsedValue = T(String(decoder.encodedString)) else {
                throw DecodingError.typeMismatch(
                    T.self,
                    .init(
                        codingPath: codingPath,
                        debugDescription: "Failed to convert to the requested type."
                    )
                )
            }
            return parsedValue
        }
    }

    /// An unkeyed container used by `LosslessStringConvertibleDecoder`.
    struct UnkeyedContainer {

        /// The underlying decoder.
        let decoder: LosslessStringConvertibleDecoder
    }

    /// A keyed container used by `LosslessStringConvertibleDecoder`.
    struct KeyedContainer<Key: CodingKey> {

        /// The underlying decoder.
        let decoder: LosslessStringConvertibleDecoder
    }
}

extension LosslessStringConvertibleDecoder.SingleValueContainer: SingleValueDecodingContainer {

    var codingPath: [any CodingKey] {
        []
    }

    func decodeNil() -> Bool {
        false
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        try _decodeLosslessStringConvertible()
    }

    func decode(_ type: String.Type) throws -> String {
        try _decodeLosslessStringConvertible()
    }

    func decode(_ type: Double.Type) throws -> Double {
        try _decodeLosslessStringConvertible()
    }

    func decode(_ type: Float.Type) throws -> Float {
        try _decodeLosslessStringConvertible()
    }

    func decode(_ type: Int.Type) throws -> Int {
        try _decodeLosslessStringConvertible()
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        try _decodeLosslessStringConvertible()
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        try _decodeLosslessStringConvertible()
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        try _decodeLosslessStringConvertible()
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        try _decodeLosslessStringConvertible()
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        try _decodeLosslessStringConvertible()
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        try _decodeLosslessStringConvertible()
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        try _decodeLosslessStringConvertible()
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        try _decodeLosslessStringConvertible()
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        try _decodeLosslessStringConvertible()
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        switch type {
        case is Bool.Type:
            return try decode(Bool.self) as! T
        case is String.Type:
            return try decode(String.self) as! T
        case is Double.Type:
            return try decode(Double.self) as! T
        case is Float.Type:
            return try decode(Float.self) as! T
        case is Int.Type:
            return try decode(Int.self) as! T
        case is Int8.Type:
            return try decode(Int8.self) as! T
        case is Int16.Type:
            return try decode(Int16.self) as! T
        case is Int32.Type:
            return try decode(Int32.self) as! T
        case is Int64.Type:
            return try decode(Int64.self) as! T
        case is UInt.Type:
            return try decode(UInt.self) as! T
        case is UInt8.Type:
            return try decode(UInt8.self) as! T
        case is UInt16.Type:
            return try decode(UInt16.self) as! T
        case is UInt32.Type:
            return try decode(UInt32.self) as! T
        case is UInt64.Type:
            return try decode(UInt64.self) as! T
        case is Date.Type:
            return try decoder
                .dateTranscoder
                .decode(String(decoder.encodedString)) as! T
        default:
            guard let convertileType = T.self as? any LosslessStringConvertible.Type else {
                throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
            }
            return try _decodeLosslessStringConvertible(convertileType) as! T
        }
    }
}

extension LosslessStringConvertibleDecoder.UnkeyedContainer: UnkeyedDecodingContainer {

    var codingPath: [any CodingKey] {
        []
    }

    var count: Int? {
        nil
    }

    var isAtEnd: Bool {
        true
    }

    var currentIndex: Int {
        0
    }

    mutating func decodeNil() throws -> Bool {
        false
    }

    mutating func decode(_ type: Bool.Type) throws -> Bool {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    mutating func decode(_ type: String.Type) throws -> String {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    mutating func decode(_ type: Double.Type) throws -> Double {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    mutating func decode(_ type: Float.Type) throws -> Float {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    mutating func decode(_ type: Int.Type) throws -> Int {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    mutating func decode(_ type: UInt.Type) throws -> UInt {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    mutating func nestedContainer<NestedKey>(
        keyedBy type: NestedKey.Type
    ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    mutating func nestedUnkeyedContainer() throws -> any UnkeyedDecodingContainer {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    mutating func superDecoder() throws -> any Decoder {
        decoder
    }

}

extension LosslessStringConvertibleDecoder.KeyedContainer: KeyedDecodingContainerProtocol {

    var codingPath: [any CodingKey] {
        []
    }

    var allKeys: [Key] {
        []
    }

    func contains(_ key: Key) -> Bool {
        false
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    func nestedContainer<NestedKey>(
        keyedBy type: NestedKey.Type,
        forKey key: Key
    ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
        throw LosslessStringConvertibleDecoder.DecoderError.containersNotSupported
    }

    func superDecoder() throws -> any Decoder {
        decoder
    }

    func superDecoder(forKey key: Key) throws -> any Decoder {
        decoder
    }
}
