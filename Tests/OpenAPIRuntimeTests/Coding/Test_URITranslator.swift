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

final class Test_URITranslator: Test_Runtime {

    func testTranslating() throws {
        struct Case {
            var value: any Encodable
            var expectedNode: URINode
            var file: StaticString = #file
            var line: UInt = #line
        }
        func makeCase(
            _ value: any Encodable,
            _ expectedNode: URINode,
            file: StaticString = #file,
            line: UInt = #line
        )
            -> Case
        {
            .init(value: value, expectedNode: expectedNode, file: file, line: line)
        }

        struct SimpleStruct: Encodable {
            var foo: String
            var bar: Int?
        }

        struct NestedStruct: Encodable {
            var simple: SimpleStruct
        }

        let cases: [Case] = [

            // An empty string.
            makeCase(
                "",
                .primitive(.string(""))
            ),

            // A string with a space.
            makeCase(
                "Hello World",
                .primitive(.string("Hello World"))
            ),

            // An integer.
            makeCase(
                1234,
                .primitive(.integer(1234))
            ),

            // A float.
            makeCase(
                12.34,
                .primitive(.double(12.34))
            ),

            // A bool.
            makeCase(
                true,
                .primitive(.bool(true))
            ),

            // A simple array.
            makeCase(
                ["a", "b", "c"],
                .array([
                    .primitive(.string("a")),
                    .primitive(.string("b")),
                    .primitive(.string("c")),
                ])
            ),

            // A nested array.
            makeCase(
                [["a"], ["b", "c"]],
                .array([
                    .array([
                        .primitive(.string("a"))
                    ]),
                    .array([
                        .primitive(.string("b")),
                        .primitive(.string("c")),
                    ]),
                ])
            ),

            // A struct.
            makeCase(
                SimpleStruct(foo: "bar"),
                .dictionary([
                    "foo": .primitive(.string("bar"))
                ])
            ),

            // A nested struct.
            makeCase(
                NestedStruct(simple: SimpleStruct(foo: "bar")),
                .dictionary([
                    "simple": .dictionary([
                        "foo": .primitive(.string("bar"))
                    ])
                ])
            ),

            // An array of structs.
            makeCase(
                [
                    SimpleStruct(foo: "bar"),
                    SimpleStruct(foo: "baz"),
                ],
                .array([
                    .dictionary([
                        "foo": .primitive(.string("bar"))
                    ]),
                    .dictionary([
                        "foo": .primitive(.string("baz"))
                    ]),
                ])
            ),

            // An array of arrays of structs.
            makeCase(
                [
                    [
                        SimpleStruct(foo: "bar")
                    ],
                    [
                        SimpleStruct(foo: "baz")
                    ],
                ],
                .array([
                    .array([
                        .dictionary([
                            "foo": .primitive(.string("bar"))
                        ])
                    ]),
                    .array([
                        .dictionary([
                            "foo": .primitive(.string("baz"))
                        ])
                    ]),
                ])
            ),

            // A simple dictionary.
            makeCase(
                ["one": 1, "two": 2],
                .dictionary([
                    "one": .primitive(.integer(1)),
                    "two": .primitive(.integer(2)),
                ])
            ),

            // A nested dictionary.
            makeCase(
                [
                    "A": ["one": 1, "two": 2],
                    "B": ["three": 3, "four": 4],
                ],
                .dictionary([
                    "A": .dictionary([
                        "one": .primitive(.integer(1)),
                        "two": .primitive(.integer(2)),
                    ]),
                    "B": .dictionary([
                        "three": .primitive(.integer(3)),
                        "four": .primitive(.integer(4)),
                    ]),
                ])
            ),

            // A dictionary of structs.
            makeCase(
                [
                    "barkey": SimpleStruct(foo: "bar"),
                    "bazkey": SimpleStruct(foo: "baz"),
                ],
                .dictionary([
                    "barkey": .dictionary([
                        "foo": .primitive(.string("bar"))
                    ]),
                    "bazkey": .dictionary([
                        "foo": .primitive(.string("baz"))
                    ]),
                ])
            ),

            // An dictionary of dictionaries of structs.
            makeCase(
                [
                    "outBar":
                        [
                            "inBar": SimpleStruct(foo: "bar")
                        ],
                    "outBaz": [
                        "inBaz": SimpleStruct(foo: "baz")
                    ],
                ],
                .dictionary([
                    "outBar": .dictionary([
                        "inBar": .dictionary([
                            "foo": .primitive(.string("bar"))
                        ])
                    ]),
                    "outBaz": .dictionary([
                        "inBaz": .dictionary([
                            "foo": .primitive(.string("baz"))
                        ])
                    ]),
                ])
            ),
        ]
        let translator = URITranslator()
        for testCase in cases {
            let translatedNode = try translator.translateValue(testCase.value)
            XCTAssertEqual(
                translatedNode,
                testCase.expectedNode,
                file: testCase.file,
                line: testCase.line
            )
        }
    }
}
