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

final class Test_URISerializer: Test_Runtime {

    let testedVariants: [URISerializer.Configuration] = [
        .formExplode,
        .formUnexplode,
        .simpleExplode,
        .simpleUnexplode,
        .formDataExplode,
        .formDataUnexplode,
    ]

    func testSerializing() throws {
        let cases: [Case] = [
            makeCase(
                .primitive(.string("")),
                "root="
            ),
            makeCase(
                .primitive(.string("fred")),
                "root=fred"
            ),
            makeCase(
                .primitive(.integer(1234)),
                "root=1234"
            ),
            makeCase(
                .primitive(.double(12.34)),
                "root=12.34"
            ),
            makeCase(
                .primitive(.bool(true)),
                "root=true"
            ),
            makeCase(
                .primitive(.string("Hello World")),
                [
                    (.formExplode, "root=Hello%20World"),
                    (.simpleExplode, "root=Hello%20World"),
                    (.formDataExplode, "root=Hello+World"),
                ]
            ),
            makeCase(
                .primitive(.string("50%")),
                "root=50%25"
            ),
            makeCase(
                .array([
                    .primitive(.string("red")),
                    .primitive(.string("green")),
                    .primitive(.string("blue")),
                ]),
                [
                    (.formExplode, "root=red&root=green&root=blue"),
                    (.formUnexplode, "root=red,green,blue"),
                    (.simpleExplode, "root=red,green,blue"),
                    (.simpleUnexplode, "root=red,green,blue"),
                    (.formDataExplode, "root=red&root=green&root=blue"),
                    (.formDataUnexplode, "root=red,green,blue"),
                ]
            ),
            makeCase(
                .dictionary([
                    "semi": .primitive(.string(";")),
                    "dot": .primitive(.string(".")),
                    "comma": .primitive(.string(","))
                ]),
                [
                    (.formExplode, "comma=%2C&dot=.&semi=%3B"),
                    (.formUnexplode, "root=comma,%2C,dot,.,semi,%3B"),
                    (.simpleExplode, "comma=%2C,dot=.,semi=%3B"),
                    (.simpleUnexplode, "root=comma,%2C,dot,.,semi,%3B"),
                    (.formDataExplode, "comma=%2C&dot=.&semi=%3B"),
                    (.formDataUnexplode, "root=comma,%2C,dot,.,semi,%3B"),
                ]
            ),
        ]
        for testCase in cases {
            for (config, expectedString) in testCase.variants {
                var serializer = URISerializer(configuration: config)
                let encodedString = try serializer.serializeNode(
                    testCase.value,
                    forKey: "root"
                )
                XCTAssertEqual(
                    encodedString,
                    expectedString,
                    "Failed for config: \(config)",
                    file: testCase.file,
                    line: testCase.line
                )
            }
        }
    }
}

extension Test_URISerializer {
    struct Case {
        var value: URIEncodableNode
        var variants: [(URISerializer.Configuration, String)]
        var file: StaticString = #file
        var line: UInt = #line
    }
    func makeCase(
        _ value: URIEncodableNode,
        _ expectedString: String,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Case {
        .init(
            value: value,
            variants: testedVariants.map { config in (config, expectedString) },
            file: file,
            line: line
        )
    }
    func makeCase(
        _ value: URIEncodableNode,
        _ variants: [(URISerializer.Configuration, String)],
        file: StaticString = #file,
        line: UInt = #line
    ) -> Case {
        .init(
            value: value,
            variants: variants,
            file: file,
            line: line
        )
    }
}
