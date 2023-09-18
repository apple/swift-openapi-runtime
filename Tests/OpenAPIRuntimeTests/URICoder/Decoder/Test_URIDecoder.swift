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
@testable import OpenAPIRuntime

final class Test_URIDecoder: Test_Runtime {

    func testDecoding() throws {
        struct Foo: Decodable, Equatable {
            var bar: String
        }
        let decoder = URIDecoder(configuration: .formDataExplode)
        let decodedValue = try decoder.decode(
            Foo.self,
            forKey: "",
            from: "bar=hello+world"
        )
        XCTAssertEqual(decodedValue, Foo(bar: "hello world"))
    }

    func testDecoding_structWithOptionalProperty() throws {
        struct Foo: Decodable, Equatable {
            var bar: String?
            var baz: Int
        }
        let decoder = URIDecoder(configuration: .formDataExplode)
        do {
            let decodedValue = try decoder.decode(
                Foo.self,
                forKey: "",
                from: "baz=1&bar=hello+world"
            )
            XCTAssertEqual(decodedValue, Foo(bar: "hello world", baz: 1))
        }
        do {
            let decodedValue = try decoder.decode(
                Foo.self,
                forKey: "",
                from: "baz=1"
            )
            XCTAssertEqual(decodedValue, Foo(baz: 1))
        }
    }

    func testDecoding_rootValue() throws {
        let decoder = URIDecoder(configuration: .formDataExplode)
        do {
            let decodedValue = try decoder.decode(
                Int.self,
                forKey: "root",
                from: "root=1"
            )
            XCTAssertEqual(decodedValue, 1)
        }
        do {
            let decodedValue = try decoder.decodeIfPresent(
                Int.self,
                forKey: "root",
                from: "baz=1"
            )
            XCTAssertEqual(decodedValue, nil)
        }
        do {
            let decodedValue = try decoder.decodeIfPresent(
                Int.self,
                forKey: "root",
                from: ""
            )
            XCTAssertEqual(decodedValue, nil)
        }
    }
    
    func testDecoding_percentEncodedCommaToString() throws {
        let decoder = URIDecoder(configuration: .simpleUnexplode)
        
        do {
            let decodedValue = try decoder.decode(
                String.self,
                forKey: "",
                from: "foo%2C%20bar"
            )
            XCTAssertEqual(decodedValue, "foo, bar")
        }
    }
    
    func testDecoding_nonPercentEncodedCommaToString() throws {
        let decoder = URIDecoder(configuration: .simpleUnexplode)
        
        do {
            let decodedValue = try decoder.decode(
                String.self,
                forKey: "",
                from: "foo, bar"
            )
            XCTAssertEqual(decodedValue, "foo, bar")
        }
    }
}
