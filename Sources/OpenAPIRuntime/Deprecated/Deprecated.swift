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

extension Converter {
    /// Gets a deserialized value from body data.
    /// - Parameters:
    ///   - type: Type used to decode the data.
    ///   - data: Encoded body data.
    ///   - transform: Closure for transforming the Decodable type into a final type.
    /// - Returns: Deserialized body value.
    @available(*, deprecated, renamed: "bodyGet(_:from:strategy:transforming:)")
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
    @available(*, deprecated, renamed: "bodyGet(_:from:strategy:transforming:)")
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
    @available(*, deprecated, renamed: "bodyGetOptional(_:from:strategy:transforming:)")
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
    @available(*, deprecated, renamed: "bodyGetRequired(_:from:strategy:transforming:)")
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
    @available(*, deprecated, renamed: "bodyGetOptional(_:from:strategy:transforming:)")
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
    @available(*, deprecated, renamed: "bodyGetRequired(_:from:strategy:transforming:)")
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
    @available(*, deprecated, renamed: "headerFieldAdd(in:strategy:name:value:)")
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
    @available(*, deprecated, renamed: "headerFieldGetOptional(in:strategy:name:as:)")
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
    @available(*, deprecated, renamed: "headerFieldGetRequired(in:strategy:name:as:)")
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
            throw RuntimeError.missingRequiredHeader(name)
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
    @available(*, deprecated, renamed: "headerFieldAdd(in:strategy:name:value:)")
    public func headerFieldAdd<T: Encodable>(
        in headerFields: inout [HeaderField],
        name: String,
        value: T?
    ) throws {
        guard let value else {
            return
        }
        if let value = value as? _StringParameterConvertible {
            headerFields.add(name: name, value: value.description)
            return
        }
        let data = try headerFieldEncoder.encode(value)
        guard let stringValue = String(data: data, encoding: .utf8) else {
            throw RuntimeError.failedToEncodeJSONHeaderIntoString(name: name)
        }
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
    @available(*, deprecated, renamed: "headerFieldGetOptional(in:strategy:name:as:)")
    public func headerFieldGetOptional<T: Decodable>(
        in headerFields: [HeaderField],
        name: String,
        as type: T.Type
    ) throws -> T? {
        guard let stringValue = headerFields.firstValue(name: name) else {
            return nil
        }
        if let myType = T.self as? _StringParameterConvertible.Type {
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
    @available(*, deprecated, renamed: "headerFieldGetRequired(in:strategy:name:as:)")
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
            throw RuntimeError.missingRequiredHeader(name)
        }
        return value
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
    func bodyAdd<T: Encodable, C>(
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
    func bodyAdd<C>(
        _ value: C,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> LegacyEncodableBodyContent<Data>
    ) throws -> Data {
        let body = transform(value)
        headerFields.add(name: "content-type", value: body.contentType)
        return body.value
    }
}
