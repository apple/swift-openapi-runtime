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

public extension Converter {

    // MARK: Miscs

    /// Validates that the Accept header in the provided response
    /// is compatible with the provided content type substring.
    /// - Parameters:
    ///   - substring: Expected content type, for example "application/json".
    ///   - headerFields: Header fields in which to look for "Accept".
    ///   Also supports wildcars, such as "application/\*" and "\*/\*".
    func validateAcceptIfPresent(
        _ substring: String,
        in headerFields: [HeaderField]
    ) throws {
        // for example: text/html, application/xhtml+xml, application/xml;q=0.9, */*;q=0.8
        let acceptHeader = headerFields.values(name: "accept").joined(separator: ", ")

        // Split with commas to get the individual values
        let acceptValues =
            acceptHeader
            .split(separator: ",")
            .map { value in
                // Drop everything after the optional semicolon (q, extensions, ...)
                value
                    .split(separator: ";")[0]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
            }

        if acceptValues.isEmpty {
            return
        }
        if acceptValues.contains("*/*") {
            return
        }
        if acceptValues.contains("\(substring.split(separator: "/")[0].lowercased())/*") {
            return
        }
        if acceptValues.contains(where: { $0.localizedCaseInsensitiveContains(substring) }) {
            return
        }
        throw RuntimeError.unexpectedAcceptHeader(acceptHeader)
    }

    // MARK: Path

    /// Returns a deserialized value for the optional path variable name.
    /// - Parameters:
    ///   - pathParameters: Path parameters where the value might exist.
    ///   - name: Path variable name.
    ///   - type: Path variable type.
    /// - Returns: Deserialized path variable value, if present.
    func pathGetOptional<T: _StringParameterConvertible>(
        in pathParameters: [String: String],
        name: String,
        as type: T.Type
    ) throws -> T? {
        guard let untypedValue = pathParameters[name] else {
            return nil
        }
        guard let typedValue = T(untypedValue) else {
            throw RuntimeError.failedToDecodePathParameter(name: name, type: String(describing: T.self))
        }
        return typedValue
    }

    /// Returns a deserialized value for the required path variable name.
    /// - Parameters:
    ///   - pathParameters: Path parameters where the value must exist.
    ///   - name: Path variable name.
    ///   - type: Path variable type.
    /// - Returns: Deserialized path variable value.
    func pathGetRequired<T: _StringParameterConvertible>(
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

    // MARK: Query - LosslessStringConvertible

    /// Returns a deserialized value for the the first query item
    /// found under the provided name.
    /// - Parameters:
    ///   - queryParameters: Query parameters container where the value might exist.
    ///   - name: Query item name.
    ///   - type: Query item value type.
    /// - Returns: Deserialized query item value, if present.
    func queryGetOptional<T: _StringParameterConvertible>(
        in queryParameters: [URLQueryItem],
        name: String,
        as type: T.Type
    ) throws -> T? {
        guard let untypedValue = queryParameters.first(where: { $0.name == name })?.value else {
            return nil
        }
        guard let typedValue = T(untypedValue) else {
            throw RuntimeError.failedToDecodeQueryParameter(
                name: name,
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
    func queryGetRequired<T: _StringParameterConvertible>(
        in queryParameters: [URLQueryItem],
        name: String,
        as type: T.Type
    ) throws -> T {
        guard let untypedValue = queryParameters.first(where: { $0.name == name })?.value else {
            throw RuntimeError.missingRequiredQueryParameter(name)
        }
        guard let typedValue = T(untypedValue) else {
            throw RuntimeError.failedToDecodeQueryParameter(name: name, type: String(describing: T.self))
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
    func queryGetOptional(
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
    func queryGetRequired(
        in queryParameters: [URLQueryItem],
        name: String,
        as type: Date.Type
    ) throws -> Date {
        guard let dateString = queryParameters.first(where: { $0.name == name })?.value else {
            throw RuntimeError.missingRequiredQueryParameter(name)
        }
        return try self.configuration.dateTranscoder.decode(dateString)
    }

    // MARK: Query - Array of _StringParameterConvertible

    /// Returns an array of deserialized values for all the query items
    /// found under the provided name.
    /// - Parameters:
    ///   - queryParameters: Query parameters container where the value might exist.
    ///   - name: Query item name.
    ///   - type: Query item value type.
    /// - Returns: Deserialized query item value, if present.
    func queryGetOptional<T: _StringParameterConvertible>(
        in queryParameters: [URLQueryItem],
        name: String,
        as type: [T].Type
    ) throws -> [T]? {
        let items: [T] =
            try queryParameters
            .filter { $0.name == name }
            .compactMap { item in
                guard let typedValue = T(item.value ?? "") else {
                    throw RuntimeError.failedToDecodeQueryParameter(
                        name: name,
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
    func queryGetRequired<T: _StringParameterConvertible>(
        in queryParameters: [URLQueryItem],
        name: String,
        as type: [T].Type
    ) throws -> [T] {
        let items: [T] =
            try queryParameters
            .filter { $0.name == name }
            .map { item in
                guard let typedValue = T(item.value ?? "") else {
                    throw RuntimeError.failedToDecodeQueryParameter(name: name, type: String(describing: T.self))
                }
                return typedValue
            }
        guard !items.isEmpty else {
            throw RuntimeError.missingRequiredQueryParameter(name)
        }
        return items
    }

    // MARK: Body - Complex

    /// Gets a deserialized value from body data, if present.
    /// - Parameters:
    ///   - type: Type used to decode the data.
    ///   - data: Encoded body data.
    ///   - transform: Closure for transforming the Decodable type into a final type.
    /// - Returns: Deserialized body value, if present.
    func bodyGetOptional<T: Decodable, C>(
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
    func bodyGetRequired<T: Decodable, C>(
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

    /// Provides a serialized value for the provided body value.
    /// - Parameters:
    ///   - value: Encodable value to turn into data.
    ///   - headerFields: Header fields container where to add the Content-Type header.
    ///   - transform: Closure for transforming the Encodable value into body content.
    /// - Returns: Data for the serialized body value.
    func bodyAdd<T: Encodable, C>(
        _ value: C,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<T>
    ) throws -> Data {
        let body = transform(value)
        headerFields.add(name: "content-type", value: body.contentType)
        return try encoder.encode(body.value)
    }

    // MARK: Body - Data

    /// Gets a deserialized value from body data, if present.
    /// - Parameters:
    ///   - type: Type used to decode the data.
    ///   - data: Encoded body data.
    ///   - transform: Closure for transforming the Decodable type into a final type.
    /// - Returns: Deserialized body value, if present.
    func bodyGetOptional<C>(
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
    func bodyGetRequired<C>(
        _ type: Data.Type,
        from data: Data?,
        transforming transform: (Data) -> C
    ) throws -> C {
        guard let data else {
            throw RuntimeError.missingRequiredRequestBody
        }
        return transform(data)
    }

    /// Provides a serialized value for the provided body value.
    /// - Parameters:
    ///   - value: Encodable value to turn into data.
    ///   - headers: Headers container where to add the Content-Type header.
    ///   - transform: Closure for transforming the Encodable value into body content.
    /// - Returns: Data for the serialized body value.
    func bodyAdd<C>(
        _ value: C,
        headerFields: inout [HeaderField],
        transforming transform: (C) -> EncodableBodyContent<Data>
    ) throws -> Data {
        let body = transform(value)
        headerFields.add(name: "content-type", value: body.contentType)
        return body.value
    }
}
