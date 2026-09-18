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

import HTTPTypes
import Logging
import XCTest
@_spi(Generated) import OpenAPIRuntime

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

final class Test_ClientOTelLoggingMiddleware: XCTestCase {
    func testRequestAndResponseAttributes() async throws {
        let events = try await recordedEvents(
            middleware: .init(requestHeaders: [.accept], responseHeaders: [.contentType]),
            request: HTTPRequest(
                soar_path: "/pets?limit=1",
                method: .get,
                headerFields: [.accept: "application/json", .userAgent: "Test/1.0"]
            ),
            body: HTTPBody("{}"),
            baseURL: try XCTUnwrap(URL(string: "https://example.com/api"))
        ) { _, _, _ in (HTTPResponse(status: .ok, headerFields: [.contentType: "application/json"]), HTTPBody("[]")) }

        XCTAssertEqual(events.count, 2)

        let requestAttributes: Logger.Metadata = [
            "network.transport": "tcp", "http.request.method": "GET", "server.address": "example.com",
            "url.scheme": "https", "url.full": "https://example.com/api/pets?limit=1", "http.request.body.size": "2",
            "user_agent.original": "Test/1.0", "http.request.header.accept": .array(["application/json"]),
        ]
        XCTAssertEqual(events.first?.level, .debug)
        XCTAssertEqual(events.first?.message, "HTTP Client Request")
        XCTAssertEqual(events.first?.metadata, requestAttributes)
        XCTAssertNil(events.first?.error)

        // The response is logged through the same logger, so it carries the request attributes too.
        XCTAssertEqual(events.last?.level, .debug)
        XCTAssertEqual(events.last?.message, "HTTP Client Response")
        XCTAssertEqual(
            events.last?.metadata,
            requestAttributes.merging([
                "http.response.status_code": "200", "http.response.body.size": "2",
                "http.response.header.content-type": .array(["application/json"]),
            ]) { _, new in new }
        )
    }

    func testURLComposition() async throws {
        try await assertURLAttributes(
            baseURL: "https://example.com/api",
            path: "/pets?limit=1",
            full: "https://example.com/api/pets?limit=1",
            address: "example.com",
            scheme: "https"
        )
        try await assertURLAttributes(
            baseURL: "https://example.com",
            path: "/pets",
            full: "https://example.com/pets",
            address: "example.com",
            scheme: "https"
        )
        try await assertURLAttributes(
            baseURL: "https://example.com/",
            path: "/pets",
            full: "https://example.com/pets",
            address: "example.com",
            scheme: "https"
        )
        try await assertURLAttributes(
            baseURL: "http://localhost:8080/v1/",
            path: "/pets/42",
            full: "http://localhost:8080/v1/pets/42",
            address: "localhost",
            port: "8080",
            scheme: "http"
        )
        try await assertURLAttributes(
            baseURL: "https://example.com/api",
            path: "/pets/a%20b?q=x%20y",
            full: "https://example.com/api/pets/a%20b?q=x%20y",
            address: "example.com",
            scheme: "https"
        )
        try await assertURLAttributes(
            baseURL: "https://example.com/api",
            path: "/pets",
            full: "https://example.com/api/pets",
            address: "example.com",
            scheme: "https"
        )
    }

    func testNilRequestPath() async throws {
        let events = try await recordedEvents(
            request: HTTPRequest(method: .get, scheme: nil, authority: nil, path: nil),
            baseURL: try XCTUnwrap(URL(string: "https://example.com/api"))
        ) { _, _, _ in (HTTPResponse(status: .ok), nil) }

        XCTAssertEqual(events.first?.metadata["url.full"], "https://example.com/api")
    }

    func testHeadersAreNotCapturedByDefault() async throws {
        let events = try await recordedEvents(
            request: HTTPRequest(soar_path: "/pets", method: .get, headerFields: [.accept: "application/json"]),
            baseURL: try XCTUnwrap(URL(string: "https://example.com"))
        ) { _, _, _ in (HTTPResponse(status: .ok, headerFields: [.contentType: "application/json"]), nil) }

        let headerKeys = events.last?.metadata.keys.filter { $0.contains(".header.") }
        XCTAssertEqual(headerKeys, [])
        XCTAssertEqual(events.last?.metadata["http.response.status_code"], "200")
    }

