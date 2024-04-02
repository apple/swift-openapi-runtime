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
    ) { headerFields[.accept] = contentTypes.map(\.rawValue).joined(separator: ", ") }

    /// Renders the path template with the specified parameters to construct a URI.
    ///
    /// - Parameters:
    ///   - template: The URI path template with placeholders for parameters.
    ///   - parameters: An array of encodable parameters used to populate the placeholders.
    ///
    /// - Returns: A URI path string with placeholders replaced by the provided parameters.
    ///
    /// - Throws: An error if rendering the path fails.
    public func renderedPath(template: String, parameters: [any Encodable]) throws -> String {
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
                renderedString = renderedString.replacingOccurrences(of: "{}", with: value, range: range)
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
                try convertToURI(style: style, explode: explode, inBody: false, key: name, value: value)
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
    /// Sets an optional request body as XML in the specified header fields and returns an `HTTPBody`.
    ///
    /// - Parameters:
    ///   - value: The optional value to be set as the request body.
    ///   - headerFields: The header fields in which to set the content type.
    ///   - contentType: The content type to be set in the header fields.
    ///
    /// - Returns: An `HTTPBody` representing the XML-encoded request body, or `nil` if the `value` is `nil`.
    ///
    /// - Throws: An error if setting the request body as XML fails.
    public func setOptionalRequestBodyAsXML<T: Encodable>(
        _ value: T?,
        headerFields: inout HTTPFields,
        contentType: String
    ) throws -> HTTPBody? {
        try setOptionalRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertBodyCodableToXML
        )
    }
    /// Sets a required request body as XML in the specified header fields and returns an `HTTPBody`.
    ///
    /// - Parameters:
    ///   - value: The value to be set as the request body.
    ///   - headerFields: The header fields in which to set the content type.
    ///   - contentType: The content type to be set in the header fields.
    ///
    /// - Returns: An `HTTPBody` representing the XML-encoded request body.
    ///
    /// - Throws: An error if setting the request body as XML fails.
    public func setRequiredRequestBodyAsXML<T: Encodable>(
        _ value: T,
        headerFields: inout HTTPFields,
        contentType: String
    ) throws -> HTTPBody {
        try setRequiredRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertBodyCodableToXML
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
    public func setOptionalRequestBodyAsBinary(_ value: HTTPBody?, headerFields: inout HTTPFields, contentType: String)
        throws -> HTTPBody?
    { setOptionalRequestBody(value, headerFields: &headerFields, contentType: contentType, convert: { $0 }) }

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
    public func setRequiredRequestBodyAsBinary(_ value: HTTPBody, headerFields: inout HTTPFields, contentType: String)
        throws -> HTTPBody
    { setRequiredRequestBody(value, headerFields: &headerFields, contentType: contentType, convert: { $0 }) }

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

    /// Sets a required request body as multipart and returns the streaming body.
    ///
    /// - Parameters:
    ///   - value: The multipart body to be set as the request body.
    ///   - headerFields: The header fields in which to set the content type.
    ///   - contentType: The content type to be set in the header fields.
    ///   - allowsUnknownParts: A Boolean value indicating whether parts with unknown names
    ///     should be pass through. If `false`, encountering an unknown part throws an error
    ///     whent the returned body sequence iterates it.
    ///   - requiredExactlyOncePartNames: The list of part names that are required exactly once.
    ///   - requiredAtLeastOncePartNames: The list of part names that are required at least once.
    ///   - atMostOncePartNames: The list of part names that can appear at most once.
    ///   - zeroOrMoreTimesPartNames: The list of names that can appear any number of times.
    ///   - encode: A closure that transforms the type-safe part into a raw part.
    /// - Returns: A streaming body representing the multipart-encoded request body.
    /// - Throws: Currently never, but might in the future.
    public func setRequiredRequestBodyAsMultipart<Part: Sendable>(
        _ value: MultipartBody<Part>,
        headerFields: inout HTTPFields,
        contentType: String,
        allowsUnknownParts: Bool,
        requiredExactlyOncePartNames: Set<String>,
        requiredAtLeastOncePartNames: Set<String>,
        atMostOncePartNames: Set<String>,
        zeroOrMoreTimesPartNames: Set<String>,
        encoding encode: @escaping @Sendable (Part) throws -> MultipartRawPart
    ) throws -> HTTPBody {
        let boundary = configuration.multipartBoundaryGenerator.makeBoundary()
        let contentTypeWithBoundary = contentType + "; boundary=\(boundary)"
        return setRequiredRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentTypeWithBoundary,
            convert: { value in
                convertMultipartToBytes(
                    value,
                    requirements: .init(
                        allowsUnknownParts: allowsUnknownParts,
                        requiredExactlyOncePartNames: requiredExactlyOncePartNames,
                        requiredAtLeastOncePartNames: requiredAtLeastOncePartNames,
                        atMostOncePartNames: atMostOncePartNames,
                        zeroOrMoreTimesPartNames: zeroOrMoreTimesPartNames
                    ),
                    boundary: boundary,
                    encode: encode
                )
            }
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
        guard let data else { throw RuntimeError.missingRequiredResponseBody }
        return try await getBufferingResponseBody(
            type,
            from: data,
            transforming: transform,
            convert: convertJSONToBodyCodable
        )
    }
    /// Retrieves the response body as XML and transforms it into a specified type.
    ///
    /// - Parameters:
    ///   - type: The type to decode the XML into.
    ///   - data: The HTTP body data containing the XML.
    ///   - transform: A transformation function to apply to the decoded XML.
    ///
    /// - Returns: The transformed result of type `C`.
    ///
    /// - Throws: An error if retrieving or transforming the response body fails.
    public func getResponseBodyAsXML<T: Decodable, C>(
        _ type: T.Type,
        from data: HTTPBody?,
        transforming transform: (T) -> C
    ) async throws -> C {
        guard let data else { throw RuntimeError.missingRequiredResponseBody }
        return try await getBufferingResponseBody(
            type,
            from: data,
            transforming: transform,
            convert: convertXMLToBodyCodable
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
        guard let data else { throw RuntimeError.missingRequiredResponseBody }
        return try getResponseBody(type, from: data, transforming: transform, convert: { $0 })
    }
    /// Returns an async sequence of multipart parts parsed from the provided body stream.
    ///
    /// - Parameters:
    ///   - type: The type representing the type-safe multipart body.
    ///   - data: The HTTP body data to transform.
    ///   - transform: A closure that transforms the multipart body into the output type.
    ///   - boundary: The multipart boundary string.
    ///   - allowsUnknownParts: A Boolean value indicating whether parts with unknown names
    ///     should be pass through. If `false`, encountering an unknown part throws an error
    ///     whent the returned body sequence iterates it.
    ///   - requiredExactlyOncePartNames: The list of part names that are required exactly once.
    ///   - requiredAtLeastOncePartNames: The list of part names that are required at least once.
    ///   - atMostOncePartNames: The list of part names that can appear at most once.
    ///   - zeroOrMoreTimesPartNames: The list of names that can appear any number of times.
    ///   - decoder: A closure that parses a raw part into a type-safe part.
    /// - Returns: A value of the output type.
    /// - Throws: If the transform closure throws.
    public func getResponseBodyAsMultipart<C, Part: Sendable>(
        _ type: MultipartBody<Part>.Type,
        from data: HTTPBody?,
        transforming transform: @escaping @Sendable (MultipartBody<Part>) throws -> C,
        boundary: String,
        allowsUnknownParts: Bool,
        requiredExactlyOncePartNames: Set<String>,
        requiredAtLeastOncePartNames: Set<String>,
        atMostOncePartNames: Set<String>,
        zeroOrMoreTimesPartNames: Set<String>,
        decoding decoder: @escaping @Sendable (MultipartRawPart) async throws -> Part
    ) throws -> C {
        guard let data else { throw RuntimeError.missingRequiredResponseBody }
        let multipart = convertBytesToMultipart(
            data,
            boundary: boundary,
            requirements: .init(
                allowsUnknownParts: allowsUnknownParts,
                requiredExactlyOncePartNames: requiredExactlyOncePartNames,
                requiredAtLeastOncePartNames: requiredAtLeastOncePartNames,
                atMostOncePartNames: atMostOncePartNames,
                zeroOrMoreTimesPartNames: zeroOrMoreTimesPartNames
            ),
            transform: decoder
        )
        return try transform(multipart)
    }
}
