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
@_spi(Generated) @testable import OpenAPIRuntime
import HTTPTypes

class Test_Runtime: XCTestCase {

    /// Setup method called before the invocation of each test method in the class.
    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
    }

    var serverURL: URL { get throws { try URL(validatingOpenAPIServerURL: "/api") } }

    var customCoder: any CustomCoder { MockCustomCoder() }
    var configuration: Configuration { .init(multipartBoundaryGenerator: .constant, xmlCoder: customCoder) }

    var converter: Converter { .init(configuration: configuration) }

    var testComponents: URLComponents {
        var components = URLComponents()
        components.path = "/api"
        return components
    }

    var testRequest: HTTPRequest { .init(soar_path: "/api", method: .get) }

    var testDate: Date { Date(timeIntervalSince1970: 1_674_036_251) }

    var testDateString: String { "2023-01-18T10:04:11Z" }

    var testDateWithFractionalSeconds: Date { Date(timeIntervalSince1970: 1_674_036_251.123) }

    var testDateWithFractionalSecondsString: String { "2023-01-18T10:04:11.123Z" }

    var testDateEscapedString: String { "2023-01-18T10%3A04%3A11Z" }

    var testDateStringData: Data { Data(testDateString.utf8) }

    var testDateEscapedStringData: Data { Data(testDateEscapedString.utf8) }

    var testString: String { "hello" }

    var testStringData: Data { Data(testString.utf8) }

    var testMultipartString: String { "hello" }

    var testMultipartStringBytes: ArraySlice<UInt8> {
        var bytes: [UInt8] = []
        bytes.append(contentsOf: "--__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__".utf8)
        bytes.append(contentsOf: ASCII.crlf)
        bytes.append(contentsOf: #"content-disposition: form-data; filename="foo.txt"; name="hello""#.utf8)
        bytes.append(contentsOf: ASCII.crlf)
        bytes.append(contentsOf: #"content-length: 5"#.utf8)
        bytes.append(contentsOf: ASCII.crlf)
        bytes.append(contentsOf: ASCII.crlf)
        bytes.append(contentsOf: "hello".utf8)
        bytes.append(contentsOf: ASCII.crlf)
        bytes.append(contentsOf: "--__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__".utf8)
        bytes.append(contentsOf: ASCII.crlf)
        bytes.append(contentsOf: #"content-disposition: form-data; filename="bar.txt"; name="world""#.utf8)
        bytes.append(contentsOf: ASCII.crlf)
        bytes.append(contentsOf: #"content-length: 5"#.utf8)
        bytes.append(contentsOf: ASCII.crlf)
        bytes.append(contentsOf: ASCII.crlf)
        bytes.append(contentsOf: "world".utf8)
        bytes.append(contentsOf: ASCII.crlf)
        bytes.append(contentsOf: "--__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__--".utf8)
        bytes.append(contentsOf: ASCII.crlf)
        bytes.append(contentsOf: ASCII.crlf)
        return ArraySlice(bytes)
    }

    var testQuotedString: String { "\"hello\"" }

    var testQuotedStringData: Data { Data(testQuotedString.utf8) }

    var testStruct: TestPet { .init(name: "Fluffz") }

    var testStructDetailed: TestPetDetailed { .init(name: "Rover!", type: "Golden Retriever", age: "3") }

    var testStructString: String { #"{"name":"Fluffz"}"# }

    var testStructPrettyString: String {
        #"""
        {
          "name" : "Fluffz"
        }
        """#
    }

    var testStructURLFormString: String { "age=3&name=Rover%21&type=Golden+Retriever" }

    var testStructBase64EncodedString: String {
        #""eyJuYW1lIjoiRmx1ZmZ6In0=""#  // {"name":"Fluffz"}
    }

    var testEnum: TestHabitat { .water }

    var testEnumString: String { "water" }

    var testStructData: Data { Data(testStructString.utf8) }

    var testStructPrettyData: Data { Data(testStructPrettyString.utf8) }

    var testStructURLFormData: Data { Data(testStructURLFormString.utf8) }

    var testEvents: [TestPet] { [.init(name: "Rover"), .init(name: "Pancake")] }
    var testEventsAsyncSequence: WrappedSyncSequence<[TestPet]> { WrappedSyncSequence(sequence: testEvents) }

    var testJSONLinesBytes: ArraySlice<UInt8> {
        let encoder = JSONEncoder()
        let bytes = try! testEvents.map { try encoder.encode($0) + [ASCII.lf] }.joined()
        return ArraySlice(bytes)
    }
    var testJSONSequenceBytes: ArraySlice<UInt8> {
        let encoder = JSONEncoder()
        let bytes = try! testEvents.map { try [ASCII.rs] + encoder.encode($0) + [ASCII.lf] }.joined()
        return ArraySlice(bytes)
    }

    func asOneBytePerElementSequence(_ source: ArraySlice<UInt8>) -> HTTPBody {
        HTTPBody(
            WrappedSyncSequence(sequence: source).map { ArraySlice([$0]) },
            length: .known(Int64(source.count)),
            iterationBehavior: .multiple
        )
    }
    var testJSONLinesOneBytePerElementSequence: HTTPBody { asOneBytePerElementSequence(testJSONLinesBytes) }
    var testJSONSequenceOneBytePerElementSequence: HTTPBody { asOneBytePerElementSequence(testJSONSequenceBytes) }
    @discardableResult func _testPrettyEncoded<Value: Encodable>(_ value: Value, expectedJSON: String) throws -> String
    {
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

/// Each line gets a CRLF added. Extra CRLFs are added after the last line's CRLF.
func chunkFromStringLines(_ strings: [String], addExtraCRLFs: Int = 0) -> ArraySlice<UInt8> {
    var slice: ArraySlice<UInt8> = []
    for string in strings { slice.append(contentsOf: chunkFromString(string, addCRLFs: 1)) }
    slice.append(contentsOf: chunkFromString("", addCRLFs: addExtraCRLFs))
    return slice
}

func chunkFromString(_ string: String, addCRLFs: Int = 0) -> ArraySlice<UInt8> {
    var slice = ArraySlice(string.utf8)
    for _ in 0..<addCRLFs { slice.append(contentsOf: ASCII.crlf) }
    return slice
}

func bufferFromString(_ string: String) -> [UInt8] { Array(string.utf8) }

extension ArraySlice<UInt8> {
    mutating func append(_ string: String) { append(contentsOf: chunkFromString(string)) }
    mutating func appendCRLF() { append(contentsOf: ASCII.crlf) }
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
        if failurePhase == .onRequest { throw TestError() }
        let (response, responseBody) = try await next(request, body, baseURL)
        if failurePhase == .onResponse { throw TestError() }
        return (response, responseBody)
    }

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        metadata: ServerRequestMetadata,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        if failurePhase == .onRequest { throw TestError() }
        let (response, responseBody) = try await next(request, body, metadata)
        if failurePhase == .onResponse { throw TestError() }
        return (response, responseBody)
    }
}

struct MockCustomCoder: CustomCoder {
    func customEncode<T>(_ value: T) throws -> Data where T: Encodable { try JSONEncoder().encode(value) }
    func customDecode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        try JSONDecoder().decode(T.self, from: data)
    }
}

/// Asserts that a given URL's absolute string representation is equal to an expected string.
///
/// - Parameters:
///   - lhs: The URL to test, which can be optional.
///   - rhs: The expected absolute string representation.
///   - file: The file name to include in the failure message (default is the source file where this function is called).
///   - line: The line number to include in the failure message (default is the line where this function is called).
public func XCTAssertEqualURLString(_ lhs: URL?, _ rhs: String, file: StaticString = #filePath, line: UInt = #line) {
    guard let lhs else {
        XCTFail("URL is nil")
        return
    }
    XCTAssertEqual(lhs.absoluteString, rhs, file: file, line: line)
}

struct TestPet: Codable, Equatable { var name: String }

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

enum MultipartTestPart: Hashable {
    case hello(payload: String, filename: String?)
    case world(payload: String, filename: String?)
    var rawPart: MultipartRawPart {
        switch self {
        case .hello(let payload, let filename):
            return .init(name: "hello", filename: filename, headerFields: [:], body: .init(payload))
        case .world(let payload, let filename):
            return .init(name: "world", filename: filename, headerFields: [:], body: .init(payload))
        }
    }
    init(_ rawPart: MultipartRawPart) async throws {
        switch rawPart.name {
        case "hello":
            self = .hello(payload: try await String(collecting: rawPart.body, upTo: .max), filename: rawPart.filename)
        case "world":
            self = .world(payload: try await String(collecting: rawPart.body, upTo: .max), filename: rawPart.filename)
        default: preconditionFailure("Unexpected part: \(rawPart.name ?? "<nil>")")
        }
    }
    static var all: [MultipartTestPart] {
        [.hello(payload: "hello", filename: "foo.txt"), .world(payload: "world", filename: "bar.txt")]
    }
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
    } catch { XCTFail(error.localizedDescription, file: file, line: line) }
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
    if let body = try expression1() { data = try await Data(collecting: body, upTo: .max) } else { data = .init() }
    XCTAssertEqualStringifiedData(data, try expression2(), message(), file: file, line: line)
}

fileprivate extension UInt8 {
    var asHex: String {
        let original: String
        switch self {
        case ASCII.cr: original = "CR"
        case ASCII.lf: original = "LF"
        case ASCII.rs: original = "RS"
        default: original = "\(UnicodeScalar(self)) "
        }
        return String(format: "%02x \(original)", self)
    }
}

/// Asserts that the data matches the expected value.
public func XCTAssertEqualData<C1: Collection, C2: Collection>(
    _ expression1: @autoclosure () throws -> C1?,
    _ expression2: @autoclosure () throws -> C2,
    _ message: @autoclosure () -> String = "Data doesn't match.",
    file: StaticString = #filePath,
    line: UInt = #line
) where C1.Element == UInt8, C2.Element == UInt8 {
    do {
        guard let actualBytes = try expression1() else {
            XCTFail("First value is nil", file: file, line: line)
            return
        }
        let expectedBytes = try expression2()
        if ArraySlice(actualBytes) == ArraySlice(expectedBytes) { return }
        let actualCount = actualBytes.count
        let expectedCount = expectedBytes.count
        let minCount = min(actualCount, expectedCount)
        print("Printing both byte sequences, first is the actual value and second is the expected one.")
        for (index, byte) in zip(actualBytes.prefix(minCount), expectedBytes.prefix(minCount)).enumerated() {
            print("\(String(format: "%04d", index)): \(byte.0 != byte.1 ? "x" : " ") \(byte.0.asHex) | \(byte.1.asHex)")
        }
        let direction: String
        let extraBytes: ArraySlice<UInt8>
        if actualCount > expectedCount {
            direction = "Actual bytes has extra bytes"
            extraBytes = ArraySlice(actualBytes.dropFirst(minCount))
        } else if expectedCount > actualCount {
            direction = "Actual bytes is missing expected bytes"
            extraBytes = ArraySlice(expectedBytes.dropFirst(minCount))
        } else {
            direction = ""
            extraBytes = []
        }
        if !extraBytes.isEmpty {
            print("\(direction):")
            for (index, byte) in extraBytes.enumerated() {
                print("\(String(format: "%04d", minCount + index)): \(byte.asHex)")
            }
        }
        XCTFail(
            "Actual stringified data '\(String(decoding: actualBytes, as: UTF8.self))' doesn't equal to expected stringified data '\(String(decoding: expectedBytes, as: UTF8.self))'. Details: \(message())",
            file: file,
            line: line
        )
    } catch { XCTFail(error.localizedDescription, file: file, line: line) }
}

/// Asserts that the data matches the expected value.
public func XCTAssertEqualAsyncData<C: Collection, AS: AsyncSequence>(
    _ expression1: @autoclosure () throws -> AS?,
    _ expression2: @autoclosure () throws -> C,
    _ message: @autoclosure () -> String = "Data doesn't match.",
    file: StaticString = #filePath,
    line: UInt = #line
) async throws where C.Element == UInt8, AS.Element == ArraySlice<UInt8> {
    guard let actualBytesBody = try expression1() else {
        XCTFail("First value is nil", file: file, line: line)
        return
    }
    let actualBytes = try await [ArraySlice<UInt8>](collecting: actualBytesBody).flatMap { $0 }
    XCTAssertEqualData(actualBytes, try expression2(), file: file, line: line)
}

/// Asserts that the data matches the expected value.
public func XCTAssertEqualData<C: Collection>(
    _ expression1: @autoclosure () throws -> HTTPBody?,
    _ expression2: @autoclosure () throws -> C,
    _ message: @autoclosure () -> String = "Data doesn't match.",
    file: StaticString = #filePath,
    line: UInt = #line
) async throws where C.Element == UInt8 {
    try await XCTAssertEqualAsyncData(try expression1(), try expression2(), file: file, line: line)
}

extension Array {
    init<Source: AsyncSequence>(collecting source: Source) async throws where Source.Element == Element {
        var elements: [Element] = []
        for try await element in source { elements.append(element) }
        self = elements
    }
}
