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
import Foundation
#if canImport(CoreFoundation)
import CoreFoundation
#endif
@_spi(Generated) @testable import OpenAPIRuntime

final class Test_OpenAPIValue: Test_Runtime {

    func testValidationOnCreation() throws {
        _ = OpenAPIValueContainer("hello")
        _ = OpenAPIValueContainer(true)
        _ = OpenAPIValueContainer(1)
        _ = OpenAPIValueContainer(4.5)

        #if FullFoundationSupport && canImport(Foundation)
        XCTAssertEqual(try OpenAPIValueContainer(unvalidatedValue: NSNull()).value as? NSNull, NSNull())
        #endif

        _ = try OpenAPIValueContainer(unvalidatedValue: ["hello"])
        _ = try OpenAPIValueContainer(unvalidatedValue: ["hello": "world"])

        _ = try OpenAPIObjectContainer(unvalidatedValue: ["hello": "world"])
        _ = try OpenAPIObjectContainer(unvalidatedValue: [
            "hello": ["nested": "world", "nested2": 2] as [String: any Sendable]
        ])

        _ = try OpenAPIArrayContainer(unvalidatedValue: ["hello"])
        _ = try OpenAPIArrayContainer(unvalidatedValue: ["hello", ["nestedHello", 2] as [any Sendable]])
    }

