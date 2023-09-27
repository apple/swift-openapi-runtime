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
    public func extractAcceptHeaderIfPresent<T: AcceptableProtocol>(
        in headerFields: HTTPFields
    ) throws -> [AcceptHeaderContentType<T>] {
        guard let rawValue = headerFields[.accept] else {
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
        in headerFields: HTTPFields
    ) throws {
        // for example: text/html, application/xhtml+xml, application/xml;q=0.9, */*;q=0.8
        guard let acceptHeader = headerFields[.accept] else {
            return
        }

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

    //    | server | get | request path | URI | required | getPathParameterAsURI |
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
                let value = try decoder.decode(
                    T.self,
                    forKey: name,
                    from: encodedString
                )
                return value
            }
        )
    }

    //    | server | get | request query | URI | optional | getOptionalQueryItemAsURI |
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
                let value = try decoder.decodeIfPresent(
                    T.self,
                    forKey: name,
                    from: query
                )
                return value
            }
        )
    }

    //    | server | get | request query | URI | required | getRequiredQueryItemAsURI |
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
                let value = try decoder.decode(
                    T.self,
                    forKey: name,
                    from: query
                )
                return value
            }
        )
    }

    //    | server | get | request body | JSON | optional | getOptionalRequestBodyAsJSON |
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

    //    | server | get | request body | JSON | required | getRequiredRequestBodyAsJSON |
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

    //    | server | get | request body | binary | optional | getOptionalRequestBodyAsBinary |
    public func getOptionalRequestBodyAsBinary<C>(
        _ type: HTTPBody.Type,
        from data: HTTPBody?,
        transforming transform: (HTTPBody) -> C
    ) throws -> C? {
        try getOptionalRequestBody(
            type,
            from: data,
            transforming: transform,
            convert: { $0 }
        )
    }

    //    | server | get | request body | binary | required | getRequiredRequestBodyAsBinary |
    public func getRequiredRequestBodyAsBinary<C>(
        _ type: HTTPBody.Type,
        from data: HTTPBody?,
        transforming transform: (HTTPBody) -> C
    ) throws -> C {
        try getRequiredRequestBody(
            type,
            from: data,
            transforming: transform,
            convert: { $0 }
        )
    }

    //    | server | get | request body | URLEncodedForm | codable | optional | getOptionalRequestBodyAsURLEncodedForm |
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

    //    | server | get | request body | URLEncodedForm | codable | required | getRequiredRequestBodyAsURLEncodedForm |
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

    //    | server | set | response body | JSON | required | setResponseBodyAsJSON |
    public func setResponseBodyAsJSON<T: Encodable>(
        _ value: T,
        headerFields: inout HTTPFields,
        contentType: String
    ) throws -> HTTPBody {
        try setResponseBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: convertBodyCodableToJSON
        )
    }

    //    | server | set | response body | binary | required | setResponseBodyAsBinary |
    public func setResponseBodyAsBinary(
        _ value: HTTPBody,
        headerFields: inout HTTPFields,
        contentType: String
    ) throws -> HTTPBody {
        try setResponseBody(
            value,
            headerFields: &headerFields,
            contentType: contentType,
            convert: { $0 }
        )
    }
}
