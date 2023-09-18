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
@_spi(Generated)@testable import OpenAPIRuntime
#if os(Linux)
@preconcurrency import Foundation
#endif

final class Test_URICodingRoundtrip: Test_Runtime {

    func testRoundtrip() throws {

        struct SimpleStruct: Codable, Equatable {
            var foo: String
            var bar: Int
            var color: SimpleEnum
            var empty: String
            var date: Date
            var maybeFoo: String?
        }

        struct TrivialStruct: Codable, Equatable {
            var foo: String
        }

        enum SimpleEnum: String, Codable, Equatable {
            case red
            case green
            case blue
        }

        struct AnyOf: Codable, Equatable, Sendable {
            var value1: Foundation.Date?
            var value2: SimpleEnum?
            var value3: TrivialStruct?
            init(value1: Foundation.Date? = nil, value2: SimpleEnum? = nil, value3: TrivialStruct? = nil) {
                self.value1 = value1
                self.value2 = value2
                self.value3 = value3
            }
            init(from decoder: any Decoder) throws {
                do {
                    let container = try decoder.singleValueContainer()
                    value1 = try? container.decode(Foundation.Date.self)
                }
                do {
                    let container = try decoder.singleValueContainer()
                    value2 = try? container.decode(SimpleEnum.self)
                }
                do {
                    let container = try decoder.singleValueContainer()
                    value3 = try? container.decode(TrivialStruct.self)
                }
                try DecodingError.verifyAtLeastOneSchemaIsNotNil(
                    [value1, value2, value3],
                    type: Self.self,
                    codingPath: decoder.codingPath
                )
            }
            func encode(to encoder: any Encoder) throws {
                if let value1 {
                    var container = encoder.singleValueContainer()
                    try container.encode(value1)
                }
                if let value2 {
                    var container = encoder.singleValueContainer()
                    try container.encode(value2)
                }
                if let value3 {
                    var container = encoder.singleValueContainer()
                    try container.encode(value3)
                }
            }
        }

        // An empty string.
        try _test(
            "",
            key: "root",
            .init(
                formExplode: "root=",
                formUnexplode: "root=",
                simpleExplode: "",
                simpleUnexplode: "",
                formDataExplode: "root=",
                formDataUnexplode: "root="
            )
        )

        // An string with a space.
        try _test(
            "Hello World!",
            key: "root",
            .init(
                formExplode: "root=Hello%20World%21",
                formUnexplode: "root=Hello%20World%21",
                simpleExplode: "Hello%20World%21",
                simpleUnexplode: "Hello%20World%21",
                formDataExplode: "root=Hello+World%21",
                formDataUnexplode: "root=Hello+World%21"
            )
        )

        // An enum.
        try _test(
            SimpleEnum.red,
            key: "root",
            .init(
                formExplode: "root=red",
                formUnexplode: "root=red",
                simpleExplode: "red",
                simpleUnexplode: "red",
                formDataExplode: "root=red",
                formDataUnexplode: "root=red"
            )
        )

        // An integer.
        try _test(
            1234,
            key: "root",
            .init(
                formExplode: "root=1234",
                formUnexplode: "root=1234",
                simpleExplode: "1234",
                simpleUnexplode: "1234",
                formDataExplode: "root=1234",
                formDataUnexplode: "root=1234"
            )
        )

        // A float.
        try _test(
            12.34,
            key: "root",
            .init(
                formExplode: "root=12.34",
                formUnexplode: "root=12.34",
                simpleExplode: "12.34",
                simpleUnexplode: "12.34",
                formDataExplode: "root=12.34",
                formDataUnexplode: "root=12.34"
            )
        )

        // A bool.
        try _test(
            true,
            key: "root",
            .init(
                formExplode: "root=true",
                formUnexplode: "root=true",
                simpleExplode: "true",
                simpleUnexplode: "true",
                formDataExplode: "root=true",
                formDataUnexplode: "root=true"
            )
        )

        // A Date.
        try _test(
            Date(timeIntervalSince1970: 1_692_948_899),
            key: "root",
            .init(
                formExplode: "root=2023-08-25T07%3A34%3A59Z",
                formUnexplode: "root=2023-08-25T07%3A34%3A59Z",
                simpleExplode: "2023-08-25T07%3A34%3A59Z",
                simpleUnexplode: "2023-08-25T07%3A34%3A59Z",
                formDataExplode: "root=2023-08-25T07%3A34%3A59Z",
                formDataUnexplode: "root=2023-08-25T07%3A34%3A59Z"
            )
        )

        // A simple array of strings.
        try _test(
            ["a", "b", "c"],
            key: "list",
            .init(
                formExplode: "list=a&list=b&list=c",
                formUnexplode: "list=a,b,c",
                simpleExplode: "a,b,c",
                simpleUnexplode: "a,b,c",
                formDataExplode: "list=a&list=b&list=c",
                formDataUnexplode: "list=a,b,c"
            )
        )

        // A simple array of dates.
        try _test(
            [
                Date(timeIntervalSince1970: 1_692_948_899),
                Date(timeIntervalSince1970: 1_692_948_901),
            ],
            key: "list",
            .init(
                formExplode: "list=2023-08-25T07%3A34%3A59Z&list=2023-08-25T07%3A35%3A01Z",
                formUnexplode: "list=2023-08-25T07%3A34%3A59Z,2023-08-25T07%3A35%3A01Z",
                simpleExplode: "2023-08-25T07%3A34%3A59Z,2023-08-25T07%3A35%3A01Z",
                simpleUnexplode: "2023-08-25T07%3A34%3A59Z,2023-08-25T07%3A35%3A01Z",
                formDataExplode: "list=2023-08-25T07%3A34%3A59Z&list=2023-08-25T07%3A35%3A01Z",
                formDataUnexplode: "list=2023-08-25T07%3A34%3A59Z,2023-08-25T07%3A35%3A01Z"
            )
        )

        // An empty array of strings.
        try _test(
            [] as [String],
            key: "list",
            .init(
                formExplode: "",
                formUnexplode: "",
                simpleExplode: .custom("", value: [""]),
                simpleUnexplode: .custom("", value: [""]),
                formDataExplode: "",
                formDataUnexplode: ""
            )
        )

        // A simple array of enums.
        try _test(
            [.red, .green, .blue] as [SimpleEnum],
            key: "list",
            .init(
                formExplode: "list=red&list=green&list=blue",
                formUnexplode: "list=red,green,blue",
                simpleExplode: "red,green,blue",
                simpleUnexplode: "red,green,blue",
                formDataExplode: "list=red&list=green&list=blue",
                formDataUnexplode: "list=red,green,blue"
            )
        )

        // A struct.
        try _test(
            SimpleStruct(
                foo: "hi!",
                bar: 24,
                color: .red,
                empty: "",
                date: Date(timeIntervalSince1970: 1_692_948_899)
            ),
            key: "keys",
            .init(
                formExplode: "bar=24&color=red&date=2023-08-25T07%3A34%3A59Z&empty=&foo=hi%21",
                formUnexplode: "keys=bar,24,color,red,date,2023-08-25T07%3A34%3A59Z,empty,,foo,hi%21",
                simpleExplode: "bar=24,color=red,date=2023-08-25T07%3A34%3A59Z,empty=,foo=hi%21",
                simpleUnexplode: "bar,24,color,red,date,2023-08-25T07%3A34%3A59Z,empty,,foo,hi%21",
                formDataExplode: "bar=24&color=red&date=2023-08-25T07%3A34%3A59Z&empty=&foo=hi%21",
                formDataUnexplode: "keys=bar,24,color,red,date,2023-08-25T07%3A34%3A59Z,empty,,foo,hi%21"
            )
        )

        // A struct with a custom Codable implementation that forwards
        // decoding to nested values.
        try _test(
            AnyOf(
                value1: Date(timeIntervalSince1970: 1_674_036_251)
            ),
            key: "root",
            .init(
                formExplode: "root=2023-01-18T10%3A04%3A11Z",
                formUnexplode: "root=2023-01-18T10%3A04%3A11Z",
                simpleExplode: "2023-01-18T10%3A04%3A11Z",
                simpleUnexplode: "2023-01-18T10%3A04%3A11Z",
                formDataExplode: "root=2023-01-18T10%3A04%3A11Z",
                formDataUnexplode: "root=2023-01-18T10%3A04%3A11Z"
            )
        )
        try _test(
            AnyOf(
                value2: .green
            ),
            key: "root",
            .init(
                formExplode: "root=green",
                formUnexplode: "root=green",
                simpleExplode: "green",
                simpleUnexplode: "green",
                formDataExplode: "root=green",
                formDataUnexplode: "root=green"
            )
        )
        try _test(
            AnyOf(
                value3: .init(foo: "bar")
            ),
            key: "root",
            .init(
                formExplode: "foo=bar",
                formUnexplode: "root=foo,bar",
                simpleExplode: "foo=bar",
                simpleUnexplode: "foo,bar",
                formDataExplode: "foo=bar",
                formDataUnexplode: "root=foo,bar"
            )
        )

        // An empty struct.
        struct EmptyStruct: Codable, Equatable {}
        try _test(
            EmptyStruct(),
            key: "keys",
            .init(
                formExplode: "",
                formUnexplode: "",
                simpleExplode: "",
                simpleUnexplode: "",
                formDataExplode: "",
                formDataUnexplode: ""
            )
        )

        // A simple dictionary.
        try _test(
            ["foo": "hi!", "bar": "24", "color": "red", "empty": ""],
            key: "keys",
            .init(
                formExplode: "bar=24&color=red&empty=&foo=hi%21",
                formUnexplode: "keys=bar,24,color,red,empty,,foo,hi%21",
                simpleExplode: "bar=24,color=red,empty=,foo=hi%21",
                simpleUnexplode: "bar,24,color,red,empty,,foo,hi%21",
                formDataExplode: "bar=24&color=red&empty=&foo=hi%21",
                formDataUnexplode: "keys=bar,24,color,red,empty,,foo,hi%21"
            )
        )

        // An empty dictionary.
        try _test(
            [:] as [String: String],
            key: "keys",
            .init(
                formExplode: "",
                formUnexplode: "",
                simpleExplode: .custom("", value: ["": ""]),
                simpleUnexplode: .custom("", value: ["": ""]),
                formDataExplode: "",
                formDataUnexplode: ""
            )
        )
    }

