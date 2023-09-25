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

extension Converter {

    /// Sets the "accept" header according to the provided content types.
    /// - Parameters:
    ///   - headerFields: The header fields where to add the "accept" header.
    ///   - contentTypes: The array of acceptable content types by the client.
    public func setAcceptHeader<T: AcceptableProtocol>(
        in headerFields: inout [HeaderField],
        contentTypes: [AcceptHeaderContentType<T>]
    ) {
        headerFields.append(
            .init(
                name: "accept",
                value: contentTypes.map(\.rawValue).joined(separator: ", ")
            )
        )
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
        in request: inout Request,
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

    //    | client | set | request body | string | optional | setOptionalRequestBodyAsString |
    public func setOptionalRequestBodyAsString<T: Encodable>(
        _ value: T?,
        headerFields: inout [HeaderField],
        contentType: String
    ) throws -> Data? {
        try setOptionalRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertToStringData
        )
    }

    //    | client | set | request body | string | required | setRequiredRequestBodyAsString |
    public func setRequiredRequestBodyAsString<T: Encodable>(
        _ value: T,
        headerFields: inout [HeaderField],
        contentType: String
    ) throws -> Data {
        try setRequiredRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertToStringData
        )
    }

    //    | client | set | request body | JSON | optional | setOptionalRequestBodyAsJSON |
    public func setOptionalRequestBodyAsJSON<T: Encodable>(
        _ value: T?,
        headerFields: inout [HeaderField],
        contentType: String
    ) throws -> Data? {
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
        headerFields: inout [HeaderField],
        contentType: String
    ) throws -> Data {
        try setRequiredRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertBodyCodableToJSON
        )
    }

    //    | client | set | request body | binary | optional | setOptionalRequestBodyAsBinary |
    public func setOptionalRequestBodyAsBinary(
        _ value: Data?,
        headerFields: inout [HeaderField],
        contentType: String
    ) throws -> Data? {
        try setOptionalRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertDataToBinary
        )
    }

    //    | client | set | request body | binary | required | setRequiredRequestBodyAsBinary |
    public func setRequiredRequestBodyAsBinary(
        _ value: Data,
        headerFields: inout [HeaderField],
        contentType: String
    ) throws -> Data {
        try setRequiredRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertDataToBinary
        )
    }

    //    | client | set | request body | urlEncodedForm | codable | optional | setOptionalRequestBodyAsURLEncodedForm |
    public func setOptionalRequestBodyAsURLEncodedForm<T: Encodable>(
        _ value: T,
        headerFields: inout [HeaderField],
        contentType: String
    ) throws -> Data? {
        try setOptionalRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertBodyCodableToURLFormData
        )
    }

    //    | client | set | request body | urlEncodedForm | codable | required | setRequiredRequestBodyAsURLEncodedForm |
    public func setRequiredRequestBodyAsURLEncodedForm<T: Encodable>(
        _ value: T,
        headerFields: inout [HeaderField],
        contentType: String
    ) throws -> Data {
        try setRequiredRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertBodyCodableToURLFormData
        )
    }

    //    | client | get | response body | string | required | getResponseBodyAsString |
    public func getResponseBodyAsString<T: Decodable, C>(
        _ type: T.Type,
        from data: Data,
        transforming transform: (T) -> C
    ) throws -> C {
        try getResponseBody(
            type,
            from: data,
            transforming: transform,
            convert: convertFromStringData
        )
    }

    //    | client | get | response body | JSON | required | getResponseBodyAsJSON |
    public func getResponseBodyAsJSON<T: Decodable, C>(
        _ type: T.Type,
        from data: Data,
        transforming transform: (T) -> C
    ) throws -> C {
        try getResponseBody(
            type,
            from: data,
            transforming: transform,
            convert: convertJSONToBodyCodable
        )
    }

    //    | client | get | response body | binary | required | getResponseBodyAsBinary |
    public func getResponseBodyAsBinary<C>(
        _ type: Data.Type,
        from data: Data,
        transforming transform: (Data) -> C
    ) throws -> C {
        try getResponseBody(
            type,
            from: data,
            transforming: transform,
            convert: convertBinaryToData
        )
    }
}
