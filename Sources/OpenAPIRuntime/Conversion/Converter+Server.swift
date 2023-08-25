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

    /// Returns the "accept" header parsed into individual content types.
    /// - Parameter headerFields: The header fields to inspect for an "accept"
    ///   header.
    /// - Returns: The parsed content types, or the default content types if
    ///   the header was not provided.
    public func extractAcceptHeaderIfPresent<T: AcceptableProtocol>(
        in headerFields: [HeaderField]
    ) throws -> [AcceptHeaderContentType<T>] {
        guard let rawValue = headerFields.firstValue(name: "accept") else {
            return AcceptHeaderContentType<T>.defaultValues
        }
        let rawComponents =
            rawValue
            .split(separator: ",")
            .map(String.init)
            .map(\.trimmingLeadingAndTrailingSpaces)
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
    public func validateAcceptIfPresent(
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

    //    | server | get | request path | uri | codable | required | getPathParameterAsURI |
    public func getPathParameterAsURI<T: Decodable>(
        in pathParameters: [String: String],
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
                let value = try decoder.decode(
                    T.self,
                    forKey: name,
                    from: encodedString
                )
                return value
            }
        )
    }

    //    | server | get | request query | uri | codable | optional | getOptionalQueryItemAsURI |
    public func getOptionalQueryItemAsURI<T: Decodable>(
        in query: String?,
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
                let value = try decoder.decode(
                    T.self,
                    forKey: name,
                    from: query
                )
                return value
            }
        )
    }

    //    | server | get | request query | uri | codable | required | getRequiredQueryItemAsURI |
    public func getRequiredQueryItemAsText<T: Decodable>(
        in query: String?,
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
                let value = try decoder.decode(
                    T.self,
                    forKey: name,
                    from: query
                )
                return value
            }
        )
    }

    //    | server | get | request body | text | string-convertible | optional | getOptionalRequestBodyAsText |
    @available(*, deprecated)
    public func getOptionalRequestBodyAsText<T: _StringConvertible, C>(
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
    @available(*, deprecated)
    public func getRequiredRequestBodyAsText<T: _StringConvertible, C>(
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
    @available(*, deprecated)
    public func getOptionalRequestBodyAsText<C>(
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
    @available(*, deprecated)
    public func getRequiredRequestBodyAsText<C>(
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
    public func getOptionalRequestBodyAsJSON<T: Decodable, C>(
        _ type: T.Type,
        from data: Data?,
        transforming transform: (T) -> C
    ) throws -> C? {
        try getOptionalRequestBody(
            type,
            from: data,
            transforming: transform,
            convert: convertJSONToBodyCodable
        )
    }

    //    | server | get | request body | JSON | codable | required | getRequiredRequestBodyAsJSON |
    public func getRequiredRequestBodyAsJSON<T: Decodable, C>(
        _ type: T.Type,
        from data: Data?,
        transforming transform: (T) -> C
    ) throws -> C {
        try getRequiredRequestBody(
            type,
            from: data,
            transforming: transform,
            convert: convertJSONToBodyCodable
        )
    }

    //    | server | get | request body | binary | data | optional | getOptionalRequestBodyAsBinary |
    public func getOptionalRequestBodyAsBinary<C>(
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
    public func getRequiredRequestBodyAsBinary<C>(
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
    @available(*, deprecated)
    public func setResponseBodyAsText<T: _StringConvertible>(
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
    @available(*, deprecated)
    public func setResponseBodyAsText(
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
    public func setResponseBodyAsJSON<T: Encodable>(
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
    public func setResponseBodyAsBinary(
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
