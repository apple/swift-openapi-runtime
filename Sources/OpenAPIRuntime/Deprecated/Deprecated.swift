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

// MARK: - Functionality to be removed in the future

/// A wrapper of a body value with its content type.
@available(*, deprecated)
@_spi(Generated)
public struct EncodableBodyContent<T: Equatable>: Equatable {

    /// An encodable body value.
    public var value: T

    /// The header value of the content type, for example `application/json`.
    public var contentType: String

    /// Creates a new content wrapper.
    /// - Parameters:
    ///   - value: An encodable body value.
    ///   - contentType: The header value of the content type.
    public init(
        value: T,
        contentType: String
    ) {
        self.value = value
        self.contentType = contentType
    }
}

extension Converter {
    /// Gets a deserialized value from body data.
    /// - Parameters:
    ///   - type: Type used to decode the data.
    ///   - data: Encoded body data.
    ///   - transform: Closure for transforming the Decodable type into a final type.
    /// - Returns: Deserialized body value.
    @available(*, deprecated)
    public func bodyGet<T: Decodable, C>(
        _ type: T.Type,
        from data: Data,
        transforming transform: (T) -> C
    ) throws -> C {
        let decoded = try decoder.decode(type, from: data)
        return transform(decoded)
    }

    /// Gets a deserialized value from body data.
    /// - Parameters:
    ///   - type: Type used to decode the data.
    ///   - data: Encoded body data.
    ///   - transform: Closure for transforming the Decodable type into a final type.
    /// - Returns: Deserialized body value.
    @available(*, deprecated)
    public func bodyGet<C>(
        _ type: Data.Type,
        from data: Data,
        transforming transform: (Data) -> C
    ) throws -> C {
        return transform(data)
    }

    /// Gets a deserialized value from body data, if present.
    /// - Parameters:
    ///   - type: Type used to decode the data.
    ///   - data: Encoded body data.
    ///   - transform: Closure for transforming the Decodable type into a final type.
    /// - Returns: Deserialized body value, if present.
    @available(*, deprecated)
    public func bodyGetOptional<T: Decodable, C>(
        _ type: T.Type,
        from data: Data?,
        transforming transform: (T) -> C
    ) throws -> C? {
        guard let data else {
            return nil
        }
        let decoded = try decoder.decode(type, from: data)
        return transform(decoded)
    }

    /// Gets a deserialized value from body data.
    /// - Parameters:
    ///   - type: Type used to decode the data.
    ///   - data: Encoded body data.
    ///   - transform: Closure for transforming the Decodable type into a final type.
    /// - Returns: Deserialized body value.
    @available(*, deprecated)
    public func bodyGetRequired<T: Decodable, C>(
        _ type: T.Type,
        from data: Data?,
        transforming transform: (T) -> C
    ) throws -> C {
        guard let data else {
            throw RuntimeError.missingRequiredRequestBody
        }
        let decoded = try decoder.decode(type, from: data)
        return transform(decoded)
    }

    /// Gets a deserialized value from body data, if present.
    /// - Parameters:
    ///   - type: Type used to decode the data.
    ///   - data: Encoded body data.
    ///   - transform: Closure for transforming the Decodable type into a final type.
    /// - Returns: Deserialized body value, if present.
    @available(*, deprecated)
    public func bodyGetOptional<C>(
        _ type: Data.Type,
        from data: Data?,
        transforming transform: (Data) -> C
    ) throws -> C? {
        guard let data else {
            return nil
        }
        return transform(data)
    }

    /// Gets a deserialized value from body data.
    /// - Parameters:
    ///   - type: Type used to decode the data.
    ///   - data: Encoded body data.
    ///   - transform: Closure for transforming the Decodable type into a final type.
    /// - Returns: Deserialized body value.
    @available(*, deprecated)
    public func bodyGetRequired<C>(
        _ type: Data.Type,
        from data: Data?,
        transforming transform: (Data) -> C
    ) throws -> C {
        guard let data else {
            throw RuntimeError.missingRequiredRequestBody
        }
        return transform(data)
    }

    /// Adds a header field with the provided name and Date value.
    /// - Parameters:
    ///   - headerFields: Collection of header fields to add to.
    ///   - name: The name of the header field.
    ///   - value: Date value. If nil, header is not added.
    @available(*, deprecated)
    public func headerFieldAdd(
        in headerFields: inout [HeaderField],
        name: String,
        value: Date?
    ) throws {
        guard let value = value else {
            return
        }
        let stringValue = try self.configuration.dateTranscoder.encode(value)
        headerFields.add(name: name, value: stringValue)
    }

    /// Returns the value for the first header field with given name.
    /// - Parameters:
    ///   - headerFields: Collection of header fields to retrieve the field from.
    ///   - name: The name of the header field (case-insensitive).
    ///   - type: Date type.
    /// - Returns: First value for the given name, if one exists.
    @available(*, deprecated)
    public func headerFieldGetOptional(
        in headerFields: [HeaderField],
        name: String,
        as type: Date.Type
    ) throws -> Date? {
        guard let dateString = headerFields.firstValue(name: name) else {
            return nil
        }
        return try self.configuration.dateTranscoder.decode(dateString)
    }

    /// Returns the value for the first header field with the given name.
    /// - Parameters:
    ///   - headerFields: Collection of header fields to retrieve the field from.
    ///   - name: Header name (case-insensitive).
    ///   - type: Date type.
    /// - Returns: First value for the given name.
    @available(*, deprecated)
    public func headerFieldGetRequired(
        in headerFields: [HeaderField],
        name: String,
        as type: Date.Type
    ) throws -> Date {
        guard
            let value = try headerFieldGetOptional(
                in: headerFields,
                name: name,
                as: type
            )
        else {
            throw RuntimeError.missingRequiredHeaderField(name)
        }
        return value
    }

