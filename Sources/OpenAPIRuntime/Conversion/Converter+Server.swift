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

extension Converter {

    // MARK: Miscs

    /// Returns the "accept" header parsed into individual content types.
    /// - Parameter headerFields: The header fields to inspect for an "accept"
    ///   header.
    /// - Returns: The parsed content types, or the default content types if
    ///   the header was not provided.
    /// - Throws: An error if the "accept" header is present but malformed, or if there are issues parsing its components.
    public func extractAcceptHeaderIfPresent<T: AcceptableProtocol>(in headerFields: HTTPFields) throws
        -> [AcceptHeaderContentType<T>]
    {
        guard let rawValue = headerFields[.accept] else { return AcceptHeaderContentType<T>.defaultValues }
        let rawComponents = rawValue.split(separator: ",").map(String.init).map(\.trimmingLeadingAndTrailingSpaces)
        let parsedComponents = try rawComponents.map { rawComponent in
            guard let value = AcceptHeaderContentType<T>(rawValue: rawComponent) else {
                throw RuntimeError.malformedAcceptHeader(rawComponent)
            }
            return value
        }
        return parsedComponents
    }

    /// Validates that the Accept header in the provided response
    /// is compatible with the provided content type substring.
    /// - Parameters:
    ///   - substring: Expected content type, for example "application/json".
    ///   - headerFields: Header fields in which to look for "Accept".
    ///   Also supports wildcars, such as "application/\*" and "\*/\*".
    /// - Throws: An error if the "Accept" header is present but incompatible with the provided content type,
    ///  or if there are issues parsing the header.
    public func validateAcceptIfPresent(_ substring: String, in headerFields: HTTPFields) throws {
        // for example: text/html, application/xhtml+xml, application/xml;q=0.9, */*;q=0.8
        guard let acceptHeader = headerFields[.accept] else { return }

        // Split with commas to get the individual values
        let acceptValues = acceptHeader.split(separator: ",")
            .map { value in
                // Drop everything after the optional semicolon (q, extensions, ...)
                value.split(separator: ";")[0].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }

        if acceptValues.isEmpty { return }
        if acceptValues.contains("*/*") { return }
        if acceptValues.contains("\(substring.split(separator: "/")[0].lowercased())/*") { return }
        if acceptValues.contains(where: { $0.localizedCaseInsensitiveContains(substring) }) { return }
        throw RuntimeError.unexpectedAcceptHeader(acceptHeader)
    }

    /// Retrieves and decodes a path parameter as a URI-encoded value of the specified type.
    ///
    /// - Parameters:
    ///   - pathParameters: A dictionary of path parameters, where the keys are parameter names, and the values are substrings.
    ///   - name: The name of the path parameter to retrieve.
    ///   - type: The type to decode the parameter value into.
    /// - Returns: The decoded value of the specified type.
    /// - Throws: An error if the specified path parameter is not found or if there are issues decoding the value.
    public func getPathParameterAsURI<T: Decodable>(
        in pathParameters: [String: Substring],
        name: String,
        as type: T.Type
    ) throws -> T {
        try getRequiredRequestPath(
            in: pathParameters,
            name: name,
            as: T.self,
            convert: { encodedString in
                let decoder = URIDecoder(
                    configuration: .init(
                        style: .simple,
                        explode: false,
                        spaceEscapingCharacter: .percentEncoded,
                        dateTranscoder: configuration.dateTranscoder
                    )
                )
                let value = try decoder.decode(T.self, forKey: name, from: encodedString)
                return value
            }
        )
    }

    /// Retrieves and decodes an optional query item as a URI-encoded value of the specified type.
    ///
    /// - Parameters:
    ///   - query: The query item to decode as a substring, or `nil` if the query item is not present.
    ///   - style: The parameter style.
    ///   - explode: An explode value.
    ///   - name: The name of the query parameter to retrieve.
    ///   - type: The type to decode the parameter value into.
    /// - Returns: The decoded value of the specified type, or `nil` if the query item is not present.
    /// - Throws: An error if there are issues decoding the value.
    public func getOptionalQueryItemAsURI<T: Decodable>(
        in query: Substring?,
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        as type: T.Type
    ) throws -> T? {
        try getOptionalQueryItem(
            in: query,
            style: style,
            explode: explode,
            name: name,
            as: type,
            convert: { query, style, explode in
                let decoder = URIDecoder(
                    configuration: .init(
                        style: .init(style),
                        explode: explode,
                        spaceEscapingCharacter: .percentEncoded,
                        dateTranscoder: configuration.dateTranscoder
                    )
                )
                let value = try decoder.decodeIfPresent(T.self, forKey: name, from: query)
                return value
            }
        )
    }

