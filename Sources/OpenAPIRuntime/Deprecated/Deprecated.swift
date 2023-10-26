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
    )
    public init(
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
    )
    public init(
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
