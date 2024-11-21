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

/// Tests for URIParser.
///
/// Guiding examples:
///
///     rootKey: "color"
///
///     form explode:
///        - nil: "" -> nil
///        - empty: "color=" -> ("color/0", "")
///        - primitive: "color=blue" -> ("color/0", "blue")
///        - array: "color=blue&color=black&color=brown" -> [("color/0", "blue"), ("color/1", "black"), ("color/2", "brown)]
///        - dictionary+array: "R=100&G=200&G=150" -> [("color/R/0", "100"), ("color/G/0", "200"), ("color/G/1", "150")]
///
///     form unexplode:
///        - nil: "" -> nil
///        - empty: "color=" -> ("color/0", "")
///        - primitive: "color=blue" -> ("color/0", "blue")
///        - array: "color=blue,black,brown" -> [("color/0", "blue"), ("color/1", "black"), ("color/2", "brown)]
///        - dictionary: "color=R,100,G,200,G,150" -> [("color/R/0", "100"), ("color/G/0", "200"), ("color/G/1", "150")]
///
///     simple explode:
///        - nil: "" -> ("color/0", "")
///        - empty: "" -> ("color/0", "")
///        - primitive: "blue" -> ("color/0", "blue")
///        - array: "blue,black,brown" -> [("color/0", "blue"), ("color/1", "black"), ("color/2", "brown)]
///        - dictionary+array: "R=100,G=200,G=150" -> [("color/R/0", "100"), ("color/G/0", "200"), ("color/G/1", "150")]
///
///     simple unexplode:
///        - nil: "" -> ("color/0", "")
///        - empty: "" -> ("color/0", "")
///        - primitive: "blue" -> ("color/0", "blue")
///        - array: "blue,black,brown" -> [("color/0", "blue"), ("color/1", "black"), ("color/2", "brown)]
///        - dictionary: "R,100,G,200,G,150" -> [("color/R/0", "100"), ("color/G/0", "200"), ("color/G/1", "150")]
///
///     deepObject unexplode: unsupported
///
///     deepObject explode:
///        - nil: -> unsupported
///        - empty: -> unsupported
///        - primitive: -> unsupported
///        - array: -> unsupported
///        - dictionary: "color%5BR%5D=100&color%5BG%5D=200&color%5BG%5D=150"
///            -> [("color/R/0", "100"), ("color/G/0", "200"), ("color/G/1", "150")]
final class Test_URIParser: Test_Runtime {

