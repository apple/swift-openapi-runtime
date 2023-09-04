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
import Foundation
#else
@preconcurrency import struct Foundation.URL
#endif

@_spi(Generated)
public struct UniversalClient: Sendable {

    public let serverURL: URL
    public let converter: Converter
    public var transport: any ClientTransport
    public var middlewares: [any NewClientMiddleware]

    internal init(
        serverURL: URL,
        converter: Converter,
        transport: any ClientTransport,
        middlewares: [any NewClientMiddleware]
    ) {
        self.serverURL = serverURL
        self.converter = converter
        self.transport = transport
        self.middlewares = middlewares
    }

    public init(
        serverURL: URL = .defaultOpenAPIServerURL,
        configuration: Configuration = .init(),
        transport: any ClientTransport,
        middlewares: [any NewClientMiddleware] = []
    ) {
        self.init(
            serverURL: serverURL,
            converter: Converter(configuration: configuration),
            transport: transport,
            middlewares: middlewares
        )
    }

    public func send<OperationInput, OperationOutput>(
        input: OperationInput,
        forOperation operationID: String,
        serializer: @Sendable (OperationInput) throws -> (HTTPRequest, HTTPBody?),
        deserializer: @Sendable (HTTPResponse, HTTPBody) throws -> OperationOutput
    ) async throws -> OperationOutput where OperationInput: Sendable, OperationOutput: Sendable {
        @Sendable
        func wrappingErrors<R>(
            work: () async throws -> R,
            mapError: (any Error) -> any Error
        ) async throws -> R {
            do {
                return try await work()
            } catch {
                throw mapError(error)
            }
        }
        let baseURL = serverURL
        func makeError(
            request: HTTPRequest? = nil,
            requestBody: HTTPBody? = nil,
            baseURL: URL? = nil,
            response: HTTPResponse? = nil,
            responseBody: HTTPBody? = nil,
            error: any Error
        ) -> any Error {
            ClientError(
                operationID: operationID,
                operationInput: input,
                request: request,
                requestBody: requestBody,
                baseURL: baseURL,
                response: response,
                responseBody: responseBody,
                underlyingError: error
            )
        }
        let (request, requestBody): (HTTPRequest, HTTPBody?) = try await wrappingErrors {
            try serializer(input)
        } mapError: { error in
            makeError(error: error)
        }
        let (response, responseBody): (HTTPResponse, HTTPBody) = try await wrappingErrors {
            var next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody) = {
                (_request, _body, _url) in
                try await wrappingErrors {
                    try await transport.send(
                        _request,
                        body: _body,
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
                        body: $1,
                        baseURL: $2,
                        operationID: operationID,
                        next: tmp
                    )
                }
            }
            return try await next(request, requestBody, baseURL)
        } mapError: { error in
            makeError(request: request, baseURL: baseURL, error: error)
        }
        return try await wrappingErrors {
            try deserializer(response, responseBody)
        } mapError: { error in
            makeError(request: request, baseURL: baseURL, response: response, error: error)
        }
    }
}
