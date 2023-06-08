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

    // MARK: Miscs

    /// Validates that the Content-Type header field (if present)
    /// is compatible with the provided content-type substring.
    ///
    /// Succeeds if no Content-Type header is found in the response headers.
    ///
    /// - Parameters:
    ///   - headerFields: Header fields to inspect for a content type.
    ///   - substring: Expected content type.
    /// - Throws: If the response's Content-Type value is not compatible with the provided substring.
    public func validateContentTypeIfPresent(
        in headerFields: [HeaderField],
        substring: String
    ) throws {
        guard
            let contentType = try getOptionalHeaderFieldAsText(
                in: headerFields,
                name: "content-type",
                as: String.self
            )
        else {
            return
        }
        guard contentType.localizedCaseInsensitiveContains(substring) else {
            throw RuntimeError.unexpectedContentTypeHeader(contentType)
        }
    }

    // MARK: - Converter helper methods

    //    | common | set | header field | text | string-convertible | both | setHeaderFieldAsText |
    public func setHeaderFieldAsText<T: _StringConvertible>(
        in headerFields: inout [HeaderField],
        name: String,
        value: T?
    ) throws {
        try setHeaderField(
            in: &headerFields,
            name: name,
            value: value,
            convert: convertStringConvertibleToText
        )
    }

    //    | common | set | header field | text | array of string-convertibles | both | setHeaderFieldAsText |
    public func setHeaderFieldAsText<T: _StringConvertible>(
        in headerFields: inout [HeaderField],
        name: String,
        value values: [T]?
    ) throws {
        try setHeaderFields(
            in: &headerFields,
            name: name,
            values: values,
            convert: convertStringConvertibleToText
        )
    }

    //    | common | set | header field | text | date | both | setHeaderFieldAsText |
    public func setHeaderFieldAsText(
        in headerFields: inout [HeaderField],
        name: String,
        value: Date?
    ) throws {
        try setHeaderField(
            in: &headerFields,
            name: name,
            value: value,
            convert: convertDateToText
        )
    }

    //    | common | set | header field | text | array of dates | both | setHeaderFieldAsText |
    public func setHeaderFieldAsText(
        in headerFields: inout [HeaderField],
        name: String,
        value values: [Date]?
    ) throws {
        try setHeaderFields(
            in: &headerFields,
            name: name,
            values: values,
            convert: convertDateToText
        )
    }

    //    | common | set | header field | JSON | codable | both | setHeaderFieldAsJSON |
    public func setHeaderFieldAsJSON<T: Encodable>(
        in headerFields: inout [HeaderField],
        name: String,
        value: T?
    ) throws {
        try setHeaderField(
            in: &headerFields,
            name: name,
            value: value,
            convert: convertHeaderFieldCodableToJSON
        )
    }

    //    | common | get | header field | text | string-convertible | optional | getOptionalHeaderFieldAsText |
    public func getOptionalHeaderFieldAsText<T: _StringConvertible>(
        in headerFields: [HeaderField],
        name: String,
        as type: T.Type
    ) throws -> T? {
        try getOptionalHeaderField(
            in: headerFields,
            name: name,
            as: type,
            convert: convertTextToStringConvertible
        )
    }

    //    | common | get | header field | text | string-convertible | required | getRequiredHeaderFieldAsText |
    public func getRequiredHeaderFieldAsText<T: _StringConvertible>(
        in headerFields: [HeaderField],
        name: String,
        as type: T.Type
    ) throws -> T {
        try getRequiredHeaderField(
            in: headerFields,
            name: name,
            as: type,
            convert: convertTextToStringConvertible
        )
    }

    //    | common | get | header field | text | array of string-convertibles | optional | getOptionalHeaderFieldAsText |
    public func getOptionalHeaderFieldAsText<T: _StringConvertible>(
        in headerFields: [HeaderField],
        name: String,
        as type: [T].Type
    ) throws -> [T]? {
        try getOptionalHeaderFields(
            in: headerFields,
            name: name,
            as: type,
            convert: convertTextToStringConvertible
        )
    }

    //    | common | get | header field | text | array of string-convertibles | required | getRequiredHeaderFieldAsText |
    public func getRequiredHeaderFieldAsText<T: _StringConvertible>(
        in headerFields: [HeaderField],
        name: String,
        as type: [T].Type
    ) throws -> [T]? {
        try getRequiredHeaderFields(
            in: headerFields,
            name: name,
            as: type,
            convert: convertTextToStringConvertible
        )
    }

    //    | common | get | header field | text | date | optional | getOptionalHeaderFieldAsText |
    public func getOptionalHeaderFieldAsText(
        in headerFields: [HeaderField],
        name: String,
        as type: Date.Type
    ) throws -> Date? {
        try getOptionalHeaderField(
            in: headerFields,
            name: name,
            as: type,
            convert: convertHeaderFieldTextToDate
        )
    }

    //    | common | get | header field | text | date | required | getRequiredHeaderFieldAsText |
    public func getRequiredHeaderFieldAsText(
        in headerFields: [HeaderField],
        name: String,
        as type: Date.Type
    ) throws -> Date {
        try getRequiredHeaderField(
            in: headerFields,
            name: name,
            as: type,
            convert: convertHeaderFieldTextToDate
        )
    }

    //    | common | get | header field | text | array of dates | optional | getOptionalHeaderFieldAsText |
    public func getOptionalHeaderFieldAsText(
        in headerFields: [HeaderField],
        name: String,
        as type: [Date].Type
    ) throws -> [Date]? {
        try getOptionalHeaderFields(
            in: headerFields,
            name: name,
            as: type,
            convert: convertHeaderFieldTextToDate
        )
    }

    //    | common | get | header field | text | array of dates | required | getRequiredHeaderFieldAsText |
    public func getRequiredHeaderFieldAsText(
        in headerFields: [HeaderField],
        name: String,
        as type: [Date].Type
    ) throws -> [Date]? {
        try getRequiredHeaderFields(
            in: headerFields,
            name: name,
            as: type,
            convert: convertHeaderFieldTextToDate
        )
    }

    //    | common | get | header field | JSON | codable | optional | getOptionalHeaderFieldAsJSON |
    public func getOptionalHeaderFieldAsJSON<T: Decodable>(
        in headerFields: [HeaderField],
        name: String,
        as type: T.Type
    ) throws -> T? {
        try getOptionalHeaderField(
            in: headerFields,
            name: name,
            as: type,
            convert: convertHeaderFieldJSONToCodable
        )
    }

    //    | common | get | header field | JSON | codable | required | getRequiredHeaderFieldAsJSON |
    public func getRequiredHeaderFieldAsJSON<T: Decodable>(
        in headerFields: [HeaderField],
        name: String,
        as type: T.Type
    ) throws -> T {
        try getRequiredHeaderField(
            in: headerFields,
            name: name,
            as: type,
            convert: convertHeaderFieldJSONToCodable
        )
    }
}
