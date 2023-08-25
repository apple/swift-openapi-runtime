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

    //    | client | set | request path | uri | codable | required | renderedPath |
    public func renderedPath(
        template: String,
        parameters: [any Encodable]
    ) throws -> String {
        var renderedString = template
        let encoder = URIEncoder(configuration: .simpleUnexplode)
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

    //    | client | set | request query | uri | codable | both | setQueryItemAsURI |
    public func setQueryItemAsURI<T: Encodable>(
        in request: inout Request,
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        value: T?
    ) throws {
        try setQueryItem(
            in: &request,
            style: style,
            explode: explode,
            name: name,
            value: value,
            convert: { value in
                try convertToURI(
                    style: .simple,
                    explode: false,
                    inBody: false,
                    key: "",
                    value: value
                )
            }
        )
    }

    //    | client | set | request body | string | codable | optional | setOptionalRequestBodyAsString |
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

    //    | client | set | request body | string | codable | required | setRequiredRequestBodyAsString |
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

    //    | client | set | request body | JSON | codable | optional | setOptionalRequestBodyAsJSON |
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

    //    | client | set | request body | JSON | codable | required | setRequiredRequestBodyAsJSON |
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

    //    | client | set | request body | binary | data | optional | setOptionalRequestBodyAsBinary |
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

    //    | client | set | request body | binary | data | required | setRequiredRequestBodyAsBinary |
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

    //    | client | get | response body | string | codable | required | getResponseBodyAsString |
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

    //    | client | get | response body | JSON | codable | required | getResponseBodyAsJSON |
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

    //    | client | get | response body | binary | data | required | getResponseBodyAsBinary |
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
