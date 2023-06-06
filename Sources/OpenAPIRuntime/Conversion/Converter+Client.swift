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

extension Converter {

    // MARK: Query - _StringConvertible

    /// Adds a query item with a string-convertible value to the request.
    /// - Parameters:
    ///   - request: Request to add the query item.
    ///   - name: Query item name.
    ///   - value: Query item string-convertible value.
    public func queryAdd<T: _StringConvertible>(
        in request: inout Request,
        name: String,
        value: T?
    ) throws {
        request.mutatingQuery { components in
            components.addQueryItem(
                name: name,
                value: value
            )
        }
    }

    // MARK: Query - Date

    /// Adds a query item with a Date value to the request.
    /// - Parameters:
    ///   - request: Request to add the query item.
    ///   - name: Query item name.
    ///   - value: Query item Date value.
    public func queryAdd(
        in request: inout Request,
        name: String,
        value: Date?
    ) throws {
        try request.mutatingQuery { components in
            try components.addQueryItem(
                name: name,
                value: value.flatMap { value in
                    try self.configuration.dateTranscoder.encode(value)
                }
            )
        }
    }

    // MARK: Query - Array of _StringConvertible

    /// Adds a query item with a list of string-convertible values to the request.
    /// - Parameters:
    ///   - request: Request to add the query item.
    ///   - name: Query item name.
    ///   - value: Query item string-convertible values.
    public func queryAdd<T: _StringConvertible>(
        in request: inout Request,
        name: String,
        value: [T]?
    ) throws {
        request.mutatingQuery { components in
            components.addQueryItem(
                name: name,
                value: value
            )
        }
    }

    // MARK: Body - Complex

    /// Gets a deserialized value from body data.
    /// - Parameters:
    ///   - type: Type used to decode the data.
    ///   - data: Encoded body data.
    ///   - strategy: A hint about which coding strategy to use.
    ///   - transform: Closure for transforming the Decodable type into a final
    ///   type.
    /// - Returns: Deserialized body value.
    public func bodyGet<T: Decodable, C>(
        _ type: T.Type,
        from data: Data,
        strategy: BodyCodingStrategy,
        transforming transform: (T) -> C
    ) throws -> C {
        let decoded: T
        if let myType = T.self as? _StringConvertible.Type,
            strategy == .string
        {
            guard
                let stringValue = String(data: data, encoding: .utf8),
                let decodedValue = myType.init(stringValue)
            else {
                throw RuntimeError.failedToDecodeBody(type: T.self)
            }
            decoded = decodedValue as! T
        } else {
            decoded = try decoder.decode(type, from: data)
        }
        return transform(decoded)
    }

    /// Provides an optional serialized value for the body value.
    /// - Parameters:
    ///   - value: Encodable value to turn into data.
    ///   - headerFields: Headers container where to add the Content-Type header.
    ///   - transform: Closure for transforming the Encodable value into body content.
    /// - Returns: Data for the serialized body value, or nil if `value` was nil.
    public func bodyAddOptional<T: Encodable, C>(
        _ value: C?,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<T>
    ) throws -> Data? {
        guard let value else {
            return nil
        }
        return try bodyAddRequired(
            value,
            headerFields: &headerFields,
            transforming: transform
        )
    }

    /// Provides a required serialized value for the body value.
    /// - Parameters:
    ///   - value: Encodable value to turn into data.
    ///   - headerFields: Headers container where to add the Content-Type header.
    ///   - transform: Closure for transforming the Encodable value into body content.
    /// - Returns: Data for the serialized body value.
    public func bodyAddRequired<T: Encodable, C>(
        _ value: C,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<T>
    ) throws -> Data {
        let body = transform(value)
        headerFields.add(name: "content-type", value: body.contentType)
        if let value = value as? _StringConvertible,
            body.strategy == .string
        {
            guard let data = value.description.data(using: .utf8) else {
                throw RuntimeError.failedToEncodeBody(type: T.self)
            }
            return data
        }
        return try encoder.encode(body.value)
    }

    // MARK: Body - Primivite - Data

    /// Gets a deserialized value from body data.
    /// - Parameters:
    ///   - type: Type used to decode the data.
    ///   - data: Encoded body data.
    ///   - strategy: A hint about which coding strategy to use.
    ///   - transform: Closure for transforming the Decodable type into a final type.
    /// - Returns: Deserialized body value.
    public func bodyGet<C>(
        _ type: Data.Type,
        from data: Data,
        strategy: BodyCodingStrategy,
        transforming transform: (Data) -> C
    ) throws -> C {
        return transform(data)
    }

    /// Provides an optional serialized value for the body value.
    /// - Parameters:
    ///   - value: Encodable value to turn into data.
    ///   - headerFields: Headers container where to add the Content-Type header.
    ///   - transform: Closure for transforming the Encodable value into body content.
    /// - Returns: Data for the serialized body value, or nil if `value` was nil.
    public func bodyAddOptional<C>(
        _ value: C?,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<Data>
    ) throws -> Data? {
        guard let value else {
            return nil
        }
        return try bodyAddRequired(
            value,
            headerFields: &headerFields,
            transforming: transform
        )
    }

    /// Provides a required serialized value for the body value.
    /// - Parameters:
    ///   - value: Encodable value to turn into data.
    ///   - headerFields: Headers container where to add the Content-Type header.
    ///   - transform: Closure for transforming the Encodable value into body content.
    /// - Returns: Data for the serialized body value.
    public func bodyAddRequired<C>(
        _ value: C,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<Data>
    ) throws -> Data {
        let body = transform(value)
        headerFields.add(name: "content-type", value: body.contentType)
        return body.value
    }
}
