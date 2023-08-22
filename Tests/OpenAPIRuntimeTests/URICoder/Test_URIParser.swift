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

final class Test_URIParser: Test_Runtime {

    
    func testParsing() throws {
        struct Case {
            var value: String
            var expectedNode: URIParsedNode
            var file: StaticString = #file
            var line: UInt = #line
        }
        func makeCase(_ value: String, _ expectedNode: URIParsedNode, file: StaticString = #file, line: UInt = #line)
            -> Case
        {
            .init(value: value, expectedNode: expectedNode, file: file, line: line)
        }

        let cases: [Case] = [
            makeCase("root=", .primitive("")),
//            makeCase(.primitive(.string("Hello World")), "root=Hello World"),
//            makeCase(.primitive(.integer(1234)), "root=1234"),
//            makeCase(.primitive(.double(12.34)), "root=12.34"),
//            makeCase(.primitive(.bool(true)), "root=true"),
//            makeCase(
//                .array([
//                    .primitive(.string("a")),
//                    .primitive(.string("b")),
//                    .primitive(.string("c")),
//                ]),
//                "root[0]=a&root[1]=b&root[2]=c"
//            ),
//            makeCase(
//                .array([
//                    .array([
//                        .primitive(.string("a"))
//                    ]),
//                    .array([
//                        .primitive(.string("b")),
//                        .primitive(.string("c")),
//                    ]),
//                ]),
//                "root[0][0]=a&root[1][0]=b&root[1][1]=c"
//            ),
//            makeCase(
//                .dictionary([
//                    "foo": .primitive(.string("bar"))
//                ]),
//                "root[foo]=bar"
//            ),
//            makeCase(
//                .dictionary([
//                    "simple": .dictionary([
//                        "foo": .primitive(.string("bar"))
//                    ])
//                ]),
//                "root[simple][foo]=bar"
//            ),
//            makeCase(
//                .array([
//                    .dictionary([
//                        "foo": .primitive(.string("bar"))
//                    ]),
//                    .dictionary([
//                        "foo": .primitive(.string("baz"))
//                    ]),
//                ]),
//                "root[0][foo]=bar&root[1][foo]=baz"
//            ),
//            makeCase(
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
//                ]),
//                "root[0][0][foo]=bar&root[1][0][foo]=baz"
//            ),
//            makeCase(
//                .dictionary([
//                    "one": .primitive(.integer(1)),
//                    "two": .primitive(.integer(2)),
//                ]),
//                "root[one]=1&root[two]=2"
//            ),
//            makeCase(
//                .dictionary([
//                    "A": .dictionary([
//                        "one": .primitive(.integer(1)),
//                        "two": .primitive(.integer(2)),
//                    ]),
//                    "B": .dictionary([
//                        "three": .primitive(.integer(3)),
//                        "four": .primitive(.integer(4)),
//                    ]),
//                ]),
//                "root[A][one]=1&root[A][two]=2&root[B][four]=4&root[B][three]=3"
//            ),
//            makeCase(
//                .dictionary([
//                    "barkey": .dictionary([
//                        "foo": .primitive(.string("bar"))
//                    ]),
//                    "bazkey": .dictionary([
//                        "foo": .primitive(.string("baz"))
//                    ]),
//                ]),
//                "root[barkey][foo]=bar&root[bazkey][foo]=baz"
//            ),
//            makeCase(
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
//                ]),
//                "root[outBar][inBar][foo]=bar&root[outBaz][inBaz][foo]=baz"
//            ),
        ]
//        var serializer = URISerializer()
//        for testCase in cases {
//            let encodedString = try serializer.writeNode(
//                testCase.value,
//                forKey: .key("root")
//            )
//            XCTAssertEqual(
//                encodedString,
//                testCase.expectedString,
//                file: testCase.file,
//                line: testCase.line
//            )
//        }
    }
}
