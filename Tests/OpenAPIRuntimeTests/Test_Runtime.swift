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

import XCTest
@_spi(Generated) import OpenAPIRuntime

class Test_Runtime: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
    }

    var serverURL: URL {
        get throws {
            try URL(validatingOpenAPIServerURL: "/api")
        }
    }

    var configuration: Configuration {
        .init()
    }

    var converter: Converter {
        .init(configuration: configuration)
    }

    var testComponents: URLComponents {
        var components: URLComponents = .init()
        components.path = "/api"
        return components
    }

    var testRequest: OpenAPIRuntime.Request {
        .init(path: "/api", query: nil, method: .get)
    }

    var testDate: Date {
        Date(timeIntervalSince1970: 1_674_036_251)
    }

    var testDateString: String {
        "2023-01-18T10:04:11Z"
    }

    var testStruct: TestPet {
        .init(name: "Fluffz")
    }

    var testStructString: String {
        #"{"name":"Fluffz"}"#
    }

    var testStructPrettyString: String {
        #"""
        {
          "name" : "Fluffz"
        }
        """#
    }

    var testStructData: Data {
        testStructString.data(using: .utf8)!
    }

    var testStructPrettyData: Data {
        testStructPrettyString.data(using: .utf8)!
    }
}

public func XCTAssertEqualURLString(_ lhs: URL?, _ rhs: String, file: StaticString = #file, line: UInt = #line) {
    guard let lhs else {
        XCTFail("URL is nil")
        return
    }
    XCTAssertEqual(lhs.absoluteString, rhs, file: file, line: line)
}

struct TestPet: Codable, Equatable {
    var name: String
}

/// Injects an authentication header to every request.
struct AuthenticationMiddleware: ClientMiddleware {

    /// Authentication bearer token value.
    var token: String

    func intercept(
        _ request: Request,
        baseURL: URL,
        operationID: String,
        next: (Request, URL) async throws -> Response
    ) async throws -> Response {
        var request = request
        request.headerFields.append(
            .init(
                name: "Authorization",
                value: "Bearer \(token)"
            )
        )
        return try await next(request, baseURL)
    }
}

/// Prints the request method + path and response status code.
struct PrintingMiddleware: ClientMiddleware {
    func intercept(
        _ request: Request,
        baseURL: URL,
        operationID: String,
        next: (Request, URL) async throws -> Response
    ) async throws -> Response {
        print("Sending \(request.method.name) \(request.path)")
        do {
            let response = try await next(request, baseURL)
            print("Received: \(response.statusCode)")
            return response
        } catch {
            print("Failed with error: \(error.localizedDescription)")
            throw error
        }
    }
}
