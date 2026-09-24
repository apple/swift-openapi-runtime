//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

public import HTTPTypes

/// An opt-in middleware that normalizes `+`-encoded spaces in the request's
/// query string to `%20`, so that requests from clients that use
/// `application/x-www-form-urlencoded` conventions decode correctly.
///
/// The OpenAPI specification follows RFC 3986, which requires spaces in query
/// strings to be percent-encoded as `%20`. However, many widely-used HTTP
/// client libraries — including Python's `requests`, Java's `URLEncoder`,
/// Scala's `sttp`, and JavaScript's `URLSearchParams` — encode spaces as `+`,
/// following the `application/x-www-form-urlencoded` convention. Without this
/// middleware, query parameters sent from such clients arrive at handlers with
/// literal `+` characters instead of spaces.
///
/// This middleware rewrites `+` to `%20` in the query portion of the request
/// path before the request is parsed, so both encoding conventions produce the
/// same decoded value. A literal `+` in the original input should already be
/// sent as `%2B` by any client; such values are unaffected because this
/// middleware only rewrites unencoded `+` characters.
///
/// ## Example usage
///
/// ```swift
/// let handler = RequestHandler()
/// try handler.registerHandlers(on: transport, middlewares: [QuerySpaceNormalizingMiddleware()])
/// ```
///
/// - Note: Only the query of the request is modified. The path, fragment, and
///   body are not touched.
public struct QuerySpaceNormalizingMiddleware: ServerMiddleware {
    /// Creates a new middleware.
    public init() {}

    // swift-format-ignore: AllPublicDeclarationsHaveDocumentation
    public func intercept(
        _ request: HTTPTypes.HTTPRequest,
        body: OpenAPIRuntime.HTTPBody?,
        metadata: OpenAPIRuntime.ServerRequestMetadata,
        operationID: String,
        next:
            @Sendable (HTTPTypes.HTTPRequest, OpenAPIRuntime.HTTPBody?, OpenAPIRuntime.ServerRequestMetadata)
            async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?)
    ) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?) {
        var request = request
        if let path = request.path {
            let fragmentStart = path.firstIndex(of: "#") ?? path.endIndex
            let pathAndQuery = path[..<fragmentStart]
            if let queryStart = pathAndQuery.firstIndex(of: "?") {
                let queryContentStart = path.index(after: queryStart)
                let query = path[queryContentStart..<fragmentStart]
                if query.contains("+") {
                    // Each "+" expands to 3 bytes ("%20"), so the worst-case
                    // length is path.count + 2 * query.count.
                    var newPath = ""
                    newPath.reserveCapacity(path.count + 2 * query.count)
                    newPath.append(contentsOf: path[..<queryContentStart])
                    for character in query {
                        if character == "+" { newPath.append("%20") } else { newPath.append(character) }
                    }
                    newPath.append(contentsOf: path[fragmentStart...])
                    request.path = newPath
                }
            }
        }
        return try await next(request, body, metadata)
    }
}