    struct Variant {
        var name: String
        var configuration: URICoderConfiguration

        static let formExplode: Self = .init(
            name: "formExplode",
            configuration: .formExplode
        )
        static let formUnexplode: Self = .init(
            name: "formUnexplode",
            configuration: .formUnexplode
        )
        static let simpleExplode: Self = .init(
            name: "simpleExplode",
            configuration: .simpleExplode
        )
        static let simpleUnexplode: Self = .init(
            name: "simpleUnexplode",
            configuration: .simpleUnexplode
        )
        static let formDataExplode: Self = .init(
            name: "formDataExplode",
            configuration: .formDataExplode
        )
        static let formDataUnexplode: Self = .init(
            name: "formDataUnexplode",
            configuration: .formDataUnexplode
        )
    }
    struct Variants<T: Codable & Equatable> {

        struct Input: ExpressibleByStringLiteral {
            var string: String
            var customValue: T?

            init(string: String, customValue: T?) {
                self.string = string
                self.customValue = customValue
            }

            init(stringLiteral value: String) {
                self.init(string: value, customValue: nil)
            }

            static func custom(_ string: String, value: T) -> Self {
                .init(string: string, customValue: value)
            }
        }

        var formExplode: Input
        var formUnexplode: Input
        var simpleExplode: Input
        var simpleUnexplode: Input
        var formDataExplode: Input
        var formDataUnexplode: Input
    }

