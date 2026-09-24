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

#if canImport(FoundationEssentials)
public import FoundationEssentials
#else
public import Foundation
#endif

/// A Middleware that logs outgoing HTTP requests and their responses, annotated with
/// [OpenTelemetry Semantic Convention HTTP Attributes][https://opentelemetry.io/docs/specs/semconv/registry/attributes/http].
///
/// A successful call emits two records at the configured log level: `HTTP Client Request` before the request is
/// handed to the transport, and `HTTP Client Response` once the response arrives. If the request
/// fails, the second record is `HTTP Client Request Error`, logged at the specified error log level.
///
/// - Note: The middleware is gated behind the `Logging` package trait, which is enabled by default.
///
/// ## Logged attributes
///
/// The request record carries:
///
/// | Attribute | Notes |
/// | --- | --- |
/// | `network.transport` | The value passed to the initializer. |
/// | `http.request.method` | |
/// | `server.address`, `server.port`, `url.scheme`, `url.full` | Derived from the base URL and the request path. |
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
/// let client = Client(
///     serverURL: try Servers.Server1.url(),
///     transport: transport,
///     middlewares: [ClientOTelLoggingMiddleware(requestHeaders: [.accept], responseHeaders: [.contentType])]
/// )
/// ```
public struct ClientOTelLoggingMiddleware: ClientMiddleware {
    private let logLevel: Logger.Level
    private let errorLevel: Logger.Level
    private let requestHeaders: OTelCapturedHeaders
    private let responseHeaders: OTelCapturedHeaders

    private let networkTransport: String

    /// Creates a new middleware.
    /// - Parameters:
    ///   - logLevel: The level at which the request and response records are logged.
    ///   - errorLevel: The level at which a failed request is logged.
    ///   - requestHeaders: The request header fields to log.
    ///   - responseHeaders: The response header fields to log.
    ///   - networkTransport: The value logged as the `network.transport` attribute. Provide the
    ///     transport actually in use, such as `"unix"`, when it is not TCP.
    public init(
        logLevel: Logger.Level = .debug,
        errorLevel: Logger.Level = .error,
        requestHeaders: OTelCapturedHeaders = .none,
        responseHeaders: OTelCapturedHeaders = .none,
        networkTransport: String = "tcp",
    ) {
        self.logLevel = logLevel
        self.errorLevel = errorLevel
        self.requestHeaders = requestHeaders
        self.responseHeaders = responseHeaders
        self.networkTransport = networkTransport
    }

    // swift-format-ignore: AllPublicDeclarationsHaveDocumentation
    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var logger = Logger.current

        logger[metadataKey: OTelAttribute.network.transport] = "\(networkTransport)"
        logger[metadataKey: OTelAttribute.http.request.method] = "\(request.method)"

        if var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false),
            let requestComponents = URLComponents(string: request.path ?? "")
        {
            if components.percentEncodedPath.hasSuffix("/") { components.percentEncodedPath.removeLast() }
            components.percentEncodedPath += requestComponents.percentEncodedPath
            components.percentEncodedQuery = requestComponents.percentEncodedQuery

            logger[metadataKey: OTelAttribute.server.address] = components.host.map { "\($0)" }
            logger[metadataKey: OTelAttribute.server.port] = components.port.map { "\($0)" }
            logger[metadataKey: OTelAttribute.url.scheme] = components.scheme.map { "\($0)" }
            logger[metadataKey: OTelAttribute.url.full] = components.string.map { "\($0)" }
        }

        if case let .known(length) = body?.length {
            logger[metadataKey: OTelExperimentalHTTPKeys.httpRequestBodySize] = "\(length)"
        }

        logger[metadataKey: OTelAttribute.userAgent.original] = request.headerFields[.userAgent].map { "\($0)" }

        requestHeaders.addMetadata(for: request.headerFields, prefix: OTelAttribute.http.request.header, to: &logger)

        logger.log(level: self.logLevel, "HTTP Client Request")

        let (response, responseBody): (HTTPResponse, HTTPBody?)
        do { (response, responseBody) = try await next(request, body, baseURL) } catch {
            logger.log(level: self.errorLevel, "HTTP Client Request Error", error: error)
            throw error
        }

        logger[metadataKey: OTelAttribute.http.response.statusCode] = "\(response.status.code)"
        if case let .known(length) = responseBody?.length {
            logger[metadataKey: OTelExperimentalHTTPKeys.httpResponseBodySize] = "\(length)"
        }

        responseHeaders.addMetadata(for: response.headerFields, prefix: OTelAttribute.http.response.header, to: &logger)

        logger.log(level: self.logLevel, "HTTP Client Response")

        return (response, responseBody)
    }
}

#endif
