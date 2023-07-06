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
@preconcurrency import Foundation
#endif

/// OpenAPI document-agnostic HTTP client used by OpenAPI document-specific,
/// generated clients to perform request serialization, middleware and transport
/// invocation, and response deserialization.
///
/// Do not call this directly, only invoked by generated code.
@_spi(Generated)
public struct UniversalClient: Sendable {

    /// The URL of the server, used as the base URL for requests made by the
    /// client.
    public let serverURL: URL

    /// Converter for encoding/decoding data.
    public let converter: Converter

    /// Type capable of sending HTTP requests and receiving HTTP responses.
    public var transport: ClientTransport

    /// Middlewares to be invoked before `transport`.
    public var middlewares: [ClientMiddleware]

    /// Internal initializer that takes an initialized `Converter`.
    internal init(
        serverURL: URL,
        converter: Converter,
        transport: ClientTransport,
        middlewares: [ClientMiddleware]
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
        transport: ClientTransport,
        middlewares: [ClientMiddleware] = []
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
    @preconcurrency
    public func send<OperationInput, OperationOutput>(
        input: OperationInput,
        forOperation operationID: String,
        serializer: @Sendable (OperationInput) throws -> Request,
        deserializer: @Sendable (Response) throws -> OperationOutput
    ) async throws -> OperationOutput {
        @Sendable
        func wrappingErrors<R>(
            work: () async throws -> R,
            mapError: (Error) -> Error
        ) async throws -> R {
            do {
                return try await work()
            } catch {
                throw mapError(error)
            }
        }
        let baseURL = serverURL
        func makeError(
            request: Request? = nil,
            baseURL: URL? = nil,
            response: Response? = nil,
            error: Error
        ) -> Error {
            ClientError(
                operationID: operationID,
                operationInput: input,
                request: request,
                baseURL: baseURL,
                response: response,
                underlyingError: error
            )
        }
        let request: Request = try await wrappingErrors {
            try serializer(input)
        } mapError: { error in
            makeError(error: error)
        }
        let response: Response = try await wrappingErrors {
            var next: @Sendable (Request, URL) async throws -> Response = { (_request, _url) in
                try await wrappingErrors {
                    try await transport.send(
                        _request,
                        baseURL: _url,
                        operationID: operationID
                    )
                } mapError: { error in
                    RuntimeError.transportFailed(error)
                }
            }
            for middleware in middlewares.reversed() {
                let tmp = next
                next = {
                    try await middleware.intercept(
                        $0,
                        baseURL: $1,
                        operationID: operationID,
                        next: tmp
                    )
                }
            }
            return try await next(request, baseURL)
        } mapError: { error in
            makeError(request: request, baseURL: baseURL, error: error)
        }
        return try await wrappingErrors {
            try deserializer(response)
        } mapError: { error in
            makeError(request: request, baseURL: baseURL, response: response, error: error)
        }
    }
}