    func testRepeatedFieldIsCapturedAsOneAttribute() async throws {
        var headerFields = HTTPFields()
        headerFields[values: .init("X-Forwarded-For")!] = ["1.2.3.4", "1.2.3.5"]
        let events = try await recordedEvents(
            middleware: .init(requestHeaders: [.init("x-forwarded-for")!]),
            request: HTTPRequest(soar_path: "/pets", method: .get, headerFields: headerFields),
            baseURL: try XCTUnwrap(URL(string: "https://example.com"))
        ) { _, _, _ in (HTTPResponse(status: .ok), nil) }

        XCTAssertEqual(events.first?.metadata["http.request.header.x-forwarded-for"], .array(["1.2.3.4", "1.2.3.5"]))
    }

    func testCapturedFieldsThatAreAbsentAreOmitted() async throws {
        let events = try await recordedEvents(
            middleware: .init(requestHeaders: [.accept, .authorization], responseHeaders: [.eTag]),
            request: HTTPRequest(soar_path: "/pets", method: .get, headerFields: [.accept: "application/json"]),
            baseURL: try XCTUnwrap(URL(string: "https://example.com"))
        ) { _, _, _ in (HTTPResponse(status: .ok), nil) }

        XCTAssertEqual(events.first?.metadata["http.request.header.accept"], .array(["application/json"]))
        XCTAssertNil(events.first?.metadata["http.request.header.authorization"])
        XCTAssertNil(events.last?.metadata["http.response.header.etag"])
    }

    func testCapturedFieldNamesMatchCaseInsensitively() async throws {
        let events = try await recordedEvents(
            middleware: .init(requestHeaders: [.init("X-Custom")!]),
            request: HTTPRequest(soar_path: "/pets", method: .get, headerFields: [.init("x-custom")!: "value"]),
            baseURL: try XCTUnwrap(URL(string: "https://example.com"))
        ) { _, _, _ in (HTTPResponse(status: .ok), nil) }

        XCTAssertEqual(events.first?.metadata["http.request.header.x-custom"], .array(["value"]))
    }

    func testAllCapturesEveryField() async throws {
        let events = try await recordedEvents(
            middleware: .init(requestHeaders: .all, responseHeaders: .all),
            request: HTTPRequest(
                soar_path: "/pets",
                method: .get,
                headerFields: [.accept: "application/json", .userAgent: "Test/1.0"]
            ),
            baseURL: try XCTUnwrap(URL(string: "https://example.com"))
        ) { _, _, _ in
            (HTTPResponse(status: .ok, headerFields: [.contentType: "application/json", .eTag: "\"abc\""]), nil)
        }

        XCTAssertEqual(events.first?.metadata["http.request.header.accept"], .array(["application/json"]))
        // The `User-Agent` field is reported as `user_agent.original`, and, having been asked for
        // explicitly, as a header attribute too.
        XCTAssertEqual(events.first?.metadata["user_agent.original"], "Test/1.0")
        XCTAssertEqual(events.first?.metadata["http.request.header.user-agent"], .array(["Test/1.0"]))
        XCTAssertEqual(events.last?.metadata["http.response.header.content-type"], .array(["application/json"]))
        XCTAssertEqual(events.last?.metadata["http.response.header.etag"], .array(["\"abc\""]))
    }

    func testNoAttributesPropagateToTheTransport() async throws {
        let sink = RecordingLogHandler.Sink()
        _ = try await sink.record {
            try await ClientOTelLoggingMiddleware(requestHeaders: .all)
                .intercept(
                    HTTPRequest(soar_path: "/pets", method: .get, headerFields: [.accept: "application/json"]),
                    body: nil,
                    baseURL: try XCTUnwrap(URL(string: "https://example.com")),
                    operationID: "getPets",
                    next: { _, _, _ in
                        Logger.current.info("Sending")
                        return (HTTPResponse(status: .ok), nil)
                    }
                )
        }

        // The middleware annotates its own records only; the transport keeps the logger it was
        // given, and correlating the records is left to the trace identifiers.
        let transportEvent = try XCTUnwrap(sink.events.first { $0.message == "Sending" })
        XCTAssertEqual(transportEvent.metadata, [:])
    }

