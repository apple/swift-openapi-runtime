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

/// A middleware that invokes the provided closure for each body chunk for logging purposes.
///
/// Does not buffer the body, so is appropriate for logging in streaming use cases, or when transferring large bodies.
///
/// For example, for an UTF-8 encoded streaming payload, use it as follows:
///
/// ```swift
/// // In clients:
/// let client = Client(serverURL: ..., transport: ..., middlewares: [
///     StreamingBodyLoggingMiddleware(
///         request: { print("Sending out request body chunk: \(String(decoding: $0, as: UTF8.self))") },
///         response: { print("Received a response body chunk: \(String(decoding: $0, as: UTF8.self))") }
///     )
/// ])
///
/// // In servers:
/// try handler.registerHandlers(on: ..., serverURL: ..., middlewares: [
///     StreamingBodyLoggingMiddleware(
///         request: { print("Sending out request body chunk: \(String(decoding: $0, as: UTF8.self))") },
///         response: { print("Received a response body chunk: \(String(decoding: $0, as: UTF8.self))") }
///     )
/// ])
/// ```
public struct StreamingBodyLoggingMiddleware: Sendable {

    /// A closure invoked for each request body chunk.
    public var request: @Sendable (ArraySlice<UInt8>) -> Void

    /// A closure invoked for each response body chunk.
    public var response: @Sendable (ArraySlice<UInt8>) -> Void

    /// Creates a new logging middleware.
    /// - Parameters:
    ///   - request: A closure invoked for each request body chunk.
    ///   - response: A closure invoked for each response body chunk.
    public init(
        request: @Sendable @escaping (ArraySlice<UInt8>) -> Void,
        response: @Sendable @escaping (ArraySlice<UInt8>) -> Void
    ) {
        self.request = request
        self.response = response
    }
}

extension StreamingBodyLoggingMiddleware {

    /// The message type.
    private enum Message {

        /// A request message.
        case request

        /// A response message.
        case response
    }

    /// Wraps the input body stream in another that invokes the appropriate closure for each chunk.
    /// - Parameters:
    ///   - body: The input body.
    ///   - message: The message type.
    /// - Returns: A wrapped body to be passed to the next middleware, or nil if the input body was nil.
    private func loggingBody(_ body: HTTPBody?, in message: Message) -> HTTPBody? {
        guard let body else { return nil }
        let loggingClosure: @Sendable (ArraySlice<UInt8>) -> Void
        switch message {
        case .request: loggingClosure = request
        case .response: loggingClosure = response
        }
        return HTTPBody(
            body.map { chunk in
                loggingClosure(chunk)
                return chunk
            },
            length: body.length,
            iterationBehavior: body.iterationBehavior
        )
    }
}

extension StreamingBodyLoggingMiddleware: ClientMiddleware {
    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let nextRequestBody = loggingBody(body, in: .request)
        let (response, responseBody) = try await next(request, nextRequestBody, baseURL)
        let nextResponseBody = loggingBody(responseBody, in: .response)
        return (response, nextResponseBody)
    }
}

extension StreamingBodyLoggingMiddleware: ServerMiddleware {
    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        metadata: ServerRequestMetadata,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let nextRequestBody = loggingBody(body, in: .request)
        let (response, responseBody) = try await next(request, nextRequestBody, metadata)
        let nextResponseBody = loggingBody(responseBody, in: .response)
        return (response, nextResponseBody)
    }
}
