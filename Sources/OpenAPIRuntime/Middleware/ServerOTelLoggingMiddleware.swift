//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2025 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if Logging && OTelSemanticConventions

public import HTTPTypes
public import Logging
import OTelSemanticConventions

/// A Middleware that logs incoming HTTP requests and the responses produced for them, annotated with
/// [OpenTelemetry Semantic Convention HTTP Attributes][https://opentelemetry.io/docs/specs/semconv/registry/attributes/http].
///
/// A successfully handled request emits two records at the configured log level: `HTTP Server Request` before the
/// request reaches the handler, and `HTTP Server Response` once the handler returns. If the handler
/// throws, the second record is `HTTP Server Request Error`, logged at the specified error log level.
///
/// - Note: The middleware is gated behind the `Logging` package trait.
///
/// ## Logged attributes
///
/// The request record carries:
///
/// | Attribute | Notes |
/// | --- | --- |
/// | `server.address`, `server.port` | The values passed to the initializer; omitted when `nil`. |
/// | `network.transport` | The value passed to the initializer. |
/// | `http.request.method` | |
/// | `url.scheme` | The scheme of the request, when present. |
/// | `url.full` | Composed from the scheme, authority, and path; omitted unless all three are present. |
/// | `http.request.body.size` | Only when the body length is known. |
/// | `user_agent.original` | Only when the request carries a `User-Agent` field. |
/// | `http.request.header.<name>` | One per captured field name, listing every value of that field. |
///
/// The response record additionally carries `http.response.status_code`,
/// `http.response.body.size` (only when the body length is known), and
/// `http.response.header.<name>` (one per captured field name). The error record carries
/// no extra attributes; the error itself is attached to the log record, leaving it to the log
/// handler to report it.
///
/// ## Example usage
///
/// ```swift
/// let handler = RequestHandler()
/// let middleware = ServerOTelLoggingMiddleware(requestHeaders: [.accept], responseHeaders: [.contentType])
/// try handler.registerHandlers(on: transport, middlewares: [middleware])
/// ```
public struct ServerOTelLoggingMiddleware: ServerMiddleware {
    private let logLevel: Logger.Level
    private let errorLevel: Logger.Level
    private let requestHeaders: OTelCapturedHeaders
    private let responseHeaders: OTelCapturedHeaders

    private let serverAddress: String?
    private let serverPort: Int?
    private let networkTransport: String

    /// Creates a new middleware.
    /// - Parameters:
    ///   - logLevel: The level at which the request and response records are logged.
    ///   - errorLevel: The level at which a failed request is logged.
    ///   - requestHeaders: The request header fields to log.
    ///   - responseHeaders: The response header fields to log.
    ///   - serverAddress: The value logged as the `server.address` attribute. The incoming request
    ///     does not carry the address the server is reachable at, so it has to be provided here.
    ///   - serverPort: The value logged as the `server.port` attribute. As with `serverAddress`, it
    ///     has to be provided here.
    ///   - networkTransport: The value logged as the `network.transport` attribute. Provide the
    ///     transport actually in use, such as `"unix"`, when it is not TCP.
    public init(
        logLevel: Logger.Level = .debug,
        errorLevel: Logger.Level = .error,
        requestHeaders: OTelCapturedHeaders = .none,
        responseHeaders: OTelCapturedHeaders = .none,
        serverAddress: String? = nil,
        serverPort: Int? = nil,
        networkTransport: String = "tcp",
    ) {
        self.logLevel = logLevel
        self.errorLevel = errorLevel
        self.requestHeaders = requestHeaders
        self.responseHeaders = responseHeaders
        self.serverAddress = serverAddress
        self.serverPort = serverPort
        self.networkTransport = networkTransport
    }

    // swift-format-ignore: AllPublicDeclarationsHaveDocumentation
    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        metadata: ServerRequestMetadata,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var logger = Logger.current

        logger[metadataKey: OTelAttribute.server.address] = serverAddress.map { "\($0)" }
        logger[metadataKey: OTelAttribute.server.port] = serverPort.map { "\($0)" }
        logger[metadataKey: OTelAttribute.network.transport] = "\(networkTransport)"

        logger[metadataKey: OTelAttribute.http.request.method] = "\(request.method)"
        logger[metadataKey: OTelAttribute.url.scheme] = request.scheme.map { "\($0)" }
        if let scheme = request.scheme, let authority = request.authority, let path = request.path {
            logger[metadataKey: OTelAttribute.url.full] = "\(scheme)://\(authority)\(path)"
        }

        if case let .known(length) = body?.length {
            logger[metadataKey: OTelExperimentalHTTPKeys.httpRequestBodySize] = "\(length)"
        }

        logger[metadataKey: OTelAttribute.userAgent.original] = request.headerFields[.userAgent].map { "\($0)" }

        requestHeaders.addMetadata(for: request.headerFields, prefix: OTelAttribute.http.request.header, to: &logger)

        logger.log(level: self.logLevel, "HTTP Server Request")

        let (response, responseBody): (HTTPResponse, HTTPBody?)
        do { (response, responseBody) = try await next(request, body, metadata) } catch {
            logger.log(level: self.errorLevel, "HTTP Server Request Error", error: error)
            throw error
        }

        logger[metadataKey: OTelAttribute.http.response.statusCode] = "\(response.status.code)"
        if case let .known(length) = responseBody?.length {
            logger[metadataKey: OTelExperimentalHTTPKeys.httpResponseBodySize] = "\(length)"
        }

        responseHeaders.addMetadata(for: response.headerFields, prefix: OTelAttribute.http.response.header, to: &logger)

        logger.log(level: self.logLevel, "HTTP Server Response")

        return (response, responseBody)
    }
}

#endif
