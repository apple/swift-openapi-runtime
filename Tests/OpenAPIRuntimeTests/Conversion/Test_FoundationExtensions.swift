//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import XCTest
import Foundation
@testable import OpenAPIRuntime

final class Test_FoundationExtensions: Test_Runtime {

    func testTrimmingMatchesFoundationBehavior() {
        let testCases = [
            "  Hello World  ",  // Standard spaces
            "\n\tHello World\r\n",  // Newlines and tabs
            "NoTrimmingNeeded",  // No whitespace
            "    ",  // Only spaces
            "",  // Empty string
            " Hello\nWorld ",  // Internal whitespace (should stay)
            "\u{00A0}Unicode\u{00A0}",  // Non-breaking space
            "\u{3000}Ideographic\u{3000}",  // Japanese/Chinese full-width space
        ]

        for input in testCases {
            let foundationResult = input.trimmingCharacters(in: .whitespacesAndNewlines)
            let swiftNativeResult = input.trimmingLeadingAndTrailingSpaces

            XCTAssertEqual(swiftNativeResult, foundationResult, "Failed for input: \(input)")
        }
    }

    func testGenericTrimming() {
        let numericString = "0001234500"
        let result = numericString.trimming(while: { $0 == "0" })
        XCTAssertEqual(result, "12345")

        let punctuationString = "...Hello!.."
        let puncResult = punctuationString.trimming(while: { $0.isPunctuation })
        XCTAssertEqual(puncResult, "Hello")
    }

    func testDoubleToFixed() {
        let testCases: [Double] = [
            0.5,  // Standard: expect 0.500
            1.23456,  // Rounding down: expect 1.235
            1.23444,  // Rounding down: expect 1.234
            0.0,  // Zero: expect 0.000
            -0.5,  // Negative: expect -0.500
            1000.1,  // Large: expect 1000.100
            0.9999,  // Rounding up to integer: expect 1.000
            0.0001,  // Very small: expect 0.000
            Double.pi,  // Transcendental: expect 3.142,
            Double.nan, Double.infinity, -Double.infinity,
        ]

        for value in testCases {
            let custom = value.toFixed(precision: 3)
            let reference = String(format: "%.3f", value)

            XCTAssertEqual(custom, reference, "Failure for value: \(value)")
        }
    }
}