    func testCustomLogLevels() async throws {
        let events = try await recordedEvents(
            middleware: .init(logLevel: .info, errorLevel: .critical),
            request: HTTPRequest(soar_path: "/pets", method: .get),
            baseURL: try XCTUnwrap(URL(string: "https://example.com"))
        ) { _, _, _ in (HTTPResponse(status: .ok), nil) }
        XCTAssertEqual(events.map(\.level), [.info, .info])

        let sink = RecordingLogHandler.Sink()
        do {
            _ = try await sink.record {
                try await ClientOTelLoggingMiddleware(logLevel: .info, errorLevel: .critical)
                    .intercept(
                        HTTPRequest(soar_path: "/pets", method: .get),
                        body: nil,
                        baseURL: try XCTUnwrap(URL(string: "https://example.com")),
                        operationID: "getPets",
                        next: { _, _, _ in throw TestError() }
                    )
            }
            XCTFail("Expected the middleware to rethrow.")
        } catch is TestError {}
        // The request is already logged by the time `next` throws, so the error path emits two
        // records: the request at `logLevel` and the failure at `errorLevel`.
        XCTAssertEqual(sink.events.map(\.level), [.info, .critical])
    }

    func testUnknownAndAbsentBodyLengthOmitSize() async throws {
        let events = try await recordedEvents(
            request: HTTPRequest(soar_path: "/pets", method: .get),
            body: nil,
            baseURL: try XCTUnwrap(URL(string: "https://example.com"))
        ) { _, _, _ in (HTTPResponse(status: .ok), HTTPBody(ArraySlice<UInt8>([0x7b, 0x7d]), length: .unknown)) }

        XCTAssertNil(events.first?.metadata["http.request.body.size"])
        XCTAssertNil(events.last?.metadata["http.response.body.size"])
    }

    func testEmptyBodyReportsZeroSize() async throws {
        let events = try await recordedEvents(
            request: HTTPRequest(soar_path: "/pets", method: .post),
            body: HTTPBody(),
            baseURL: try XCTUnwrap(URL(string: "https://example.com"))
        ) { _, _, _ in (HTTPResponse(status: .ok), HTTPBody()) }

        XCTAssertEqual(events.first?.metadata["http.request.body.size"], "0")
        XCTAssertEqual(events.last?.metadata["http.response.body.size"], "0")
    }

    func testErrorPath() async throws {
        let sink = RecordingLogHandler.Sink()
        do {
            _ = try await sink.record {
                try await ClientOTelLoggingMiddleware()
                    .intercept(
                        HTTPRequest(soar_path: "/pets", method: .get),
                        body: nil,
                        baseURL: try XCTUnwrap(URL(string: "https://example.com")),
                        operationID: "getPets",
                        next: { _, _, _ in throw TestError() }
                    )
            }
            XCTFail("Expected the middleware to rethrow.")
        } catch is TestError {}

        // The request record is emitted before `next` runs, so a failure produces two records and
        // no "HTTP Client Response".
        let events = sink.events
        XCTAssertEqual(events.map(\.message), ["HTTP Client Request", "HTTP Client Request Error"])
        XCTAssertEqual(events.last?.level, .error)
        XCTAssertNil(events.last?.metadata["http.response.status_code"])
        XCTAssertTrue(events.last?.error is TestError)

        // The failure record keeps the full request context; the error is carried by the record
        // itself rather than by an attribute.
        let requestAttributes = try XCTUnwrap(events.first?.metadata)
        XCTAssertEqual(events.last?.metadata, requestAttributes)
    }

    // MARK: - Helpers

    private func recordedEvents(
        middleware: ClientOTelLoggingMiddleware = .init(),
        request: HTTPRequest,
        body: HTTPBody? = nil,
        baseURL: URL,
        operationID: String = "getPets",
        next: @escaping @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> [RecordingLogHandler.Event] {
        let sink = RecordingLogHandler.Sink()
        _ = try await sink.record {
            try await middleware.intercept(request, body: body, baseURL: baseURL, operationID: operationID, next: next)
        }
        return sink.events
    }

    private func assertURLAttributes(
        baseURL: String,
        path: String,
        full: String,
        address: String,
        port: Logger.Metadata.Value? = nil,
        scheme: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let events = try await recordedEvents(
            request: HTTPRequest(soar_path: path, method: .get),
            baseURL: try XCTUnwrap(URL(string: baseURL), file: file, line: line)
        ) { _, _, _ in (HTTPResponse(status: .ok), nil) }

        let metadata = try XCTUnwrap(events.first?.metadata, file: file, line: line)
        XCTAssertEqual(metadata["url.full"], "\(full)", file: file, line: line)
        XCTAssertEqual(metadata["server.address"], "\(address)", file: file, line: line)
        XCTAssertEqual(metadata["server.port"], port, file: file, line: line)
        XCTAssertEqual(metadata["url.scheme"], "\(scheme)", file: file, line: line)
    }
}

#endif
