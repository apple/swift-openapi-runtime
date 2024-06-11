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
#if canImport(Darwin) || swift(>=5.9.1)
import struct Foundation.Date
#else
@preconcurrency import struct Foundation.Date
#endif
@_spi(Generated) @testable import OpenAPIRuntime

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

        struct TrivialStruct: Codable, Equatable { var foo: String }

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
                var errors: [any Error] = []
                do {
                    let container = try decoder.singleValueContainer()
                    value1 = try container.decode(Foundation.Date.self)
                } catch { errors.append(error) }
                do {
                    let container = try decoder.singleValueContainer()
                    value2 = try container.decode(SimpleEnum.self)
                } catch { errors.append(error) }
                do {
                    let container = try decoder.singleValueContainer()
                    value3 = try container.decode(TrivialStruct.self)
                } catch { errors.append(error) }
                try DecodingError.verifyAtLeastOneSchemaIsNotNil(
                    [value1, value2, value3],
                    type: Self.self,
                    codingPath: decoder.codingPath,
                    errors: errors
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
                formDataUnexplode: "root=",
                deepObjectExplode: .custom("root=", expectedError: .deepObjectsWithPrimitiveValuesNotSupported)
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
                formDataUnexplode: "root=Hello+World%21",
                deepObjectExplode: .custom(
                    "root=Hello%20World%21",
                    expectedError: .deepObjectsWithPrimitiveValuesNotSupported
                )
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
                formDataUnexplode: "root=red",
                deepObjectExplode: .custom("root=red", expectedError: .deepObjectsWithPrimitiveValuesNotSupported)
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
                formDataUnexplode: "root=1234",
                deepObjectExplode: .custom("root=1234", expectedError: .deepObjectsWithPrimitiveValuesNotSupported)
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
                formDataUnexplode: "root=12.34",
                deepObjectExplode: .custom("root=12.34", expectedError: .deepObjectsWithPrimitiveValuesNotSupported)
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
                formDataUnexplode: "root=true",
                deepObjectExplode: .custom("root=true", expectedError: .deepObjectsWithPrimitiveValuesNotSupported)
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
                formDataUnexplode: "root=2023-08-25T07%3A34%3A59Z",
                deepObjectExplode: .custom(
                    "root=2023-08-25T07%3A34%3A59Z",
                    expectedError: .deepObjectsWithPrimitiveValuesNotSupported
                )
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
                formDataUnexplode: "list=a,b,c",
                deepObjectExplode: .custom("list=a&list=b&list=c", expectedError: .deepObjectsArrayNotSupported)
            )
        )

        // A simple array of dates.
        try _test(
            [Date(timeIntervalSince1970: 1_692_948_899), Date(timeIntervalSince1970: 1_692_948_901)],
            key: "list",
            .init(
                formExplode: "list=2023-08-25T07%3A34%3A59Z&list=2023-08-25T07%3A35%3A01Z",
                formUnexplode: "list=2023-08-25T07%3A34%3A59Z,2023-08-25T07%3A35%3A01Z",
                simpleExplode: "2023-08-25T07%3A34%3A59Z,2023-08-25T07%3A35%3A01Z",
                simpleUnexplode: "2023-08-25T07%3A34%3A59Z,2023-08-25T07%3A35%3A01Z",
                formDataExplode: "list=2023-08-25T07%3A34%3A59Z&list=2023-08-25T07%3A35%3A01Z",
                formDataUnexplode: "list=2023-08-25T07%3A34%3A59Z,2023-08-25T07%3A35%3A01Z",
                deepObjectExplode: .custom(
                    "list=2023-08-25T07%3A34%3A59Z&list=2023-08-25T07%3A35%3A01Z",
                    expectedError: .deepObjectsArrayNotSupported
                )
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
                formDataUnexplode: "",
                deepObjectExplode: .custom("", expectedError: .deepObjectsArrayNotSupported)
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
                formDataUnexplode: "list=red,green,blue",
                deepObjectExplode: .custom(
                    "list=red&list=green&list=blue",
                    expectedError: .deepObjectsArrayNotSupported
                )
            )
        )

        // A struct.
        try _test(
            SimpleStruct(foo: "hi!", bar: 24, color: .red, empty: "", date: Date(timeIntervalSince1970: 1_692_948_899)),
            key: "keys",
            .init(
                formExplode: "bar=24&color=red&date=2023-08-25T07%3A34%3A59Z&empty=&foo=hi%21",
                formUnexplode: "keys=bar,24,color,red,date,2023-08-25T07%3A34%3A59Z,empty,,foo,hi%21",
                simpleExplode: "bar=24,color=red,date=2023-08-25T07%3A34%3A59Z,empty=,foo=hi%21",
                simpleUnexplode: "bar,24,color,red,date,2023-08-25T07%3A34%3A59Z,empty,,foo,hi%21",
                formDataExplode: "bar=24&color=red&date=2023-08-25T07%3A34%3A59Z&empty=&foo=hi%21",
                formDataUnexplode: "keys=bar,24,color,red,date,2023-08-25T07%3A34%3A59Z,empty,,foo,hi%21",
                deepObjectExplode:
                    "keys%5Bbar%5D=24&keys%5Bcolor%5D=red&keys%5Bdate%5D=2023-08-25T07%3A34%3A59Z&keys%5Bempty%5D=&keys%5Bfoo%5D=hi%21"
            )
        )

        // A struct with a custom Codable implementation that forwards
        // decoding to nested values.
        try _test(
            AnyOf(value1: Date(timeIntervalSince1970: 1_674_036_251)),
            key: "root",
            .init(
                formExplode: "root=2023-01-18T10%3A04%3A11Z",
                formUnexplode: "root=2023-01-18T10%3A04%3A11Z",
                simpleExplode: "2023-01-18T10%3A04%3A11Z",
                simpleUnexplode: "2023-01-18T10%3A04%3A11Z",
                formDataExplode: "root=2023-01-18T10%3A04%3A11Z",
                formDataUnexplode: "root=2023-01-18T10%3A04%3A11Z",
                deepObjectExplode: .custom(
                    "root=2023-01-18T10%3A04%3A11Z",
                    expectedError: .deepObjectsWithPrimitiveValuesNotSupported
                )
            )
        )
        try _test(
            AnyOf(value2: .green),
            key: "root",
            .init(
                formExplode: "root=green",
                formUnexplode: "root=green",
                simpleExplode: "green",
                simpleUnexplode: "green",
                formDataExplode: "root=green",
                formDataUnexplode: "root=green",
                deepObjectExplode: .custom("root=green", expectedError: .deepObjectsWithPrimitiveValuesNotSupported)
            )
        )
        try _test(
            AnyOf(value3: .init(foo: "bar")),
            key: "root",
            .init(
                formExplode: "foo=bar",
                formUnexplode: "root=foo,bar",
                simpleExplode: "foo=bar",
                simpleUnexplode: "foo,bar",
                formDataExplode: "foo=bar",
                formDataUnexplode: "root=foo,bar",
                deepObjectExplode: "root%5Bfoo%5D=bar"
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
                formDataUnexplode: "",
                deepObjectExplode: ""
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
                formDataUnexplode: "keys=bar,24,color,red,empty,,foo,hi%21",
                deepObjectExplode: "keys%5Bbar%5D=24&keys%5Bcolor%5D=red&keys%5Bempty%5D=&keys%5Bfoo%5D=hi%21"
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
                formDataUnexplode: "",
                deepObjectExplode: ""
            )
        )
    }

    struct Variant {
        var name: String
        var configuration: URICoderConfiguration

        static let formExplode: Self = .init(name: "formExplode", configuration: .formExplode)
        static let formUnexplode: Self = .init(name: "formUnexplode", configuration: .formUnexplode)
        static let simpleExplode: Self = .init(name: "simpleExplode", configuration: .simpleExplode)
        static let simpleUnexplode: Self = .init(name: "simpleUnexplode", configuration: .simpleUnexplode)
        static let formDataExplode: Self = .init(name: "formDataExplode", configuration: .formDataExplode)
        static let formDataUnexplode: Self = .init(name: "formDataUnexplode", configuration: .formDataUnexplode)
        static let deepObjectExplode: Self = .init(name: "deepObjectExplode", configuration: .deepObjectExplode)
    }
    struct Variants<T: Codable & Equatable> {

        struct Input: ExpressibleByStringLiteral {
            var string: String
            var customValue: T?
            var expectedError: URISerializer.SerializationError?
            init(string: String, customValue: T?, expectedError: URISerializer.SerializationError?) {
                self.string = string
                self.customValue = customValue
                self.expectedError = expectedError
            }

            init(stringLiteral value: String) { self.init(string: value, customValue: nil, expectedError: nil) }

            static func custom(_ string: String, value: T) -> Self {
                .init(string: string, customValue: value, expectedError: nil)
            }
            static func custom(_ string: String, expectedError: URISerializer.SerializationError) -> Self {
                .init(string: string, customValue: nil, expectedError: expectedError)
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

    func _test<T: Codable & Equatable>(
        _ value: T,
        key: String,
        _ variants: Variants<T>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        func testVariant(name: String, configuration: URICoderConfiguration, variant: Variants<T>.Input) throws {
            let encoder = URIEncoder(configuration: configuration)
            do {
                let encodedString = try encoder.encode(value, forKey: key)
                XCTAssertEqual(encodedString, variant.string, "Variant: \(name)", file: file, line: line)
                let decoder = URIDecoder(configuration: configuration)
                let decodedValue = try decoder.decode(T.self, forKey: key, from: encodedString[...])
                XCTAssertEqual(decodedValue, variant.customValue ?? value, "Variant: \(name)", file: file, line: line)
            } catch {
                guard let expectedError = variant.expectedError,
                    let serializationError = error as? URISerializer.SerializationError
                else {
                    XCTAssert(false, "Unexpected error thrown: \(error)", file: file, line: line)
                    return
                }
                XCTAssertEqual(
                    expectedError,
                    serializationError,
                    "Failed for config: \(variant.string)",
                    file: file,
                    line: line
                )
            }
        }
        try testVariant(name: "formExplode", configuration: .formExplode, variant: variants.formExplode)
        try testVariant(name: "formUnexplode", configuration: .formUnexplode, variant: variants.formUnexplode)
        try testVariant(name: "simpleExplode", configuration: .simpleExplode, variant: variants.simpleExplode)
        try testVariant(name: "simpleUnexplode", configuration: .simpleUnexplode, variant: variants.simpleUnexplode)
        try testVariant(name: "formDataExplode", configuration: .formDataExplode, variant: variants.formDataExplode)
        try testVariant(
            name: "formDataUnexplode",
            configuration: .formDataUnexplode,
            variant: variants.formDataUnexplode
        )
        try testVariant(
            name: "deepObjectExplode",
            configuration: .deepObjectExplode,
            variant: variants.deepObjectExplode
        )
    }
}
