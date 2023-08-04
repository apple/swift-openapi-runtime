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

public extension Converter {

    // MARK: Miscs

    /// Validates that the Accept header in the provided response
    /// is compatible with the provided content type substring.
    /// - Parameters:
    ///   - substring: Expected content type, for example "application/json".
    ///   - headerFields: Header fields in which to look for "Accept".
    ///   Also supports wildcars, such as "application/\*" and "\*/\*".
    func validateAcceptIfPresent(
        _ substring: String,
        in headerFields: [HeaderField]
    ) throws {
        // for example: text/html, application/xhtml+xml, application/xml;q=0.9, */*;q=0.8
        let acceptHeader = headerFields.values(name: "accept").joined(separator: ", ")

        // Split with commas to get the individual values
        let acceptValues =
            acceptHeader
            .split(separator: ",")
            .map { value in
                // Drop everything after the optional semicolon (q, extensions, ...)
                value
                    .split(separator: ";")[0]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
            }

        if acceptValues.isEmpty {
            return
        }
        if acceptValues.contains("*/*") {
            return
        }
        if acceptValues.contains("\(substring.split(separator: "/")[0].lowercased())/*") {
            return
        }
        if acceptValues.contains(where: { $0.localizedCaseInsensitiveContains(substring) }) {
            return
        }
        throw RuntimeError.unexpectedAcceptHeader(acceptHeader)
    }

    //    | server | get | request path | text | string-convertible | required | getPathParameterAsText |
    func getPathParameterAsText<T: _StringConvertible>(
        in pathParameters: [String: String],
        name: String,
        as type: T.Type
    ) throws -> T {
        try getRequiredRequestPath(
            in: pathParameters,
            name: name,
            as: type,
            convert: convertTextToStringConvertible
        )
    }

    //    | server | get | request query | text | string-convertible | optional | getOptionalQueryItemAsText |
    func getOptionalQueryItemAsText<T: _StringConvertible>(
        in queryParameters: [URLQueryItem],
        style: ParameterStyle? = nil,
        explode: Bool? = nil,
        name: String,
        as type: T.Type
    ) throws -> T? {
        try getOptionalQueryItem(
            in: queryParameters,
            style: style,
            explode: explode,
            name: name,
            as: type,
            convert: convertTextToStringConvertible
        )
    }

    //    | server | get | request query | text | string-convertible | required | getRequiredQueryItemAsText |
    func getRequiredQueryItemAsText<T: _StringConvertible>(
        in queryParameters: [URLQueryItem],
        style: ParameterStyle? = nil,
        explode: Bool? = nil,
        name: String,
        as type: T.Type
    ) throws -> T {
        try getRequiredQueryItem(
            in: queryParameters,
            style: style,
            explode: explode,
            name: name,
            as: type,
            convert: convertTextToStringConvertible
        )
    }

    //    | server | get | request query | text | array of string-convertibles | optional | getOptionalQueryItemAsText |
    func getOptionalQueryItemAsText<T: _StringConvertible>(
        in queryParameters: [URLQueryItem],
        style: ParameterStyle? = nil,
        explode: Bool? = nil,
        name: String,
        as type: [T].Type
    ) throws -> [T]? {
        try getOptionalQueryItems(
            in: queryParameters,
            style: style,
            explode: explode,
            name: name,
            as: type,
            convert: convertTextToStringConvertible
        )
    }

    //    | server | get | request query | text | array of string-convertibles | required | getRequiredQueryItemAsText |
    func getRequiredQueryItemAsText<T: _StringConvertible>(
        in queryParameters: [URLQueryItem],
        style: ParameterStyle? = nil,
        explode: Bool? = nil,
        name: String,
        as type: [T].Type
    ) throws -> [T] {
        try getRequiredQueryItems(
            in: queryParameters,
            style: style,
            explode: explode,
            name: name,
            as: type,
            convert: convertTextToStringConvertible
        )
    }

    //    | server | get | request query | text | date | optional | getOptionalQueryItemAsText |
    func getOptionalQueryItemAsText(
        in queryParameters: [URLQueryItem],
        style: ParameterStyle? = nil,
        explode: Bool? = nil,
        name: String,
        as type: Date.Type
    ) throws -> Date? {
        try getOptionalQueryItem(
            in: queryParameters,
            style: style,
            explode: explode,
            name: name,
            as: type,
            convert: convertTextToDate
        )
    }

    //    | server | get | request query | text | date | required | getRequiredQueryItemAsText |
    func getRequiredQueryItemAsText(
        in queryParameters: [URLQueryItem],
        style: ParameterStyle? = nil,
        explode: Bool? = nil,
        name: String,
        as type: Date.Type
    ) throws -> Date {
        try getRequiredQueryItem(
            in: queryParameters,
            style: style,
            explode: explode,
            name: name,
            as: type,
            convert: convertTextToDate
        )
    }

    //    | server | get | request query | text | array of dates | optional | getOptionalQueryItemAsText |
    func getOptionalQueryItemAsText(
        in queryParameters: [URLQueryItem],
        style: ParameterStyle? = nil,
        explode: Bool? = nil,
        name: String,
        as type: [Date].Type
    ) throws -> [Date]? {
        try getOptionalQueryItems(
            in: queryParameters,
            style: style,
            explode: explode,
            name: name,
            as: type,
            convert: convertTextToDate
        )
    }