    func _test<T: Codable & Equatable>(
        _ value: T,
        key: String,
        _ variants: Variants<T>,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        func testVariant(
            name: String,
            configuration: URICoderConfiguration,
            variant: Variants<T>.Input
        ) throws {
            let encoder = URIEncoder(configuration: configuration)
            let encodedString = try encoder.encode(value, forKey: key)
            XCTAssertEqual(
                encodedString,
                variant.string,
                "Variant: \(name)",
                file: file,
                line: line
            )
            let decoder = URIDecoder(configuration: configuration)
            let decodedValue = try decoder.decode(
                T.self,
                forKey: key,
                from: encodedString[...]
            )
            XCTAssertEqual(
                decodedValue,
                variant.customValue ?? value,
                "Variant: \(name)",
                file: file,
                line: line
            )
        }
        try testVariant(
            name: "formExplode",
            configuration: .formExplode,
            variant: variants.formExplode
        )
        try testVariant(
            name: "formUnexplode",
            configuration: .formUnexplode,
            variant: variants.formUnexplode
        )
        try testVariant(
            name: "simpleExplode",
            configuration: .simpleExplode,
            variant: variants.simpleExplode
        )
        try testVariant(
            name: "simpleUnexplode",
            configuration: .simpleUnexplode,
            variant: variants.simpleUnexplode
        )
        try testVariant(
            name: "formDataExplode",
            configuration: .formDataExplode,
            variant: variants.formDataExplode
        )
        try testVariant(
            name: "formDataUnexplode",
            configuration: .formDataUnexplode,
            variant: variants.formDataUnexplode
        )
    }

}
