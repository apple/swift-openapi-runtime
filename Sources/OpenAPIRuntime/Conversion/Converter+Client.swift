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

    /// Sets the "accept" header according to the provided content types.
    /// - Parameters:
    ///   - headerFields: The header fields where to add the "accept" header.
    ///   - contentTypes: The array of acceptable content types by the client.
    public func setAcceptHeader<T: AcceptableProtocol>(
        in headerFields: inout HTTPFields,
        contentTypes: [AcceptHeaderContentType<T>]
    ) {
        headerFields[.accept] = contentTypes.map(\.rawValue).joined(separator: ", ")
    }

    /// Renders the path template with the specified parameters to construct a URI.
    ///
    /// - Parameters:
    ///   - template: The URI path template with placeholders for parameters.
    ///   - parameters: An array of encodable parameters used to populate the placeholders.
    ///
    /// - Returns: A URI path string with placeholders replaced by the provided parameters.
    ///
    /// - Throws: An error if rendering the path fails.
    public func renderedPath(
        template: String,
        parameters: [any Encodable]
    ) throws -> String {
        var renderedString = template
        let encoder = URIEncoder(
            configuration: .init(
                style: .simple,
                explode: false,
                spaceEscapingCharacter: .percentEncoded,
                dateTranscoder: configuration.dateTranscoder
            )
        )
        for parameter in parameters {
            let value = try encoder.encode(parameter, forKey: "")
            if let range = renderedString.range(of: "{}") {
                renderedString = renderedString.replacingOccurrences(
                    of: "{}",
                    with: value,
                    range: range
                )
            }
        }
        return renderedString
    }

    /// Sets a query item with the specified name and value in the HTTP request's query parameters, treating the value as a URI component.
    ///
    /// - Parameters:
    ///   - request: The HTTP request to which the query item is added.
    ///   - style: The parameter style to apply when encoding the value.
    ///   - explode: A Boolean indicating whether to explode values.
    ///   - name: The name of the query item.
    ///   - value: The value to be treated as a URI component.
    ///
    /// - Throws: An error of if setting the query item as a URI component fails.
    public func setQueryItemAsURI<T: Encodable>(
        in request: inout HTTPRequest,
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        value: T?
    ) throws {
        try setEscapedQueryItem(
            in: &request,
            style: style,
            explode: explode,
            name: name,
            value: value,
            convert: { value, style, explode in
                try convertToURI(
                    style: style,
                    explode: explode,
                    inBody: false,
                    key: name,
                    value: value
                )
            }
        )
    }

    /// Sets an optional request body as JSON in the specified header fields and returns an `HTTPBody`.
    ///
    /// - Parameters:
    ///   - value: The optional value to be set as the request body.
    ///   - headerFields: The header fields in which to set the content type.
    ///   - contentType: The content type to be set in the header fields.
    ///
    /// - Returns: An `HTTPBody` representing the JSON-encoded request body, or `nil` if the `value` is `nil`.
    ///
    /// - Throws: An error if setting the request body as JSON fails.
    public func setOptionalRequestBodyAsJSON<T: Encodable>(
        _ value: T?,
        headerFields: inout HTTPFields,
        contentType: String
    ) throws -> HTTPBody? {
        try setOptionalRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertBodyCodableToJSON
        )
    }

    /// Sets a required request body as JSON in the specified header fields and returns an `HTTPBody`.
    ///
    /// - Parameters:
    ///   - value: The value to be set as the request body.
    ///   - headerFields: The header fields in which to set the content type.
    ///   - contentType: The content type to be set in the header fields.
    ///
    /// - Returns: An `HTTPBody` representing the JSON-encoded request body.
    ///
    /// - Throws: An error if setting the request body as JSON fails.
    public func setRequiredRequestBodyAsJSON<T: Encodable>(
        _ value: T,
        headerFields: inout HTTPFields,
        contentType: String
    ) throws -> HTTPBody {
        try setRequiredRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertBodyCodableToJSON
        )
    }

    /// Sets an optional request body as binary in the specified header fields and returns an `HTTPBody`.
    ///
    /// - Parameters:
    ///   - value: The optional `HTTPBody` to be set as the request body.
    ///   - headerFields: The header fields in which to set the content type.
    ///   - contentType: The content type to be set in the header fields.
    ///
    /// - Returns: An `HTTPBody` representing the binary request body, or `nil` if the `value` is `nil`.
    ///
    /// - Throws: An error if setting the request body as binary fails.
    public func setOptionalRequestBodyAsBinary(
        _ value: HTTPBody?,
        headerFields: inout HTTPFields,
        contentType: String
    ) throws -> HTTPBody? {
        try setOptionalRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: { $0 }
        )
    }

    /// Sets a required request body as binary in the specified header fields and returns an `HTTPBody`.
    ///
    /// - Parameters:
    ///   - value: The `HTTPBody` to be set as the request body.
    ///   - headerFields: The header fields in which to set the content type.
    ///   - contentType: The content type to be set in the header fields.
    ///
    /// - Returns: An `HTTPBody` representing the binary request body.
    ///
    /// - Throws: An error if setting the request body as binary fails.
    public func setRequiredRequestBodyAsBinary(
        _ value: HTTPBody,
        headerFields: inout HTTPFields,
        contentType: String
    ) throws -> HTTPBody {
        try setRequiredRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: { $0 }
        )
    }

    /// Sets an optional request body as URL-encoded form data in the specified header fields and returns an `HTTPBody`.
    ///
    /// - Parameters:
    ///   - value: The optional value to be set as the request body.
    ///   - headerFields: The header fields in which to set the content type.
    ///   - contentType: The content type to be set in the header fields.
    ///
    /// - Returns: An `HTTPBody` representing the URL-encoded form data request body, or `nil` if the `value` is `nil`.
    ///
    /// - Throws: An error if setting the request body as URL-encoded form data fails.
    public func setOptionalRequestBodyAsURLEncodedForm<T: Encodable>(
        _ value: T,
        headerFields: inout HTTPFields,
        contentType: String
    ) throws -> HTTPBody? {
        try setOptionalRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertBodyCodableToURLFormData
        )
    }

    /// Sets a required request body as URL-encoded form data in the specified header fields and returns an `HTTPBody`.
    ///
    /// - Parameters:
    ///   - value: The value to be set as the request body.
    ///   - headerFields: The header fields in which to set the content type.
    ///   - contentType: The content type to be set in the header fields.
    ///
    /// - Returns: An `HTTPBody` representing the URL-encoded form data request body.
    ///
    /// - Throws: An error if setting the request body as URL-encoded form data fails.
    public func setRequiredRequestBodyAsURLEncodedForm<T: Encodable>(
        _ value: T,
        headerFields: inout HTTPFields,
        contentType: String
    ) throws -> HTTPBody {
        try setRequiredRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertBodyCodableToURLFormData
        )
    }

    /// Retrieves the response body as JSON and transforms it into a specified type.
    ///
    /// - Parameters:
    ///   - type: The type to decode the JSON into.
    ///   - data: The HTTP body data containing the JSON.
    ///   - transform: A transformation function to apply to the decoded JSON.
    ///
    /// - Returns: The transformed result of type `C`.
    ///
    /// - Throws: An error if retrieving or transforming the response body fails.
    public func getResponseBodyAsJSON<T: Decodable, C>(
        _ type: T.Type,
        from data: HTTPBody?,
        transforming transform: (T) -> C
    ) async throws -> C {
        guard let data else {
            throw RuntimeError.missingRequiredResponseBody
        }
        return try await getBufferingResponseBody(
            type,
            from: data,
            transforming: transform,
            convert: convertJSONToBodyCodable
        )
    }

    /// Retrieves the response body as binary data and transforms it into a specified type.
    ///
    /// - Parameters:
    ///   - type: The type representing the response body.
    ///   - data: The HTTP body data to transform.
    ///   - transform: A transformation function to apply to the binary data.
    ///
    /// - Returns: The transformed result of type `C`.
    ///
    /// - Throws: An error if retrieving or transforming the response body fails.
    public func getResponseBodyAsBinary<C>(
        _ type: HTTPBody.Type,
        from data: HTTPBody?,
        transforming transform: (HTTPBody) -> C
    ) throws -> C {
        guard let data else {
            throw RuntimeError.missingRequiredResponseBody
        }
        return try getResponseBody(
            type,
            from: data,
            transforming: transform,
            convert: { $0 }
        )
    }
}