    func testEncoding_container_success() throws {
        let values: [(any Sendable)?] = [
            nil, "Hello", ["key": "value", "anotherKey": [1, "two"] as [any Sendable]] as [String: any Sendable],
            1 as Int, 2.5 as Double, [true],
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
    #if FullFoundationSupport && canImport(Foundation)
    func testEncodingNSNull() throws {
        let value = NSNull()
        let container = try OpenAPIValueContainer(unvalidatedValue: value)
        let expectedString = #"""
            null
            """#
        try _testPrettyEncoded(container, expectedJSON: expectedString)
    }

    #if canImport(CoreFoundation)
    func testEncodingNSNumber() throws {
        func assertEncodedCF(
            _ value: CFNumber,
            as encodedValue: String,
            file: StaticString = #filePath,
            line: UInt = #line
        ) throws {
            #if canImport(ObjectiveC)
            let nsNumber = value as NSNumber
            #else
            let nsNumber = unsafeBitCast(self, to: NSNumber.self)
            #endif
            try assertEncoded(nsNumber, as: encodedValue, file: file, line: line)
        }
        func assertEncoded(
            _ value: NSNumber,
            as encodedValue: String,
            file: StaticString = #filePath,
            line: UInt = #line
        ) throws {
            let container = try OpenAPIValueContainer(unvalidatedValue: value)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let data = try encoder.encode(container)
            XCTAssertEqual(String(decoding: data, as: UTF8.self), encodedValue, file: file, line: line)
        }
        try assertEncoded(NSNumber(value: true as Bool), as: "true")
        try assertEncoded(NSNumber(value: false as Bool), as: "false")
        try assertEncoded(NSNumber(value: 24 as Int8), as: "24")
        try assertEncoded(NSNumber(value: 24 as Int16), as: "24")
        try assertEncoded(NSNumber(value: 24 as Int32), as: "24")
        try assertEncoded(NSNumber(value: 24 as Int64), as: "24")
        try assertEncoded(NSNumber(value: 24 as Int), as: "24")
        try assertEncoded(NSNumber(value: 24 as UInt8), as: "24")
        try assertEncoded(NSNumber(value: 24 as UInt16), as: "24")
        try assertEncoded(NSNumber(value: 24 as UInt32), as: "24")
        try assertEncoded(NSNumber(value: 24 as UInt64), as: "24")
        try assertEncoded(NSNumber(value: 24 as UInt), as: "24")
        #if canImport(ObjectiveC)
        try assertEncoded(NSNumber(value: 24 as NSInteger), as: "24")
        #endif
        try assertEncoded(NSNumber(value: 24 as CFIndex), as: "24")
        try assertEncoded(NSNumber(value: 24.1 as Float32), as: "24.1")
        try assertEncoded(NSNumber(value: 24.1 as Float64), as: "24.1")
        try assertEncoded(NSNumber(value: 24.1 as Float), as: "24.1")
        try assertEncoded(NSNumber(value: 24.1 as Double), as: "24.1")
        XCTAssertThrowsError(try assertEncodedCF(kCFNumberNaN, as: "-"))
        XCTAssertThrowsError(try assertEncodedCF(kCFNumberNegativeInfinity, as: "-"))
        XCTAssertThrowsError(try assertEncodedCF(kCFNumberPositiveInfinity, as: "-"))
    }
    #endif
    #endif
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
        let values: [String: (any Sendable)?] = ["key": "value", "keyMore": [true]]
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

    func testEncoding_anyOfObjects_success() throws {
        let values1: [String: (any Sendable)?] = ["key": "value"]
        let values2: [String: (any Sendable)?] = ["keyMore": [true]]
        let container = MyAnyOf2(
            value1: try OpenAPIObjectContainer(unvalidatedValue: values1),
            value2: try OpenAPIObjectContainer(unvalidatedValue: values2)
        )
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

    func testDecoding_anyOfObjects_success() throws {
        let json = #"""
            {
              "key" : "value",
              "keyMore" : [
                true
              ]
            }
            """#
        let container: MyAnyOf2<OpenAPIObjectContainer, OpenAPIObjectContainer> = try _getDecoded(json: json)
        let value1 = container.value1?.value
        XCTAssertEqual(value1?.count, 2)
        XCTAssertEqual(value1?["key"] as? String, "value")
        XCTAssertEqual(value1?["keyMore"] as? [Bool], [true])
        let value2 = container.value2?.value
        XCTAssertEqual(value2?.count, 2)
        XCTAssertEqual(value2?["key"] as? String, "value")
        XCTAssertEqual(value2?["keyMore"] as? [Bool], [true])
    }

    func testEncoding_anyOfValues_success() throws {
        let values1: [String: (any Sendable)?] = ["key": "value"]
        let values2: [String: (any Sendable)?] = ["keyMore": [true]]
        let container = MyAnyOf2(
            value1: try OpenAPIValueContainer(unvalidatedValue: values1),
            value2: try OpenAPIValueContainer(unvalidatedValue: values2)
        )
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

    func testDecoding_anyOfValues_success() throws {
        let json = #"""
            {
              "key" : "value",
              "keyMore" : [
                true
              ]
            }
            """#
        let container: MyAnyOf2<OpenAPIValueContainer, OpenAPIValueContainer> = try _getDecoded(json: json)
        let value1 = try XCTUnwrap(container.value1?.value as? [String: (any Sendable)?])
        XCTAssertEqual(value1.count, 2)
        XCTAssertEqual(value1["key"] as? String, "value")
        XCTAssertEqual(value1["keyMore"] as? [Bool], [true])
        let value2 = try XCTUnwrap(container.value2?.value as? [String: (any Sendable)?])
        XCTAssertEqual(value2.count, 2)
        XCTAssertEqual(value2["key"] as? String, "value")
        XCTAssertEqual(value2["keyMore"] as? [Bool], [true])
    }

    func testEncoding_array_success() throws {
        let values: [(any Sendable)?] = ["one", ["two": 2]]
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

    func testEncoding_arrayOfObjects_success() throws {
        let values: [(any Sendable)?] = [["one": 1], ["two": 2]]
        let container = try OpenAPIArrayContainer(unvalidatedValue: values)
        let expectedString = #"""
            [
              {
                "one" : 1
              },
              {
                "two" : 2
              }
            ]
            """#
        try _testPrettyEncoded(container, expectedJSON: expectedString)
    }

    func testDecoding_arrayOfObjects_success() throws {
        let json = #"""
            [
              {
                "one" : 1
              },
              {
                "two" : 2
              }
            ]
            """#
        let container: OpenAPIArrayContainer = try _getDecoded(json: json)
        let value = container.value
        XCTAssertEqual(value.count, 2)
        XCTAssertEqual(value[0] as? [String: Int], ["one": 1])
        XCTAssertEqual(value[1] as? [String: Int], ["two": 2])
    }

    func testEncoding_objectNested_success() throws {
        struct Foo: Encodable {
            var bar: String
            var dict: OpenAPIObjectContainer = .init()
        }
        try _testPrettyEncoded(
            Foo(
                bar: "hi",
                dict: try .init(unvalidatedValue: [
                    "baz": "bar", "number": 1, "nestedArray": [1, ["k": "v"]] as [(any Sendable)?],
                    "nestedDict": ["nested": 2],
                ])
            ),
            expectedJSON: #"""
                {
                  "bar" : "hi",
                  "dict" : {
                    "baz" : "bar",
                    "nestedArray" : [
                      1,
                      {
                        "k" : "v"
                      }
                    ],
                    "nestedDict" : {
                      "nested" : 2
                    },
                    "number" : 1
                  }
                }
                """#
        )
    }

    func testDecoding_objectNested_success() throws {
        struct Foo: Codable {
            var bar: String
            var dict: OpenAPIObjectContainer = .init()
        }
        let decoded: Foo = try _getDecoded(
            json: #"""
                {
                  "bar" : "hi",
                  "dict" : {
                    "baz" : "bar",
                    "nestedArray" : [
                      1,
                      {
                        "k" : "v"
                      }
                    ],
                    "nestedDict" : {
                      "nested" : 2
                    },
                    "number" : 1
                  }
                }
                """#
        )
        let nestedDict = try XCTUnwrap(decoded.dict.value["nestedDict"] as? [String: Any?])
        let nestedValue = try XCTUnwrap(nestedDict["nested"] as? Int)
        XCTAssertEqual(nestedValue, 2)
    }

    func testEncoding_base64_success() throws {
        let encodedData = Base64EncodedData(testStructData)

        let JSONEncoded = try JSONEncoder().encode(encodedData)
        XCTAssertEqual(String(data: JSONEncoded, encoding: .utf8)!, testStructBase64EncodedString)
    }

    func testDecoding_base64_success() throws {
        let encodedData = Base64EncodedData(testStructData)

        // `testStructBase64EncodedString` quoted and base64-encoded again
        let JSONEncoded = Data(base64Encoded: "ImV5SnVZVzFsSWpvaVJteDFabVo2SW4wPSI=")!

        XCTAssertEqual(try JSONDecoder().decode(Base64EncodedData.self, from: JSONEncoded), encodedData)
    }

    func testEncodingDecodingRoundtrip_base64_success() throws {
        let encodedData = Base64EncodedData(testStructData)
        XCTAssertEqual(
            try JSONDecoder().decode(Base64EncodedData.self, from: JSONEncoder().encode(encodedData)),
            encodedData
        )
    }
}

struct MyAnyOf2<Value1: Codable & Hashable & Sendable, Value2: Codable & Hashable & Sendable>: Codable, Hashable,
    Sendable
{
    var value1: Value1?
    var value2: Value2?
    init(value1: Value1? = nil, value2: Value2? = nil) {
        self.value1 = value1
        self.value2 = value2
    }
    init(from decoder: any Decoder) throws {
        var errors: [any Error] = []
        do { self.value1 = try .init(from: decoder) } catch { errors.append(error) }
        do { self.value2 = try .init(from: decoder) } catch { errors.append(error) }
        try Swift.DecodingError.verifyAtLeastOneSchemaIsNotNil(
            [self.value1, self.value2],
            type: Self.self,
            codingPath: decoder.codingPath,
            errors: errors
        )
    }
    func encode(to encoder: any Encoder) throws {
        try self.value1?.encode(to: encoder)
        try self.value2?.encode(to: encoder)
    }
}
