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

/// A namespace of utilities for byte parsers and serializers.
enum ASCII {

    /// The dash `-` character.
    static let dash: UInt8 = 0x2d

    /// The carriage return `<CR>` character.
    static let cr: UInt8 = 0x0d

    /// The line feed `<LF>` character.
    static let lf: UInt8 = 0x0a

    /// The record separator `<RS>` character.
    static let rs: UInt8 = 0x1e
    /// The colon `:` character.
    static let colon: UInt8 = 0x3a

    /// The space ` ` character.
    static let space: UInt8 = 0x20

    /// The horizontal tab `<TAB>` character.
    static let tab: UInt8 = 0x09

    /// Two dash characters.
    static let dashes: [UInt8] = [dash, dash]

    /// The `<CR>` character followed by the `<LF>` character.
    static let crlf: [UInt8] = [cr, lf]

    /// The colon character followed by the space character.
    static let colonSpace: [UInt8] = [colon, space]

    /// The characters that represent optional whitespace (OWS).
    static let optionalWhitespace: Set<UInt8> = [space, tab]

    /// Checks whether the provided byte can appear in a header field name.
    /// - Parameter byte: The byte to check.
    /// - Returns: A Boolean value; `true` if the byte is valid in a header field
    ///   name, `false` otherwise.
    static func isValidHeaderFieldNameByte(_ byte: UInt8) -> Bool {
        // Copied from swift-http-types, because we create HTTPField.Name from these anyway later.
        switch byte {
        case 0x21, 0x23, 0x24, 0x25, 0x26, 0x27, 0x2A, 0x2B, 0x2D, 0x2E, 0x5E, 0x5F, 0x60, 0x7C, 0x7E: return true
        case 0x30...0x39, 0x41...0x5A, 0x61...0x7A:  // DIGHT, ALPHA
            return true
        default: return false
        }
    }
}

/// A value returned by the `firstIndexAfterPrefix` method.
enum FirstIndexAfterPrefixResult<C: RandomAccessCollection> {

    /// The index after the end of the prefix match.
    case index(C.Index)

    /// Matched all characters so far, but reached the end of self before matching all.
    /// When more data is fetched, it's possible this will fully match.
    case reachedEndOfSelf

    /// The character at the provided index does not match the expected character.
    case unexpectedPrefix(C.Index)
}

extension RandomAccessCollection where Element: Equatable {

    /// Verifies that the elements match the provided sequence and returns the first index past the match.
    /// - Parameter expectedElements: The elements to match against.
    /// - Returns: The result.
    func firstIndexAfterPrefix(_ expectedElements: some Sequence<Element>) -> FirstIndexAfterPrefixResult<Self> {
        var index = startIndex
        for expectedElement in expectedElements {
            guard index < endIndex else { return .reachedEndOfSelf }
            guard self[index] == expectedElement else { return .unexpectedPrefix(index) }
            formIndex(after: &index)
        }
        return .index(index)
    }
}

/// A value returned by the `longestMatch` method.
enum LongestMatchResult<C: RandomAccessCollection> {

    /// No match found at any position in self.
    case noMatch

    /// Found a prefix match but reached the end of self.
    /// Provides the index of the first matching character.
    /// When more data is fetched, this might become a full match.
    case prefixMatch(fromIndex: C.Index)

    /// Found a full match within self at the provided range.
    case fullMatch(Range<C.Index>)
}

extension RandomAccessCollection where Element: Equatable {

    /// Returns the longest match found within the sequence.
    /// - Parameter expectedElements: The elements to match in the sequence.
    /// - Returns: The result.
    func longestMatch(_ expectedElements: some Sequence<Element>) -> LongestMatchResult<Self> {
        var index = startIndex
        while index < endIndex {
            switch self[index...].firstIndexAfterPrefix(expectedElements) {
            case .index(let end): return .fullMatch(index..<end)
            case .reachedEndOfSelf: return .prefixMatch(fromIndex: index)
            case .unexpectedPrefix: formIndex(after: &index)
            }
        }
        return .noMatch
    }
}

/// A value returned by the `longestMatchOfOneOf` method.
enum MatchOfOneOfResult<C: RandomAccessCollection> {

    /// No match found at any position in self.
    case noMatch

    case first(C.Index)
    case second(C.Index)
}

extension RandomAccessCollection where Element: Equatable {

    func matchOfOneOf(first: Element, second: Element) -> MatchOfOneOfResult<Self> {
        var index = startIndex
        while index < endIndex {
            let element = self[index]
            if element == first { return .first(index) }
            if element == second { return .second(index) }
            formIndex(after: &index)
        }
        return .noMatch
    }
}
