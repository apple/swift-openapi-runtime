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

final class Test_StringCodingRoundtrip: Test_Runtime {

    func testRoundtrip() throws {

        enum SimpleEnum: String, Codable, Equatable {
            case red
            case green
            case blue
        }

        struct CustomValue: LosslessStringConvertible, Codable, Equatable {
            var innerString: String

            init(innerString: String) {
                self.innerString = innerString
            }

            init?(_ description: String) {
                self.init(innerString: description)
            }

            var description: String {
                innerString
            }

            func encode(to encoder: any Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(innerString)
            }

            enum CodingKeys: CodingKey {
                case innerString
            }

            init(from decoder: any Decoder) throws {
                let container = try decoder.singleValueContainer()
                self.innerString = try container.decode(String.self)
            }
        }

        // An empty string.
        try _test(
            "",
            ""
        )

        // An string with a space.
        try _test(
            "Hello World!",
            "Hello World!"
        )

        // An enum.
        try _test(
            SimpleEnum.red,
            "red"
        )

        // A custom value.
        try _test(
            CustomValue(innerString: "hello"),
            "hello"
        )

        // An integer.
        try _test(
            1234,
            "1234"
        )

        // A float.
        try _test(
            12.34,
            "12.34"
        )

        // A bool.
        try _test(
            true,
            "true"
        )

        // A Date.
        try _test(
            Date(timeIntervalSince1970: 1_692_948_899),
            "2023-08-25T07:34:59Z"
        )
    }

    func _test<T: Codable & Equatable>(
        _ value: T,
        _ expectedString: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let encoder = StringEncoder(dateTranscoder: .iso8601)
        let encodedString = try encoder.encode(value)
        XCTAssertEqual(
            encodedString,
            expectedString,
            file: file,
            line: line
        )
        let decoder = StringDecoder(dateTranscoder: .iso8601)
        let decodedValue = try decoder.decode(
            T.self,
            from: encodedString
        )
        XCTAssertEqual(
            decodedValue,
            value,
            file: file,
            line: line
        )
    }
}
