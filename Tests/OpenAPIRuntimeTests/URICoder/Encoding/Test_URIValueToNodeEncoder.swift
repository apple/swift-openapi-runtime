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

final class Test_URIValueToNodeEncoder: Test_Runtime {

    func testEncoding() throws {
        struct Case {
            var value: any Encodable
            var expectedNode: URIEncodedNode
            var file: StaticString = #file
            var line: UInt = #line
        }
        func makeCase(
            _ value: any Encodable,
            _ expectedNode: URIEncodedNode,
            file: StaticString = #file,
            line: UInt = #line
        ) -> Case { .init(value: value, expectedNode: expectedNode, file: file, line: line) }

        enum SimpleEnum: String, Encodable {
            case foo
            case bar
        }

        struct SimpleStruct: Encodable {
            var foo: String
            var bar: Int?
            var val: SimpleEnum?
        }

        struct StructWithArray: Encodable {
            var foo: String
            var bar: [Int]?
            var val: [String]
        }

        struct NestedStruct: Encodable { var simple: SimpleStruct }

        let cases: [Case] = [

            // An empty string.
            makeCase("", .primitive(.string(""))),

            // A string with a space.
            makeCase("Hello World", .primitive(.string("Hello World"))),

            // An integer.
            makeCase(1234, .primitive(.integer(1234))),

            // A float.
            makeCase(12.34, .primitive(.double(12.34))),

            // A bool.
            makeCase(true, .primitive(.bool(true))),

            // An enum.
            makeCase(SimpleEnum.foo, .primitive(.string("foo"))),

            // A simple array of strings.
            makeCase(
                ["a", "b", "c"],
                .array([.primitive(.string("a")), .primitive(.string("b")), .primitive(.string("c"))])
            ),

            // A simple array of enums.
            makeCase(
                [SimpleEnum.foo, SimpleEnum.bar],
                .array([.primitive(.string("foo")), .primitive(.string("bar"))])
            ),

            // A nested array.
            makeCase(
                [["a"], ["b", "c"]],
                .array([
                    .array([.primitive(.string("a"))]), .array([.primitive(.string("b")), .primitive(.string("c"))]),
                ])
            ),

            // A struct.
            makeCase(
                SimpleStruct(foo: "bar", val: .foo),
                .dictionary(["foo": .primitive(.string("bar")), "val": .primitive(.string("foo"))])
            ),

            // A struct with an array property.
            makeCase(
                StructWithArray(foo: "bar", bar: [1, 2], val: ["baz", "baq"]),
                .dictionary([
                    "foo": .primitive(.string("bar")),
                    "bar": .array([.primitive(.integer(1)), .primitive(.integer(2))]),
                    "val": .array([.primitive(.string("baz")), .primitive(.string("baq"))]),
                ])
            ),

            // A nested struct.
            makeCase(
                NestedStruct(simple: SimpleStruct(foo: "bar")),
                .dictionary(["simple": .dictionary(["foo": .primitive(.string("bar"))])])
            ),

            // An array of structs.
            makeCase(
                [SimpleStruct(foo: "bar"), SimpleStruct(foo: "baz", val: .bar)],
                .array([
                    .dictionary(["foo": .primitive(.string("bar"))]),
                    .dictionary(["foo": .primitive(.string("baz")), "val": .primitive(.string("bar"))]),
                ])
            ),

            // An array of arrays of structs.
            makeCase(
                [[SimpleStruct(foo: "bar")], [SimpleStruct(foo: "baz")]],
                .array([
                    .array([.dictionary(["foo": .primitive(.string("bar"))])]),
                    .array([.dictionary(["foo": .primitive(.string("baz"))])]),
                ])
            ),

            // A simple dictionary of string -> int pairs.
            makeCase(
                ["one": 1, "two": 2],
                .dictionary(["one": .primitive(.integer(1)), "two": .primitive(.integer(2))])
            ),

            // A simple dictionary of string -> enum pairs.
            makeCase(["one": SimpleEnum.bar], .dictionary(["one": .primitive(.string("bar"))])),

            // A nested dictionary.
            makeCase(
                ["A": ["one": 1, "two": 2], "B": ["three": 3, "four": 4]],
                .dictionary([
                    "A": .dictionary(["one": .primitive(.integer(1)), "two": .primitive(.integer(2))]),
                    "B": .dictionary(["three": .primitive(.integer(3)), "four": .primitive(.integer(4))]),
                ])
            ),

            // A dictionary of structs.
            makeCase(
                ["barkey": SimpleStruct(foo: "bar"), "bazkey": SimpleStruct(foo: "baz")],
                .dictionary([
                    "barkey": .dictionary(["foo": .primitive(.string("bar"))]),
                    "bazkey": .dictionary(["foo": .primitive(.string("baz"))]),
                ])
            ),

            // An dictionary of dictionaries of structs.
            makeCase(
                ["outBar": ["inBar": SimpleStruct(foo: "bar")], "outBaz": ["inBaz": SimpleStruct(foo: "baz")]],
                .dictionary([
                    "outBar": .dictionary(["inBar": .dictionary(["foo": .primitive(.string("bar"))])]),
                    "outBaz": .dictionary(["inBaz": .dictionary(["foo": .primitive(.string("baz"))])]),
                ])
            ),
        ]
        let encoder = URIValueToNodeEncoder()
        for testCase in cases {
            let encodedNode = try encoder.encodeValue(testCase.value)
            XCTAssertEqual(encodedNode, testCase.expectedNode, file: testCase.file, line: testCase.line)
        }
    }
}
