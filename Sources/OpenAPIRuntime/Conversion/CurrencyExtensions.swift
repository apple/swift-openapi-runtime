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
    ///   - name: The name of the query item for which to resolve the inputs.
    ///   - style: The provided parameter style, if any.
    ///   - explode: The provided explode value, if any.
    /// - Throws: For an unsupported input combination.
    /// - Returns: A tuple of the style and explode values.
    static func resolvedQueryStyleAndExplode(name: String, style: ParameterStyle?, explode: Bool?) throws -> (
        ParameterStyle, Bool
    ) {
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

    /// Creates a new name for the provided string.
    /// - Parameter name: A field name.
    /// - Throws: If the name isn't a valid field name.
    init(validated name: String) throws {
        guard let fieldName = Self(name) else { throw RuntimeError.invalidHeaderFieldName(name) }
        self = fieldName
    }
}

extension HTTPRequest {

    /// Returns the path of the request, and throws an error if it's nil.
    var requiredPath: Substring {
        get throws {
            guard let path else { throw RuntimeError.pathUnset }
            return path[...]
        }
    }
}

extension Converter {

    // MARK: Converter helpers

    /// Creates a new configuration for the URI coder.
    /// - Parameters:
    ///   - style: A parameter style.
    ///   - explode: An explode value.
    ///   - inBody: A Boolean value indicating whether the URI coder is being
    ///     used for encoding a body URI. Specify `false` if used for a query,
    ///     header, and so on.
    /// - Returns: A new URI coder configuration.
    func uriCoderConfiguration(style: ParameterStyle, explode: Bool, inBody: Bool) -> URICoderConfiguration {
        .init(
            style: .init(style),
            explode: explode,
            spaceEscapingCharacter: inBody ? .plus : .percentEncoded,
            dateTranscoder: configuration.dateTranscoder
        )
    }

    /// Returns a URI encoded string for the provided inputs.
    /// - Parameters:
    ///   - style: A parameter style.
    ///   - explode: An explode value.
    ///   - inBody: A Boolean value indicating whether the URI coder is being
    ///     used for encoding a body URI. Specify `false` if used for a query,
    ///     header, and so on.
    ///   - key: The key to be encoded with the value.
    ///   - value: The value to be encoded.
    /// - Returns: A URI encoded string.
    /// - Throws: An error if encoding fails.
    func convertToURI<T: Encodable>(style: ParameterStyle, explode: Bool, inBody: Bool, key: String, value: T) throws
        -> String
    {
        let encoder = URIEncoder(configuration: uriCoderConfiguration(style: style, explode: explode, inBody: inBody))
        let encodedString = try encoder.encode(value, forKey: key)
        return encodedString
    }

    /// Returns a value decoded from a URI encoded string.
    /// - Parameters:
    ///   - style: A parameter style.
    ///   - explode: An explode value.
    ///   - inBody: A Boolean value indicating whether the URI coder is being
    ///     used for encoding a body URI. Specify `false` if used for a query,
    ///     header, and so on.
    ///   - key: The key for which the value was decoded.
    ///   - encodedValue: The encoded value to be decoded.
    /// - Returns: A decoded value.
    /// - Throws: An error if decoding fails.
    func convertFromURI<T: Decodable>(
        style: ParameterStyle,
        explode: Bool,
        inBody: Bool,
        key: String,
        encodedValue: Substring
    ) throws -> T {
        let decoder = URIDecoder(configuration: uriCoderConfiguration(style: style, explode: explode, inBody: inBody))
        let value = try decoder.decode(T.self, forKey: key, from: encodedValue)
        return value
    }

    /// Returns a value decoded from a JSON body.
    /// - Parameter body: The body containing the raw JSON bytes.
    /// - Returns: A decoded value.
    /// - Throws: An error if decoding from the body fails.
    func convertJSONToBodyCodable<T: Decodable>(_ body: HTTPBody) async throws -> T {
        let data = try await Data(collecting: body, upTo: .max)
        return try decoder.decode(T.self, from: data)
    }

