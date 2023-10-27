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

    /// Returns the MIME type from the content-type header, if present.
    /// - Parameter headerFields: The header fields to inspect for the content
    /// type header.
    /// - Returns: The content type value, or nil if not found or invalid.
    public func extractContentTypeIfPresent(in headerFields: HTTPFields) -> OpenAPIMIMEType? {
        guard let rawValue = headerFields[.contentType] else {
            return nil
        }
        return OpenAPIMIMEType(rawValue)
    }

    /// Chooses the most appropriate content type for the provided received
    /// content type and a list of options.
    /// - Parameters:
    ///   - received: The received content type.
    ///   - options: The options to match against.
    /// - Returns: The most appropriate option.
    /// - Throws: If none of the options match the received content type.
    /// - Precondition: `options` must not be empty.
    public func bestContentType(
        received: OpenAPIMIMEType?,
        options: [String]
    ) throws -> String {
        precondition(!options.isEmpty, "bestContentType options must not be empty.")
        guard
            let received,
            case let .concrete(type: receivedType, subtype: receivedSubtype) = received.kind
        else {
            // If none received or if we received a wildcard, use the first one.
            // This behavior isn't well defined by the OpenAPI specification.
            // Note: We treat a partial wildcard, like `image/*` as a full
            // wildcard `*/*`, but that's okay because for a concrete received
            // content type the behavior of a wildcard is not clearly defined
            // either.
            return options[0]
        }
        let evaluatedOptions = try options.map { stringOption in
            guard let parsedOption = OpenAPIMIMEType(stringOption) else {
                throw RuntimeError.invalidExpectedContentType(stringOption)
            }
            let match = OpenAPIMIMEType.evaluate(
                receivedType: receivedType,
                receivedSubtype: receivedSubtype,
                receivedParameters: received.parameters,
                against: parsedOption
            )
            return (contentType: stringOption, match: match)
        }
        let sortedOptions = evaluatedOptions.sorted { a, b in
            a.match.score > b.match.score
        }
        let bestOption = sortedOptions[0]
        let bestContentType = bestOption.contentType
        if case .incompatible = bestOption.match {
            throw RuntimeError.unexpectedContentTypeHeader(bestContentType)
        }
        return bestContentType
    }

    // MARK: - Converter helper methods

    /// Sets a header field with an optional value, encoding it as a URI component if not nil.
    ///
    /// - Parameters:
    ///   - headerFields: The HTTP header fields dictionary where the field will be set.
    ///   - name: The name of the header field.
    ///   - value: The optional value to be encoded as a URI component if not nil.
    /// - Throws: An error if there's an issue with encoding the value as a URI component.
    public func setHeaderFieldAsURI<T: Encodable>(
        in headerFields: inout HTTPFields,
        name: String,
        value: T?
    ) throws {
        guard let value else {
            return
        }
        try setHeaderField(
            in: &headerFields,
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

    /// Sets a header field with an optional value, encoding it as a JSON component if not nil.
    ///
    /// - Parameters:
    ///   - headerFields: The HTTP header fields dictionary where the field will be set.
    ///   - name: The name of the header field.
    ///   - value: The optional value to be encoded as a JSON component if not nil.
    /// - Throws: An error if there's an issue with encoding the value as a JSON component.
    public func setHeaderFieldAsJSON<T: Encodable>(
        in headerFields: inout HTTPFields,
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

    /// Attempts to retrieve an optional header field value and decodes it as a URI component, returning it as the specified type.
    ///
    /// - Parameters:
    ///   - headerFields: The HTTP header fields dictionary where the field is expected.
    ///   - name: The name of the header field to retrieve.
    ///   - type: The expected type of the decoded value.
    /// - Returns: The decoded header field value as the specified type, or `nil` if the field is not present.
    /// - Throws: An error if there's an issue with decoding the URI component or
    /// if the field is present but cannot be decoded as the specified type.
    public func getOptionalHeaderFieldAsURI<T: Decodable>(
        in headerFields: HTTPFields,
        name: String,
        as type: T.Type
    ) throws -> T? {
        try getOptionalHeaderField(
            in: headerFields,
            name: name,
            as: type,
            convert: { encodedValue in
                try convertFromURI(
                    style: .simple,
                    explode: false,
                    inBody: false,
                    key: "",
                    encodedValue: encodedValue
                )
            }
        )
    }

    /// Attempts to retrieve a required header field value and decodes it as a URI component, returning it as the specified type.
    ///
    /// - Parameters:
    ///   - headerFields: The HTTP header fields dictionary where the field is expected.
    ///   - name: The name of the header field to retrieve.
    ///   - type: The expected type of the decoded value.
    /// - Returns: The decoded header field value as the specified type.
    /// - Throws: An error if the field is not present or if there's an issue with decoding the URI component or
    ///  if the field is present but cannot be decoded as the specified type.
    public func getRequiredHeaderFieldAsURI<T: Decodable>(
        in headerFields: HTTPFields,
        name: String,
        as type: T.Type
    ) throws -> T {
        try getRequiredHeaderField(
            in: headerFields,
            name: name,
            as: type,
            convert: { encodedValue in
                try convertFromURI(
                    style: .simple,
                    explode: false,
                    inBody: false,
                    key: "",
                    encodedValue: encodedValue
                )
            }
        )
    }

    /// Attempts to retrieve an optional header field value and decodes it as JSON, returning it as the specified type.
    ///
    /// - Parameters:
    ///   - headerFields: The HTTP header fields dictionary where the field is expected.
    ///   - name: The name of the header field to retrieve.
    ///   - type: The expected type of the decoded value.
    /// - Returns: The decoded header field value as the specified type, or
    /// `nil` if the field is not present in the headerFields dictionary.
    /// - Throws: An error if there's an issue with decoding the JSON value or if the field is present but cannot be decoded as the specified type.
    public func getOptionalHeaderFieldAsJSON<T: Decodable>(
        in headerFields: HTTPFields,
        name: String,
        as type: T.Type
    ) throws -> T? {
        try getOptionalHeaderField(
            in: headerFields,
            name: name,
            as: type,
            convert: convertJSONToHeaderFieldCodable
        )
    }

    /// Retrieves a required header field value and decodes it as JSON, returning it as the specified type.
    ///
    /// - Parameters:
    ///   - headerFields: The HTTP header fields dictionary where the field is expected.
    ///   - name: The name of the header field to retrieve.
    ///   - type: The expected type of the decoded value.
    /// - Returns: The decoded header field value as the specified type.
    /// - Throws: An error if the field is not present in the headerFields dictionary, if there's an issue with decoding the JSON value,
    ///  or if the field cannot be decoded as the specified type.
    public func getRequiredHeaderFieldAsJSON<T: Decodable>(
        in headerFields: HTTPFields,
        name: String,
        as type: T.Type
    ) throws -> T {
        try getRequiredHeaderField(
            in: headerFields,
            name: name,
            as: type,
            convert: convertJSONToHeaderFieldCodable
        )
    }
}