    /// Adds a header field with the provided name and encodable value.
    ///
    /// Encodes the value into minimized JSON.
    /// - Parameters:
    ///   - headerFields: Collection of header fields to add to.
    ///   - name: Header name.
    ///   - value: Encodable header value.
    @available(*, deprecated)
    public func headerFieldAdd<T: Encodable>(
        in headerFields: inout [HeaderField],
        name: String,
        value: T?
    ) throws {
        guard let value else {
            return
        }
        if let value = value as? (any _StringConvertible) {
            headerFields.add(name: name, value: value.description)
            return
        }
        let data = try headerFieldEncoder.encode(value)
        let stringValue = String(decoding: data, as: UTF8.self)
        headerFields.add(name: name, value: stringValue)
    }

    /// Returns the value of the first header field for the given name.
    ///
    /// Decodes the value from JSON.
    /// - Parameters:
    ///   - headerFields: Collection of header fields to retrieve the field from.
    ///   - name: Header name (case-insensitive).
    ///   - type: Date type.
    /// - Returns: First value for the given name, if one exists.
    @available(*, deprecated)
    public func headerFieldGetOptional<T: Decodable>(
        in headerFields: [HeaderField],
        name: String,
        as type: T.Type
    ) throws -> T? {
        guard let stringValue = headerFields.firstValue(name: name) else {
            return nil
        }
        if let myType = T.self as? any _StringConvertible.Type {
            return myType.init(stringValue).map { $0 as! T }
        }
        let data = Data(stringValue.utf8)
        return try decoder.decode(T.self, from: data)
    }

    /// Returns the first header value for the given (case-insensitive) name.
    ///
    /// Decodes the value from JSON.
    /// - Parameters:
    ///   - headerFields: Collection of header fields to retrieve the field from.
    ///   - name: Header name (case-insensitive).
    ///   - type: Date type.
    /// - Returns: First value for the given name.
    @available(*, deprecated)
    public func headerFieldGetRequired<T: Decodable>(
        in headerFields: [HeaderField],
        name: String,
        as type: T.Type
    ) throws -> T {
        guard
            let value = try headerFieldGetOptional(
                in: headerFields,
                name: name,
                as: type
            )
        else {
            throw RuntimeError.missingRequiredHeaderField(name)
        }
        return value
    }

    // MARK: Query - _StringConvertible

    /// Adds a query item with a string-convertible value to the request.
    /// - Parameters:
    ///   - request: Request to add the query item.
    ///   - name: Query item name.
    ///   - value: Query item string-convertible value.
    @available(*, deprecated)
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
    @available(*, deprecated)
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
    @available(*, deprecated)
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

    // MARK: Query - LosslessStringConvertible

    /// Returns a deserialized value for the the first query item
    /// found under the provided name.
    /// - Parameters:
    ///   - queryParameters: Query parameters container where the value might exist.
    ///   - name: Query item name.
    ///   - type: Query item value type.
    /// - Returns: Deserialized query item value, if present.
    @available(*, deprecated)
    public func queryGetOptional<T: _StringConvertible>(
        in queryParameters: [URLQueryItem],
        name: String,
        as type: T.Type
    ) throws -> T? {
        guard let untypedValue = queryParameters.first(where: { $0.name == name })?.value else {
            return nil
        }
        guard let typedValue = T(untypedValue) else {
            throw RuntimeError.failedToDecodeStringConvertibleValue(
                type: String(describing: T.self)
            )
        }
        return typedValue
    }

    /// Returns a deserialized value for the the first query item
    /// found under the provided name.
    /// - Parameters:
    ///   - queryParameters: Query parameters container where the value must exist.
    ///   - name: Query item name.
    ///   - type: Query item value type.
    /// - Returns: Deserialized query item value.
    @available(*, deprecated)
    public func queryGetRequired<T: _StringConvertible>(
        in queryParameters: [URLQueryItem],
        name: String,
        as type: T.Type
    ) throws -> T {
        guard let untypedValue = queryParameters.first(where: { $0.name == name })?.value else {
            throw RuntimeError.missingRequiredQueryParameter(name)
        }
        guard let typedValue = T(untypedValue) else {
            throw RuntimeError.failedToDecodeStringConvertibleValue(type: String(describing: T.self))
        }
        return typedValue
    }

    // MARK: Query - Date

    /// Returns a deserialized value for the the first query item
    /// found under the provided name.
    /// - Parameters:
    ///   - queryParameters: Query parameters container where the value might exist.
    ///   - name: Query item name.
    ///   - type: Query item value type.
    /// - Returns: Deserialized query item value, if present.
    @available(*, deprecated)
    public func queryGetOptional(
        in queryParameters: [URLQueryItem],
        name: String,
        as type: Date.Type
    ) throws -> Date? {
        guard let dateString = queryParameters.first(where: { $0.name == name })?.value else {
            return nil
        }
        return try self.configuration.dateTranscoder.decode(dateString)
    }

    /// Returns a deserialized value for the the first query item
    /// found under the provided name.
    /// - Parameters:
    ///   - queryParameters: Query parameters container where the value must exist.
    ///   - name: Query item name.
    ///   - type: Query item value type.
    /// - Returns: Deserialized query item value.
    @available(*, deprecated)
    public func queryGetRequired(
        in queryParameters: [URLQueryItem],
        name: String,
        as type: Date.Type
    ) throws -> Date {
        guard let dateString = queryParameters.first(where: { $0.name == name })?.value else {
            throw RuntimeError.missingRequiredQueryParameter(name)
        }
        return try self.configuration.dateTranscoder.decode(dateString)
    }

    // MARK: Query - Array of _StringConvertible

    /// Returns an array of deserialized values for all the query items
    /// found under the provided name.
    /// - Parameters:
    ///   - queryParameters: Query parameters container where the value might exist.
    ///   - name: Query item name.
    ///   - type: Query item value type.
    /// - Returns: Deserialized query item value, if present.
    @available(*, deprecated)
    public func queryGetOptional<T: _StringConvertible>(
        in queryParameters: [URLQueryItem],
        name: String,
        as type: [T].Type
    ) throws -> [T]? {
        let items: [T] =
            try queryParameters
            .filter { $0.name == name }
            .compactMap { item in
                guard let typedValue = T(item.value ?? "") else {
                    throw RuntimeError.failedToDecodeStringConvertibleValue(
                        type: String(describing: T.self)
                    )
                }
                return typedValue
            }
        guard !items.isEmpty else {
            return nil
        }
        return items
    }