    //    | server | get | request query | text | array of dates | required | getRequiredQueryItemAsText |
    func getRequiredQueryItemAsText(
        in queryParameters: [URLQueryItem],
        style: ParameterStyle? = nil,
        explode: Bool? = nil,
        name: String,
        as type: [Date].Type
    ) throws -> [Date] {
        try getRequiredQueryItems(
            in: queryParameters,
            style: style,
            explode: explode,
            name: name,
            as: type,
            convert: convertTextToDate
        )
    }

    //    | server | get | request body | text | string-convertible | optional | getOptionalRequestBodyAsText |
    func getOptionalRequestBodyAsText<T: _StringConvertible, C>(
        _ type: T.Type,
        from data: Data?,
        transforming transform: (T) -> C
    ) throws -> C? {
        try getOptionalRequestBody(
            type,
            from: data,
            transforming: transform,
            convert: convertTextDataToStringConvertible
        )
    }

    //    | server | get | request body | text | string-convertible | required | getRequiredRequestBodyAsText |
    func getRequiredRequestBodyAsText<T: _StringConvertible, C>(
        _ type: T.Type,
        from data: Data?,
        transforming transform: (T) -> C
    ) throws -> C {
        try getRequiredRequestBody(
            type,
            from: data,
            transforming: transform,
            convert: convertTextDataToStringConvertible
        )
    }

    //    | server | get | request body | text | date | optional | getOptionalRequestBodyAsText |
    func getOptionalRequestBodyAsText<C>(
        _ type: Date.Type,
        from data: Data?,
        transforming transform: (Date) -> C
    ) throws -> C? {
        try getOptionalRequestBody(
            type,
            from: data,
            transforming: transform,
            convert: convertTextDataToDate
        )
    }

    //    | server | get | request body | text | date | required | getRequiredRequestBodyAsText |
    func getRequiredRequestBodyAsText<C>(
        _ type: Date.Type,
        from data: Data?,
        transforming transform: (Date) -> C
    ) throws -> C {
        try getRequiredRequestBody(
            type,
            from: data,
            transforming: transform,
            convert: convertTextDataToDate
        )
    }

    //    | server | get | request body | JSON | codable | optional | getOptionalRequestBodyAsJSON |
    func getOptionalRequestBodyAsJSON<T: Decodable, C>(
        _ type: T.Type,
        from data: Data?,
        transforming transform: (T) -> C
    ) throws -> C? {
        try getOptionalRequestBody(
            type,
            from: data,
            transforming: transform,
            convert: convertJSONToCodable
        )
    }

    //    | server | get | request body | JSON | codable | required | getRequiredRequestBodyAsJSON |
    func getRequiredRequestBodyAsJSON<T: Decodable, C>(
        _ type: T.Type,
        from data: Data?,
        transforming transform: (T) -> C
    ) throws -> C {
        try getRequiredRequestBody(
            type,
            from: data,
            transforming: transform,
            convert: convertJSONToCodable
        )
    }

    //    | server | get | request body | binary | data | optional | getOptionalRequestBodyAsBinary |
    func getOptionalRequestBodyAsBinary<C>(
        _ type: Data.Type,
        from data: Data?,
        transforming transform: (Data) -> C
    ) throws -> C? {
        try getOptionalRequestBody(
            type,
            from: data,
            transforming: transform,
            convert: convertBinaryToData
        )
    }

    //    | server | get | request body | binary | data | required | getRequiredRequestBodyAsBinary |
    func getRequiredRequestBodyAsBinary<C>(
        _ type: Data.Type,
        from data: Data?,
        transforming transform: (Data) -> C
    ) throws -> C {
        try getRequiredRequestBody(
            type,
            from: data,
            transforming: transform,
            convert: convertBinaryToData
        )
    }

    //    | server | set | response body | text | string-convertible | required | setResponseBodyAsText |
    func setResponseBodyAsText<T: _StringConvertible>(
        _ value: T,
        headerFields: inout [HeaderField],
        contentType: String
    ) throws -> Data {
        try setResponseBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertStringConvertibleToTextData
        )
    }

    //    | server | set | response body | text | date | required | setResponseBodyAsText |
    func setResponseBodyAsText(
        _ value: Date,
        headerFields: inout [HeaderField],
        contentType: String
    ) throws -> Data {
        try setResponseBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertDateToTextData
        )
    }

    //    | server | set | response body | JSON | codable | required | setResponseBodyAsJSON |
    func setResponseBodyAsJSON<T: Encodable>(
        _ value: T,
        headerFields: inout [HeaderField],
        contentType: String
    ) throws -> Data {
        try setResponseBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertBodyCodableToJSON
        )
    }

    //    | server | set | response body | binary | data | required | setResponseBodyAsBinary |
    func setResponseBodyAsBinary(
        _ value: Data,
        headerFields: inout [HeaderField],
        contentType: String
    ) throws -> Data {
        try setResponseBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertDataToBinary
        )
    }
}
