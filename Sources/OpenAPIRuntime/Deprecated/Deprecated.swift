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

// MARK: - Functionality to be removed in the future

extension ClientError {
    /// Creates a new error.
    /// - Parameters:
    ///   - operationID: The OpenAPI operation identifier.
    ///   - operationInput: The operation-specific Input value.
    ///   - request: The HTTP request created during the operation.
    ///   - requestBody: The HTTP request body created during the operation.
    ///   - baseURL: The base URL for HTTP requests.
    ///   - response: The HTTP response received during the operation.
    ///   - responseBody: The HTTP response body received during the operation.
    ///   - underlyingError: The underlying error that caused the operation
    ///     to fail.
    @available(
        *,
        deprecated,
        renamed:
            "ClientError.init(operationID:operationInput:request:requestBody:baseURL:response:responseBody:causeDescription:underlyingError:)",
        message: "Use the initializer with a causeDescription parameter."
    ) public init(
        operationID: String,
        operationInput: any Sendable,
        request: HTTPRequest? = nil,
        requestBody: HTTPBody? = nil,
        baseURL: URL? = nil,
        response: HTTPResponse? = nil,
        responseBody: HTTPBody? = nil,
        underlyingError: any Error
    ) {
        self.init(
            operationID: operationID,
            operationInput: operationInput,
            request: request,
            requestBody: requestBody,
            baseURL: baseURL,
            response: response,
            responseBody: responseBody,
            causeDescription: "Legacy error without a causeDescription.",
            underlyingError: underlyingError
        )
    }
}

extension ServerError {
    /// Creates a new error.
    /// - Parameters:
    ///   - operationID: The OpenAPI operation identifier.
    ///   - request: The HTTP request provided to the server.
    ///   - requestBody: The HTTP request body provided to the server.
    ///   - requestMetadata: The request metadata extracted by the server.
    ///   - operationInput: An operation-specific Input value.
    ///   - operationOutput: An operation-specific Output value.
    ///   - underlyingError: The underlying error that caused the operation
    ///     to fail.
    @available(
        *,
        deprecated,
        renamed:
            "ServerError.init(operationID:request:requestBody:requestMetadata:operationInput:operationOutput:causeDescription:underlyingError:)",
        message: "Use the initializer with a causeDescription parameter."
    ) public init(
        operationID: String,
        request: HTTPRequest,
        requestBody: HTTPBody?,
        requestMetadata: ServerRequestMetadata,
        operationInput: (any Sendable)? = nil,
        operationOutput: (any Sendable)? = nil,
        underlyingError: any Error
    ) {
        self.init(
            operationID: operationID,
            request: request,
            requestBody: requestBody,
            requestMetadata: requestMetadata,
            operationInput: operationInput,
            operationOutput: operationOutput,
            causeDescription: "Legacy error without a causeDescription.",
            underlyingError: underlyingError
        )
    }
}

extension Converter {
    /// Returns an error to be thrown when an unexpected content type is
    /// received.
    /// - Parameter contentType: The content type that was received.
    /// - Returns: An error representing an unexpected content type.
    @available(*, deprecated) public func makeUnexpectedContentTypeError(contentType: OpenAPIMIMEType?) -> any Error {
        RuntimeError.unexpectedContentTypeHeader(contentType?.description ?? "")
    }