    /// Returns an array of deserialized values for all the query items
    /// found under the provided name.
    /// - Parameters:
    ///   - queryParameters: Query parameters container where the value must exist.
    ///   - name: Query item name.
    ///   - type: Query item value type.
    /// - Returns: Deserialized query item value.
    @available(*, deprecated)
    public func queryGetRequired<T: _StringConvertible>(
        in queryParameters: [URLQueryItem],
        name: String,
        as type: [T].Type
    ) throws -> [T] {
        let items: [T] =
            try queryParameters
            .filter { $0.name == name }
            .map { item in
                guard let typedValue = T(item.value ?? "") else {
                    throw RuntimeError.failedToDecodeStringConvertibleValue(type: String(describing: T.self))
                }
                return typedValue
            }
        guard !items.isEmpty else {
            throw RuntimeError.missingRequiredQueryParameter(name)
        }
        return items
    }
}

extension Request {
    /// Allows modifying the parsed query parameters of the request.
    @available(*, deprecated)
    mutating func mutatingQuery(_ closure: (inout URLComponents) throws -> Void) rethrows {
        var urlComponents = URLComponents()
        if let query {
            urlComponents.percentEncodedQuery = query
        }
        try closure(&urlComponents)
        query = urlComponents.percentEncodedQuery
    }
}

extension URLComponents {
    /// Adds a query item using the provided name and typed value.
    /// - Parameters:
    ///   - name: Query name.
    ///   - value: Typed value.
    @available(*, deprecated)
    mutating func addQueryItem<T: _StringConvertible>(
        name: String,
        value: T?
    ) {
        guard let value = value else {
            return
        }
        queryItems =
            (queryItems ?? []) + [
                .init(name: name, value: value.description)
            ]
    }

    /// Adds query items using the provided name and typed values.
    /// - Parameters:
    ///   - name: Query name.
    ///   - value: Array of typed values.
    @available(*, deprecated)
    mutating func addQueryItem<T: _StringConvertible>(
        name: String,
        value: [T]?
    ) {
        guard let items = value else {
            return
        }
        for item in items {
            addQueryItem(name: name, value: item)
        }
    }
}

/// A wrapper of a body value with its content type.
@_spi(Generated)
@available(*, deprecated, renamed: "EncodableBodyContent")
public struct LegacyEncodableBodyContent<T: Encodable & Equatable>: Equatable {

    /// An encodable body value.
    public var value: T

    /// The header value of the content type, for example `application/json`.
    public var contentType: String

    /// Creates a new content wrapper.
    /// - Parameters:
    ///   - value: An encodable body value.
    ///   - contentType: The header value of the content type.
    public init(
        value: T,
        contentType: String
    ) {
        self.value = value
        self.contentType = contentType
    }
}

