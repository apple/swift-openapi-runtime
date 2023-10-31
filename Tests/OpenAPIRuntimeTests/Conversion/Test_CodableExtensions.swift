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

final class Test_CodableExtensions: Test_Runtime {

    var testDecoder: JSONDecoder { JSONDecoder() }

    var testEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    func testDecodeAdditionalProperties_false() throws {

        struct Foo: Decodable {
            var bar: String

            enum CodingKeys: String, CodingKey { case bar }

            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.bar = try container.decode(String.self, forKey: .bar)
                try decoder.ensureNoAdditionalProperties(knownKeys: ["bar"])
            }
        }

        do {
            let data = Data(
                #"""
                {
                    "bar": "hi"
                }
                """#
                .utf8
            )
            _ = try testDecoder.decode(Foo.self, from: data)
        }

        do {
            let data = Data(
                #"""
                {
                    "bar": "hi",
                    "baz": "oh no"
                }
                """#
                .utf8
            )
            XCTAssertThrowsError(try testDecoder.decode(Foo.self, from: data)) { error in
                let err = try! XCTUnwrap(error as? DecodingError)
                guard case let .dataCorrupted(context) = err else {
                    XCTFail("Unexpected error")
                    return
                }
                XCTAssertEqual(context.codingPath.count, 1)
                XCTAssertEqual(
                    context.debugDescription,
                    "Additional properties are disabled, but found 1 unknown keys during decoding"
                )
            }
        }
    }

    func testDecodeAdditionalProperties_true() throws {

        struct Foo: Decodable {
            var bar: String
            var additionalProperties: OpenAPIObjectContainer

            enum CodingKeys: String, CodingKey { case bar }

            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.bar = try container.decode(String.self, forKey: .bar)
                self.additionalProperties = try decoder.decodeAdditionalProperties(knownKeys: ["bar"])
            }
        }

        do {
            let data = Data(
                #"""
                {
                    "bar": "hi"
                }
                """#
                .utf8
            )
            let value = try testDecoder.decode(Foo.self, from: data)
            XCTAssertEqual(value.bar, "hi")
            XCTAssertEqual(value.additionalProperties.value.count, 0)
        }

        do {
            let data = Data(
                #"""
                {
                    "bar": "hi",
                    "baz": "oh no"
                }
                """#
                .utf8
            )
            let value = try testDecoder.decode(Foo.self, from: data)
            XCTAssertEqual(value.bar, "hi")
            let additionalProperties = value.additionalProperties.value
            XCTAssertEqual(additionalProperties.count, 1)
            XCTAssertEqual(additionalProperties["baz"] as? String, "oh no")
        }
    }

    func testDecodeAdditionalProperties_typed() throws {

        struct Foo: Decodable {
            var bar: String
            var additionalProperties: [String: Int]

            enum CodingKeys: String, CodingKey { case bar }

            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.bar = try container.decode(String.self, forKey: .bar)
                self.additionalProperties = try decoder.decodeAdditionalProperties(knownKeys: ["bar"])
            }
        }

        do {
            let data = Data(
                #"""
                {
                    "bar": "hi"
                }
                """#
                .utf8
            )
            let value = try JSONDecoder().decode(Foo.self, from: data)
            XCTAssertEqual(value.bar, "hi")
            XCTAssertEqual(value.additionalProperties.count, 0)
        }

        do {
            let data = Data(
                #"""
                {
                    "bar": "hi",
                    "baz": 1
                }
                """#
                .utf8
            )
            let value = try JSONDecoder().decode(Foo.self, from: data)
            XCTAssertEqual(value.bar, "hi")
            let additionalProperties = value.additionalProperties
            XCTAssertEqual(additionalProperties.count, 1)
            XCTAssertEqual(additionalProperties["baz"], 1)
        }
    }

    func testEncodeAdditionalProperties_true() throws {

        struct Foo: Encodable {
            var bar: String
            var additionalProperties = OpenAPIObjectContainer()

            enum CodingKeys: String, CodingKey { case bar }

            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(bar, forKey: .bar)
                try encoder.encodeAdditionalProperties(additionalProperties)
            }
        }

        do {
            let value = Foo(bar: "hi")
            let data = try testEncoder.encode(value)
            XCTAssertEqual(
                String(decoding: data, as: UTF8.self),
                #"""
                {
                  "bar" : "hi"
                }
                """#
            )
        }

        do {
            let value = Foo(bar: "hi", additionalProperties: try .init(unvalidatedValue: ["baz": "bar", "number": 1]))
            let data = try testEncoder.encode(value)
            XCTAssertEqual(
                String(decoding: data, as: UTF8.self),
                #"""
                {
                  "bar" : "hi",
                  "baz" : "bar",
                  "number" : 1
                }
                """#
            )
        }
    }

    func testEncodeAdditionalProperties_typed() throws {

        struct Foo: Encodable {
            var bar: String
            var additionalProperties: [String: Int] = [:]

            enum CodingKeys: String, CodingKey { case bar }

            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(bar, forKey: .bar)
                try encoder.encodeAdditionalProperties(additionalProperties)
            }
        }

        do {
            let value = Foo(bar: "hi")
            let data = try testEncoder.encode(value)
            XCTAssertEqual(
                String(decoding: data, as: UTF8.self),
                #"""
                {
                  "bar" : "hi"
                }
                """#
            )
        }

        do {
            let value = Foo(bar: "hi", additionalProperties: ["number": 1])
            let data = try testEncoder.encode(value)
            XCTAssertEqual(
                String(decoding: data, as: UTF8.self),
                #"""
                {
                  "bar" : "hi",
                  "number" : 1
                }
                """#
            )
        }
    }
}
