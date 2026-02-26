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

    func testReplacingOccurencesMatchesFoundationBehaviour() {
        // Tuple format: (Input String, Target to replace, Replacement string)
        let testCases: [(input: String, target: String, replacement: String)] = [
            ("Hello World", "World", "Swift"),  // Standard replacement
            ("banana", "a", "o"),  // Multiple occurrences
            ("aaaa", "aa", "b"),  // Overlapping occurrences (should result in "bb")
            ("Nothing here", "xyz", "abc"),  // Target not found
            ("Case sensitive", "case", "X"),  // Case sensitivity check (should not replace)
            ("👨‍👩‍👧‍👦 Family", "👨‍👩‍👧‍👦", "👪"),  // Complex Emoji / Grapheme clusters
            ("Café", "é", "e"),  // Accented characters
            ("", "target", "replacement"),  // Empty input string
            ("exact match", "exact match", "success"),  // Exact full string match
        ]

        for testCase in testCases {
            let foundationResult = testCase.input.replacingOccurrences(of: testCase.target, with: testCase.replacement)
            let customResult = testCase.input.replacingOccurrences(
                of: testCase.target,
                with: testCase.replacement,
                maxReplacements: .max
            )
            XCTAssertEqual(
                customResult,
                foundationResult,
                "Mismatch for input: '\(testCase.input)'. Expected '\(foundationResult)', got '\(customResult)'"
            )
        }
    }

    func testReplacingOccurencesMaxReplacementsLogic() {
        let input = "a b a b a"

        let replaceOne = input.replacingOccurrences(of: "a", with: "c", maxReplacements: 1)
        XCTAssertEqual(replaceOne, "c b a b a", "Failed to limit replacement to 1")

        let replaceTwo = input.replacingOccurrences(of: "a", with: "c", maxReplacements: 2)
        XCTAssertEqual(replaceTwo, "c b c b a", "Failed to limit replacement to 2")

        let replaceTen = input.replacingOccurrences(of: "a", with: "c", maxReplacements: 10)
        XCTAssertEqual(replaceTen, "c b c b c", "Failed when maxReplacements is greater than occurrences")

        let replaceZero = input.replacingOccurrences(of: "a", with: "c", maxReplacements: 0)
        XCTAssertEqual(replaceZero, input, "String should remain unchanged when maxReplacements is 0")
    }

    private var unreservedAndSpace: CharacterSet {
        var charset = CharacterSet.alphanumerics
        charset.insert(charactersIn: "-._~ ")
        return charset
    }

    func testAddingPercentEncodingAllowingUnreservedAndSpace() {
        let testCases = [
            "HelloWorld",  // Alphanumerics (No encoding needed)
            "Hello World",  // Space (Should NOT be encoded based on requirements)
            "user@email.com",  // '@' is reserved (Should be encoded)
            "price=$100&tax=yes",  // '=', '$', '&' are reserved (Should be encoded)
            "café",  // Non-ASCII character (Should be encoded)
            "👨‍💻 swift",  // Emoji and space
            "~_.-",  // Unreserved punctuation (Should NOT be encoded)
            "",  // Empty string
            "100% coverage",  // '%' symbol itself (Must be encoded to %25)
        ]

        for input in testCases {
            let foundationResult = input.addingPercentEncoding(withAllowedCharacters: unreservedAndSpace)
            let customResult = input.addingPercentEncodingAllowingUnreservedAndSpace()
            XCTAssertEqual(
                customResult,
                foundationResult,
                "Encoding mismatch for input: '\(input)'. Expected '\(String(describing: foundationResult))', got '\(String(describing: customResult))'"
            )
        }
    }

    // MARK: - Removing Encoding Tests

    func testRemovingPercentEncoding() {
        let testCases = [
            "HelloWorld",  // Nothing to decode
            "Hello%20World",  // Standard space decoding
            "user%40email.com",  // Reserved character decoding ('@')
            "caf%C3%A9",  // UTF-8 multibyte decoding ('é')
            "%F0%9F%91%A8%E2%80%8D%F0%9F%92%BB",  // Complex Emoji decoding
            "~_.-",  // Unencoded unreserved characters
            "",  // Empty string
            "100%25%20coverage",  // Decodes to "100% coverage"

            // Edge Cases & Invalid Inputs
            "Hello%2World",  // Malformed percent encoding (missing second hex digit)
            "%ZZ",  // Invalid hex characters
            "%FF",  // Valid hex, but invalid UTF-8 byte sequence
        ]

        for input in testCases {
            let foundationResult = input.removingPercentEncoding
            let customResult = input.removingPercentEncoding()

            // 3. Compare
            XCTAssertEqual(
                customResult,
                foundationResult,
                "Decoding mismatch for input: '\(input)'. Expected '\(String(describing: foundationResult))', got '\(String(describing: customResult))'"
            )
        }
    }
}
