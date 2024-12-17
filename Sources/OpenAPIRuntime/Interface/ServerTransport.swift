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

public import HTTPTypes

/// A type that registers and handles HTTP operations.
///
/// Decouples the HTTP server framework from the generated server code.
///
/// ### Choose between a transport and a middleware
///
/// The ``ServerTransport`` and ``ServerMiddleware`` protocols look similar,
/// however each serves a different purpose.
///
/// A _transport_ abstracts over the underlying HTTP library that actually
/// receives the HTTP requests from the network. An implemented _handler_
/// (a type implemented by you that conforms to the generated `APIProtocol`
/// protocol) is generally configured with exactly one server transport.
///
/// A _middleware_ intercepts the HTTP request and response, without being
/// responsible for receiving the HTTP operations itself. That's why
/// middlewares take the extra `next` parameter, to delegate calling the handler
/// to the transport at the top of the middleware stack.
///
/// ### Use an existing server transport
///
/// Instantiate the transport using the parameters required by the specific
/// implementation. For example, using the server transport for the
/// `Vapor` web framework, first create the `Application` object provided by
/// Vapor, and provided it to the initializer of `VaporTransport`:
///
///     let app = Vapor.Application()
///     let transport = VaporTransport(routesBuilder: app)
///
/// Implement a new type that conforms to the generated `APIProtocol`, which
/// serves as the request handler of your server's business logic. For example,
/// this is what a simple implementation of a server that has a single
/// HTTP operation called `checkHealth` defined in the OpenAPI document, and
/// it always returns the 200 HTTP status code:
///
///     struct MyAPIImplementation: APIProtocol {
///         func checkHealth(
///             _ input: Operations.checkHealth.Input
///         ) async throws -> Operations.checkHealth.Output {
///             .ok(.init())
///         }
///     }
///
/// The generated operation method takes an `Input` type unique to
/// the operation, and returns an `Output` type unique to the operation.
///
/// > Note: You use the `Input` type to provide parameters such as HTTP request
/// headers, query items, path parameters, and request bodies; and inspect
/// the `Output` type to handle the received HTTP response status code,
/// response header and body.
///
/// Create an instance of your handler:
///
///     let handler = MyAPIImplementation()
///
/// Create the URL where the server will run. The path of the URL is extracted
/// by the transport to create a common prefix (such as `/api/v1`) that might
/// be expected by the clients.
///
/// Register the generated request handlers by calling the method generated
/// on the `APIProtocol` protocol:
///
///     try handler.registerHandlers(
///         on: transport,
///         serverURL: URL(string: "/api/v1")!
///     )
///
/// Start the server by following the documentation of your chosen transport:
///
///     try await app.execute()
///
/// ### Implement a custom server transport
///
/// If a server transport implementation for your preferred web framework
/// doesn't yet exist, or you need to simulate rare network conditions in
/// your tests, consider implementing a custom server transport.
///
/// Define a new type that conforms to the `ServerTransport` protocol by
/// registering request handlers with the underlying web framework, to be
/// later called when the web framework receives an HTTP request to one
/// of the HTTP routes.
///
/// In tests, this might require using the web framework's specific test
/// APIs to allow for simulating incoming HTTP requests.
///
/// Implementing a test server transport is just one way to help test your
/// code that integrates with your handler. Another is to implement
/// a type conforming to the generated protocol `APIProtocol`, and to implement
/// a custom ``ServerMiddleware``.
public protocol ServerTransport {