    /// Returns a JSON body for the provided encodable value.
    /// - Parameter value: The value to encode as JSON.
    /// - Returns: The raw JSON body.
    /// - Throws: An error if encoding to JSON fails.
    func convertBodyCodableToJSON<T: Encodable>(_ value: T) throws -> HTTPBody {
        let data = try encoder.encode(value)
        return HTTPBody(data)
    }

    /// Returns a value decoded from a URL-encoded form body.
    /// - Parameter body: The body containing the raw URL-encoded form bytes.
    /// - Returns: A decoded value.
    /// - Throws: An error if decoding from the URL-encoded form fails.
    func convertURLEncodedFormToCodable<T: Decodable>(_ body: HTTPBody) async throws -> T {
        let decoder = URIDecoder(
            configuration: .init(
                style: .form,
                explode: true,
                spaceEscapingCharacter: .plus,
                dateTranscoder: configuration.dateTranscoder
            )
        )
        let data = try await Data(collecting: body, upTo: .max)
        let uriString = Substring(decoding: data, as: UTF8.self)
        return try decoder.decode(T.self, from: uriString)
    }

    /// Returns a URL-encoded form string for the provided encodable value.
    /// - Parameter value: The value to encode.
    /// - Returns: The raw URL-encoded form body.
    /// - Throws: An error if encoding to URL-encoded form fails.
    func convertBodyCodableToURLFormData<T: Encodable>(_ value: T) throws -> HTTPBody {
        let encoder = URIEncoder(
            configuration: .init(
                style: .form,
                explode: true,
                spaceEscapingCharacter: .plus,
                dateTranscoder: configuration.dateTranscoder
            )
        )
        let encodedString = try encoder.encode(value, forKey: "")
        return HTTPBody(encodedString)
    }
    func convertMultipartToBinary(_ value: MultipartChunks) -> HTTPBody {
        // TODO: Use a closure that produces the boundary, allowing for randomization and make it configurable.
        HTTPBody(value, boundary: "__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__")
    }
    func convertBinaryToMultipart(_ body: HTTPBody) -> MultipartChunks {
        // TODO: We'll need to propagate headers here to allow us to extract the boundary from the header.
        MultipartChunks(parsing: body, boundary: "__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__")
    }
    func convertTypedToRawMultipart<Part: MultipartTypedPart>(
        _ value: MultipartTypedBody<Part>,
        transform: @escaping @Sendable (Part) throws -> MultipartUntypedPart
    ) -> MultipartChunks {
        let chunks =
            value.map { part in
                var untypedPart = try transform(part)
                let contentDispositionHeaderValue = "form-data; name=\"\(part.name)\""
                untypedPart.headerFields[.contentDisposition] = contentDispositionHeaderValue
                if case .known(let byteCount) = untypedPart.body.length {
                    untypedPart.headerFields[.contentLength] = String(byteCount)
                }
                return untypedPart
            }
            .asMultipartChunks()
        return .init(chunks, length: value.length, iterationBehavior: value.iterationBehavior)
    }
    func convertRawToTypedMultipart<Part: MultipartTypedPart>(_ value: MultipartChunks) -> MultipartTypedBody<Part> {
        fatalError()
    }
    /// Returns a JSON string for the provided encodable value.
    /// - Parameter value: The value to encode.
    /// - Returns: A JSON string.
    /// - Throws: An error if encoding the value to JSON fails.
    func convertHeaderFieldCodableToJSON<T: Encodable>(_ value: T) throws -> String {
        let data = try headerFieldEncoder.encode(value)
        let stringValue = String(decoding: data, as: UTF8.self)
        return stringValue
    }

