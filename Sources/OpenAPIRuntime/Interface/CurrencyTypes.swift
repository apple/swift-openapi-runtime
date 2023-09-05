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

/// A container for request metadata already parsed and validated
/// by the server transport.
public struct ServerRequestMetadata: Hashable, Sendable {

    /// The path parameters parsed from the URL of the HTTP request.
    public var pathParameters: [String: Substring]

    /// Creates a new metadata wrapper with the specified path and query parameters.
    /// - Parameters:
    ///   - pathParameters: Path parameters parsed from the URL of the HTTP
    ///   request.
    public init(
        pathParameters: [String: Substring] = [:]
    ) {
        self.pathParameters = pathParameters
    }
}

extension HTTPRequest {

    /// Creates a new request.
    /// - Parameters:
    ///   - path: The URL path of the resource.
    ///   - method: The HTTP method.
    @_spi(Generated)
    public init(path: String, method: Method) {
        self.init(method: method, scheme: nil, authority: nil, path: path)
    }

    /// The query substring of the request's path.
    @_spi(Generated)
    public var query: Substring? {
        guard let path else {
            return nil
        }
        guard let queryStart = path.firstIndex(of: "?") else {
            return nil
        }
        let queryEnd = path.firstIndex(of: "#") ?? path.endIndex
        let query = path[path.index(after: queryStart)..<queryEnd]
        return query
    }
}

extension HTTPResponse {

    /// Creates a new response.
    /// - Parameter statusCode: The status code of the response.AsString
    @_spi(Generated)
    public init(statusCode: Int) {
        self.init(status: .init(code: statusCode))
    }
}
