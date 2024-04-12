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

    let testedVariants: [URICoderConfiguration] = [
        .formExplode, .formUnexplode, .simpleExplode, .simpleUnexplode, .formDataExplode, .formDataUnexplode, .deepObjectExplode
    ]

    func testParsing() throws {
        let cases: [Case] = [
            makeCase(
                .init(
                    formExplode: "empty=",
                    formUnexplode: "empty=",
                    simpleExplode: .custom("", value: ["": [""]]),
                    simpleUnexplode: .custom("", value: ["": [""]]),
                    formDataExplode: "empty=",
                    formDataUnexplode: "empty=",
                    deepObjectExplode: "object%5Bempty%5D="
                ),
                value: ["empty": [""]]
            ),
            makeCase(
                .init(
                    formExplode: "",
                    formUnexplode: "",
                    simpleExplode: .custom("", value: ["": [""]]),
                    simpleUnexplode: .custom("", value: ["": [""]]),
                    formDataExplode: "",
                    formDataUnexplode: "",
                    deepObjectExplode: ""
                ),
                value: [:]
            ),
            makeCase(
                .init(
                    formExplode: "who=fred",
                    formUnexplode: "who=fred",
                    simpleExplode: .custom("fred", value: ["": ["fred"]]),
                    simpleUnexplode: .custom("fred", value: ["": ["fred"]]),
                    formDataExplode: "who=fred",
                    formDataUnexplode: "who=fred",
                    deepObjectExplode: "object%5Bwho%5D=fred"
                ),
                value: ["who": ["fred"]]
            ),
            makeCase(
                .init(
                    formExplode: "hello=Hello%20World",
                    formUnexplode: "hello=Hello%20World",
                    simpleExplode: .custom("Hello%20World", value: ["": ["Hello World"]]),
                    simpleUnexplode: .custom("Hello%20World", value: ["": ["Hello World"]]),
                    formDataExplode: "hello=Hello+World",
                    formDataUnexplode: "hello=Hello+World",
                    deepObjectExplode: "object%5Bhello%5D=Hello%20World"
                ),
                value: ["hello": ["Hello World"]]
            ),
            makeCase(
                .init(
                    formExplode: "list=red&list=green&list=blue",
                    formUnexplode: "list=red,green,blue",
                    simpleExplode: .custom("red,green,blue", value: ["": ["red", "green", "blue"]]),
                    simpleUnexplode: .custom("red,green,blue", value: ["": ["red", "green", "blue"]]),
                    formDataExplode: "list=red&list=green&list=blue",
                    formDataUnexplode: "list=red,green,blue",
                    deepObjectExplode: .custom(
                        "object%5Blist%5D=red&object%5Blist%5D=green&object%5Blist%5D=blue",
                        expectedError: .malformedKeyValuePair("list")
                    )
                ),
                value: ["list": ["red", "green", "blue"]]
            ),
            makeCase(
                .init(
                    formExplode: "comma=%2C&dot=.&semi=%3B",
                    formUnexplode: .custom(
                        "keys=comma,%2C,dot,.,semi,%3B",
                        value: ["keys": ["comma", ",", "dot", ".", "semi", ";"]]
                    ),
                    simpleExplode: "comma=%2C,dot=.,semi=%3B",
                    simpleUnexplode: .custom(
                        "comma,%2C,dot,.,semi,%3B",
                        value: ["": ["comma", ",", "dot", ".", "semi", ";"]]
                    ),
                    formDataExplode: "comma=%2C&dot=.&semi=%3B",
                    formDataUnexplode: .custom(
                        "keys=comma,%2C,dot,.,semi,%3B",
                        value: ["keys": ["comma", ",", "dot", ".", "semi", ";"]]
                    ), 
                    deepObjectExplode: "keys%5Bcomma%5D=%2C&keys%5Bdot%5D=.&keys%5Bsemi%5D=%3B"
                ),
                value: ["semi": [";"], "dot": ["."], "comma": [","]]
            ),
        ]
        for testCase in cases {
            func testVariant(_ variant: Case.Variant, _ input: Case.Variants.Input) throws {
                var parser = URIParser(configuration: variant.config, data: input.string[...])
                do {
                    let parsedNode = try parser.parseRoot()
                    XCTAssertEqual(
                        parsedNode,
                        input.valueOverride ?? testCase.value,
                        "Failed for config: \(variant.name)",
                        file: testCase.file,
                        line: testCase.line
                    )
                } catch {
                    guard let expectedError = input.expectedError,
                          let parsingError = error as? ParsingError else {
                        XCTAssert(
                            false,
                            "Unexpected error thrown: \(error)",
                            file: testCase.file,
                            line: testCase.line
                        )
                        return
                    }
                    XCTAssertEqual(
                        expectedError,
                        parsingError,
                        "Failed for config: \(variant.name)",
                        file: testCase.file,
                        line: testCase.line
                    )
                }
            }
            let variants = testCase.variants
            try testVariant(.formExplode, variants.formExplode)
            try testVariant(.formUnexplode, variants.formUnexplode)
            try testVariant(.simpleExplode, variants.simpleExplode)
            try testVariant(.simpleUnexplode, variants.simpleUnexplode)
            try testVariant(.formDataExplode, variants.formDataExplode)
            try testVariant(.formDataUnexplode, variants.formDataUnexplode)
            try testVariant(.deepObjectExplode, variants.deepObjectExplode)
        }
    }
}

extension Test_URIParser {
    struct Case {
        struct Variant {
            var name: String
            var config: URICoderConfiguration

            static let formExplode: Self = .init(name: "formExplode", config: .formExplode)
            static let formUnexplode: Self = .init(name: "formUnexplode", config: .formUnexplode)
            static let simpleExplode: Self = .init(name: "simpleExplode", config: .simpleExplode)
            static let simpleUnexplode: Self = .init(name: "simpleUnexplode", config: .simpleUnexplode)
            static let formDataExplode: Self = .init(name: "formDataExplode", config: .formDataExplode)
            static let formDataUnexplode: Self = .init(name: "formDataUnexplode", config: .formDataUnexplode)
            static let deepObjectExplode: Self = .init(name: "deepObjectExplode", config: .deepObjectExplode)
        }
        struct Variants {

            struct Input: ExpressibleByStringLiteral {
                var string: String
                var valueOverride: URIParsedNode?
                var expectedError: ParsingError?

                init(string: String, valueOverride: URIParsedNode? = nil, expectedError: ParsingError? = nil) {
                    self.string = string
                    self.valueOverride = valueOverride
                    self.expectedError = expectedError
                }

                static func custom(_ string: String, value: URIParsedNode) -> Self {
                    .init(string: string, valueOverride: value, expectedError: nil)
                }
                
                static func custom(_ string: String, expectedError: ParsingError) -> Self {
                    .init(string: string, valueOverride: nil, expectedError: expectedError)
                }

                init(stringLiteral value: String) {
                    self.string = value
                    self.valueOverride = nil
                    self.expectedError = nil
                }
            }

            var formExplode: Input
            var formUnexplode: Input
            var simpleExplode: Input
            var simpleUnexplode: Input
            var formDataExplode: Input
            var formDataUnexplode: Input
            var deepObjectExplode: Input
        }
        var variants: Variants
        var value: URIParsedNode
        var file: StaticString = #file
        var line: UInt = #line
    }
    func makeCase(_ variants: Case.Variants, value: URIParsedNode, file: StaticString = #file, line: UInt = #line)
        -> Case
    { .init(variants: variants, value: value, file: file, line: line) }
}
