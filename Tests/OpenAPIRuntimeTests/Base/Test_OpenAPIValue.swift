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

final class Test_OpenAPIValue: Test_Runtime {

    func testValidationOnCreation() throws {
        _ = OpenAPIValueContainer("hello")
        _ = OpenAPIValueContainer(true)
        _ = OpenAPIValueContainer(1)
        _ = OpenAPIValueContainer(4.5)

        _ = try OpenAPIValueContainer(unvalidatedValue: ["hello"])
        _ = try OpenAPIValueContainer(unvalidatedValue: ["hello": "world"])

        _ = try OpenAPIObjectContainer(unvalidatedValue: ["hello": "world"])
        _ = try OpenAPIObjectContainer(unvalidatedValue: ["hello": ["nested": "world", "nested2": 2] as [String: any Sendable]])

        _ = try OpenAPIArrayContainer(unvalidatedValue: ["hello"])
        _ = try OpenAPIArrayContainer(unvalidatedValue: ["hello", ["nestedHello", 2] as [any Sendable]])
    }

    func testEncoding_container_success() throws {
        let values: [(any Sendable)?] = [
            nil,
            "Hello",
            [
                "key": "value",
                "anotherKey": [
                    1,
                    "two",
                ] as [any Sendable],
            ] as [String: any Sendable],
            1 as Int,
            2.5 as Double,
            [true],
        ]
        let container = try OpenAPIValueContainer(unvalidatedValue: values)
        let expectedString = #"""
            [
              null,
              "Hello",
              {
                "anotherKey" : [
                  1,
                  "two"
                ],
                "key" : "value"
              },
              1,
              2.5,
              [
                true
              ]
            ]
            """#
        try _testPrettyEncoded(container, expectedJSON: expectedString)
    }

    func testEncoding_container_failure() throws {
        struct Foobar: Equatable {}
        XCTAssertThrowsError(try OpenAPIValueContainer(unvalidatedValue: Foobar())) { error in
            let err = try! XCTUnwrap(error as? EncodingError)
            guard case let .invalidValue(value, context) = err else {
                XCTFail("Unexpected error")
                return
            }
            let typedValue = try! XCTUnwrap(value as? Foobar)
            XCTAssertEqual(typedValue, Foobar())
            XCTAssert(context.codingPath.isEmpty)
            XCTAssertNil(context.underlyingError)
            XCTAssertEqual(context.debugDescription, "Type 'Foobar' is not a supported OpenAPI value.")
        }
    }

    func testDecoding_container_success() throws {
        let json = #"""
            [
              null,
              "Hello",
              {
                "anotherKey" : [
                  1,
                  "two"
                ],
                "key" : "value"
              },
              1,
              2.5,
              [
                true
              ]
            ]
            """#
        let container: OpenAPIValueContainer = try _getDecoded(json: json)
        let value = try XCTUnwrap(container.value)
        let array = try XCTUnwrap(value as? [(any Sendable)?])
        XCTAssertEqual(array.count, 6)
        XCTAssertNil(array[0])
        XCTAssertEqual(array[1] as? String, "Hello")
        let dict = try XCTUnwrap(array[2] as? [String: (any Sendable)?])
        XCTAssertEqual(dict.count, 2)
        let nestedArray = try XCTUnwrap(dict["anotherKey"] as? [(any Sendable)?])
        XCTAssertEqual(nestedArray.count, 2)
        XCTAssertEqual(nestedArray[0] as? Int, 1)
        XCTAssertEqual(nestedArray[1] as? String, "two")
        XCTAssertEqual(dict["key"] as? String, "value")
        XCTAssertEqual(array[3] as? Int, 1)
        XCTAssertEqual(array[4] as? Double, 2.5)
        let boolArray = try XCTUnwrap(array[5] as? [(any Sendable)?])
        XCTAssertEqual(boolArray.count, 1)
        XCTAssertEqual(boolArray[0] as? Bool, true)
    }

    func testEncoding_object_success() throws {
        let values: [String: (any Sendable)?] = [
            "key": "value",
            "keyMore": [
                true
            ],
        ]
        let container = try OpenAPIObjectContainer(unvalidatedValue: values)
        let expectedString = #"""
            {
              "key" : "value",
              "keyMore" : [
                true
              ]
            }
            """#
        try _testPrettyEncoded(container, expectedJSON: expectedString)
    }

    func testDecoding_object_success() throws {
        let json = #"""
            {
              "key" : "value",
              "keyMore" : [
                true
              ]
            }
            """#
        let container: OpenAPIObjectContainer = try _getDecoded(json: json)
        let value = container.value
        XCTAssertEqual(value.count, 2)
        XCTAssertEqual(value["key"] as? String, "value")
        XCTAssertEqual(value["keyMore"] as? [Bool], [true])
    }

    func testEncoding_array_success() throws {
        let values: [(any Sendable)?] = [
            "one",
            ["two": 2],
        ]
        let container = try OpenAPIArrayContainer(unvalidatedValue: values)
        let expectedString = #"""
            [
              "one",
              {
                "two" : 2
              }
            ]
            """#
        try _testPrettyEncoded(container, expectedJSON: expectedString)
    }

    func testDecoding_array_success() throws {
        let json = #"""
            [
              "one",
              {
                "two" : 2
              }
            ]
            """#
        let container: OpenAPIArrayContainer = try _getDecoded(json: json)
        let value = container.value
        XCTAssertEqual(value.count, 2)
        XCTAssertEqual(value[0] as? String, "one")
        XCTAssertEqual(value[1] as? [String: Int], ["two": 2])
    }
}
