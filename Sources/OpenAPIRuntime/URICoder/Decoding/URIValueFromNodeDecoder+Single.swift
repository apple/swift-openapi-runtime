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

struct URISingleValueDecodingContainer  {
    let _codingPath: [any CodingKey]
    let value: URIParsedValue
}

extension URISingleValueDecodingContainer {
    private func _decodeBinaryFloatingPoint<T: BinaryFloatingPoint>(
        _: T.Type = T.self
    ) throws -> T {
        guard let double = Double(value) else {
            throw DecodingError.typeMismatch(
                T.self,
                .init(
                    codingPath: codingPath,
                    debugDescription: "Failed to convert to Double."
                )
            )
        }
        return T(double)
    }

    private func _decodeFixedWidthInteger<T: FixedWidthInteger>(
        _: T.Type = T.self
    ) throws -> T {
        guard let parsedValue = T(value) else {
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
    
    private func _decodeLosslessStringConvertible<T: LosslessStringConvertible>(
        _: T.Type = T.self
    ) throws -> T {
        guard let parsedValue = T(String(value)) else {
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

extension URISingleValueDecodingContainer: SingleValueDecodingContainer {
    
    var codingPath: [any CodingKey] {
        _codingPath
    }
    
    func decodeNil() -> Bool {
        false
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        try _decodeLosslessStringConvertible()
    }
    
    func decode(_ type: String.Type) throws -> String {
        String(value)
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        try _decodeBinaryFloatingPoint()
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        try _decodeBinaryFloatingPoint()
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        try _decodeFixedWidthInteger()
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        try _decodeFixedWidthInteger()
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        try _decodeFixedWidthInteger()
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        try _decodeFixedWidthInteger()
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        try _decodeFixedWidthInteger()
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        try _decodeFixedWidthInteger()
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        try _decodeFixedWidthInteger()
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        try _decodeFixedWidthInteger()
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        try _decodeFixedWidthInteger()
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        try _decodeFixedWidthInteger()
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
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
        default:
            throw URIValueFromNodeDecoder.GeneralError.unsupportedType(T.self)
        }
    }
}