    /// Checks whether a concrete content type matches an expected content type.
    ///
    /// The concrete content type can contain parameters, such as `charset`, but
    /// they are ignored in the equality comparison.
    ///
    /// The expected content type can contain wildcards, such as */* and text/*.
    /// - Parameters:
    ///   - received: The concrete content type to validate against the other.
    ///   - expectedRaw: The expected content type, can contain wildcards.
    /// - Throws: A `RuntimeError` when `expectedRaw` is not a valid content type.
    /// - Returns: A Boolean value representing whether the concrete content
    /// type matches the expected one.
    @available(*, deprecated) public func isMatchingContentType(received: OpenAPIMIMEType?, expectedRaw: String) throws
        -> Bool
    {
        guard let received else { return false }
        guard case let .concrete(type: receivedType, subtype: receivedSubtype) = received.kind else { return false }
        guard let expectedContentType = OpenAPIMIMEType(expectedRaw) else {
            throw RuntimeError.invalidExpectedContentType(expectedRaw)
        }
        switch expectedContentType.kind {
        case .any: return true
        case .anySubtype(let expectedType): return receivedType.lowercased() == expectedType.lowercased()
        case .concrete(let expectedType, let expectedSubtype):
            return receivedType.lowercased() == expectedType.lowercased()
                && receivedSubtype.lowercased() == expectedSubtype.lowercased()
        }
    }
}

extension DecodingError {
    /// Returns a decoding error used by the oneOf decoder when not a single
    /// child schema decodes the received payload.
    /// - Parameters:
    ///   - type: The type representing the oneOf schema in which the decoding
    ///   occurred.
    ///   - codingPath: The coding path to the decoder that attempted to decode
    ///   the type.
    /// - Returns: A decoding error.
    @_spi(Generated) @available(*, deprecated) public static func failedToDecodeOneOfSchema(
        type: Any.Type,
        codingPath: [any CodingKey]
    ) -> Self {
        DecodingError.valueNotFound(
            type,
            DecodingError.Context.init(
                codingPath: codingPath,
                debugDescription: "The oneOf structure did not decode into any child schema."
            )
        )
    }

    /// Returns a decoding error used by the anyOf decoder when not a single
    /// child schema decodes the received payload.
    /// - Parameters:
    ///   - type: The type representing the anyOf schema in which the decoding
    ///   occurred.
    ///   - codingPath: The coding path to the decoder that attempted to decode
    ///   the type.
    /// - Returns: A decoding error.
    @available(*, deprecated) static func failedToDecodeAnySchema(type: Any.Type, codingPath: [any CodingKey]) -> Self {
        DecodingError.valueNotFound(
            type,
            DecodingError.Context.init(
                codingPath: codingPath,
                debugDescription: "The anyOf structure did not decode into any child schema."
            )
        )
    }

    /// Verifies that the anyOf decoder successfully decoded at least one
    /// child schema, and throws an error otherwise.
    /// - Parameters:
    ///   - values: An array of optional values to check.
    ///   - type: The type representing the anyOf schema in which the decoding
    ///   occurred.
    ///   - codingPath: The coding path to the decoder that attempted to decode
    ///   the type.
    /// - Throws: An error of type `DecodingError.failedToDecodeAnySchema` if none of the child schemas were successfully decoded.
    @_spi(Generated) @available(*, deprecated) public static func verifyAtLeastOneSchemaIsNotNil(
        _ values: [Any?],
        type: Any.Type,
        codingPath: [any CodingKey]
    ) throws {
        guard values.contains(where: { $0 != nil }) else {
            throw DecodingError.failedToDecodeAnySchema(type: type, codingPath: codingPath)
        }
    }
}

extension Configuration {
    /// Creates a new configuration with the specified values.
    ///
    /// - Parameter dateTranscoder: The transcoder to use when converting between date
    ///   and string values.
    @available(*, deprecated, renamed: "init(dateTranscoder:multipartBoundaryGenerator:)") @_disfavoredOverload
    public init(dateTranscoder: any DateTranscoder) {
        self.init(dateTranscoder: dateTranscoder, multipartBoundaryGenerator: .random)
    }
}

extension HTTPBody {
    /// Describes how many times the provided sequence can be iterated.
    @available(
        *,
        deprecated,
        renamed: "IterationBehavior",
        message: "Use the top level IterationBehavior directly instead of HTTPBody.IterationBehavior."
    ) public typealias IterationBehavior = OpenAPIRuntime.IterationBehavior
}
