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
#if canImport(Darwin)
import struct Foundation.URL
#else
@preconcurrency import struct Foundation.URL
#endif

/// OpenAPI document-agnostic HTTP client used by OpenAPI document-specific,
/// generated clients to perform request serialization, middleware and transport
/// invocation, and response deserialization.
///
/// Do not call this directly, only invoked by generated code.
@_spi(Generated) public struct UniversalClient: Sendable {

    /// The URL of the server, used as the base URL for requests made by the
    /// client.
    public let serverURL: URL

    /// A converter for encoding/decoding data.
    public let converter: Converter

    /// A type capable of sending HTTP requests and receiving HTTP responses.
    public var transport: any ClientTransport

    /// The middlewares to be invoked before the transport.
    public var middlewares: [any ClientMiddleware]

    /// Internal initializer that takes an initialized `Converter`.
    internal init(
        serverURL: URL,
        converter: Converter,
        transport: any ClientTransport,
        middlewares: [any ClientMiddleware]
    ) {
        self.serverURL = serverURL
        self.converter = converter
        self.transport = transport
        self.middlewares = middlewares
    }

    /// Creates a new client.
    public init(
        serverURL: URL = .defaultOpenAPIServerURL,
        configuration: Configuration = .init(),
        transport: any ClientTransport,
        middlewares: [any ClientMiddleware] = []
    ) {
        self.init(
            serverURL: serverURL,
            converter: Converter(configuration: configuration),
            transport: transport,
            middlewares: middlewares
        )
    }

    /// Performs the HTTP operation.
    ///
    /// Should only be called by generated code, not directly.
    ///
    /// An operation consists of three steps:
    /// 1. Convert Input into an HTTP request.
    /// 2. Invoke the `ClientTransport` to perform the HTTP call, wrapped by middlewares.
    /// 3. Convert the HTTP response into Output.
    ///
    /// It wraps any thrown errors and attaches appropriate context.
    ///
    /// - Parameters:
    ///   - input: Operation-specific input value.
    ///   - operationID: The OpenAPI operation identifier.
    ///   - serializer: Creates an HTTP request from the provided Input value.
    ///   - deserializer: Creates an Output value from the provided HTTP response.
    /// - Returns: The Output value produced by `deserializer`.
    /// - Throws: An error if any part of the HTTP operation process fails.
    public func send<OperationInput, OperationOutput>(
        input: OperationInput,
        forOperation operationID: String,
        serializer: @Sendable (OperationInput) throws -> (HTTPRequest, HTTPBody?),
        deserializer: @Sendable (HTTPResponse, HTTPBody?) async throws -> OperationOutput
    ) async throws -> OperationOutput where OperationInput: Sendable, OperationOutput: Sendable {
        @Sendable func wrappingErrors<R>(work: () async throws -> R, mapError: (any Error) -> any Error) async throws
            -> R
        {
            do { return try await work() } catch let error as ClientError { throw error } catch {
                throw mapError(error)
            }
        }
        let baseURL = serverURL
        let errorHandler = converter.configuration.clientErrorHandler
        @Sendable func makeError(
            request: HTTPRequest? = nil,
            requestBody: HTTPBody? = nil,
            baseURL: URL? = nil,
            response: HTTPResponse? = nil,
            responseBody: HTTPBody? = nil,
            error: any Error
        ) -> any Error {
            if var error = error as? ClientError {
                error.request = error.request ?? request
                error.requestBody = error.requestBody ?? requestBody
                error.baseURL = error.baseURL ?? baseURL
                error.response = error.response ?? response
                error.responseBody = error.responseBody ?? responseBody
                errorHandler?.handleClientError(error)
                return error
            }
            let causeDescription: String
            let underlyingError: any Error
            if let runtimeError = error as? RuntimeError {
                causeDescription = runtimeError.prettyDescription
                underlyingError = runtimeError.underlyingError ?? error
            } else {
                causeDescription = "Unknown"
                underlyingError = error
            }
            let clientError = ClientError(
                operationID: operationID,
                operationInput: input,
                request: request,
                requestBody: requestBody,
                baseURL: baseURL,
                response: response,
                responseBody: responseBody,
                causeDescription: causeDescription,
                underlyingError: underlyingError
            )
            errorHandler?.handleClientError(clientError)
            return clientError
        }
        let (request, requestBody): (HTTPRequest, HTTPBody?) = try await wrappingErrors {
            try serializer(input)
        } mapError: { error in
            makeError(error: error)
        }
        var next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = {
            (_request, _body, _url) in
            try await wrappingErrors {
                try await transport.send(_request, body: _body, baseURL: _url, operationID: operationID)
            } mapError: { error in
                makeError(
                    request: request,
                    requestBody: requestBody,
                    baseURL: baseURL,
                    error: RuntimeError.transportFailed(error)
                )
            }
        }
        for middleware in middlewares.reversed() {
            let tmp = next
            next = { (_request, _body, _url) in
                try await wrappingErrors {
                    try await middleware.intercept(
                        _request,
                        body: _body,
                        baseURL: _url,
                        operationID: operationID,
                        next: tmp
                    )
                } mapError: { error in
                    makeError(
                        request: request,
                        requestBody: requestBody,
                        baseURL: baseURL,
                        error: RuntimeError.middlewareFailed(middlewareType: type(of: middleware), error)
                    )
                }
            }
        }
        let (response, responseBody): (HTTPResponse, HTTPBody?) = try await next(request, requestBody, baseURL)
        return try await wrappingErrors {
            try await deserializer(response, responseBody)
        } mapError: { error in
            makeError(
                request: request,
                requestBody: requestBody,
                baseURL: baseURL,
                response: response,
                responseBody: responseBody,
                error: error
            )
        }
    }
}