    /// Registers an HTTP operation handler at the provided path and method.
    /// - Parameters:
    ///   - handler: A handler to be invoked when an HTTP request is received.
    ///   - method: An HTTP request method.
    ///   - path: A URL template for the path, for example `/pets/{petId}`.
    /// - Throws: An error if the registration of the handler fails.
    /// - Important: The `path` can have mixed components, such
    ///   as `/file/{name}.zip`.
    func register(
        _ handler: @Sendable @escaping (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (
            HTTPResponse, HTTPBody?
        ),
        method: HTTPRequest.Method,
        path: String
    ) throws
}

/// A type that intercepts HTTP requests and responses.
///
/// It allows you to customize the request after it was provided by
/// the transport, but before it was parsed, validated, and provided to
/// the request handler; and the response after it was provided by the request
/// handler, but before it was handed back to the transport.
///
/// Appropriate for verifying authentication, performing logging, metrics,
/// tracing, injecting custom headers such as "user-agent", and more.
///
/// ### Choose between a transport and a middleware
///
/// The ``ServerTransport`` and ``ServerMiddleware`` protocols look similar,
/// however each serves a different purpose.
///
/// A _transport_ abstracts over the underlying HTTP library that actually
/// receives the HTTP requests from the network. An implemented _handler_
/// (a type implemented by you that conforms to the generated `APIProtocol`
/// protocol) is generally configured with exactly one server transport.
///
/// A _middleware_ intercepts the HTTP request and response, without being
/// responsible for receiving the HTTP operations itself. That's why
/// middlewares take the extra `next` parameter, to delegate calling the handler
/// to the transport at the top of the middleware stack.
///
/// ### Use an existing server middleware
///
/// Instantiate the middleware using the parameters required by the specific
/// implementation. For example, using a hypothetical existing middleware
/// that logs every request and response:
///
///     let loggingMiddleware = LoggingMiddleware()
///
/// Similarly to the process of using an existing ``ServerTransport``, provide
/// the middleware to the call to register handlers:
///
///     try handler.registerHandlers(
///         on: transport,
///         serverURL: URL(string: "/api/v1")!,
///         middlewares: [
///             loggingMiddleware,
///         ]
///     )
///
/// Then when an HTTP request is received, the server first invokes
/// the middlewares in the order you provided them, and then passes
/// the parsed request to your handler. When a response is received from
/// the handler, the last middleware handles the response first, and it goes
/// back in the reverse order of the `middlewares` array. At the end,
/// the transport sends the final response back to the client.
///
/// ### Implement a custom server middleware
///
/// If a server middleware implementation with your desired behavior doesn't
/// yet exist, or you need to simulate rare requests in your tests,
/// consider implementing a custom server middleware.
///
/// For example, an implementation a middleware that prints only basic
/// information about the incoming request and outgoing response:
///
///     /// A middleware that prints request and response metadata.
///     struct PrintingMiddleware: ServerMiddleware {
///         func intercept(
///             _ request: HTTPRequest,
///             body: HTTPBody?,
///             metadata: ServerRequestMetadata,
///             operationID: String,
///             next: (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (HTTPResponse, HTTPBody?)
///         ) async throws -> (HTTPResponse, HTTPBody?) {
///             print(">>>: \(request.method.rawValue) \(request.soar_pathOnly)")
///             do {
///                 let (response, responseBody) = try await next(request, body, metadata)
///                 print("<<<: \(response.status.code)")
///                 return (response, responseBody)
///             } catch {
///                 print("!!!: \(error.localizedDescription)")
///                 throw error
///             }
///         }
///     }
///
/// Implementing a test server middleware is just one way to help test your
/// code that integrates with your handler. Another is to implement
/// a type conforming to the generated protocol `APIProtocol`, and to implement
/// a custom ``ServerTransport``.
public protocol ServerMiddleware: Sendable {

    /// Intercepts an incoming HTTP request and an outgoing HTTP response.
    /// - Parameters:
    ///   - request: An HTTP request.
    ///   - body: An HTTP request body.
    ///   - metadata: The metadata parsed from the HTTP request, including path
    ///   parameters.
    ///   - operationID: The identifier of the OpenAPI operation.
    ///   - next: A closure that calls the next middleware, or the transport.
    /// - Returns: An HTTP response and its body.
    /// - Throws: An error if the interception process fails.
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        metadata: ServerRequestMetadata,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?)
}
