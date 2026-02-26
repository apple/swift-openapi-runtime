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
}
