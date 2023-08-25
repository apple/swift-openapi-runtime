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
@preconcurrency import struct Foundation.Data
@preconcurrency import struct Foundation.URLQueryItem
#endif

/// A header field used in an HTTP request or response.
public struct HeaderField: Hashable, Sendable {

    /// The name of the HTTP header field.
    public var name: String

    /// The value of the HTTP header field.
    public var value: String

    /// Creates a new HTTP header field.
    /// - Parameters:
    ///   - name: A name of the HTTP header field.
    ///   - value: A value of the HTTP header field.
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

/// Describes the HTTP method used in an OpenAPI operation.
///
/// https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.3.md#fixed-fields-7
public struct HTTPMethod: RawRepresentable, Hashable, Sendable {

    /// Describes an HTTP method explicitly supported by OpenAPI.
    private enum OpenAPIHTTPMethod: String, Hashable, Sendable {
        case GET
        case PUT
        case POST
        case DELETE
        case OPTIONS
        case HEAD
        case PATCH
        case TRACE
    }

    /// The underlying HTTP method.
    private let value: OpenAPIHTTPMethod

    /// Creates a new method from the provided known supported HTTP method.
    private init(value: OpenAPIHTTPMethod) {
        self.value = value
    }

    public init?(rawValue: String) {
        guard let value = OpenAPIHTTPMethod(rawValue: rawValue) else {
            return nil
        }
        self.value = value
    }

    public var rawValue: String {
        value.rawValue
    }

    /// The name of the HTTP method.
    public var name: String {
        rawValue
    }

    /// Returns an HTTP GET method.
    public static var get: Self {
        .init(value: .GET)
    }

    /// Returns an HTTP PUT method.
    public static var put: Self {
        .init(value: .PUT)
    }

    /// Returns an HTTP POST method.
    public static var post: Self {
        .init(value: .POST)
    }

    /// Returns an HTTP DELETE method.
    public static var delete: Self {
        .init(value: .DELETE)
    }

    /// Returns an HTTP OPTIONS method.
    public static var options: Self {
        .init(value: .OPTIONS)
    }

    /// Returns an HTTP HEAD method.
    public static var head: Self {
        .init(value: .HEAD)
    }

    /// Returns an HTTP PATCH method.
    public static var patch: Self {
        .init(value: .PATCH)
    }

    /// Returns an HTTP TRACE method.
    public static var trace: Self {
        .init(value: .TRACE)
    }
}

/// An HTTP request, sent by the client to the server.
public struct Request: Hashable, Sendable {

    /// The path of the URL for the HTTP request.
    public var path: String

    /// The query string of the URL for the HTTP request.
    ///
    /// A query string provides support for assigning values to parameters
    /// within a URL.
    ///
    /// _URL encoding_, officially known as _percent-encoding_, is a method
    /// to encode arbitrary data in a URI using only ASCII characters.
    ///
    /// An example of a URL with a query string is:
    ///
    /// ```
    /// https://example.com?name=Maria%20Ruiz&email=mruiz2%40icloud.com
    /// ```
    ///
    /// For this request, the query string is:
    ///
    /// ```
    /// name=Maria%20Ruiz&email=mruiz2%40icloud.com
    /// ```
    ///
    /// - NOTE: The `?` is a seperator in the URL and is **not** part of
    /// the query string.
    /// - NOTE: Only query parameter names and values are percent-encoded,
    /// the `&` and `=` remain.
    public var query: String?

    /// The method of the HTTP request.
    public var method: HTTPMethod

    /// The header fields of the HTTP request.
    public var headerFields: [HeaderField]

    /// The body data of the HTTP request.
    public var body: Data?

