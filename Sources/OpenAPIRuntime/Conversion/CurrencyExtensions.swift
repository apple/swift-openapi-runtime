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

extension HeaderField: CustomStringConvertible {
    public var description: String {
        let value: String
        if HeaderField.internalRedactedHeaderFields.contains(name.lowercased()) {
            value = "<redacted>"
        } else {
            value = self.value
        }
        return "\(name): \(value)"
    }
}

extension Request: CustomStringConvertible {
    public var description: String {
        "path: \(path), query: \(query ?? "<nil>"), method: \(method), header fields: \(headerFields.description), body (prefix): \(body?.prettyPrefix ?? "<nil>")"
    }
}

extension Response: CustomStringConvertible {
    public var description: String {
        "status: \(statusCode), header fields: \(headerFields.description), body: \(body.prettyPrefix)"
    }
}

extension ServerRequestMetadata: CustomStringConvertible {
    public var description: String {
        "path parameters: \(pathParameters.description), query parameters: \(queryParameters.description)"
    }
}

extension Array where Element == HeaderField {

    /// Adds a header for the provided name and value.
    /// - Parameters:
    ///   - name: Header name.
    ///   - value: Header value. If nil, the header is not added.
    mutating func add(name: String, value: String?) {
        guard let value = value else {
            return
        }
        append(.init(name: name, value: value))
    }

    /// Adds headers for the provided name and values.
    /// - Parameters:
    ///   - name: Header name.
    ///   - value: Header values.
    mutating func add(name: String, values: [String]?) {
        guard let values = values else {
            return
        }
        for value in values {
            append(.init(name: name, value: value))
        }
    }

    /// Removes all headers matching the provided (case-insensitive) name.
    /// - Parameters:
    ///   - name: Header name.
    mutating func removeAll(named name: String) {
        removeAll {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    /// Returns the first header value for the provided (case-insensitive) name.
    /// - Parameter name: Header name.
    /// - Returns: First value for the given name. Nil if one does not exist.
    func firstValue(name: String) -> String? {
        first { $0.name.caseInsensitiveCompare(name) == .orderedSame }?.value
    }

    /// Returns all header values for the given (case-insensitive) name.
    /// - Parameter name: Header name.
    /// - Returns: All values for the given name, might be empty if none are found.
    func values(name: String) -> [String] {
        filter { $0.name.caseInsensitiveCompare(name) == .orderedSame }.map { $0.value }
    }
}

extension ParameterStyle {

    /// Returns the parameter style and explode parameter that should be used
    /// based on the provided inputs, taking defaults into considerations.
    /// - Parameters:
    ///   - style: The provided parameter style, if any.
    ///   - explode: The provided explode value, if any.
    /// - Throws: For an unsupported input combination.
    static func resolvedQueryStyleAndExplode(
        name: String,
        style: ParameterStyle?,
        explode: Bool?
    ) throws -> (ParameterStyle, Bool) {
        let resolvedStyle = style ?? .defaultForQueryItems
        let resolvedExplode = explode ?? ParameterStyle.defaultExplodeFor(forStyle: resolvedStyle)
        guard resolvedStyle == .form else {
            throw RuntimeError.unsupportedParameterStyle(
                name: name,
                location: .query,
                style: resolvedStyle,
                explode: resolvedExplode
            )
        }
        return (resolvedStyle, resolvedExplode)
    }
}

extension Converter {

    // MARK: Common functions for Converter's SPI helper methods

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

    func uriCoderConfiguration(
        style: ParameterStyle,
        explode: Bool,
        inBody: Bool
    ) -> URICoderConfiguration {
        let configStyle: URICoderConfiguration.Style
        switch style {
        case .form:
            configStyle = .form
        case .simple:
            configStyle = .simple
        }
        return .init(
            style: configStyle,
            explode: explode,
            spaceEscapingCharacter: inBody ? .plus : .percentEncoded
        )
    }

    func convertToURI<T: Encodable>(
        style: ParameterStyle,
        explode: Bool,
        inBody: Bool,
        key: String,
        value: T
    ) throws -> String {
        let encoder = URIEncoder(
            configuration: uriCoderConfiguration(
                style: style,
                explode: explode,
                inBody: inBody
            )
        )
        let encodedString = try encoder.encode(value, forKey: key)
        return encodedString
    }

    func convertDateToText(_ value: Date) throws -> String {
        try configuration.dateTranscoder.encode(value)
    }

    func convertDateToTextData(_ value: Date) throws -> Data {
        try Data(convertDateToText(value).utf8)
    }

    func convertTextToDate(_ stringValue: String) throws -> Date {
        try configuration.dateTranscoder.decode(stringValue)
    }

    func convertTextDataToDate(_ data: Data) throws -> Date {
        let stringValue = String(decoding: data, as: UTF8.self)
        return try convertTextToDate(stringValue)
    }

    func convertJSONToCodable<T: Decodable>(
        _ data: Data
    ) throws -> T {
        try decoder.decode(T.self, from: data)
    }

    func convertBodyCodableToJSON<T: Encodable>(
        _ value: T
    ) throws -> Data {
        try encoder.encode(value)
    }

    func convertHeaderFieldTextToDate(_ stringValue: String) throws -> Date {
        try convertTextToDate(stringValue)
    }

    func convertHeaderFieldCodableToJSON<T: Encodable>(
        _ value: T
    ) throws -> String {
        let data = try headerFieldEncoder.encode(value)
        let stringValue = String(decoding: data, as: UTF8.self)
        return stringValue
    }

    func convertHeaderFieldJSONToCodable<T: Decodable>(
        _ stringValue: String
    ) throws -> T {
        let data = Data(stringValue.utf8)
        return try decoder.decode(T.self, from: data)
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

    func convertFromURI<T: Decodable>(
        style: ParameterStyle,
        explode: Bool,
        inBody: Bool,
        key: String,
        encodedValue: String
    ) throws -> T {
        let decoder = URIDecoder(
            configuration: uriCoderConfiguration(
                style: style,
                explode: explode,
                inBody: inBody
            )
        )
        let value = try decoder.decode(
            T.self,
            forKey: key,
            from: encodedValue
        )
        return value
    }

    @available(*, deprecated)
    func convertTextDataToStringConvertible<T: _StringConvertible>(
        _ data: Data
    ) throws -> T {
        let stringValue = String(decoding: data, as: UTF8.self)
        return try convertTextToStringConvertible(stringValue)
    }

    func setHeaderField<T>(
        in headerFields: inout [HeaderField],
        name: String,
        value: T?,
        convert: (T) throws -> String
    ) throws {
        guard let value else {
            return
        }
        headerFields.add(
            name: name,
            value: try convert(value)
        )
    }

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

    func getOptionalHeaderField<T>(
        in headerFields: [HeaderField],
        name: String,
        as type: T.Type,
        convert: (String) throws -> T
    ) throws -> T? {
        guard let stringValue = headerFields.firstValue(name: name) else {
            return nil
        }
        return try convert(stringValue)
    }

    func getRequiredHeaderField<T>(
        in headerFields: [HeaderField],
        name: String,
        as type: T.Type,
        convert: (String) throws -> T
    ) throws -> T {
        guard let stringValue = headerFields.firstValue(name: name) else {
            throw RuntimeError.missingRequiredHeaderField(name)
        }
        return try convert(stringValue)
    }

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

    func setQueryItem<T>(
        in request: inout Request,
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        value: T?,
        convert: (T) throws -> String
    ) throws {
        guard let value else {
            return
        }
        let (_, resolvedExplode) = try ParameterStyle.resolvedQueryStyleAndExplode(
            name: name,
            style: style,
            explode: explode
        )
        request.addQueryItem(
            name: name,
            value: try convert(value),
            explode: resolvedExplode
        )
    }

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
            request.addQueryItem(
                name: name,
                value: try convert(value),
                explode: resolvedExplode
            )
        }
    }

    func getOptionalQueryItem<T>(
        in queryParameters: [URLQueryItem],
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        as type: T.Type,
        convert: (String) throws -> T
    ) throws -> T? {
        // Even though the return value isn't used, the validation
        // in the method is important for consistently handling
        // style+explode combinations in all the helper functions.
        let (_, _) = try ParameterStyle.resolvedQueryStyleAndExplode(
            name: name,
            style: style,
            explode: explode
        )
        guard
            let untypedValue =
                queryParameters
                .first(where: { $0.name == name })
        else {
            return nil
        }
        return try convert(untypedValue.value ?? "")
    }

    func getRequiredQueryItem<T>(
        in queryParameters: [URLQueryItem],
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        as type: T.Type,
        convert: (String) throws -> T
    ) throws -> T {
        guard
            let value = try getOptionalQueryItem(
                in: queryParameters,
                style: style,
                explode: explode,
                name: name,
                as: type,
                convert: convert
            )
        else {
            throw RuntimeError.missingRequiredQueryParameter(name)
        }
        return value
    }

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

    func setRequiredRequestBody<T>(
        _ value: T,
        headerFields: inout [HeaderField],
        contentType: String,
        convert: (T) throws -> Data
    ) throws -> Data {
        headerFields.add(name: "content-type", value: contentType)
        return try convert(value)
    }

    func setOptionalRequestBody<T>(
        _ value: T?,
        headerFields: inout [HeaderField],
        contentType: String,
        convert: (T) throws -> Data
    ) throws -> Data? {
        guard let value else {
            return nil
        }
        return try setRequiredRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convert
        )
    }

