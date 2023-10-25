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
import HTTPTypes

class Test_Runtime: XCTestCase {

    /// Setup method called before the invocation of each test method in the class.
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
        var components = URLComponents()
        components.path = "/api"
        return components
    }

    var testRequest: HTTPRequest {
        .init(soar_path: "/api", method: .get)
    }

    var testDate: Date {
        Date(timeIntervalSince1970: 1_674_036_251)
    }

    var testDateString: String {
        "2023-01-18T10:04:11Z"
    }

    var testDateEscapedString: String {
        "2023-01-18T10%3A04%3A11Z"
    }

    var testDateStringData: Data {
        Data(testDateString.utf8)
    }

    var testDateEscapedStringData: Data {
        Data(testDateEscapedString.utf8)
    }

    var testString: String {
        "hello"
    }

    var testStringData: Data {
        Data(testString.utf8)
    }

    var testQuotedString: String {
        "\"hello\""
    }

    var testQuotedStringData: Data {
        Data(testQuotedString.utf8)
    }

    var testStruct: TestPet {
        .init(name: "Fluffz")
    }

    var testStructDetailed: TestPetDetailed {
        .init(name: "Rover!", type: "Golden Retriever", age: "3")
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

    var testStructURLFormString: String {
        "age=3&name=Rover%21&type=Golden+Retriever"
    }

    var testStructBase64EncodedString: String {
        #""eyJuYW1lIjoiRmx1ZmZ6In0=""#  // {"name":"Fluffz"}
    }

    var testEnum: TestHabitat {
        .water
    }

    var testEnumString: String {
        "water"
    }

    var testStructData: Data {
        Data(testStructString.utf8)
    }

    var testStructPrettyData: Data {
        Data(testStructPrettyString.utf8)
    }

    var testStructURLFormData: Data {
        Data(testStructURLFormString.utf8)
    }

    @discardableResult
    func _testPrettyEncoded<Value: Encodable>(_ value: Value, expectedJSON: String) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        let encodedString = String(decoding: data, as: UTF8.self)
        XCTAssertEqual(encodedString, expectedJSON)
        return encodedString
    }

    func _getDecoded<Value: Decodable>(json: String) throws -> Value {
        let inputData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        return try decoder.decode(Value.self, from: inputData)
    }

    func testRoundtrip<Value: Codable & Equatable>(_ value: Value, expectedJSON: String) throws {
        let encodedString = try _testPrettyEncoded(value, expectedJSON: expectedJSON)
        let decoded: Value = try _getDecoded(json: encodedString)
        XCTAssertEqual(decoded, value)
    }
}

struct TestError: Error, Equatable {}

struct MockMiddleware: ClientMiddleware, ServerMiddleware {
    enum FailurePhase {
        case never
        case onRequest
        case onResponse
    }
    var failurePhase: FailurePhase = .never
    
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        if failurePhase == .onRequest {
            throw TestError()
        }
        let (response, responseBody) = try await next(request, body, baseURL)
        if failurePhase == .onResponse {
            throw TestError()
        }
        return (response, responseBody)
    }
    
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        metadata: ServerRequestMetadata,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        if failurePhase == .onRequest {
            throw TestError()
        }
        let (response, responseBody) = try await next(request, body, metadata)
        if failurePhase == .onResponse {
            throw TestError()
        }
        return (response, responseBody)
    }
}

/// Asserts that a given URL's absolute string representation is equal to an expected string.
///
/// - Parameters:
///   - lhs: The URL to test, which can be optional.
///   - rhs: The expected absolute string representation.
///   - file: The file name to include in the failure message (default is the source file where this function is called).
///   - line: The line number to include in the failure message (default is the line where this function is called).
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

struct TestPetDetailed: Codable, Equatable {
    var name: String
    var type: String
    var age: String
}

enum TestHabitat: String, Codable, Equatable {
    case water
    case land
    case air
}

/// Injects an authentication header to every request.
struct AuthenticationMiddleware: ClientMiddleware {

    /// Authentication bearer token value.
    var token: String

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        request.headerFields[.authorization] = "Bearer \(token)"
        return try await next(request, body, baseURL)
    }
}

/// Prints the request method + path and response status code.
struct PrintingMiddleware: ClientMiddleware {
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        print("Sending \(request.method) \(request.path ?? "<no path>")")
        do {
            let (response, responseBody) = try await next(request, body, baseURL)
            print("Received: \(response.status)")
            return (response, responseBody)
        } catch {
            print("Failed with error: \(error.localizedDescription)")
            throw error
        }
    }
}

/// Asserts that the string representation of binary data in a given sequence is equal to an expected string.
///
/// - Parameters:
///   - expression1: An autoclosure that evaluates to a sequence of `UInt8`, typically binary data.
///   - expression2: An autoclosure that evaluates to the expected string.
///   - message: An optional custom message to display upon test failure.
///   - file: The file name to include in the failure message (default is the source file where this function is called).
///   - line: The line number to include in the failure message (default is the line where this function is called).
public func XCTAssertEqualStringifiedData<S: Sequence>(
    _ expression1: @autoclosure () throws -> S?,
    _ expression2: @autoclosure () throws -> String,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) where S.Element == UInt8 {
    do {
        guard let value1 = try expression1() else {
            XCTFail("First value is nil", file: file, line: line)
            return
        }
        let actualString = String(decoding: Array(value1), as: UTF8.self)
        XCTAssertEqual(actualString, try expression2(), file: file, line: line)
    } catch {
        XCTFail(error.localizedDescription, file: file, line: line)
    }
}

/// Asserts that the string representation of binary data in an HTTP body is equal to an expected string.
/// - Parameters:
///   - expression1: An autoclosure that evaluates to an `HTTPBody?`, which represents the binary data.
///   - expression2: An autoclosure that evaluates to the expected string.
///   - message: An optional custom message to display upon test failure.
///   - file: The file name to include in the failure message (default is the source file where this function is called).
///   - line: The line number to include in the failure message (default is the line where this function is called).
/// - Throws: If either of the autoclosures throws an error, the function will rethrow that error.
public func XCTAssertEqualStringifiedData(
    _ expression1: @autoclosure () throws -> HTTPBody?,
    _ expression2: @autoclosure () throws -> String,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async throws {
    let data: Data
    if let body = try expression1() {
        data = try await Data(collecting: body, upTo: .max)
    } else {
        data = .init()
    }
    XCTAssertEqualStringifiedData(data, try expression2(), message(), file: file, line: line)
}
