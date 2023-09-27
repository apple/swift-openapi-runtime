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

import HTTPTypes
import protocol Foundation.LocalizedError

/// An error thrown by a server handling an OpenAPI operation.
public struct ServerError: Error {

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

    /// The underlying error that caused the operation to fail.
    public var underlyingError: any Error

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
    public init(
        operationID: String,
        request: HTTPRequest,
        requestBody: HTTPBody?,
        requestMetadata: ServerRequestMetadata,
        operationInput: (any Sendable)? = nil,
        operationOutput: (any Sendable)? = nil,
        underlyingError: (any Error)
    ) {
        self.operationID = operationID
        self.request = request
        self.requestBody = requestBody
        self.requestMetadata = requestMetadata
        self.operationInput = operationInput
        self.operationOutput = operationOutput
        self.underlyingError = underlyingError
    }

    // MARK: Private

    fileprivate var underlyingErrorDescription: String {
        guard let prettyError = underlyingError as? (any PrettyStringConvertible) else {
            return underlyingError.localizedDescription
        }
        return prettyError.prettyDescription
    }
}

extension ServerError: CustomStringConvertible {
    public var description: String {
        "Server error - operationID: \(operationID), request: \(request.prettyDescription), requestBody: \(requestBody?.prettyDescription ?? "<nil>"), metadata: \(requestMetadata.description), operationInput: \(operationInput.map { String(describing: $0) } ?? "<nil>"), operationOutput: \(operationOutput.map { String(describing: $0) } ?? "<nil>"), underlying error: \(underlyingErrorDescription)"
    }
}

extension ServerError: LocalizedError {
    public var errorDescription: String? {
        description
    }
}