    func testParsing() throws {
        // Guiding examples, test filtering relevant keys for the rootKey
        try testCase(
            formExplode: .init(
                rootKey: "color",
                primitive: .assert("prefix=bar&color=blue&suffix=baz", equals: .init(key: "color", value: "blue")),
                array: .assert(
                    "prefix=bar&color=blue&color=black&color=brown&suffix=baz",
                    equals: [
                        .init(key: "color", value: "blue"), .init(key: "color", value: "black"),
                        .init(key: "color", value: "brown"),
                    ]
                ),
                dictionary: .assert(
                    "R=100&G=200&G=150",
                    equals: [
                        .init(key: "R", value: "100"), .init(key: "G", value: "200"), .init(key: "G", value: "150"),
                    ]
                )
            ),
            formUnexplode: .init(
                rootKey: "color",
                primitive: .assert("prefix=bar&color=blue&suffix=baz", equals: .init(key: "color", value: "blue")),
                array: .assert(
                    "prefix=bar&color=blue,black,brown&suffix=baz",
                    equals: [
                        .init(key: "color", value: "blue"), .init(key: "color", value: "black"),
                        .init(key: "color", value: "brown"),
                    ]
                ),
                dictionary: .assert(
                    "prefix=bar&color=R,100,G,200,G,150&suffix=baz",
                    equals: [
                        .init(key: "color/R", value: "100"), .init(key: "color/G", value: "200"),
                        .init(key: "color/G", value: "150"),
                    ]
                )
            ),
            simpleExplode: .init(
                rootKey: "color",
                primitive: .assert("blue", equals: .init(key: .empty, value: "blue")),
                array: .assert(
                    "blue,black,brown",
                    equals: [
                        .init(key: .empty, value: "blue"), .init(key: .empty, value: "black"),
                        .init(key: .empty, value: "brown"),
                    ]
                ),
                dictionary: .assert(
                    "R=100,G=200,G=150",
                    equals: [
                        .init(key: "R", value: "100"), .init(key: "G", value: "200"), .init(key: "G", value: "150"),
                    ]
                )
            ),
            simpleUnexplode: .init(
                rootKey: "color",
                primitive: .assert("blue", equals: .init(key: .empty, value: "blue")),
                array: .assert(
                    "blue,black,brown",
                    equals: [
                        .init(key: .empty, value: "blue"), .init(key: .empty, value: "black"),
                        .init(key: .empty, value: "brown"),
                    ]
                ),
                dictionary: .assert(
                    "R,100,G,200,G,150",
                    equals: [
                        .init(key: "R", value: "100"), .init(key: "G", value: "200"), .init(key: "G", value: "150"),
                    ]
                )
            ),
            formDataExplode: .init(
                rootKey: "color",
                primitive: .assert("prefix=bar&color=blue&suffix=baz", equals: .init(key: "color", value: "blue")),
                array: .assert(
                    "prefix=bar&color=blue&color=black&color=brown&suffix=baz",
                    equals: [
                        .init(key: "color", value: "blue"), .init(key: "color", value: "black"),
                        .init(key: "color", value: "brown"),
                    ]
                ),
                dictionary: .assert(
                    "R=100&G=200&G=150",
                    equals: [
                        .init(key: "R", value: "100"), .init(key: "G", value: "200"), .init(key: "G", value: "150"),
                    ]
                )
            ),
            formDataUnexplode: .init(
                rootKey: "color",
                primitive: .assert("prefix=bar&color=blue&suffix=baz", equals: .init(key: "color", value: "blue")),
                array: .assert(
                    "prefix=bar&color=blue,black,brown&suffix=baz",
                    equals: [
                        .init(key: "color", value: "blue"), .init(key: "color", value: "black"),
                        .init(key: "color", value: "brown"),
                    ]
                ),
                dictionary: .assert(
                    "prefix=bar&color=R,100,G,200,G,150&suffix=baz",
                    equals: [
                        .init(key: "color/R", value: "100"), .init(key: "color/G", value: "200"),
                        .init(key: "color/G", value: "150"),
                    ]
                )
            ),
            deepObjectExplode: .init(
                rootKey: "color",
                primitive: .init(
                    string: "",
                    result: .failure({ error in
                        guard case .invalidConfiguration = error else {
                            XCTFail("Unexpected error: \(error)")
                            return
                        }
                    })
                ),
                array: .init(
                    string: "",
                    result: .failure({ error in
                        guard case .invalidConfiguration = error else {
                            XCTFail("Unexpected error: \(error)")
                            return
                        }
                    })
                ),
                dictionary: .assert(
                    "prefix%5Bfoo%5D=1&color%5BR%5D=100&color%5BG%5D=200&color%5BG%5D=150&suffix%5Bbaz%5D=2",
                    equals: [
                        .init(key: "color/R", value: "100"), .init(key: "color/G", value: "200"),
                        .init(key: "color/G", value: "150"),
                    ]
                )
            )
        )

        // Test escaping
        try testCase(
            formExplode: .init(
                rootKey: "message",
                primitive: .assert("message=Hello%20world", equals: .init(key: "message", value: "Hello world")),
                array: .assert(
                    "message=Hello%20world&message=%240",
                    equals: [.init(key: "message", value: "Hello world"), .init(key: "message", value: "$0")]
                ),
                dictionary: .assert(
                    "R=Hello%20world&G=%24%24%24&G=%40%40%40",
                    equals: [
                        .init(key: "R", value: "Hello world"), .init(key: "G", value: "$$$"),
                        .init(key: "G", value: "@@@"),
                    ]
                )
            ),
            formUnexplode: .init(
                rootKey: "message",
                primitive: .assert("message=Hello%20world", equals: .init(key: "message", value: "Hello world")),
                array: .assert(
                    "message=Hello%20world,%240",
                    equals: [.init(key: "message", value: "Hello world"), .init(key: "message", value: "$0")]
                ),
                dictionary: .assert(
                    "message=R,Hello%20world,G,%24%24%24,G,%40%40%40",
                    equals: [
                        .init(key: "message/R", value: "Hello world"), .init(key: "message/G", value: "$$$"),
                        .init(key: "message/G", value: "@@@"),
                    ]
                )
            ),
            simpleExplode: .init(
                rootKey: "message",
                primitive: .assert("Hello%20world", equals: .init(key: .empty, value: "Hello world")),
                array: .assert(
                    "Hello%20world,%24%24%24,%40%40%40",
                    equals: [
                        .init(key: .empty, value: "Hello world"), .init(key: .empty, value: "$$$"),
                        .init(key: .empty, value: "@@@"),
                    ]
                ),
                dictionary: .assert(
                    "R=Hello%20world,G=%24%24%24,G=%40%40%40",
                    equals: [
                        .init(key: "R", value: "Hello world"), .init(key: "G", value: "$$$"),
                        .init(key: "G", value: "@@@"),
                    ]
                )
            ),
            simpleUnexplode: .init(
                rootKey: "message",
                primitive: .assert("Hello%20world", equals: .init(key: .empty, value: "Hello world")),
                array: .assert(
                    "Hello%20world,%24%24%24,%40%40%40",
                    equals: [
                        .init(key: .empty, value: "Hello world"), .init(key: .empty, value: "$$$"),
                        .init(key: .empty, value: "@@@"),
                    ]
                ),
                dictionary: .assert(
                    "R,Hello%20world,G,%24%24%24,G,%40%40%40",
                    equals: [
                        .init(key: "R", value: "Hello world"), .init(key: "G", value: "$$$"),
                        .init(key: "G", value: "@@@"),
                    ]
                )
            ),
            formDataExplode: .init(
                rootKey: "message",
                primitive: .assert("message=Hello+world", equals: .init(key: "message", value: "Hello world")),
                array: .assert(
                    "message=Hello+world&message=%240",
                    equals: [.init(key: "message", value: "Hello world"), .init(key: "message", value: "$0")]
                ),
                dictionary: .assert(
                    "R=Hello+world&G=%24%24%24&G=%40%40%40",
                    equals: [
                        .init(key: "R", value: "Hello world"), .init(key: "G", value: "$$$"),
                        .init(key: "G", value: "@@@"),
                    ]
                )
            ),
            formDataUnexplode: .init(
                rootKey: "message",
                primitive: .assert("message=Hello+world", equals: .init(key: "message", value: "Hello world")),
                array: .assert(
                    "message=Hello+world,%240",
                    equals: [.init(key: "message", value: "Hello world"), .init(key: "message", value: "$0")]
                ),
                dictionary: .assert(
                    "message=R,Hello+world,G,%24%24%24,G,%40%40%40",
                    equals: [
                        .init(key: "message/R", value: "Hello world"), .init(key: "message/G", value: "$$$"),
                        .init(key: "message/G", value: "@@@"),
                    ]
                )
            ),
            deepObjectExplode: .init(
                rootKey: "message",
                primitive: .init(
                    string: "",
                    result: .failure({ error in
                        guard case .invalidConfiguration = error else {
                            XCTFail("Unexpected error: \(error)")
                            return
                        }
                    })
                ),
                array: .init(
                    string: "",
                    result: .failure({ error in
                        guard case .invalidConfiguration = error else {
                            XCTFail("Unexpected error: \(error)")
                            return
                        }
                    })
                ),
                dictionary: .assert(
                    "message%5BR%5D=Hello%20world&message%5BG%5D=%24%24%24&message%5BG%5D=%40%40%40",
                    equals: [
                        .init(key: "message/R", value: "Hello world"), .init(key: "message/G", value: "$$$"),
                        .init(key: "message/G", value: "@@@"),
                    ]
                )
            )
        )

        // Missing/nil
        try testCase(
            formExplode: .init(
                rootKey: "color",
                primitive: .assert("prefix=bar&suffix=baz", equals: nil),
                array: .assert("prefix=bar&suffix=baz", equals: []),
                dictionary: .assert("", equals: [])
            ),
            formUnexplode: .init(
                rootKey: "color",
                primitive: .assert("prefix=bar&suffix=baz", equals: nil),
                array: .assert("prefix=bar&suffix=baz", equals: []),
                dictionary: .assert("prefix=bar&suffix=baz", equals: [])
            ),
            simpleExplode: .init(
                rootKey: "color",
                primitive: .assert("", equals: .init(key: .empty, value: "")),
                array: .assert("", equals: []),
                dictionary: .assert("", equals: [])
            ),
            simpleUnexplode: .init(
                rootKey: "color",
                primitive: .assert("", equals: .init(key: .empty, value: "")),
                array: .assert("", equals: []),
                dictionary: .assert("", equals: [])
            ),
            formDataExplode: .init(
                rootKey: "color",
                primitive: .assert("prefix=bar&suffix=baz", equals: nil),
                array: .assert("prefix=bar&suffix=baz", equals: []),
                dictionary: .assert("", equals: [])
            ),
            formDataUnexplode: .init(
                rootKey: "color",
                primitive: .assert("prefix=bar&suffix=baz", equals: nil),
                array: .assert("prefix=bar&suffix=baz", equals: []),
                dictionary: .assert("prefix=bar&suffix=baz", equals: [])
            ),
            deepObjectExplode: .init(
                rootKey: "color",
                primitive: .init(
                    string: "",
                    result: .failure({ error in
                        guard case .invalidConfiguration = error else {
                            XCTFail("Unexpected error: \(error)")
                            return
                        }
                    })
                ),
                array: .init(
                    string: "",
                    result: .failure({ error in
                        guard case .invalidConfiguration = error else {
                            XCTFail("Unexpected error: \(error)")
                            return
                        }
                    })
                ),
                dictionary: .assert("prefix%5Bfoo%5D=1&suffix%5Bbaz%5D=2", equals: [])
            )
        )

        // Empty value (distinct from missing/nil, but some cases overlap)
        try testCase(
            formExplode: .init(
                rootKey: "color",
                primitive: .assert("prefix=bar&color=&suffix=baz", equals: .init(key: "color", value: "")),
                array: .assert("prefix=bar&color=&suffix=baz", equals: [.init(key: "color", value: "")]),
                dictionary: .assert(
                    "R=&G=200&G=150",
                    equals: [.init(key: "R", value: ""), .init(key: "G", value: "200"), .init(key: "G", value: "150")]
                )
            ),
            formUnexplode: .init(
                rootKey: "color",
                primitive: .assert("prefix=bar&color=&suffix=baz", equals: .init(key: "color", value: "")),
                array: .assert("prefix=bar&color=&suffix=baz", equals: [.init(key: "color", value: "")]),
                dictionary: .assert(
                    "prefix=bar&color=R,,G,200,G,150&suffix=baz",
                    equals: [
                        .init(key: "color/R", value: ""), .init(key: "color/G", value: "200"),
                        .init(key: "color/G", value: "150"),
                    ]
                )
            ),
            simpleExplode: .init(
                rootKey: "color",
                primitive: .assert("", equals: .init(key: .empty, value: "")),
                array: .assert(
                    ",black,brown",
                    equals: [
                        .init(key: .empty, value: ""), .init(key: .empty, value: "black"),
                        .init(key: .empty, value: "brown"),
                    ]
                ),
                dictionary: .assert(
                    "R=,G=200,G=150",
                    equals: [.init(key: "R", value: ""), .init(key: "G", value: "200"), .init(key: "G", value: "150")]
                )
            ),
            simpleUnexplode: .init(
                rootKey: "color",
                primitive: .assert("", equals: .init(key: .empty, value: "")),
                array: .assert(
                    ",black,brown",
                    equals: [
                        .init(key: .empty, value: ""), .init(key: .empty, value: "black"),
                        .init(key: .empty, value: "brown"),
                    ]
                ),
                dictionary: .assert(
                    "R,,G,200,G,150",
                    equals: [.init(key: "R", value: ""), .init(key: "G", value: "200"), .init(key: "G", value: "150")]
                )
            ),
            formDataExplode: .init(
                rootKey: "color",
                primitive: .assert("prefix=bar&color=&suffix=baz", equals: .init(key: "color", value: "")),
                array: .assert(
                    "prefix=bar&color=&color=black&color=brown&suffix=baz",
                    equals: [
                        .init(key: "color", value: ""), .init(key: "color", value: "black"),
                        .init(key: "color", value: "brown"),
                    ]
                ),
                dictionary: .assert(
                    "R=&G=200&G=150",
                    equals: [.init(key: "R", value: ""), .init(key: "G", value: "200"), .init(key: "G", value: "150")]
                )
            ),
            formDataUnexplode: .init(
                rootKey: "color",
                primitive: .assert("prefix=bar&color=&suffix=baz", equals: .init(key: "color", value: "")),
                array: .assert(
                    "prefix=bar&color=,black,brown&suffix=baz",
                    equals: [
                        .init(key: "color", value: ""), .init(key: "color", value: "black"),
                        .init(key: "color", value: "brown"),
                    ]
                ),
                dictionary: .assert(
                    "prefix=bar&color=R,,G,200,G,150&suffix=baz",
                    equals: [
                        .init(key: "color/R", value: ""), .init(key: "color/G", value: "200"),
                        .init(key: "color/G", value: "150"),
                    ]
                )
            ),
            deepObjectExplode: .init(
                rootKey: "color",
                primitive: .init(
                    string: "",
                    result: .failure({ error in
                        guard case .invalidConfiguration = error else {
                            XCTFail("Unexpected error: \(error)")
                            return
                        }
                    })
                ),
                array: .init(
                    string: "",
                    result: .failure({ error in
                        guard case .invalidConfiguration = error else {
                            XCTFail("Unexpected error: \(error)")
                            return
                        }
                    })
                ),
                dictionary: .assert(
                    "prefix%5Bfoo%5D=1&color%5BR%5D=&color%5BG%5D=200&color%5BG%5D=150&suffix%5Bbaz%5D=2",
                    equals: [
                        .init(key: "color/R", value: ""), .init(key: "color/G", value: "200"),
                        .init(key: "color/G", value: "150"),
                    ]
                )
            )
        )
    }

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
        struct RootInput<RootType: Equatable> {
            var string: String
            enum ExpectedResult {
                case success(RootType)
                case failure((ParsingError) -> Void)
            }
            var result: ExpectedResult