    /// Returns a value decoded from the provided JSON string.
    /// - Parameter stringValue: A JSON string.
    /// - Returns: The decoded value.
    /// - Throws: An error if decoding from the JSON string fails.
    func convertJSONToHeaderFieldCodable<T: Decodable>(_ stringValue: Substring) throws -> T {
        let data = Data(stringValue.utf8)
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Helpers for specific types of parameters

    /// Sets the provided header field into the header field storage.
    /// - Parameters:
    ///   - headerFields: The header field storage.
    ///   - name: The name of the header to set.
    ///   - value: The value of the header to set.
    ///   - convert: The closure used to serialize the header value to string.
    /// - Throws: An error if an issue occurs while serializing the header value.
    func setHeaderField<T>(in headerFields: inout HTTPFields, name: String, value: T?, convert: (T) throws -> String)
        throws
    {
        guard let value else { return }
        try headerFields.append(.init(name: .init(validated: name), value: convert(value)))
    }

    /// Returns the value of the header with the provided name from the provided
    /// header field storage.
    /// - Parameters:
    ///   - headerFields: The header field storage.
    ///   - name: The name of the header field.
    /// - Returns: The value of the header field, if found. Nil otherwise.
    /// - Throws: An error if an issue occurs while retrieving the header value.
    func getHeaderFieldValuesString(in headerFields: HTTPFields, name: String) throws -> String? {
        try headerFields[.init(validated: name)]
    }

    /// Returns a decoded value for the header field with the provided name.
    /// - Parameters:
    ///   - headerFields: The header field storage.
    ///   - name: The name of the header field.
    ///   - type: The type to decode the value as.
    ///   - convert: The closure to convert the value from string.
    /// - Returns: The decoded value, if found. Nil otherwise.
    /// - Throws: An error if an issue occurs while decoding or converting the header value.
    func getOptionalHeaderField<T>(
        in headerFields: HTTPFields,
        name: String,
        as type: T.Type,
        convert: (Substring) throws -> T
    ) throws -> T? {
        guard let stringValue = try getHeaderFieldValuesString(in: headerFields, name: name) else { return nil }
        return try convert(stringValue[...])
    }

    /// Returns a decoded value for the header field with the provided name.
    /// - Parameters:
    ///   - headerFields: The header field storage.
    ///   - name: The name of the header field.
    ///   - type: The type to decode the value as.
    ///   - convert: The closure to convert the value from string.
    /// - Returns: The decoded value.
    /// - Throws: An error if the required header field is missing or
    ///  if an issue occurs while decoding or converting the header value.
    func getRequiredHeaderField<T>(
        in headerFields: HTTPFields,
        name: String,
        as type: T.Type,
        convert: (Substring) throws -> T
    ) throws -> T {
        guard let stringValue = try getHeaderFieldValuesString(in: headerFields, name: name) else {
            throw RuntimeError.missingRequiredHeaderField(name)
        }
        return try convert(stringValue[...])
    }

    /// Sets a query parameter with the provided inputs.
    /// - Parameters:
    ///   - request: The request to set the query parameter on.
    ///   - style: A parameter style.
    ///   - explode: An explode value.
    ///   - name: The name of the query parameter.
    ///   - value: The value of the query parameter. Must already be
    ///     percent-escaped.
    ///   - convert: The closure that converts the provided value to string.
    /// - Throws: An error if an issue occurs while setting the query parameter, such as invalid input values or encoding errors.
    func setEscapedQueryItem<T>(
        in request: inout HTTPRequest,
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        value: T?,
        convert: (T, ParameterStyle, Bool) throws -> String
    ) throws {
        guard let value else { return }
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

    /// Returns the decoded value for the provided name of a query parameter.
    /// - Parameters:
    ///   - query: The full encoded query string from which to extract the
    ///     parameter.
    ///   - style: A parameter style.
    ///   - explode: An explode value.
    ///   - name: The name of the query parameter.
    ///   - type: The type to decode the string value as.
    ///   - convert: The closure that decodes the value from string.
    /// - Returns: A decoded value, if found. Nil otherwise.
    /// - Throws: An error if an issue occurs while decoding the query parameter, such as invalid input values or decoding errors.
    func getOptionalQueryItem<T>(
        in query: Substring?,
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        as type: T.Type,
        convert: (Substring, ParameterStyle, Bool) throws -> T?
    ) throws -> T? {
        guard let query, !query.isEmpty else { return nil }
        let (resolvedStyle, resolvedExplode) = try ParameterStyle.resolvedQueryStyleAndExplode(
            name: name,
            style: style,
            explode: explode
        )
        return try convert(query, resolvedStyle, resolvedExplode)
    }

    /// Returns the decoded value for the provided name of a query parameter.
    /// - Parameters:
    ///   - query: The full encoded query string from which to extract the
    ///     parameter.
    ///   - style: A parameter style.
    ///   - explode: An explode value.
    ///   - name: The name of the query parameter.
    ///   - type: The type to decode the string value as.
    ///   - convert: The closure that decodes the value from string.
    /// - Returns: A decoded value.
    /// - Throws: An error if an issue occurs while decoding the query parameter, such as invalid input values or decoding errors.
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
        else { throw RuntimeError.missingRequiredQueryParameter(name) }
        return value
    }

    /// Sets the provided request body and the appropriate content type.
    /// - Parameters:
    ///   - value: The value to encode into the body.
    ///   - headerFields: The header fields storage where to save the content
    ///     type.
    ///   - contentType: The content type value.
    ///   - convert: The closure that encodes the value into a raw body.
    /// - Returns: The body.
    /// - Throws: An error if an issue occurs while encoding the request body or setting the content type.
    func setRequiredRequestBody<T>(
        _ value: T,
        headerFields: inout HTTPFields,
        contentType: String,
        convert: (T) throws -> HTTPBody
    ) throws -> HTTPBody {
        headerFields[.contentType] = contentType
        return try convert(value)
    }

    /// Sets the provided request body and the appropriate content type.
    /// - Parameters:
    ///   - value: The value to encode into the body.
    ///   - headerFields: The header fields storage where to save the content
    ///     type.
    ///   - contentType: The content type value.
    ///   - convert: The closure that encodes the value into a raw body.
    /// - Returns: The body, if value was not nil.
    /// - Throws: An error if an issue occurs while encoding the request body or setting the content type.
    func setOptionalRequestBody<T>(
        _ value: T?,
        headerFields: inout HTTPFields,
        contentType: String,
        convert: (T) throws -> HTTPBody
    ) throws -> HTTPBody? {
        guard let value else { return nil }
        return try setRequiredRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convert
        )
    }