    /// Creates a new HTTP request.
    /// - Parameters:
    ///   - path: The path of the URL for the request. This must not include
    ///   the base URL of the server.
    ///   - query: The query string of the URL for the request. This should not
    ///   include the separator question mark (`?`) and the names and values
    ///   should be percent-encoded. See ``query`` for more information.
    ///   - method: The method of the HTTP request.
    ///   - headerFields: The header fields of the HTTP request.
    ///   - body: The body data of the HTTP request.
    ///
    /// An example of a request:
    /// ```
    /// let request = Request(
    ///   path: "/users",
    ///   query: "name=Maria%20Ruiz&email=mruiz2%40icloud.com",
    ///   method: .GET,
    ///   headerFields: [
    ///       .init(name: "Accept", value: "application/json"
    ///   ],
    ///   body: nil
    /// )
    /// ```
    public init(
        path: String,
        query: String? = nil,
        method: HTTPMethod,
        headerFields: [HeaderField] = [],
        body: Data? = nil
    ) {
        self.path = path
        self.query = query
        self.method = method
        self.headerFields = headerFields
        self.body = body
    }
}

/// An HTTP response, returned by the server to the client.
public struct Response: Hashable, Sendable {

    /// The status code of the HTTP response, for example `200`.
    public var statusCode: Int

    /// The header fields of the HTTP response.
    public var headerFields: [HeaderField]

    /// The body data of the HTTP response.
    public var body: Data

    /// Creates a new HTTP response.
    /// - Parameters:
    ///   - statusCode: The status code of the HTTP response, for example `200`.
    ///   - headerFeilds: The header fields of the HTTP response.
    ///   - body: The body data of the HTTP response.
    public init(
        statusCode: Int,
        headerFields: [HeaderField] = [],
        body: Data = .init()
    ) {
        self.statusCode = statusCode
        self.headerFields = headerFields
        self.body = body
    }
}

/// A container for request metadata already parsed and validated
/// by the server transport.
public struct ServerRequestMetadata: Hashable, Sendable {

    /// The path parameters parsed from the URL of the HTTP request.
    public var pathParameters: [String: String]

    /// The query parameters parsed from the URL of the HTTP request.
    @available(*, deprecated, message: "Use the Request.query string directly.")
    public var queryParameters: [URLQueryItem]

    /// Creates a new metadata wrapper with the specified path and query parameters.
    /// - Parameters:
    ///   - pathParameters: Path parameters parsed from the URL of the HTTP
    ///   request.
    ///   - queryParameters: The query parameters parsed from the URL of
    ///   the HTTP request.
    @available(*, deprecated, message: "Use the Request.query string directly.")
    public init(
        pathParameters: [String: String] = [:],
        queryParameters: [URLQueryItem] = []
    ) {
        self.pathParameters = pathParameters
        self.queryParameters = queryParameters
    }

    /// Creates a new metadata wrapper with the specified path and query parameters.
    /// - Parameters:
    ///   - pathParameters: Path parameters parsed from the URL of the HTTP
    ///   request.
    public init(
        pathParameters: [String: String] = [:]
    ) {
        self.pathParameters = pathParameters
        self.queryParameters = []
    }
}

/// Describes the kind and associated data of a URL path component.
public enum RouterPathComponent: Hashable, Sendable {

    /// A constant string component.
    ///
    /// For example, in `/pets`, the associated value is "pets".
    case constant(String)

    /// A parameter component.
    ///
    /// For example, in `/{petId}`, the associated value is "petId"
    case parameter(String)
}

extension RouterPathComponent: ExpressibleByStringLiteral {
    /// Creates a new component for the provided value.
    /// - Parameter value: A string literal. If the string begins with
    /// a colon (for example `":petId"`), it gets parsed as a parameter
    /// component, otherwise it is treated as a constant component.
    public init(stringLiteral value: StringLiteralType) {
        if value.first == ":" {
            self = .parameter(String(value.dropFirst()))
        } else {
            self = .constant(value)
        }
    }
}

extension RouterPathComponent: CustomStringConvertible {
    public var description: String {
        switch self {
        case .constant(let string):
            return string
        case .parameter(let string):
            return ":\(string)"
        }
    }
}
