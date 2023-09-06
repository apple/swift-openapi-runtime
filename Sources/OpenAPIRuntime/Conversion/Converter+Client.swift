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

    //    | client | set | request path | URI | required | renderedPath |
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

    //    | client | set | request query | URI | both | setQueryItemAsURI |
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

    //    | client | set | request body | JSON | optional | setOptionalRequestBodyAsJSON |
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

    //    | client | set | request body | JSON | required | setRequiredRequestBodyAsJSON |
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

    //    | client | set | request body | binary | optional | setOptionalRequestBodyAsBinary |
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

    //    | client | set | request body | binary | required | setRequiredRequestBodyAsBinary |
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

    //    | client | get | response body | JSON | required | getResponseBodyAsJSON |
    public func getResponseBodyAsJSON<T: Decodable, C>(
        _ type: T.Type,
        from data: HTTPBody,
        transforming transform: (T) -> C
    ) async throws -> C {
        try await getBufferingResponseBody(
            type,
            from: data,
            transforming: transform,
            convert: convertJSONToBodyCodable
        )
    }

    //    | client | get | response body | binary | required | getResponseBodyAsBinary |
    public func getResponseBodyAsBinary<C>(
        _ type: HTTPBody.Type,
        from data: HTTPBody,
        transforming transform: (HTTPBody) -> C
    ) throws -> C {
        try getResponseBody(
            type,
            from: data,
            transforming: transform,
            convert: { $0 }
        )
    }
}