    /// Returns a value decoded from the provided body.
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - body: The body to decode the value from.
    ///   - transform: The closure that wraps the body in its generated type.
    ///   - convert: The closure that decodes the body.
    /// - Returns: A decoded wrapped type, if body is not nil.
    /// - Throws: An error if an issue occurs while decoding the request body.
    func getOptionalBufferingRequestBody<T, C>(
        _ type: T.Type,
        from body: HTTPBody?,
        transforming transform: (T) -> C,
        convert: (HTTPBody) async throws -> T
    ) async throws -> C? {
        guard let body else { return nil }
        let decoded = try await convert(body)
        return transform(decoded)
    }

    /// Returns a value decoded from the provided body.
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - body: The body to decode the value from.
    ///   - transform: The closure that wraps the body in its generated type.
    ///   - convert: The closure that decodes the body.
    /// - Returns: A decoded wrapped type.
    /// - Throws: An error if an issue occurs while decoding the request body or if the required body is missing.
    func getRequiredBufferingRequestBody<T, C>(
        _ type: T.Type,
        from body: HTTPBody?,
        transforming transform: (T) -> C,
        convert: (HTTPBody) async throws -> T
    ) async throws -> C {
        guard
            let body = try await getOptionalBufferingRequestBody(
                type,
                from: body,
                transforming: transform,
                convert: convert
            )
        else { throw RuntimeError.missingRequiredRequestBody }
        return body
    }

