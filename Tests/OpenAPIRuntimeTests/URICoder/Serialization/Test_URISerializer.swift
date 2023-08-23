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

    let testedVariants: [URICoderConfiguration] = [
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
                value: .primitive(.string("")),
                key: "empty",
                .init(
                    formExplode: "empty=",
                    formUnexplode: "empty=",
                    simpleExplode: "",
                    simpleUnexplode: "",
                    formDataExplode: "empty=",
                    formDataUnexplode: "empty="
                )
            ),
            makeCase(
                value: .primitive(.string("fred")),
                key: "who",
                .init(
                    formExplode: "who=fred",
                    formUnexplode: "who=fred",
                    simpleExplode: "fred",
                    simpleUnexplode: "fred",
                    formDataExplode: "who=fred",
                    formDataUnexplode: "who=fred"
                )
            ),
            makeCase(
                value: .primitive(.integer(1234)),
                key: "x",
                .init(
                    formExplode: "x=1234",
                    formUnexplode: "x=1234",
                    simpleExplode: "1234",
                    simpleUnexplode: "1234",
                    formDataExplode: "x=1234",
                    formDataUnexplode: "x=1234"
                )
            ),
            makeCase(
                value: .primitive(.double(12.34)),
                key: "x",
                .init(
                    formExplode: "x=12.34",
                    formUnexplode: "x=12.34",
                    simpleExplode: "12.34",
                    simpleUnexplode: "12.34",
                    formDataExplode: "x=12.34",
                    formDataUnexplode: "x=12.34"
                )
            ),
            makeCase(
                value: .primitive(.bool(true)),
                key: "enabled",
                .init(
                    formExplode: "enabled=true",
                    formUnexplode: "enabled=true",
                    simpleExplode: "true",
                    simpleUnexplode: "true",
                    formDataExplode: "enabled=true",
                    formDataUnexplode: "enabled=true"
                )
            ),
            makeCase(
                value: .primitive(.string("Hello World")),
                key: "hello",
                .init(
                    formExplode: "hello=Hello%20World",
                    formUnexplode: "hello=Hello%20World",
                    simpleExplode: "Hello%20World",
                    simpleUnexplode: "Hello%20World",
                    formDataExplode: "hello=Hello+World",
                    formDataUnexplode: "hello=Hello+World"
                )
            ),
            makeCase(
                value: .array([
                    .primitive(.string("red")),
                    .primitive(.string("green")),
                    .primitive(.string("blue")),
                ]),
                key: "list",
                .init(
                    formExplode: "list=red&list=green&list=blue",
                    formUnexplode: "list=red,green,blue",
                    simpleExplode: "red,green,blue",
                    simpleUnexplode: "red,green,blue",
                    formDataExplode: "list=red&list=green&list=blue",
                    formDataUnexplode: "list=red,green,blue"
                )
            ),
            makeCase(
                value: .dictionary([
                    "semi": .primitive(.string(";")),
                    "dot": .primitive(.string(".")),
                    "comma": .primitive(.string(","))
                ]),
                key: "keys",
                .init(
                    formExplode: "comma=%2C&dot=.&semi=%3B",
                    formUnexplode: "keys=comma,%2C,dot,.,semi,%3B",
                    simpleExplode: "comma=%2C,dot=.,semi=%3B",
                    simpleUnexplode: "comma,%2C,dot,.,semi,%3B",
                    formDataExplode: "comma=%2C&dot=.&semi=%3B",
                    formDataUnexplode: "keys=comma,%2C,dot,.,semi,%3B"
                )
            ),
        ]
        for testCase in cases {
            func testVariant(_ variant: Case.Variant, _ expectedString: String) throws {
                var serializer = URISerializer(configuration: variant.config)
                let encodedString = try serializer.serializeNode(
                    testCase.value,
                    forKey: testCase.key
                )
                XCTAssertEqual(
                    encodedString,
                    expectedString,
                    "Failed for config: \(variant.name)",
                    file: testCase.file,
                    line: testCase.line
                )
            }
            try testVariant(.formExplode, testCase.variants.formExplode)
            try testVariant(.formUnexplode, testCase.variants.formUnexplode)
            try testVariant(.simpleExplode, testCase.variants.simpleExplode)
            try testVariant(.simpleUnexplode, testCase.variants.simpleUnexplode)
            try testVariant(.formDataExplode,testCase.variants.formDataExplode)
            try testVariant(.formDataUnexplode, testCase.variants.formDataUnexplode)
        }
    }
}

extension Test_URISerializer {
    struct Case {
        struct Variant {
            var name: String
            var config: URICoderConfiguration
            
            static let formExplode: Self = .init(
                name: "formExplode",
                config: .formExplode
            )
            static let formUnexplode: Self = .init(
                name: "formUnexplode",
                config: .formUnexplode
            )
            static let simpleExplode: Self = .init(
                name: "simpleExplode",
                config: .simpleExplode
            )
            static let simpleUnexplode: Self = .init(
                name: "simpleUnexplode",
                config: .simpleUnexplode
            )
            static let formDataExplode: Self = .init(
                name: "formDataExplode",
                config: .formDataExplode
            )
            static let formDataUnexplode: Self = .init(
                name: "formDataUnexplode",
                config: .formDataUnexplode
            )
        }
        struct Variants {
            var formExplode: String
            var formUnexplode: String
            var simpleExplode: String
            var simpleUnexplode: String
            var formDataExplode: String
            var formDataUnexplode: String
        }
        var value: URIEncodedNode
        var key: String
        var variants: Variants
        var file: StaticString = #file
        var line: UInt = #line
    }
    func makeCase(
        value: URIEncodedNode,
        key: String,
        _ variants: Case.Variants,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Case {
        .init(
            value: value,
            key: key,
            variants: variants,
            file: file,
            line: line
        )
    }
}