            init(string: String, result: ExpectedResult) {
                self.string = string
                self.result = result
            }

            static func assert(_ string: String, equals value: RootType) -> Self {
                .init(string: string, result: .success(value))
            }
            static func assert(_ string: String, validateError: @escaping (ParsingError) -> Void) -> Self {
                .init(string: string, result: .failure(validateError))
            }
        }
        struct Input {
            var rootKey: URIParsedKeyComponent
            var primitive: RootInput<URIParsedPair?>
            var array: RootInput<[URIParsedPair]>
            var dictionary: RootInput<[URIParsedPair]>
        }
        struct Variants {
            var formExplode: Input
            var formUnexplode: Input
            var simpleExplode: Input
            var simpleUnexplode: Input
            var formDataExplode: Input
            var formDataUnexplode: Input
            var deepObjectExplode: Input
        }
        var variants: Variants
        var file: StaticString = #file
        var line: UInt = #line
    }

    func testCase(_ variants: Case.Variants, file: StaticString = #file, line: UInt = #line) throws {
        let caseValue = Case(variants: variants, file: file, line: line)
        func testVariant(_ variant: Case.Variant, _ input: Case.Input) throws {
            func testRoot<RootType: Equatable>(
                rootName: String,
                _ root: Case.RootInput<RootType>,
                parse: (URIParser) throws -> RootType
            ) throws {
                let parser = URIParser(configuration: variant.config, data: root.string[...])
                switch root.result {
                case .success(let expectedValue):
                    let parsedValue = try parse(parser)
                    XCTAssertEqual(
                        parsedValue,
                        expectedValue,
                        "Failed for config: \(variant.name), root: \(rootName)",
                        file: caseValue.file,
                        line: caseValue.line
                    )
                case .failure(let validateError):
                    do {
                        _ = try parse(parser)
                        XCTFail("Should have thrown an error", file: caseValue.file, line: caseValue.line)
                    } catch {
                        guard let parsingError = error as? ParsingError else {
                            XCTAssert(
                                false,
                                "Unexpected error thrown: \(error)",
                                file: caseValue.file,
                                line: caseValue.line
                            )
                            return
                        }
                        validateError(parsingError)
                    }
                }
            }
            try testRoot(
                rootName: "primitive",
                input.primitive,
                parse: { try $0.parseRootAsPrimitive(rootKey: input.rootKey) }
            )
            try testRoot(rootName: "array", input.array, parse: { try $0.parseRootAsArray(rootKey: input.rootKey) })
            try testRoot(
                rootName: "dictionary",
                input.dictionary,
                parse: { try $0.parseRootAsDictionary(rootKey: input.rootKey) }
            )
        }
        let variants = caseValue.variants
        try testVariant(.formExplode, variants.formExplode)
        try testVariant(.formUnexplode, variants.formUnexplode)
        try testVariant(.simpleExplode, variants.simpleExplode)
        try testVariant(.simpleUnexplode, variants.simpleUnexplode)
        try testVariant(.formDataExplode, variants.formDataExplode)
        try testVariant(.formDataUnexplode, variants.formDataUnexplode)
        try testVariant(.deepObjectExplode, variants.deepObjectExplode)
    }

    func testCase(
        formExplode: Case.Input,
        formUnexplode: Case.Input,
        simpleExplode: Case.Input,
        simpleUnexplode: Case.Input,
        formDataExplode: Case.Input,
        formDataUnexplode: Case.Input,
        deepObjectExplode: Case.Input,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        try testCase(
            .init(
                formExplode: formExplode,
                formUnexplode: formUnexplode,
                simpleExplode: simpleExplode,
                simpleUnexplode: simpleUnexplode,
                formDataExplode: formDataExplode,
                formDataUnexplode: formDataUnexplode,
                deepObjectExplode: deepObjectExplode
            ),
            file: file,
            line: line
        )
    }
}