    func getOptionalRequestBody<T, C>(
        _ type: T.Type,
        from data: Data?,
        transforming transform: (T) -> C,
        convert: (Data) throws -> T
    ) throws -> C? {
        guard let data else {
            return nil
        }
        let decoded = try convert(data)
        return transform(decoded)
    }

    func getRequiredRequestBody<T, C>(
        _ type: T.Type,
        from data: Data?,
        transforming transform: (T) -> C,
        convert: (Data) throws -> T
    ) throws -> C {
        guard
            let body = try getOptionalRequestBody(
                type,
                from: data,
                transforming: transform,
                convert: convert
            )
        else {
            throw RuntimeError.missingRequiredRequestBody
        }
        return body
    }

    func getResponseBody<T, C>(
        _ type: T.Type,
        from data: Data,
        transforming transform: (T) -> C,
        convert: (Data) throws -> T
    ) throws -> C {
        let parsedValue = try convert(data)
        let transformedValue = transform(parsedValue)
        return transformedValue
    }

    func setResponseBody<T>(
        _ value: T,
        headerFields: inout [HeaderField],
        contentType: String,
        convert: (T) throws -> Data
    ) throws -> Data {
        headerFields.add(name: "content-type", value: contentType)
        return try convert(value)
    }

    func convertBinaryToData(
        _ binary: Data
    ) throws -> Data {
        binary
    }

    func convertDataToBinary(
        _ data: Data
    ) throws -> Data {
        data
    }

    func getRequiredRequestPath<T>(
        in pathParameters: [String: String],
        name: String,
        as type: T.Type,
        convert: (String) throws -> T
    ) throws -> T {
        guard let untypedValue = pathParameters[name] else {
            throw RuntimeError.missingRequiredPathParameter(name)
        }
        return try convert(untypedValue)
    }
}
