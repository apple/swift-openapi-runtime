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
import HTTPTypes

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

extension HTTPField.Name {

    // TODO: Docs
    init(validated name: String) throws {
        guard let fieldName = Self.init(name) else {
            throw RuntimeError.invalidHeaderFieldName(name)
        }
        self = fieldName
    }
}

extension HTTPRequest {

    // TODO: Docs
    var requiredPath: Substring {
        get throws {
            guard let path else {
                throw RuntimeError.pathUnset
            }
            return path[...]
        }
    }
}

extension HTTPRequest {
    
    @_spi(Generated)
    public init(path: String, method: Method) {
        self.init(method: method, scheme: nil, authority: nil, path: path)
    }
    
    @_spi(Generated)
    public var query: Substring? {
        guard let path else {
            return nil
        }
        guard let queryStart = path.firstIndex(of: "?") else {
            return nil
        }
        let queryEnd = path.firstIndex(of: "#") ?? path.endIndex
        let query = path[path.index(after: queryStart) ..< queryEnd]
        return query
    }
}

extension HTTPResponse {
    
    @_spi(Generated)
    public init(statusCode: Int) {
        self.init(status: .init(code: statusCode))
    }
}

extension Converter {

    // MARK: Converter helpers

    func uriCoderConfiguration(
        style: ParameterStyle,
        explode: Bool,
        inBody: Bool
    ) -> URICoderConfiguration {
        .init(
            style: .init(style),
            explode: explode,
            spaceEscapingCharacter: inBody ? .plus : .percentEncoded,
            dateTranscoder: configuration.dateTranscoder
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

    func convertFromURI<T: Decodable>(
        style: ParameterStyle,
        explode: Bool,
        inBody: Bool,
        key: String,
        encodedValue: some StringProtocol
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
            from: Substring(encodedValue)
        )
        return value
    }

    func convertJSONToBodyCodable<T: Decodable>(
        _ body: HTTPBody
    ) async throws -> T {
        let data = try await body.collectAsData(upTo: .max)
        return try decoder.decode(T.self, from: data)
    }

    func convertBodyCodableToJSON<T: Encodable>(
        _ value: T
    ) throws -> HTTPBody {
        let data = try encoder.encode(value)
        return HTTPBody(data: data)
    }

    func convertHeaderFieldCodableToJSON<T: Encodable>(
        _ value: T
    ) throws -> String {
        let data = try headerFieldEncoder.encode(value)
        let stringValue = String(decoding: data, as: UTF8.self)
        return stringValue
    }

    func convertJSONToHeaderFieldCodable<T: Decodable>(
        _ stringValue: String
    ) throws -> T {
        let data = Data(stringValue.utf8)
        return try decoder.decode(T.self, from: data)
    }

    func convertFromStringData<T: Decodable>(
        _ body: HTTPBody
    ) async throws -> T {
        let data = try await body.collect(upTo: .max)
        let encodedString = String(decoding: data, as: UTF8.self)
        let decoder = StringDecoder(
            dateTranscoder: configuration.dateTranscoder
        )
        let value = try decoder.decode(
            T.self,
            from: encodedString
        )
        return value
    }

    func convertToStringData<T: Encodable>(
        _ value: T
    ) throws -> HTTPBody {
        let encoder = StringEncoder(
            dateTranscoder: configuration.dateTranscoder
        )
        let encodedString = try encoder.encode(value)
        return HTTPBody(data: Array(encodedString.utf8))
    }

    func convertBinaryToData(
        _ binary: HTTPBody
    ) throws -> HTTPBody {
        binary
    }

    func convertDataToBinary(
        _ data: HTTPBody
    ) throws -> HTTPBody {
        data
    }

    // MARK: - Helpers for specific types of parameters

    func setHeaderField<T>(
        in headerFields: inout HTTPFields,
        name: String,
        value: T?,
        convert: (T) throws -> String
    ) throws {
        guard let value else {
            return
        }
        try headerFields.append(
            .init(
                name: .init(validated: name),
                value: convert(value)
            )
        )
    }

    func getHeaderFieldValuesString(
        in headerFields: HTTPFields,
        name: String
    ) throws -> String? {
        try headerFields[.init(validated: name)]
    }

    func getOptionalHeaderField<T>(
        in headerFields: HTTPFields,
        name: String,
        as type: T.Type,
        convert: (String) throws -> T
    ) throws -> T? {
        guard
            let stringValue = try getHeaderFieldValuesString(
                in: headerFields,
                name: name
            )
        else {
            return nil
        }
        return try convert(stringValue)
    }

    func getRequiredHeaderField<T>(
        in headerFields: HTTPFields,
        name: String,
        as type: T.Type,
        convert: (String) throws -> T
    ) throws -> T {
        guard
            let stringValue = try getHeaderFieldValuesString(
                in: headerFields,
                name: name
            )
        else {
            throw RuntimeError.missingRequiredHeaderField(name)
        }
        return try convert(stringValue)
    }

    func setEscapedQueryItem<T>(
        in request: inout HTTPRequest,
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
        let escapedUriSnippet = try convert(value, resolvedStyle, resolvedExplode)

        let pathAndAll = try request.requiredPath

        // https://datatracker.ietf.org/doc/html/rfc3986#section-3.4
        // > The query component is indicated by the first question
        // > mark ("?") character and terminated by a number sign ("#")
        // > character or by the end of the URI.

        let fragmentStart = pathAndAll.firstIndex(of: "#") ?? pathAndAll.endIndex
        let fragment = pathAndAll[fragmentStart..<pathAndAll.endIndex]

        let queryStart = pathAndAll.firstIndex(of: "?")

        let pathEnd = queryStart ?? fragmentStart
        let path = pathAndAll[pathAndAll.startIndex..<pathEnd]

        guard let queryStart else {
            // No existing query substring, add the question mark.
            request.path = path.appending("?\(escapedUriSnippet)\(fragment)")
            return
        }

        let query = pathAndAll[pathAndAll.index(after: queryStart)..<fragmentStart]
        request.path = path.appending("?\(query)&\(escapedUriSnippet)\(fragment)")
    }

    func getOptionalQueryItem<T>(
        in query: Substring?,
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        as type: T.Type,
        convert: (Substring, ParameterStyle, Bool) throws -> T
    ) throws -> T? {
        guard let query else {
            return nil
        }
        let (resolvedStyle, resolvedExplode) = try ParameterStyle.resolvedQueryStyleAndExplode(
            name: name,
            style: style,
            explode: explode
        )
        return try convert(query, resolvedStyle, resolvedExplode)
    }

    func getRequiredQueryItem<T>(
        in query: Substring?,
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        as type: T.Type,
        convert: (Substring, ParameterStyle, Bool) throws -> T
    ) throws -> T {
        guard
            let value = try getOptionalQueryItem(
                in: query,
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

    func setRequiredRequestBody<T>(
        _ value: T,
        headerFields: inout HTTPFields,
        contentType: String,
        convert: (T) throws -> HTTPBody
    ) throws -> HTTPBody {
        headerFields[.contentType] = contentType
        return try convert(value)
    }

    func setOptionalRequestBody<T>(
        _ value: T?,
        headerFields: inout HTTPFields,
        contentType: String,
        convert: (T) throws -> HTTPBody
    ) throws -> HTTPBody? {
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

    func getOptionalBufferingRequestBody<T, C>(
        _ type: T.Type,
        from data: HTTPBody?,
        transforming transform: (T) -> C,
        convert: (HTTPBody) async throws -> T
    ) async throws -> C? {
        guard let data else {
            return nil
        }
        let decoded = try await convert(data)
        return transform(decoded)
    }

    func getOptionalRequestBody<T, C>(
        _ type: T.Type,
        from data: HTTPBody?,
        transforming transform: (T) -> C,
        convert: (HTTPBody) throws -> T
    ) throws -> C? {
        guard let data else {
            return nil
        }
        let decoded = try convert(data)
        return transform(decoded)
    }

    func getRequiredBufferingRequestBody<T, C>(
        _ type: T.Type,
        from data: HTTPBody?,
        transforming transform: (T) -> C,
        convert: (HTTPBody) async throws -> T
    ) async throws -> C {
        guard
            let body = try await getOptionalBufferingRequestBody(
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

    func getRequiredRequestBody<T, C>(
        _ type: T.Type,
        from data: HTTPBody?,
        transforming transform: (T) -> C,
        convert: (HTTPBody) throws -> T
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

    func getBufferingResponseBody<T, C>(
        _ type: T.Type,
        from data: HTTPBody,
        transforming transform: (T) -> C,
        convert: (HTTPBody) async throws -> T
    ) async throws -> C {
        let parsedValue = try await convert(data)
        let transformedValue = transform(parsedValue)
        return transformedValue
    }

    func getResponseBody<T, C>(
        _ type: T.Type,
        from data: HTTPBody,
        transforming transform: (T) -> C,
        convert: (HTTPBody) throws -> T
    ) throws -> C {
        let parsedValue = try convert(data)
        let transformedValue = transform(parsedValue)
        return transformedValue
    }

    func setResponseBody<T>(
        _ value: T,
        headerFields: inout HTTPFields,
        contentType: String,
        convert: (T) throws -> HTTPBody
    ) throws -> HTTPBody {
        headerFields[.contentType] = contentType
        return try convert(value)
    }

    func getRequiredRequestPath<T>(
        in pathParameters: [String: Substring],
        name: String,
        as type: T.Type,
        convert: (Substring) throws -> T
    ) throws -> T {
        guard let untypedValue = pathParameters[name] else {
            throw RuntimeError.missingRequiredPathParameter(name)
        }
        return try convert(untypedValue)
    }
}
