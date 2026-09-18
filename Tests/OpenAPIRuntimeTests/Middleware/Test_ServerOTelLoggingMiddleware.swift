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

final class Test_ServerOTelLoggingMiddleware: XCTestCase {
    func testRequestAndResponseAttributes() async throws {
        let events = try await recordedEvents(
            middleware: .init(
                requestHeaders: [.accept],
                responseHeaders: [.contentType],
                serverAddress: "0.0.0.0",
                serverPort: 8080
            ),
            request: HTTPRequest(
                method: .get,
                scheme: "https",
                authority: "example.com",
                path: "/api/pets?limit=1",
                headerFields: [.accept: "application/json", .userAgent: "Test/1.0"]
            ),
            body: HTTPBody("{}")
        ) { _, _, _ in (HTTPResponse(status: .ok, headerFields: [.contentType: "application/json"]), HTTPBody("[]")) }

        XCTAssertEqual(events.count, 2)

        let requestAttributes: Logger.Metadata = [
            "server.address": "0.0.0.0", "server.port": "8080", "network.transport": "tcp",
            "http.request.method": "GET", "url.scheme": "https", "url.full": "https://example.com/api/pets?limit=1",
            "http.request.body.size": "2", "user_agent.original": "Test/1.0",
            "http.request.header.accept": .array(["application/json"]),
        ]
        XCTAssertEqual(events.first?.level, .debug)
        XCTAssertEqual(events.first?.message, "HTTP Server Request")
        XCTAssertEqual(events.first?.metadata, requestAttributes)
        XCTAssertNil(events.first?.error)

        // The response is logged through the same logger, so it carries the request attributes too.
        XCTAssertEqual(events.last?.level, .debug)
        XCTAssertEqual(events.last?.message, "HTTP Server Response")
        XCTAssertEqual(
            events.last?.metadata,
            requestAttributes.merging([
                "http.response.status_code": "200", "http.response.body.size": "2",
                "http.response.header.content-type": .array(["application/json"]),
            ]) { _, new in new }
        )
    }

    func testPeerAttributesAreOmittedWhenNotConfigured() async throws {
        let events = try await recordedEvents(request: HTTPRequest(soar_path: "/api/pets", method: .get)) { _, _, _ in
            (HTTPResponse(status: .ok), nil)
        }

        XCTAssertNil(events.first?.metadata["server.address"])
        XCTAssertNil(events.first?.metadata["server.port"])
        XCTAssertEqual(events.first?.metadata["network.transport"], "tcp")
    }

    func testCustomNetworkTransport() async throws {
        let events = try await recordedEvents(
            middleware: .init(networkTransport: "unix"),
            request: HTTPRequest(soar_path: "/api/pets", method: .get)
        ) { _, _, _ in (HTTPResponse(status: .ok), nil) }

        XCTAssertEqual(events.first?.metadata["network.transport"], "unix")
    }

    func testURLAttributesRequireSchemeAndAuthority() async throws {
        // A request built without a scheme or authority — as `soar_path` produces — has no
        // absolute URL to report.
        let events = try await recordedEvents(request: HTTPRequest(soar_path: "/api/pets", method: .get)) { _, _, _ in
            (HTTPResponse(status: .ok), nil)
        }
        XCTAssertNil(events.first?.metadata["url.full"])
        XCTAssertNil(events.first?.metadata["url.scheme"])

        // The scheme alone is reported even when the authority is missing.
        let schemeOnly = try await recordedEvents(
            request: HTTPRequest(method: .get, scheme: "https", authority: nil, path: "/api/pets")
        ) { _, _, _ in (HTTPResponse(status: .ok), nil) }
        XCTAssertEqual(schemeOnly.first?.metadata["url.scheme"], "https")
        XCTAssertNil(schemeOnly.first?.metadata["url.full"])
    }

    func testHeadersAreNotCapturedByDefault() async throws {
        let events = try await recordedEvents(
            request: HTTPRequest(soar_path: "/api/pets", method: .get, headerFields: [.accept: "application/json"])
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
            request: HTTPRequest(soar_path: "/api/pets", method: .get, headerFields: headerFields)
        ) { _, _, _ in (HTTPResponse(status: .ok), nil) }

        XCTAssertEqual(events.first?.metadata["http.request.header.x-forwarded-for"], .array(["1.2.3.4", "1.2.3.5"]))
    }

    func testCapturedFieldsThatAreAbsentAreOmitted() async throws {
        let events = try await recordedEvents(
            middleware: .init(requestHeaders: [.accept, .authorization], responseHeaders: [.eTag]),
            request: HTTPRequest(soar_path: "/api/pets", method: .get, headerFields: [.accept: "application/json"])
        ) { _, _, _ in (HTTPResponse(status: .ok), nil) }

        XCTAssertEqual(events.first?.metadata["http.request.header.accept"], .array(["application/json"]))
        XCTAssertNil(events.first?.metadata["http.request.header.authorization"])
        XCTAssertNil(events.last?.metadata["http.response.header.etag"])
    }

    func testCapturedFieldNamesMatchCaseInsensitively() async throws {
        let events = try await recordedEvents(
            middleware: .init(requestHeaders: [.init("X-Custom")!]),
            request: HTTPRequest(soar_path: "/api/pets", method: .get, headerFields: [.init("x-custom")!: "value"])
        ) { _, _, _ in (HTTPResponse(status: .ok), nil) }

        XCTAssertEqual(events.first?.metadata["http.request.header.x-custom"], .array(["value"]))
    }

