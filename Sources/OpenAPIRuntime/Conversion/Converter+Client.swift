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

    //    | client | set | request path | text | string-convertible | required | renderedRequestPath |
    public func renderedRequestPath(
        template: String,
        parameters: [any _StringConvertible]
    ) throws -> String {
        var renderedString = template
        for parameter in parameters {
            if let range = renderedString.range(of: "{}") {
                renderedString = renderedString.replacingOccurrences(
                    of: "{}",
                    with: parameter.description,
                    range: range
                )
            }
        }
        return renderedString
    }

    //    | client | set | request query | text | string-convertible | both | setQueryItemAsText |
    public func setQueryItemAsText<T: _StringConvertible>(
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
            convert: convertStringConvertibleToText
        )
    }

    //    | client | set | request query | text | array of string-convertibles | both | setQueryItemAsText |
    public func setQueryItemAsText<T: _StringConvertible>(
        in request: inout Request,
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        value: [T]?
    ) throws {
        try setQueryItems(
            in: &request,
            style: style,
            explode: explode,
            name: name,
            values: value,
            convert: convertStringConvertibleToText
        )
    }

    //    | client | set | request query | text | date | both | setQueryItemAsText |
    public func setQueryItemAsText(
        in request: inout Request,
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        value: Date?
    ) throws {
        try setQueryItem(
            in: &request,
            style: style,
            explode: explode,
            name: name,
            value: value,
            convert: convertDateToText
        )
    }

    //    | client | set | request query | text | array of dates | both | setQueryItemAsText |
    public func setQueryItemAsText(
        in request: inout Request,
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        value: [Date]?
    ) throws {
        try setQueryItems(
            in: &request,
            style: style,
            explode: explode,
            name: name,
            values: value,
            convert: convertDateToText
        )
    }

    //    | client | set | request body | text | string-convertible | optional | setOptionalRequestBodyAsText |
    public func setOptionalRequestBodyAsText<T: _StringConvertible>(
        _ value: T?,
        headerFields: inout [HeaderField],
        contentType: String
    ) throws -> Data? {
        try setOptionalRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertStringConvertibleToTextData
        )
    }

    //    | client | set | request body | text | string-convertible | required | setRequiredRequestBodyAsText |
    public func setRequiredRequestBodyAsText<T: _StringConvertible>(
        _ value: T,
        headerFields: inout [HeaderField],
        contentType: String
    ) throws -> Data {
        try setRequiredRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertStringConvertibleToTextData
        )
    }

    //    | client | set | request body | text | date | optional | setOptionalRequestBodyAsText |
    public func setOptionalRequestBodyAsText(
        _ value: Date?,
        headerFields: inout [HeaderField],
        contentType: String
    ) throws -> Data? {
        try setOptionalRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertDateToTextData
        )
    }

    //    | client | set | request body | text | date | required | setRequiredRequestBodyAsText |
    public func setRequiredRequestBodyAsText(
        _ value: Date,
        headerFields: inout [HeaderField],
        contentType: String
    ) throws -> Data {
        try setRequiredRequestBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertDateToTextData
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

    //    | client | get | response body | text | string-convertible | required | getResponseBodyAsText |
    public func getResponseBodyAsText<T: _StringConvertible, C>(
        _ type: T.Type,
        from data: Data,
        transforming transform: (T) -> C
    ) throws -> C {
        try getResponseBody(
            type,
            from: data,
            transforming: transform,
            convert: convertTextDataToStringConvertible
        )
    }

    //    | client | get | response body | text | date | required | getResponseBodyAsText |
    public func getResponseBodyAsText<C>(
        _ type: Date.Type,
        from data: Data,
        transforming transform: (Date) -> C
    ) throws -> C {
        try getResponseBody(
            type,
            from: data,
            transforming: transform,
            convert: convertTextDataToDate
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
            convert: convertJSONToCodable
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