extension Converter {
    /// Provides an optional serialized value for the body value.
    /// - Parameters:
    ///   - value: Encodable value to turn into data.
    ///   - headerFields: Headers container where to add the Content-Type header.
    ///   - transform: Closure for transforming the Encodable value into body content.
    /// - Returns: Data for the serialized body value, or nil if `value` was nil.
    @available(*, deprecated, message: "Use the variant with EncodableBodyContent")
    public func bodyAddOptional<T: Encodable, C>(
        _ value: C?,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> LegacyEncodableBodyContent<T>
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
    @available(*, deprecated, message: "Use the variant with EncodableBodyContent")
    public func bodyAddRequired<T: Encodable, C>(
        _ value: C,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> LegacyEncodableBodyContent<T>
    ) throws -> Data {
        let body = transform(value)
        headerFields.add(name: "content-type", value: body.contentType)
        return try encoder.encode(body.value)
    }

    /// Provides an optional serialized value for the body value.
    /// - Parameters:
    ///   - value: Encodable value to turn into data.
    ///   - headerFields: Headers container where to add the Content-Type header.
    ///   - transform: Closure for transforming the Encodable value into body content.
    /// - Returns: Data for the serialized body value, or nil if `value` was nil.
    @available(*, deprecated, message: "Use the variant with EncodableBodyContent")
    public func bodyAddOptional<C>(
        _ value: C?,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> LegacyEncodableBodyContent<Data>
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
    @available(*, deprecated, message: "Use the variant with EncodableBodyContent")
    public func bodyAddRequired<C>(
        _ value: C,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> LegacyEncodableBodyContent<Data>
    ) throws -> Data {
        let body = transform(value)
        headerFields.add(name: "content-type", value: body.contentType)
        return body.value
    }

    /// Provides a serialized value for the provided body value.
    /// - Parameters:
    ///   - value: Encodable value to turn into data.
    ///   - headerFields: Header fields container where to add the Content-Type header.
    ///   - transform: Closure for transforming the Encodable value into body content.
    /// - Returns: Data for the serialized body value.
    @available(*, deprecated, message: "Use the variant with EncodableBodyContent")
    public func bodyAdd<T: Encodable, C>(
        _ value: C,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> LegacyEncodableBodyContent<T>
    ) throws -> Data {
        let body = transform(value)
        headerFields.add(name: "content-type", value: body.contentType)
        return try encoder.encode(body.value)
    }

    /// Provides a serialized value for the provided body value.
    /// - Parameters:
    ///   - value: Encodable value to turn into data.
    ///   - headers: Headers container where to add the Content-Type header.
    ///   - transform: Closure for transforming the Encodable value into body content.
    /// - Returns: Data for the serialized body value.
    @available(*, deprecated, message: "Use the variant with EncodableBodyContent")
    public func bodyAdd<C>(
        _ value: C,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> LegacyEncodableBodyContent<Data>
    ) throws -> Data {
        let body = transform(value)
        headerFields.add(name: "content-type", value: body.contentType)
        return body.value
    }

    /// Returns a deserialized value for the required path variable name.
    /// - Parameters:
    ///   - pathParameters: Path parameters where the value must exist.
    ///   - name: Path variable name.
    ///   - type: Path variable type.
    /// - Returns: Deserialized path variable value.
    @available(*, deprecated)
    public func pathGetRequired<T: _StringConvertible>(
        in pathParameters: [String: String],
        name: String,
        as type: T.Type
    ) throws -> T {
        guard
            let value = try pathGetOptional(
                in: pathParameters,
                name: name,
                as: type
            )
        else {
            throw RuntimeError.missingRequiredPathParameter(name)
        }
        return value
    }

    /// Returns a deserialized value for the optional path variable name.
    /// - Parameters:
    ///   - pathParameters: Path parameters where the value might exist.
    ///   - name: Path variable name.
    ///   - type: Path variable type.
    /// - Returns: Deserialized path variable value, if present.
    @available(*, deprecated)
    public func pathGetOptional<T: _StringConvertible>(
        in pathParameters: [String: String],
        name: String,
        as type: T.Type
    ) throws -> T? {
        guard let untypedValue = pathParameters[name] else {
            return nil
        }
        guard let typedValue = T(untypedValue) else {
            throw RuntimeError.failedToDecodeStringConvertibleValue(type: String(describing: T.self))
        }
        return typedValue
    }
}

extension Converter {

    /// Validates that the Content-Type header field (if present)
    /// is compatible with the provided content-type substring.
    ///
    /// Succeeds if no Content-Type header is found in the response headers.
    ///
    /// - Parameters:
    ///   - headerFields: Header fields to inspect for a content type.
    ///   - substring: Expected content type.
    /// - Throws: If the response's Content-Type value is not compatible with
    /// the provided substring.
    @available(*, deprecated, message: "Use isMatchingContentType instead.")
    public func validateContentTypeIfPresent(
        in headerFields: [HeaderField],
        substring: String
    ) throws {
        guard let contentType = extractContentTypeIfPresent(in: headerFields) else {
            return
        }
        guard try isMatchingContentType(received: contentType, expectedRaw: substring) else {
            throw RuntimeError.unexpectedContentTypeHeader(contentType.description)
        }
    }

    //    | client | set | request body | text | string-convertible | optional | setOptionalRequestBodyAsText |
    @available(*, deprecated)
    public func setOptionalRequestBodyAsText<T: _StringConvertible, C>(
        _ value: C?,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<T>
    ) throws -> Data? {
        try setOptionalRequestBody(
            value,
            headerFields: &headerFields,
            transforming: transform,
            convert: convertStringConvertibleToTextData
        )
    }

    //    | client | set | request body | text | string-convertible | required | setRequiredRequestBodyAsText |
    @available(*, deprecated)
    public func setRequiredRequestBodyAsText<T: _StringConvertible, C>(
        _ value: C,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<T>
    ) throws -> Data {
        try setRequiredRequestBody(
            value,
            headerFields: &headerFields,
            transforming: transform,
            convert: convertStringConvertibleToTextData
        )
    }

    //    | client | set | request body | text | date | optional | setOptionalRequestBodyAsText |
    @available(*, deprecated)
    public func setOptionalRequestBodyAsText<C>(
        _ value: C?,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<Date>
    ) throws -> Data? {
        try setOptionalRequestBody(
            value,
            headerFields: &headerFields,
            transforming: transform,
            convert: convertDateToTextData
        )
    }

    //    | client | set | request body | text | date | required | setRequiredRequestBodyAsText |
    @available(*, deprecated)
    public func setRequiredRequestBodyAsText<C>(
        _ value: C,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<Date>
    ) throws -> Data {
        try setRequiredRequestBody(
            value,
            headerFields: &headerFields,
            transforming: transform,
            convert: convertDateToTextData
        )
    }

    //    | client | set | request body | JSON | codable | optional | setOptionalRequestBodyAsJSON |
    @available(*, deprecated)
    public func setOptionalRequestBodyAsJSON<T: Encodable, C>(
        _ value: C?,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<T>
    ) throws -> Data? {
        try setOptionalRequestBody(
            value,
            headerFields: &headerFields,
            transforming: transform,
            convert: convertBodyCodableToJSON
        )
    }

    //    | client | set | request body | JSON | codable | required | setRequiredRequestBodyAsJSON |
    @available(*, deprecated)
    public func setRequiredRequestBodyAsJSON<T: Encodable, C>(
        _ value: C,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<T>
    ) throws -> Data {
        try setRequiredRequestBody(
            value,
            headerFields: &headerFields,
            transforming: transform,
            convert: convertBodyCodableToJSON
        )
    }

    //    | client | set | request body | binary | data | optional | setOptionalRequestBodyAsBinary |
    @available(*, deprecated)
    public func setOptionalRequestBodyAsBinary<C>(
        _ value: C?,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<Data>
    ) throws -> Data? {
        try setOptionalRequestBody(
            value,
            headerFields: &headerFields,
            transforming: transform,
            convert: convertDataToBinary
        )
    }

    //    | client | set | request body | binary | data | required | setRequiredRequestBodyAsBinary |
    @available(*, deprecated)
    public func setRequiredRequestBodyAsBinary<C>(
        _ value: C,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<Data>
    ) throws -> Data {
        try setRequiredRequestBody(
            value,
            headerFields: &headerFields,
            transforming: transform,
            convert: convertDataToBinary
        )
    }

    //    | server | set | response body | text | string-convertible | required | setResponseBodyAsText |
    @available(*, deprecated)
    public func setResponseBodyAsText<T: _StringConvertible, C>(
        _ value: C,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<T>
    ) throws -> Data {
        try setResponseBody(
            value,
            headerFields: &headerFields,
            transforming: transform,
            convert: convertStringConvertibleToTextData
        )
    }

    //    | server | set | response body | text | date | required | setResponseBodyAsText |
    @available(*, deprecated)
    public func setResponseBodyAsText<C>(
        _ value: C,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<Date>
    ) throws -> Data {
        try setResponseBody(
            value,
            headerFields: &headerFields,
            transforming: transform,
            convert: convertDateToTextData
        )
    }

    //    | server | set | response body | JSON | codable | required | setResponseBodyAsJSON |
    @available(*, deprecated)
    public func setResponseBodyAsJSON<T: Encodable, C>(
        _ value: C,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<T>
    ) throws -> Data {
        try setResponseBody(
            value,
            headerFields: &headerFields,
            transforming: transform,
            convert: convertBodyCodableToJSON
        )
    }

    //    | server | set | response body | binary | data | required | setResponseBodyAsBinary |
    @available(*, deprecated)
    public func setResponseBodyAsBinary<C>(
        _ value: C,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<Data>
    ) throws -> Data {
        try setResponseBody(
            value,
            headerFields: &headerFields,
            transforming: transform,
            convert: convertDataToBinary
        )
    }

    @available(*, deprecated)
    public func setRequiredRequestBody<T, C>(
        _ value: C,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<T>,
        convert: (T) throws -> Data
    ) throws -> Data {
        let body = transform(value)
        headerFields.add(name: "content-type", value: body.contentType)
        let convertibleValue = body.value
        return try convert(convertibleValue)
    }

    @available(*, deprecated)
    public func setOptionalRequestBody<T, C>(
        _ value: C?,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<T>,
        convert: (T) throws -> Data
    ) throws -> Data? {
        guard let value else {
            return nil
        }
        return try setRequiredRequestBody(
            value,
            headerFields: &headerFields,
            transforming: transform,
            convert: convert
        )
    }

    @available(*, deprecated)
    public func setResponseBody<T, C>(
        _ value: C,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<T>,
        convert: (T) throws -> Data
    ) throws -> Data {
        let body = transform(value)
        headerFields.add(name: "content-type", value: body.contentType)
        let convertibleValue = body.value
        return try convert(convertibleValue)
    }

    //    | client | set | request query | text | string-convertible | both | setQueryItemAsText |
    @available(*, deprecated)
    public func setQueryItemAsText<T: _StringConvertible>(
        in request: inout Request,
        name: String,
        value: T?
    ) throws {
        try setUnescapedQueryItem(
            in: &request,
            style: nil,
            explode: nil,
            name: name,
            value: value,
            convert: { value, _, _ in
                try convertStringConvertibleToText(value)
            }
        )
    }

    //    | client | set | request query | text | array of string-convertibles | both | setQueryItemAsText |
    @available(*, deprecated)
    public func setQueryItemAsText<T: _StringConvertible>(
        in request: inout Request,
        name: String,
        value: [T]?
    ) throws {
        try setQueryItems(
            in: &request,
            style: nil,
            explode: nil,
            name: name,
            values: value,
            convert: convertStringConvertibleToText
        )
    }

    //    | client | set | request query | text | date | both | setQueryItemAsText |
    @available(*, deprecated)
    public func setQueryItemAsText(
        in request: inout Request,
        name: String,
        value: Date?
    ) throws {
        try setUnescapedQueryItem(
            in: &request,
            style: nil,
            explode: nil,
            name: name,
            value: value,
            convert: { value, _, _ in
                try convertDateToText(value)
            }
        )
    }

    //    | client | set | request query | text | array of dates | both | setQueryItemAsText |
    @available(*, deprecated)
    public func setQueryItemAsText(
        in request: inout Request,
        name: String,
        value: [Date]?
    ) throws {
        try setQueryItems(
            in: &request,
            style: nil,
            explode: nil,
            name: name,
            values: value,
            convert: convertDateToText
        )
    }

    //    | server | get | request query | text | string-convertible | optional | getOptionalQueryItemAsText |
    @available(*, deprecated)
    public func getOptionalQueryItemAsText<T: _StringConvertible>(
        in queryParameters: [URLQueryItem],
        name: String,
        as type: T.Type
    ) throws -> T? {
        try getOptionalQueryItem(
            in: queryParameters,
            style: nil,
            explode: nil,
            name: name,
            as: type,
            convert: convertTextToStringConvertible
        )
    }

    //    | server | get | request query | text | string-convertible | required | getRequiredQueryItemAsText |
    @available(*, deprecated)
    public func getRequiredQueryItemAsText<T: _StringConvertible>(
        in queryParameters: [URLQueryItem],
        name: String,
        as type: T.Type
    ) throws -> T {
        try getRequiredQueryItem(
            in: queryParameters,
            style: nil,
            explode: nil,
            name: name,
            as: type,
            convert: convertTextToStringConvertible
        )
    }

    //    | server | get | request query | text | array of string-convertibles | optional | getOptionalQueryItemAsText |
    @available(*, deprecated)
    public func getOptionalQueryItemAsText<T: _StringConvertible>(
        in queryParameters: [URLQueryItem],
        name: String,
        as type: [T].Type
    ) throws -> [T]? {
        try getOptionalQueryItems(
            in: queryParameters,
            style: nil,
            explode: nil,
            name: name,
            as: type,
            convert: convertTextToStringConvertible
        )
    }

    //    | server | get | request query | text | array of string-convertibles | required | getRequiredQueryItemAsText |
    @available(*, deprecated)
    public func getRequiredQueryItemAsText<T: _StringConvertible>(
        in queryParameters: [URLQueryItem],
        name: String,
        as type: [T].Type
    ) throws -> [T] {
        try getRequiredQueryItems(
            in: queryParameters,
            style: nil,
            explode: nil,
            name: name,
            as: type,
            convert: convertTextToStringConvertible
        )
    }

    //    | server | get | request query | text | date | optional | getOptionalQueryItemAsText |
    @available(*, deprecated)
    public func getOptionalQueryItemAsText(
        in queryParameters: [URLQueryItem],
        name: String,
        as type: Date.Type
    ) throws -> Date? {
        try getOptionalQueryItem(
            in: queryParameters,
            style: nil,
            explode: nil,
            name: name,
            as: type,
            convert: convertTextToDate
        )
    }

    //    | server | get | request query | text | date | required | getRequiredQueryItemAsText |
    @available(*, deprecated)
    public func getRequiredQueryItemAsText(
        in queryParameters: [URLQueryItem],
        name: String,
        as type: Date.Type
    ) throws -> Date {
        try getRequiredQueryItem(
            in: queryParameters,
            style: nil,
            explode: nil,
            name: name,
            as: type,
            convert: convertTextToDate
        )
    }

    //    | server | get | request query | text | array of dates | optional | getOptionalQueryItemAsText |
    @available(*, deprecated)
    public func getOptionalQueryItemAsText(
        in queryParameters: [URLQueryItem],
        name: String,
        as type: [Date].Type
    ) throws -> [Date]? {
        try getOptionalQueryItems(
            in: queryParameters,
            style: nil,
            explode: nil,
            name: name,
            as: type,
            convert: convertTextToDate
        )
    }

    //    | server | get | request query | text | array of dates | required | getRequiredQueryItemAsText |
    @available(*, deprecated)
    public func getRequiredQueryItemAsText(
        in queryParameters: [URLQueryItem],
        name: String,
        as type: [Date].Type
    ) throws -> [Date] {
        try getRequiredQueryItems(
            in: queryParameters,
            style: nil,
            explode: nil,
            name: name,
            as: type,
            convert: convertTextToDate
        )
    }

    // MARK: - Deprecated as part of moving to URI coder

    //    | common | set | header field | text | string-convertible | both | setHeaderFieldAsText |
    @available(*, deprecated)
    public func setHeaderFieldAsText<T: _StringConvertible>(
        in headerFields: inout [HeaderField],
        name: String,
        value: T?
    ) throws {
        try setHeaderField(
            in: &headerFields,
            name: name,
            value: value,
            convert: convertStringConvertibleToText
        )
    }

    //    | common | set | header field | text | array of string-convertibles | both | setHeaderFieldAsText |
    @available(*, deprecated)
    public func setHeaderFieldAsText<T: _StringConvertible>(
        in headerFields: inout [HeaderField],
        name: String,
        value values: [T]?
    ) throws {
        try setHeaderFields(
            in: &headerFields,
            name: name,
            values: values,
            convert: convertStringConvertibleToText
        )
    }

    //    | common | set | header field | text | date | both | setHeaderFieldAsText |
    @available(*, deprecated)
    public func setHeaderFieldAsText(
        in headerFields: inout [HeaderField],
        name: String,
        value: Date?
    ) throws {
        try setHeaderField(
            in: &headerFields,
            name: name,
            value: value,
            convert: convertDateToText
        )
    }

    //    | common | set | header field | text | array of dates | both | setHeaderFieldAsText |
    @available(*, deprecated)
    public func setHeaderFieldAsText(
        in headerFields: inout [HeaderField],
        name: String,
        value values: [Date]?
    ) throws {
        try setHeaderFields(
            in: &headerFields,
            name: name,
            values: values,
            convert: convertDateToText
        )
    }

    //    | common | get | header field | text | string-convertible | optional | getOptionalHeaderFieldAsText |
    @available(*, deprecated)
    public func getOptionalHeaderFieldAsText<T: _StringConvertible>(
        in headerFields: [HeaderField],
        name: String,
        as type: T.Type
    ) throws -> T? {
        try getOptionalHeaderField(
            in: headerFields,
            name: name,
            as: type,
            convert: convertTextToStringConvertible
        )
    }

    //    | common | get | header field | text | string-convertible | required | getRequiredHeaderFieldAsText |
    @available(*, deprecated)
    public func getRequiredHeaderFieldAsText<T: _StringConvertible>(
        in headerFields: [HeaderField],
        name: String,
        as type: T.Type
    ) throws -> T {
        try getRequiredHeaderField(
            in: headerFields,
            name: name,
            as: type,
            convert: convertTextToStringConvertible
        )
    }

    //    | common | get | header field | text | array of string-convertibles | optional | getOptionalHeaderFieldAsText |
    @available(*, deprecated)
    public func getOptionalHeaderFieldAsText<T: _StringConvertible>(
        in headerFields: [HeaderField],
        name: String,
        as type: [T].Type
    ) throws -> [T]? {
        try getOptionalHeaderFields(
            in: headerFields,
            name: name,
            as: type,
            convert: convertTextToStringConvertible
        )
    }

    //    | common | get | header field | text | array of string-convertibles | required | getRequiredHeaderFieldAsText |
    @available(*, deprecated)
    public func getRequiredHeaderFieldAsText<T: _StringConvertible>(
        in headerFields: [HeaderField],
        name: String,
        as type: [T].Type
    ) throws -> [T] {
        try getRequiredHeaderFields(
            in: headerFields,
            name: name,
            as: type,
            convert: convertTextToStringConvertible
        )
    }

    //    | common | get | header field | text | date | optional | getOptionalHeaderFieldAsText |
    @available(*, deprecated)
    public func getOptionalHeaderFieldAsText(
        in headerFields: [HeaderField],
        name: String,
        as type: Date.Type
    ) throws -> Date? {
        try getOptionalHeaderField(
            in: headerFields,
            name: name,
            as: type,
            convert: convertHeaderFieldTextToDate
        )
    }

    //    | common | get | header field | text | date | required | getRequiredHeaderFieldAsText |
    @available(*, deprecated)
    public func getRequiredHeaderFieldAsText(
        in headerFields: [HeaderField],
        name: String,
        as type: Date.Type
    ) throws -> Date {
        try getRequiredHeaderField(
            in: headerFields,
            name: name,
            as: type,
            convert: convertHeaderFieldTextToDate
        )
    }

    //    | common | get | header field | text | array of dates | optional | getOptionalHeaderFieldAsText |
    @available(*, deprecated)
    public func getOptionalHeaderFieldAsText(
        in headerFields: [HeaderField],
        name: String,
        as type: [Date].Type
    ) throws -> [Date]? {
        try getOptionalHeaderFields(
            in: headerFields,
            name: name,
            as: type,
            convert: convertHeaderFieldTextToDate
        )
    }

    //    | common | get | header field | text | array of dates | required | getRequiredHeaderFieldAsText |
    @available(*, deprecated)
    public func getRequiredHeaderFieldAsText(
        in headerFields: [HeaderField],
        name: String,
        as type: [Date].Type
    ) throws -> [Date] {
        try getRequiredHeaderFields(
            in: headerFields,
            name: name,
            as: type,
            convert: convertHeaderFieldTextToDate
        )
    }

    //    | client | set | request path | text | string-convertible | required | renderedRequestPath |
    @available(*, deprecated)
    public func renderedRequestPath(
        template: String,
        parameters: [any _StringConvertible]
    ) throws -> String {
        var renderedString = template
        for parameter in parameters {
            if let range = renderedString.range(of: "{}") {
                renderedString = renderedString.replacingOccurrences(
                    of: "{}",
                    with: parameter.description,
                    range: range
                )
            }
        }
        return renderedString
    }

    //    | client | set | request query | text | string-convertible | both | setQueryItemAsText |
    @available(*, deprecated)
    public func setQueryItemAsText<T: _StringConvertible>(
        in request: inout Request,
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        value: T?
    ) throws {
        try setUnescapedQueryItem(
            in: &request,
            style: style,
            explode: explode,
            name: name,
            value: value,
            convert: { value, _, _ in
                try convertStringConvertibleToText(value)
            }
        )
    }

    //    | client | set | request query | text | array of string-convertibles | both | setQueryItemAsText |
    @available(*, deprecated)
    public func setQueryItemAsText<T: _StringConvertible>(
        in request: inout Request,
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        value: [T]?
    ) throws {
        try setQueryItems(
            in: &request,
            style: style,
            explode: explode,
            name: name,
            values: value,
            convert: convertStringConvertibleToText
        )
    }

    //    | client | set | request query | text | date | both | setQueryItemAsText |
    @available(*, deprecated)
    public func setQueryItemAsText(
        in request: inout Request,
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        value: Date?
    ) throws {
        try setUnescapedQueryItem(
            in: &request,
            style: style,
            explode: explode,
            name: name,
            value: value,
            convert: { value, _, _ in
                try convertDateToText(value)
            }
        )
    }

    //    | client | set | request query | text | array of dates | both | setQueryItemAsText |
    @available(*, deprecated)
    public func setQueryItemAsText(
        in request: inout Request,
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        value: [Date]?
    ) throws {
        try setQueryItems(
            in: &request,
            style: style,
            explode: explode,
            name: name,
            values: value,
            convert: convertDateToText
        )
    }

    //    | client | get | response body | text | string-convertible | required | getResponseBodyAsText |
    @available(*, deprecated)
    public func getResponseBodyAsText<T: _StringConvertible, C>(
        _ type: T.Type,
        from data: Data,
        transforming transform: (T) -> C
    ) throws -> C {
        try getResponseBody(
            type,
            from: data,
            transforming: transform,
            convert: convertTextDataToStringConvertible
        )
    }

    //    | client | get | response body | text | date | required | getResponseBodyAsText |
    @available(*, deprecated)
    public func getResponseBodyAsText<C>(
        _ type: Date.Type,
        from data: Data,
        transforming transform: (Date) -> C
    ) throws -> C {
        try getResponseBody(
            type,
            from: data,
            transforming: transform,
            convert: convertTextDataToDate
        )
    }

    //    | client | set | request body | text | string-convertible | optional | setOptionalRequestBodyAsText |
    @available(*, deprecated)
    public func setOptionalRequestBodyAsText<T: _StringConvertible>(
        _ value: T?,
        headerFields: inout [HeaderField],
        contentType: String
    ) throws -> Data? {
        try setOptionalRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertStringConvertibleToTextData
        )
    }

    //    | client | set | request body | text | string-convertible | required | setRequiredRequestBodyAsText |
    @available(*, deprecated)
    public func setRequiredRequestBodyAsText<T: _StringConvertible>(
        _ value: T,
        headerFields: inout [HeaderField],
        contentType: String
    ) throws -> Data {
        try setRequiredRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertStringConvertibleToTextData
        )
    }

