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

public import Foundation
public import HTTPTypes

/// An error thrown by a server handling an OpenAPI operation.
public struct ServerError: Error, HTTPResponseConvertible {

    /// Identifier of the operation that threw the error.
    public var operationID: String

    /// The HTTP request provided to the server.
    public var request: HTTPRequest

    /// The HTTP request body provided to the server.
    public var requestBody: HTTPBody?

    /// The request metadata extracted by the server.
    public var requestMetadata: ServerRequestMetadata

    /// An operation-specific Input value.
    ///
    /// Is nil if error was thrown during request -> Input conversion.
    public var operationInput: (any Sendable)?

    /// An operation-specific Output value.
    ///
    /// Is nil if error was thrown before/during Output -> response conversion.
    public var operationOutput: (any Sendable)?

    /// A user-facing description of what caused the underlying error
    /// to be thrown.
    public var causeDescription: String

    /// The underlying error that caused the operation to fail.
    public var underlyingError: any Error

    /// An HTTP status to return in the response.
    public var httpStatus: HTTPResponse.Status

    /// The HTTP header fields of the response.
    public var httpHeaderFields: HTTPTypes.HTTPFields

    /// The body of the HTTP response.
    public var httpBody: OpenAPIRuntime.HTTPBody?

    /// Creates a new error.
    /// - Parameters:
    ///   - operationID: The OpenAPI operation identifier.
    ///   - request: The HTTP request provided to the server.
    ///   - requestBody: The HTTP request body provided to the server.
    ///   - requestMetadata: The request metadata extracted by the server.
    ///   - operationInput: An operation-specific Input value.
    ///   - operationOutput: An operation-specific Output value.
    ///   - causeDescription: A user-facing description of what caused
    ///     the underlying error to be thrown.
    ///   - underlyingError: The underlying error that caused the operation
    ///     to fail.
    public init(
        operationID: String,
        request: HTTPRequest,
        requestBody: HTTPBody?,
        requestMetadata: ServerRequestMetadata,
        operationInput: (any Sendable)? = nil,
        operationOutput: (any Sendable)? = nil,
        causeDescription: String,
        underlyingError: any Error
    ) {
        let httpStatus: HTTPResponse.Status
        let httpHeaderFields: HTTPTypes.HTTPFields
        let httpBody: OpenAPIRuntime.HTTPBody?
        if let httpConvertibleError = underlyingError as? (any HTTPResponseConvertible) {
            httpStatus = httpConvertibleError.httpStatus
            httpHeaderFields = httpConvertibleError.httpHeaderFields
            httpBody = httpConvertibleError.httpBody
        } else {
            httpStatus = .internalServerError
            httpHeaderFields = [:]
            httpBody = nil
        }

        self.init(
            operationID: operationID,
            request: request,
            requestBody: requestBody,
            requestMetadata: requestMetadata,
            operationInput: operationInput,
            operationOutput: operationOutput,
            causeDescription: causeDescription,
            underlyingError: underlyingError,
            httpStatus: httpStatus,
            httpHeaderFields: httpHeaderFields,
            httpBody: httpBody
        )
    }

    /// Creates a new error.
    /// - Parameters:
    ///   - operationID: The OpenAPI operation identifier.
    ///   - request: The HTTP request provided to the server.
    ///   - requestBody: The HTTP request body provided to the server.
    ///   - requestMetadata: The request metadata extracted by the server.
    ///   - operationInput: An operation-specific Input value.
    ///   - operationOutput: An operation-specific Output value.
    ///   - causeDescription: A user-facing description of what caused
    ///     the underlying error to be thrown.
    ///   - underlyingError: The underlying error that caused the operation
    ///     to fail.
    ///   - httpStatus: An HTTP status to return in the response.
    ///   - httpHeaderFields: The HTTP header fields of the response.
    ///   - httpBody: The body of the HTTP response.
    public init(
        operationID: String,
        request: HTTPRequest,
        requestBody: HTTPBody?,
        requestMetadata: ServerRequestMetadata,
        operationInput: (any Sendable)? = nil,
        operationOutput: (any Sendable)? = nil,
        causeDescription: String,
        underlyingError: any Error,
        httpStatus: HTTPResponse.Status,
        httpHeaderFields: HTTPTypes.HTTPFields,
        httpBody: OpenAPIRuntime.HTTPBody?
    ) {
        self.operationID = operationID
        self.request = request
        self.requestBody = requestBody
        self.requestMetadata = requestMetadata
        self.operationInput = operationInput
        self.operationOutput = operationOutput
        self.causeDescription = causeDescription
        self.underlyingError = underlyingError
        self.httpStatus = httpStatus
        self.httpHeaderFields = httpHeaderFields
        self.httpBody = httpBody
    }

    // MARK: Private

    fileprivate var underlyingErrorDescription: String {
        guard let prettyError = underlyingError as? (any PrettyStringConvertible) else { return "\(underlyingError)" }
        return prettyError.prettyDescription
    }
}

extension ServerError: CustomStringConvertible {
    /// A human-readable description of the server error.
    ///
    /// This computed property returns a string that includes information about the server error.
    ///
    /// - Returns: A string describing the server error and its associated details.
    public var description: String {
        "Server error - cause description: '\(causeDescription)', underlying error: \(underlyingErrorDescription), operationID: \(operationID), request: \(request.prettyDescription), requestBody: \(requestBody?.prettyDescription ?? "<nil>"), metadata: \(requestMetadata.description), operationInput: \(operationInput.map { String(describing: $0) } ?? "<nil>"), operationOutput: \(operationOutput.map { String(describing: $0) } ?? "<nil>")"
    }
}

extension ServerError: LocalizedError {
    /// A localized description of the server error.
    ///
    /// This computed property provides a localized human-readable description of the server error, which is suitable for displaying to users.
    ///
    /// - Returns: A localized string describing the server error.
    public var errorDescription: String? {
        "Server encountered an error handling the operation \"\(operationID)\", caused by \"\(causeDescription)\", underlying error: \(underlyingError.localizedDescription)."
    }
}
