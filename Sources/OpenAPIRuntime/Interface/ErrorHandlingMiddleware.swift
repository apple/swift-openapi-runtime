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

/// An opt-in error handling middleware that converts an error to an HTTP response.
///
/// Inclusion of  ``ErrorHandlingMiddleware`` should be accompanied by conforming errors to the ``HTTPResponseConvertible``  protocol.
/// Errors not conforming to ``HTTPResponseConvertible`` are converted to a response with the 500 status code.
///
/// ## Example usage
///
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
/// 2. Opt into the ``ErrorHandlingMiddleware``  while registering the handler:
///
/// ```swift
/// let handler = RequestHandler()
/// try handler.registerHandlers(on: transport, middlewares: [ErrorHandlingMiddleware()])
/// ```
/// - Note: The placement of ``ErrorHandlingMiddleware`` in the middleware chain is important. It should be determined based on the specific needs of each application. Consider the order of execution and dependencies between middlewares.
public struct ErrorHandlingMiddleware: ServerMiddleware {
    /// Creates a new middleware.
    public init() {}
    // swift-format-ignore: AllPublicDeclarationsHaveDocumentation
    public func intercept(
        _ request: HTTPTypes.HTTPRequest,
        body: OpenAPIRuntime.HTTPBody?,
        metadata: OpenAPIRuntime.ServerRequestMetadata,
        operationID: String,
        next: @Sendable (HTTPTypes.HTTPRequest, OpenAPIRuntime.HTTPBody?, OpenAPIRuntime.ServerRequestMetadata)
            async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?)
    ) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?) {
        do { return try await next(request, body, metadata) } catch {
            if let serverError = error as? ServerError,
                let appError = serverError.underlyingError as? (any HTTPResponseConvertible)
            {
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

/// A value that can be converted to an HTTP response and body.
///
/// Conform your error type to this protocol to convert it to an `HTTPResponse` and ``HTTPBody``.
///
/// You must provide ``ErrorHandlingMiddleware`` to `registerHandlers` in order for
/// this value to get converted to the desired HTTP response.
public protocol HTTPResponseConvertible {

    /// An HTTP status to return in the response.
    var httpStatus: HTTPResponse.Status { get }

    /// The HTTP header fields of the response.
    /// This is optional as default values are provided in the extension.
    var httpHeaderFields: HTTPTypes.HTTPFields { get }

    /// The body of the HTTP response.
    var httpBody: OpenAPIRuntime.HTTPBody? { get }
}

extension HTTPResponseConvertible {

    // swift-format-ignore: AllPublicDeclarationsHaveDocumentation
    public var httpHeaderFields: HTTPTypes.HTTPFields { [:] }

    // swift-format-ignore: AllPublicDeclarationsHaveDocumentation
    public var httpBody: OpenAPIRuntime.HTTPBody? { nil }
}

/// An concrete error type that represents a desired HTTP response to be returned by the server.
///
/// Throw this error in your API handler to return a specific undocumented HTTP response.
///
/// You must provide ``ErrorHandlingMiddleware`` to `registerHandlers` in order for
/// this error to get converted to the desired HTTP response.
public struct HTTPResponseError: Error, HTTPResponseConvertible {

    /// An HTTP status to return in the response.
    public var httpStatus: HTTPResponse.Status

    /// The HTTP header fields of the response.
    public var httpHeaderFields: HTTPTypes.HTTPFields

    /// The body of the HTTP response.
    public var httpBody: OpenAPIRuntime.HTTPBody?

    /// Creates a new error.
    /// - Parameters:
    ///   - httpStatus: An HTTP status to return in the response.
    ///   - httpHeaderFields: The HTTP header fields of the response.
    ///   - httpBody: The body of the HTTP response.
    public init(
        httpStatus: HTTPResponse.Status,
        httpHeaderFields: HTTPTypes.HTTPFields = [:],
        httpBody: OpenAPIRuntime.HTTPBody? = nil
    ) {
        self.httpStatus = httpStatus
        self.httpHeaderFields = httpHeaderFields
        self.httpBody = httpBody
    }
}