    func testExcludeCapturesEveryOtherField() async throws {
        let events = try await recordedEvents(
            middleware: .init(requestHeaders: .exclude([.authorization]), responseHeaders: .exclude([.setCookie])),
            request: HTTPRequest(
                soar_path: "/api/pets",
                method: .get,
                headerFields: [.accept: "application/json", .authorization: "Bearer secret"]
            )
        ) { _, _, _ in
            (HTTPResponse(status: .ok, headerFields: [.contentType: "application/json", .setCookie: "session=1"]), nil)
        }

        XCTAssertEqual(events.first?.metadata["http.request.header.accept"], .array(["application/json"]))
        XCTAssertNil(events.first?.metadata["http.request.header.authorization"])
        XCTAssertEqual(events.last?.metadata["http.response.header.content-type"], .array(["application/json"]))
        XCTAssertNil(events.last?.metadata["http.response.header.set-cookie"])
    }

    func testExcludingNothingCapturesEveryField() async throws {
        let events = try await recordedEvents(
            middleware: .init(requestHeaders: .exclude([])),
            request: HTTPRequest(soar_path: "/api/pets", method: .get, headerFields: [.accept: "application/json"])
        ) { _, _, _ in (HTTPResponse(status: .ok), nil) }

        XCTAssertEqual(events.first?.metadata["http.request.header.accept"], .array(["application/json"]))
    }

    func testIncludingNothingCapturesNoField() async throws {
        let events = try await recordedEvents(
            middleware: .init(requestHeaders: .include([])),
            request: HTTPRequest(soar_path: "/api/pets", method: .get, headerFields: [.accept: "application/json"])
        ) { _, _, _ in (HTTPResponse(status: .ok), nil) }

        XCTAssertEqual(events.first?.metadata.keys.filter { $0.contains(".header.") }, [])
    }

    func testAllCapturesEveryField() async throws {
        let events = try await recordedEvents(
            middleware: .init(requestHeaders: .all, responseHeaders: .all),
            request: HTTPRequest(
                soar_path: "/api/pets",
                method: .get,
                headerFields: [.accept: "application/json", .userAgent: "Test/1.0"]
            )
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

    func testNoAttributesPropagateToTheHandler() async throws {
        let sink = RecordingLogHandler.Sink()
        _ = try await sink.record {
            try await ServerOTelLoggingMiddleware(requestHeaders: .all)
                .intercept(
                    HTTPRequest(soar_path: "/api/pets", method: .get, headerFields: [.accept: "application/json"]),
                    body: nil,
                    metadata: .init(),
                    operationID: "getPets",
                    next: { _, _, _ in
                        Logger.current.info("Handling")
                        return (HTTPResponse(status: .ok), nil)
                    }
                )
        }

        // The middleware annotates its own records only; the handler keeps the logger it was given,
        // and correlating the records is left to the trace identifiers.
        let handlerEvent = try XCTUnwrap(sink.events.first { $0.message == "Handling" })
        XCTAssertEqual(handlerEvent.metadata, [:])
    }

    func testUnknownAndAbsentBodyLengthOmitSize() async throws {
        let streamedBody = HTTPBody(ArraySlice<UInt8>([0x7b, 0x7d]), length: .unknown)
        let request = HTTPRequest(soar_path: "/api/pets", method: .get)
        let events = try await recordedEvents(request: request, body: nil) { _, _, _ in
            (HTTPResponse(status: .ok), streamedBody)
        }

        XCTAssertNil(events.first?.metadata["http.request.body.size"])
        XCTAssertNil(events.last?.metadata["http.response.body.size"])
    }

    func testEmptyBodyReportsZeroSize() async throws {
        let events = try await recordedEvents(
            request: HTTPRequest(soar_path: "/api/pets", method: .post),
            body: HTTPBody()
        ) { _, _, _ in (HTTPResponse(status: .ok), HTTPBody()) }

        XCTAssertEqual(events.first?.metadata["http.request.body.size"], "0")
        XCTAssertEqual(events.last?.metadata["http.response.body.size"], "0")
    }

    func testErrorPath() async throws {
        let sink = RecordingLogHandler.Sink()
        do {
            _ = try await sink.record {
                try await ServerOTelLoggingMiddleware()
                    .intercept(
                        HTTPRequest(soar_path: "/api/pets", method: .get),
                        body: nil,
                        metadata: .init(),
                        operationID: "getPets",
                        next: { _, _, _ in throw TestError() }
                    )
            }
            XCTFail("Expected the middleware to rethrow.")
        } catch is TestError {}

        let events = sink.events
        XCTAssertEqual(events.map(\.message), ["HTTP Server Request", "HTTP Server Request Error"])
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
        middleware: ServerOTelLoggingMiddleware = .init(),
        request: HTTPRequest,
        body: HTTPBody? = nil,
        operationID: String = "getPets",
        next:
            @escaping @Sendable (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (
                HTTPResponse, HTTPBody?
            )
    ) async throws -> [RecordingLogHandler.Event] {
        let sink = RecordingLogHandler.Sink()
        _ = try await sink.record {
            try await middleware.intercept(request, body: body, metadata: .init(), operationID: operationID, next: next)
        }
        return sink.events
    }
}

#endif
