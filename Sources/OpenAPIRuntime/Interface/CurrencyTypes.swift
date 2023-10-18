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
    /// - Parameter pathParameters: Path parameters parsed from the URL of the HTTP
    ///     request.
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
    ///   - headerFields: The HTTP header fields.
    @_spi(Generated)
    public init(soar_path path: String, method: Method, headerFields: HTTPFields = .init()) {
        self.init(method: method, scheme: nil, authority: nil, path: path, headerFields: headerFields)
    }

    /// The query substring of the request's path.
    @_spi(Generated)
    public var soar_query: Substring? {
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

    /// The request path, without any query or fragment portions.
    @_spi(Generated)
    public var soar_pathOnly: Substring {
        guard let path else {
            return ""[...]
        }
        let pathEndIndex = path.firstIndex(of: "?") ?? path.firstIndex(of: "#") ?? path.endIndex
        return path[path.startIndex..<pathEndIndex]
    }
}

extension HTTPResponse {

    /// Creates a new response.
    /// - Parameter statusCode: The status code of the response.AsString
    @_spi(Generated)
    public init(soar_statusCode statusCode: Int) {
        self.init(status: .init(code: statusCode))
    }
}

extension ServerRequestMetadata: CustomStringConvertible {
    /// A textual description of the `ServerRequestMetadata` instance.
    /// The description includes information about path parameters.
    public var description: String {
        "Path parameters: \(pathParameters.description)"
    }
}

extension HTTPFields: PrettyStringConvertible {
    var prettyDescription: String {
        sorted(by: { $0.name.canonicalName.localizedCompare($1.name.canonicalName) == .orderedAscending })
            .map { "\($0.name.canonicalName): \($0.value)" }
            .joined(separator: "; ")
    }
}

extension HTTPRequest: PrettyStringConvertible {
    var prettyDescription: String {
        "\(method.rawValue) \(path ?? "<nil>") [\(headerFields.prettyDescription)]"
    }
}

extension HTTPResponse: PrettyStringConvertible {
    var prettyDescription: String {
        "\(status.code) [\(headerFields.prettyDescription)]"
    }
}

extension HTTPBody: PrettyStringConvertible {
    var prettyDescription: String {
        String(describing: self)
    }
}