    //    | client | set | request body | text | date | optional | setOptionalRequestBodyAsText |
    @available(*, deprecated)
    public func setOptionalRequestBodyAsText(
        _ value: Date?,
        headerFields: inout [HeaderField],
        contentType: String
    ) throws -> Data? {
        try setOptionalRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertDateToTextData
        )
    }

    //    | client | set | request body | text | date | required | setRequiredRequestBodyAsText |
    @available(*, deprecated)
    public func setRequiredRequestBodyAsText(
        _ value: Date,
        headerFields: inout [HeaderField],
        contentType: String
    ) throws -> Data {
        try setRequiredRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertDateToTextData
        )
    }

    @available(*, deprecated)
    func convertStringConvertibleToText<T: _StringConvertible>(
        _ value: T
    ) throws -> String {
        value.description
    }

    @available(*, deprecated)
    func convertStringConvertibleToTextData<T: _StringConvertible>(
        _ value: T
    ) throws -> Data {
        try Data(convertStringConvertibleToText(value).utf8)
    }

    @available(*, deprecated)
    func convertDateToText(_ value: Date) throws -> String {
        try configuration.dateTranscoder.encode(value)
    }

    @available(*, deprecated)
    func convertDateToTextData(_ value: Date) throws -> Data {
        try Data(convertDateToText(value).utf8)
    }

    @available(*, deprecated)
    func convertTextToDate(_ stringValue: String) throws -> Date {
        try configuration.dateTranscoder.decode(stringValue)
    }

    @available(*, deprecated)
    func convertTextDataToDate(_ data: Data) throws -> Date {
        let stringValue = String(decoding: data, as: UTF8.self)
        return try convertTextToDate(stringValue)
    }

    @available(*, deprecated)
    func convertHeaderFieldTextToDate(_ stringValue: String) throws -> Date {
        try convertTextToDate(stringValue)
    }

    @available(*, deprecated)
    func convertTextToStringConvertible<T: _StringConvertible>(
        _ stringValue: String
    ) throws -> T {
        guard let value = T.init(stringValue) else {
            throw RuntimeError.failedToDecodeStringConvertibleValue(
                type: String(describing: T.self)
            )
        }
        return value
    }

    @available(*, deprecated)
    func convertTextDataToStringConvertible<T: _StringConvertible>(
        _ data: Data
    ) throws -> T {
        let stringValue = String(decoding: data, as: UTF8.self)
        return try convertTextToStringConvertible(stringValue)
    }

    @available(*, deprecated)
    func setHeaderFields<T>(
        in headerFields: inout [HeaderField],
        name: String,
        values: [T]?,
        convert: (T) throws -> String
    ) throws {
        guard let values else {
            return
        }
        for value in values {
            headerFields.add(
                name: name,
                value: try convert(value)
            )
        }
    }

    @available(*, deprecated)
    func getOptionalHeaderFields<T>(
        in headerFields: [HeaderField],
        name: String,
        as type: [T].Type,
        convert: (String) throws -> T
    ) throws -> [T]? {
        let values = headerFields.values(name: name)
        if values.isEmpty {
            return nil
        }
        return try values.map { value in try convert(value) }
    }

    @available(*, deprecated)
    func getRequiredHeaderFields<T>(
        in headerFields: [HeaderField],
        name: String,
        as type: [T].Type,
        convert: (String) throws -> T
    ) throws -> [T] {
        let values = headerFields.values(name: name)
        if values.isEmpty {
            throw RuntimeError.missingRequiredHeaderField(name)
        }
        return try values.map { value in try convert(value) }
    }

    @available(*, deprecated)
    func setQueryItems<T>(
        in request: inout Request,
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        values: [T]?,
        convert: (T) throws -> String
    ) throws {
        guard let values else {
            return
        }
        let (_, resolvedExplode) = try ParameterStyle.resolvedQueryStyleAndExplode(
            name: name,
            style: style,
            explode: explode
        )
        for value in values {
            request.addUnescapedQueryItem(
                name: name,
                value: try convert(value),
                explode: resolvedExplode
            )
        }
    }

    @available(*, deprecated)
    func getOptionalQueryItems<T>(
        in queryParameters: [URLQueryItem],
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        as type: [T].Type,
        convert: (String) throws -> T
    ) throws -> [T]? {
        let (_, resolvedExplode) = try ParameterStyle.resolvedQueryStyleAndExplode(
            name: name,
            style: style,
            explode: explode
        )
        let untypedValues =
            queryParameters
            .filter { $0.name == name }
            .map { $0.value ?? "" }
        // If explode is false, some of the items might have multiple
        // comma-separate values, so we need to split them here.
        let processedValues: [String]
        if resolvedExplode {
            processedValues = untypedValues
        } else {
            processedValues = untypedValues.flatMap { multiValue in
                multiValue
                    .split(separator: ",", omittingEmptySubsequences: false)
                    .map(String.init)
            }
        }
        return try processedValues.map(convert)
    }

    @available(*, deprecated)
    func getRequiredQueryItems<T>(
        in queryParameters: [URLQueryItem],
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        as type: [T].Type,
        convert: (String) throws -> T
    ) throws -> [T] {
        guard
            let values = try getOptionalQueryItems(
                in: queryParameters,
                style: style,
                explode: explode,
                name: name,
                as: type,
                convert: convert
            ), !values.isEmpty
        else {
            throw RuntimeError.missingRequiredQueryParameter(name)
        }
        return values
    }

    @available(*, deprecated)
    func setUnescapedQueryItem<T>(
        in request: inout Request,
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        value: T?,
        convert: (T, ParameterStyle, Bool) throws -> String
    ) throws {
        guard let value else {
            return
        }
        let (resolvedStyle, resolvedExplode) = try ParameterStyle.resolvedQueryStyleAndExplode(
            name: name,
            style: style,
            explode: explode
        )
        request.addUnescapedQueryItem(
            name: name,
            value: try convert(value, resolvedStyle, resolvedExplode),
            explode: resolvedExplode
        )
    }
}

