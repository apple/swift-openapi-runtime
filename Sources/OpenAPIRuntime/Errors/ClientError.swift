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
#if canImport(Darwin)
import Foundation
#else
@preconcurrency import struct Foundation.URL
@preconcurrency import protocol Foundation.LocalizedError
#endif

/// An error thrown by a client performing an OpenAPI operation.
///
/// Use a `ClientError` to inspect details about the request and response that resulted in an error.
///
/// You don't create or throw instances of `ClientError` yourself; they are created and thrown on
/// your behalf by the runtime library when a client operation fails.
public struct ClientError: Error {
    /// The identifier of the operation, as defined in the OpenAPI document.
    public var operationID: String

    /// The operation-specific Input value.
    public var operationInput: any Sendable

    /// The HTTP request created during the operation.
    ///
    /// Will be nil if the error resulted before the request was generated,
    /// for example if generating the request from the Input failed.
    public var request: Request?

    /// The base URL for HTTP requests.
    ///
    /// Will be nil if the error resulted before the request was generated,
    /// for example if generating the request from the Input failed.
    public var baseURL: URL?

    /// The HTTP response received during the operation.
    ///
    /// Will be `nil` if the error resulted before the `Response` was received.
    public var response: Response?

    /// The underlying error that caused the operation to fail.
    public var underlyingError: any Error

    /// Creates a new error.
    /// - Parameters:
    ///   - operationID: The OpenAPI operation identifier.
    ///   - operationInput: The operation-specific Input value.
    ///   - request: The HTTP request created during the operation.
    ///   - baseURL: The base URL for HTTP requests.
    ///   - response: The HTTP response received during the operation.
    ///   - underlyingError: The underlying error that caused the operation to fail.
    public init(
        operationID: String,
        operationInput: any Sendable,
        request: Request? = nil,
        baseURL: URL? = nil,
        response: Response? = nil,
        underlyingError: any Error
    ) {
        self.operationID = operationID
        self.operationInput = operationInput
        self.request = request
        self.baseURL = baseURL
        self.response = response
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

extension ClientError: CustomStringConvertible {
    public var description: String {
        "Client error - operationID: \(operationID), operationInput: \(String(describing: operationInput)), request: \(request?.description ?? "<nil>"), baseURL: \(baseURL?.absoluteString ?? "<nil>"), response: \(response?.description ?? "<nil>"), underlying error: \(underlyingErrorDescription)"
    }
}

extension ClientError: LocalizedError {
    public var errorDescription: String? {
        description
    }
}