    /// Retrieves and decodes a required query item as a URI-encoded value of the specified type.
    ///
    /// - Parameters:
    ///   - query: The query item to decode as a substring, or `nil` if the query item is not present.
    ///   - style: The parameter style.
    ///   - explode: An explode value
    ///   - name: The name of the query parameter to retrieve.
    ///   - type: The type to decode the parameter value into.
    /// - Returns: The decoded value of the specified type.
    /// - Throws: An error if the query item is not present or if there are issues decoding the value.
    public func getRequiredQueryItemAsURI<T: Decodable>(
        in query: Substring?,
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        as type: T.Type
    ) throws -> T {
        try getRequiredQueryItem(
            in: query,
            style: style,
            explode: explode,
            name: name,
            as: type,
            convert: { query, style, explode in
                let decoder = URIDecoder(
                    configuration: .init(
                        style: .init(style),
                        explode: explode,
                        spaceEscapingCharacter: .percentEncoded,
                        dateTranscoder: configuration.dateTranscoder
                    )
                )
                let value = try decoder.decode(T.self, forKey: name, from: query)
                return value
            }
        )
    }

    /// Retrieves and decodes an optional JSON-encoded request body and transforms it to a different type.
    ///
    /// - Parameters:
    ///   - type: The type to decode the request body into.
    ///   - data: The HTTP request body to decode, or `nil` if the body is not present.
    ///   - transform: A closure that transforms the decoded value to a different type.
    /// - Returns: The transformed value, or `nil` if the request body is not present or if decoding fails.
    /// - Throws: An error if there are issues decoding or transforming the request body.
    public func getOptionalRequestBodyAsJSON<T: Decodable, C>(
        _ type: T.Type,
        from data: HTTPBody?,
        transforming transform: (T) -> C
    ) async throws -> C? {
        try await getOptionalBufferingRequestBody(
            type,
            from: data,
            transforming: transform,
            convert: convertJSONToBodyCodable
        )
    }

    /// Retrieves and decodes a required JSON-encoded request body and transforms it to a different type.
    ///
    /// - Parameters:
    ///   - type: The type to decode the request body into.
    ///   - data: The HTTP request body to decode, or `nil` if the body is not present.
    ///   - transform: A closure that transforms the decoded value to a different type.
    /// - Returns: The transformed value.
    /// - Throws: An error if the request body is not present, if decoding fails, or if there are issues transforming the request body.
    public func getRequiredRequestBodyAsJSON<T: Decodable, C>(
        _ type: T.Type,
        from data: HTTPBody?,
        transforming transform: (T) -> C
    ) async throws -> C {
        try await getRequiredBufferingRequestBody(
            type,
            from: data,
            transforming: transform,
            convert: convertJSONToBodyCodable
        )
    }

    /// Retrieves and transforms an optional binary request body.
    ///
    /// - Parameters:
    ///   - type: The type representing an HTTP request body (usually `HTTPBody.Type`).
    ///   - data: The HTTP request body to transform, or `nil` if the body is not present.
    ///   - transform: A closure that transforms the binary request body to a different type.
    /// - Returns: The transformed value, or `nil` if the request body is not present.
    /// - Throws: An error if there are issues transforming the request body.
    public func getOptionalRequestBodyAsBinary<C>(
        _ type: HTTPBody.Type,
        from data: HTTPBody?,
        transforming transform: (HTTPBody) -> C
    ) throws -> C? { try getOptionalRequestBody(type, from: data, transforming: transform, convert: { $0 }) }