extension Request {
    /// Adds the provided name and value to the URL's query.
    /// - Parameters:
    ///   - name: The name of the query item.
    ///   - value: The value of the query item.
    ///   - explode: A Boolean value indicating whether query items with the
    ///   same name should be provided as separate key-value pairs (`true`) or
    ///   if all the values for one key should be concatenated with a comma
    ///   and provided as a single key-value pair (`false`).
    @available(*, deprecated)
    mutating func addUnescapedQueryItem(name: String, value: String, explode: Bool) {
        mutateQuery { urlComponents in
            urlComponents.addUnescapedStringQueryItem(
                name: name,
                value: value,
                explode: explode
            )
        }
    }
}

extension URLComponents {

    /// Adds the provided name and value to the URL's query.
    /// - Parameters:
    ///   - name: The name of the query item.
    ///   - value: The value of the query item.
    ///   - explode: A Boolean value indicating whether query items with the
    ///   same name should be provided as separate key-value pairs (`true`) or
    ///   if all the values for one key should be concatenated with a comma
    ///   and provided as a single key-value pair (`false`).
    @available(*, deprecated)
    mutating func addUnescapedStringQueryItem(
        name: String,
        value: String,
        explode: Bool
    ) {
        if explode {
            queryItems =
                (queryItems ?? []) + [
                    .init(name: name, value: value)
                ]
            return
        }
        // When explode is false, we need to collect all the potential existing
        // values from the array with the same name, add the new one, and
        // concatenate them with a comma.
        let originalQueryItems = queryItems ?? []
        struct GroupedQueryItems {
            var matchingValues: [String] = []
            var otherItems: [URLQueryItem] = []
        }
        let groups =
            originalQueryItems
            .reduce(into: GroupedQueryItems()) { partialResult, item in
                if item.name == name {
                    partialResult.matchingValues.append(item.value ?? "")
                } else {
                    partialResult.otherItems.append(item)
                }
            }
        let newItem = URLQueryItem(
            name: name,
            value: (groups.matchingValues + [value]).joined(separator: ",")
        )
        queryItems = groups.otherItems + [newItem]
    }
}
