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

/// An error thrown by a server handling an OpenAPI operation.
public struct ServerError: Error {
    /// Identifier of the operation that threw the error.
    public var operationID: String

    /// HTTP request provided to the server.
    public var request: Request

    /// Request metadata extracted by the server.
    public var requestMetadata: ServerRequestMetadata

    /// Operation-specific Input value.
    ///
    /// Is nil if error was thrown during request -> Input conversion.
    public var operationInput: Any?

    /// Operation-specific Output value.
    ///
    /// Is nil if error was thrown before/during Output -> response conversion.
    public var operationOutput: Any?

    /// The underlying error that caused the operation to fail.
    public var underlyingError: Error

    /// Creates a new error.
    /// - Parameters:
    ///   - operationID: The OpenAPI operation identifier.
    ///   - request: HTTP request provided to the server.
    ///   - requestMetadata: Request metadata extracted by the server.
    ///   - operationInput: Operation-specific Input value.
    ///   - operationOutput: Operation-specific Output value.
    ///   - underlyingError: The underlying error that caused the operation
    ///     to fail.
    public init(
        operationID: String,
        request: Request,
        requestMetadata: ServerRequestMetadata,
        operationInput: Any? = nil,
        operationOutput: Any? = nil,
        underlyingError: Error
    ) {
        self.operationID = operationID
        self.request = request
        self.requestMetadata = requestMetadata
        self.operationInput = operationInput
        self.operationOutput = operationOutput
        self.underlyingError = underlyingError
    }

    // MARK: Private

    fileprivate var underlyingErrorDescription: String {
        guard let prettyError = underlyingError as? PrettyStringConvertible else {
            return underlyingError.localizedDescription
        }
        return prettyError.prettyDescription
    }
}

extension ServerError: CustomStringConvertible {
    public var description: String {
        "Server error - operationID: \(operationID), request: \(request.description), metadata: \(requestMetadata.description), operationInput: \(operationInput.map { String(describing: $0) } ?? "<nil>"), operationOutput: \(operationOutput.map { String(describing: $0) } ?? "<nil>"), underlying error: \(underlyingErrorDescription)"
    }
}

extension ServerError: LocalizedError {
    public var errorDescription: String? {
        description
    }
}
