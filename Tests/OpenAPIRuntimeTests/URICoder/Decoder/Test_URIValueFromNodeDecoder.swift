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

        enum SimpleEnum: String, Decodable, Equatable {
            case red
            case green
            case blue
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

        // An enum.
        try test(
            ["": ["red"]],
            SimpleEnum.red
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

        // A simple array of strings.
        try test(
            ["": ["a", "b", "c"]],
            ["a", "b", "c"]
        )

        // A simple array of enums.
        try test(
            ["": ["red", "green", "blue"]],
            [.red, .green, .blue] as [SimpleEnum]
        )

        // A struct.
        try test(
            ["foo": ["bar"]],
            SimpleStruct(foo: "bar")
        )

        // A struct with a nested enum.
        try test(
            ["foo": ["bar"], "color": ["blue"]],
            SimpleStruct(foo: "bar", color: .blue)
        )

        // A simple dictionary.
        try test(
            ["one": ["1"], "two": ["2"]],
            ["one": 1, "two": 2]
        )

        // A dictionary of enums.
        try test(
            ["one": ["blue"], "two": ["green"]],
            ["one": .blue, "two": .green] as [String: SimpleEnum]
        )

        enum IsExploded: Equatable {
            case exploded
            case unexploded
        }

        func test<T: Decodable & Equatable>(
            _ node: URIParsedNode,
            _ expectedValue: T,
            _ isExploded: IsExploded = .exploded,
            file: StaticString = #file,
            line: UInt = #line
        ) throws {
            let decoder = URIValueFromNodeDecoder(
                node: node,
                explode: isExploded == .exploded
            )
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
