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

final class Test_URIValueFromNodeDecoder: Test_Runtime {

    func testDecoding() throws {
        struct SimpleStruct: Encodable {
            var foo: String
            var bar: Int?
        }

        // An empty string.
        try test(
            ["": [""]],
            ""
        )

        // A string with a space.
        try test(
            ["": ["Hello World"]],
            "Hello World"
        )

        // An integer.
        try test(
            ["": ["1234"]],
            1234
        )
        
        // A float.
        try test(
            ["": ["12.34"]],
            12.34
        )
        
        // A bool.
        try test(
            ["": ["true"]],
            true
        )

        // A simple array.
        try test(
            ["": ["a", "b", "c"]],
            ["a", "b", "c"]
        )

//            // A nested array.
//            makeCase(
//                [["a"], ["b", "c"]],
//                .array([
//                    .array([
//                        .primitive(.string("a"))
//                    ]),
//                    .array([
//                        .primitive(.string("b")),
//                        .primitive(.string("c")),
//                    ]),
//                ])
//            ),
//
//            // A struct.
//            makeCase(
//                SimpleStruct(foo: "bar"),
//                .dictionary([
//                    "foo": .primitive(.string("bar"))
//                ])
//            ),
//
//            // A nested struct.
//            makeCase(
//                NestedStruct(simple: SimpleStruct(foo: "bar")),
//                .dictionary([
//                    "simple": .dictionary([
//                        "foo": .primitive(.string("bar"))
//                    ])
//                ])
//            ),
//
//            // An array of structs.
//            makeCase(
//                [
//                    SimpleStruct(foo: "bar"),
//                    SimpleStruct(foo: "baz"),
//                ],
//                .array([
//                    .dictionary([
//                        "foo": .primitive(.string("bar"))
//                    ]),
//                    .dictionary([
//                        "foo": .primitive(.string("baz"))
//                    ]),
//                ])
//            ),
//
//            // An array of arrays of structs.
//            makeCase(
//                [
//                    [
//                        SimpleStruct(foo: "bar")
//                    ],
//                    [
//                        SimpleStruct(foo: "baz")
//                    ],
//                ],
//                .array([
//                    .array([
//                        .dictionary([
//                            "foo": .primitive(.string("bar"))
//                        ])
//                    ]),
//                    .array([
//                        .dictionary([
//                            "foo": .primitive(.string("baz"))
//                        ])
//                    ]),
//                ])
//            ),
//
//            // A simple dictionary.
//            makeCase(
//                ["one": 1, "two": 2],
//                .dictionary([
//                    "one": .primitive(.integer(1)),
//                    "two": .primitive(.integer(2)),
//                ])
//            ),
//
//            // A nested dictionary.
//            makeCase(
//                [
//                    "A": ["one": 1, "two": 2],
//                    "B": ["three": 3, "four": 4],
//                ],
//                .dictionary([
//                    "A": .dictionary([
//                        "one": .primitive(.integer(1)),
//                        "two": .primitive(.integer(2)),
//                    ]),
//                    "B": .dictionary([
//                        "three": .primitive(.integer(3)),
//                        "four": .primitive(.integer(4)),
//                    ]),
//                ])
//            ),
//
//            // A dictionary of structs.
//            makeCase(
//                [
//                    "barkey": SimpleStruct(foo: "bar"),
//                    "bazkey": SimpleStruct(foo: "baz"),
//                ],
//                .dictionary([
//                    "barkey": .dictionary([
//                        "foo": .primitive(.string("bar"))
//                    ]),
//                    "bazkey": .dictionary([
//                        "foo": .primitive(.string("baz"))
//                    ]),
//                ])
//            ),
//
//            // An dictionary of dictionaries of structs.
//            makeCase(
//                [
//                    "outBar":
//                        [
//                            "inBar": SimpleStruct(foo: "bar")
//                        ],
//                    "outBaz": [
//                        "inBaz": SimpleStruct(foo: "baz")
//                    ],
//                ],
//                .dictionary([
//                    "outBar": .dictionary([
//                        "inBar": .dictionary([
//                            "foo": .primitive(.string("bar"))
//                        ])
//                    ]),
//                    "outBaz": .dictionary([
//                        "inBaz": .dictionary([
//                            "foo": .primitive(.string("baz"))
//                        ])
//                    ]),
//                ])
//            ),
        
        func test<T: Decodable & Equatable>(
            _ node: URIParsedNode,
            _ expectedValue: T,
            file: StaticString = #file,
            line: UInt = #line
        ) throws {
            let decoder = URIValueFromNodeDecoder(node: node)
            let decodedValue = try decoder.decodeRoot(T.self)
            XCTAssertEqual(
                decodedValue,
                expectedValue,
                file: file,
                line: line
            )
        }
    }
}
