//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2024 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import HTTPTypes

/// An opt-in error handling middleware that converts an error to a HTTP response.
///
/// Inclusion of  ``ErrorHandlingMiddleware`` should be accompanied by conforming errors to the ``HTTPResponseConvertible``  protocol.
/// Errors not conforming to ``HTTPResponseConvertible`` are converted to a response with the 500 status code.
///
/// ## Example usage
/// 1. Create an error type that conforms to the ``HTTPResponseConvertible`` protocol:
///
/// ```swift
/// extension MyAppError: HTTPResponseConvertible {
///    var httpStatus: HTTPResponse.Status {
///        switch self {
///        case .invalidInputFormat:
///            .badRequest
///        case .authorizationError:
///            .forbidden
///        }
///    }
/// }
/// ```
///
/// 2. Opt in to the ``ErrorHandlingMiddleware``  while registering the handler:
///
/// ```swift
/// let handler = RequestHandler()
/// try handler.registerHandlers(on: transport, middlewares: [ErrorHandlingMiddleware()])
/// ```
/// - Note: The placement of ``ErrorHandlingMiddleware`` in the middleware chain is important.
/// It should be determined based on the specific needs of each application.
/// Consider the order of execution and dependencies between middlewares.
public struct ErrorHandlingMiddleware: ServerMiddleware {
    
    /// Creates an ErrorHandlingMiddleware.
    public init() {}
    
    /// Intercepts an outgoing HTTP request and an incoming HTTP Response, and converts errors(if any) that confirms to ``HTTPResponseConvertible`` to an HTTP response.
    /// - Parameters:
    ///   - request: The HTTP request created during the operation.
    ///   - body: The HTTP request body created during the operation.
    ///   - metadata: Request metadata
    ///   - operationID: The OpenAPI operation identifier.
    ///   - next: A closure that calls the next middleware, or the transport.
    /// - Returns: An HTTPResponse and an optional HTTPBody.
    public func intercept(
        _ request: HTTPTypes.HTTPRequest,
        body: OpenAPIRuntime.HTTPBody?,
        metadata: OpenAPIRuntime.ServerRequestMetadata,
        operationID: String,
        next: @Sendable (HTTPTypes.HTTPRequest, OpenAPIRuntime.HTTPBody?, OpenAPIRuntime.ServerRequestMetadata)
            async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?)
    ) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?) {
        do { return try await next(request, body, metadata) } catch let error as ServerError {
            if let appError = error.underlyingError as? (any HTTPResponseConvertible) {
                return (
                    HTTPResponse(status: appError.httpStatus, headerFields: appError.httpHeaderFields),
                    appError.httpBody
                )
            } else {
                return (HTTPResponse(status: .internalServerError), nil)
            }
        }
    }
}

/// A protocol used by ``ErrorHandlingMiddleware`` to map an error to an ``HTTPResponse`` and ``HTTPBody``.
/// Adopters who wish to convert their application error to an `HTTPResponse` and ``HTTPBody`` should conform the error type to this protocol.
public protocol HTTPResponseConvertible {

    /// An HTTP status to return in the response.
    var httpStatus: HTTPResponse.Status { get }
    /// The HTTP headers of the response.
    /// This is optional as default values are provided in the extension.
    var httpHeaderFields: HTTPTypes.HTTPFields { get }
    /// The body of the HTTP response.
    var httpBody: OpenAPIRuntime.HTTPBody? { get }
}

/// Extension to HTTPResponseConvertible to provide default values for certain fields.
extension HTTPResponseConvertible {
    public var httpHeaderFields: HTTPTypes.HTTPFields { [:] }
    public var httpBody: OpenAPIRuntime.HTTPBody? { nil }
}
