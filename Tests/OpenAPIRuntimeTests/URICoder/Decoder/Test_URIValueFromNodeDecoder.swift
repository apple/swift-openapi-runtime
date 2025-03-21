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
        struct SimpleStruct: Decodable, Equatable {
            var foo: String
            var bar: Int?
            var color: SimpleEnum?
        }

        struct StructWithArray: Decodable, Equatable {
            var foo: String
            var bar: [Int]?
            var val: [String]
        }

        enum SimpleEnum: String, Decodable, Equatable {
            case red
            case green
            case blue
        }

        // An empty string.
        try test("root=", "", key: "root")

        // An empty string with a simple style.
        try test("", "", key: "root", style: .simple)

        // A string with a space.
        try test("root=Hello%20world", "Hello world", key: "root")

        // An enum.
        try test("root=red", SimpleEnum.red, key: "root")

        // An integer.
        try test("root=1234", 1234, key: "root")

        // A float.
        try test("root=12.34", 12.34, key: "root")

        // A bool.
        try test("root=true", true, key: "root")

        // A simple array of strings.
        try test("root=a&root=b&root=c", ["a", "b", "c"], key: "root")

        // A simple array of enums.
        try test("root=red&root=green&root=blue", [.red, .green, .blue] as [SimpleEnum], key: "root")

        // A struct.
        try test("foo=bar", SimpleStruct(foo: "bar"), key: "root")

        // A struct with an array property.
        try test(
            "foo=bar&bar=1&bar=2&val=baz&val=baq",
            StructWithArray(foo: "bar", bar: [1, 2], val: ["baz", "baq"]),
            key: "root"
        )

        // A struct with a nested enum.
        try test("foo=bar&color=blue", SimpleStruct(foo: "bar", color: .blue), key: "root")

        // A simple dictionary.
        try test("one=1&two=2", ["one": 1, "two": 2], key: "root")

        // A unexploded simple dictionary.
        try test("one,1,two,2", ["one": 1, "two": 2], key: "root", style: .simple, explode: false)

        // A dictionary of enums.
        try test("one=blue&two=green", ["one": .blue, "two": .green] as [String: SimpleEnum], key: "root")

        func test<T: Decodable & Equatable>(
            _ data: String,
            _ expectedValue: T,
            key: String,
            style: URICoderConfiguration.Style = .form,
            explode: Bool = true,
            file: StaticString = #filePath,
            line: UInt = #line
        ) throws {
            let decoder = URIValueFromNodeDecoder(
                data: data[...],
                rootKey: key[...],
                configuration: .init(
                    style: style,
                    explode: explode,
                    spaceEscapingCharacter: .percentEncoded,
                    dateTranscoder: .iso8601
                )
            )
            let decodedValue = try decoder.decodeRoot(T.self)
            XCTAssertEqual(decodedValue, expectedValue, file: file, line: line)
        }
    }
}