    /// Retrieves and transforms a required binary request body.
    ///
    /// - Parameters:
    ///   - type: The type representing an HTTP request body (usually `HTTPBody.Type`).
    ///   - data: The HTTP request body to transform, or `nil` if the body is not present.
    ///   - transform: A closure that transforms the binary request body to a different type.
    /// - Returns: The transformed value.
    /// - Throws: An error if the request body is not present or if there are issues transforming the request body.
    public func getRequiredRequestBodyAsBinary<C>(
        _ type: HTTPBody.Type,
        from data: HTTPBody?,
        transforming transform: (HTTPBody) -> C
    ) throws -> C { try getRequiredRequestBody(type, from: data, transforming: transform, convert: { $0 }) }

    public func getOptionalRequestBodyAsMultipart<C>(
        _ type: MultipartBody.Type,
        from data: HTTPBody?,
        transforming transform: (MultipartBody) -> C
    ) throws -> C? {
        try getOptionalRequestBody(type, from: data, transforming: transform, convert: convertBinaryToMultipart)
    }

    public func getRequiredRequestBodyAsMultipart<C>(
        _ type: MultipartBody.Type,
        from data: HTTPBody?,
        transforming transform: (MultipartBody) -> C
    ) throws -> C {
        try getRequiredRequestBody(type, from: data, transforming: transform, convert: convertBinaryToMultipart)
    }

    /// Retrieves and transforms an optional URL-encoded form request body.
    ///
    /// - Parameters:
    ///   - type: The type representing the expected structure of the URL-encoded form data.
    ///   - data: The HTTP request body to transform, or `nil` if the body is not present.
    ///   - transform: A closure that transforms the URL-encoded form request body to a different type.
    /// - Returns: The transformed value, or `nil` if the request body is not present.
    /// - Throws: An error if there are issues transforming the request body.
    public func getOptionalRequestBodyAsURLEncodedForm<T: Decodable, C>(
        _ type: T.Type,
        from data: HTTPBody?,
        transforming transform: (T) -> C
    ) async throws -> C? {
        try await getOptionalBufferingRequestBody(
            type,
            from: data,
            transforming: transform,
            convert: convertURLEncodedFormToCodable
        )
    }

    /// Retrieves and decodes the required request body as URL-encoded form data.
    ///
    /// - Parameters:
    ///   - type: The type to decode the request body into.
    ///   - data: The HTTP body containing the URL-encoded form data.
    ///   - transform: A closure to further transform the decoded value.
    /// - Returns: The transformed, decoded value of type `C`.
    /// - Throws: An error if the decoding or transformation fails.
    public func getRequiredRequestBodyAsURLEncodedForm<T: Decodable, C>(
        _ type: T.Type,
        from data: HTTPBody?,
        transforming transform: (T) -> C
    ) async throws -> C {
        try await getRequiredBufferingRequestBody(
            type,
            from: data,
            transforming: transform,
            convert: convertURLEncodedFormToCodable
        )
    }

    /// Sets the response body as JSON data, serializing the provided value.
    ///
    /// - Parameters:
    ///   - value: The value to be serialized into the response body.
    ///   - headerFields: The HTTP header fields to update with the new `contentType`.
    ///   - contentType: The content type to set in the HTTP header fields.
    /// - Returns: An `HTTPBody` with the response body set as JSON data.
    /// - Throws: An error if serialization or setting the response body fails.
    public func setResponseBodyAsJSON<T: Encodable>(_ value: T, headerFields: inout HTTPFields, contentType: String)
        throws -> HTTPBody
    {
        try setResponseBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertBodyCodableToJSON
        )
    }

    /// Sets the response body as binary data.
    ///
    /// - Parameters:
    ///   - value: The binary data to set as the response body.
    ///   - headerFields: A reference to the header fields to update with the content type.
    ///   - contentType: The content type to set in the header fields.
    /// - Returns: The updated `HTTPBody` containing the binary response data.
    /// - Throws: An error if there are issues setting the response body or updating the header fields.
    public func setResponseBodyAsBinary(_ value: HTTPBody, headerFields: inout HTTPFields, contentType: String) throws
        -> HTTPBody
    { try setResponseBody(value, headerFields: &headerFields, contentType: contentType, convert: { $0 }) }
    public func setResponseBodyAsMultipart(_ value: MultipartBody, headerFields: inout HTTPFields, contentType: String)
        throws -> HTTPBody
    {
        try setResponseBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertMultipartToBinary
        )
    }
}