    /// Returns a value decoded from the provided body.
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - body: The body to decode the value from.
    ///   - transform: The closure that wraps the body in its generated type.
    ///   - convert: The closure that decodes the body.
    /// - Returns: A decoded wrapped type, if body is not nil.
    /// - Throws: An error if an issue occurs while decoding the request body.
    func getOptionalRequestBody<T, C>(
        _ type: T.Type,
        from body: HTTPBody?,
        transforming transform: (T) -> C,
        convert: (HTTPBody) throws -> T
    ) throws -> C? {
        guard let body else { return nil }
        let decoded = try convert(body)
        return transform(decoded)
    }

    /// Returns a value decoded from the provided body.
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - body: The body to decode the value from.
    ///   - transform: The closure that wraps the body in its generated type.
    ///   - convert: The closure that decodes the body.
    /// - Returns: A decoded wrapped type.
    /// - Throws: An error if an issue occurs while decoding the request body, or if the body is missing.
    func getRequiredRequestBody<T, C>(
        _ type: T.Type,
        from body: HTTPBody?,
        transforming transform: (T) -> C,
        convert: (HTTPBody) throws -> T
    ) throws -> C {
        guard let body = try getOptionalRequestBody(type, from: body, transforming: transform, convert: convert) else {
            throw RuntimeError.missingRequiredRequestBody
        }
        return body
    }

    /// Returns a value decoded from the provided body.
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - body: The body to decode the value from.
    ///   - transform: The closure that wraps the body in its generated type.
    ///   - convert: The closure that decodes the body.
    /// - Returns: A decoded wrapped type.
    /// - Throws: An error if an issue occurs while decoding the response body.
    func getBufferingResponseBody<T, C>(
        _ type: T.Type,
        from body: HTTPBody,
        transforming transform: (T) -> C,
        convert: (HTTPBody) async throws -> T
    ) async throws -> C {
        let parsedValue = try await convert(body)
        let transformedValue = transform(parsedValue)
        return transformedValue
    }

    /// Returns a value decoded from the provided body.
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - body: The body to decode the value from.
    ///   - transform: The closure that wraps the body in its generated type.
    ///   - convert: The closure that decodes the body.
    /// - Returns: A decoded wrapped type.
    /// - Throws: An error if an issue occurs while decoding the response body.
    func getResponseBody<T, C>(
        _ type: T.Type,
        from body: HTTPBody,
        transforming transform: (T) -> C,
        convert: (HTTPBody) throws -> T
    ) throws -> C {
        let parsedValue = try convert(body)
        let transformedValue = transform(parsedValue)
        return transformedValue
    }

    /// Sets the provided request body and the appropriate content type.
    /// - Parameters:
    ///   - value: The value to encode into the body.
    ///   - headerFields: The header fields storage where to save the content
    ///     type.
    ///   - contentType: The content type value.
    ///   - convert: The closure that encodes the value into a raw body.
    /// - Returns: The body, if value was not nil.
    /// - Throws: An error if an issue occurs while encoding the request body.
    func setResponseBody<T>(
        _ value: T,
        headerFields: inout HTTPFields,
        contentType: String,
        convert: (T) throws -> HTTPBody
    ) throws -> HTTPBody {
        headerFields[.contentType] = contentType
        return try convert(value)
    }

    /// Returns a decoded value for the provided path parameter.
    /// - Parameters:
    ///   - pathParameters: The storage of path parameters.
    ///   - name: The name of the path parameter.
    ///   - type: The type to decode the value as.
    ///   - convert: The closure that decodes the value from string.
    /// - Returns: A decoded value.
    /// - Throws: An error if the specified path parameter is missing or if there's an issue decoding the value.
    func getRequiredRequestPath<T>(
        in pathParameters: [String: Substring],
        name: String,
        as type: T.Type,
        convert: (Substring) throws -> T
    ) throws -> T {
        guard let untypedValue = pathParameters[name] else { throw RuntimeError.missingRequiredPathParameter(name) }
        return try convert(untypedValue)
    }
}
