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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension StringProtocol {
    /// Returns the string with leading and trailing whitespace (such as spaces
    /// and newlines) removed.
    var trimmingLeadingAndTrailingSpaces: String { self.trimming { $0.isWhitespace } }

    /// Returns a new string by removing leading and trailing characters
    /// that satisfy the given predicate.
    func trimming(while predicate: (Character) -> Bool) -> String {
        guard let start = self.firstIndex(where: { !predicate($0) }) else { return "" }
        let end = self.lastIndex(where: { !predicate($0) })!

        return String(self[start...end])
    }

    /// Returns a new string in which all occurrences of a target
    /// string are replaced by another given string.
    @inlinable func replacingOccurrences<Replacement: StringProtocol>(
        of target: String,
        with replacement: Replacement,
        maxReplacements: Int = .max
    ) -> String {
        guard !target.isEmpty, maxReplacements > 0 else { return String(self) }
        var result = ""
        result.reserveCapacity(self.count)
        var searchStart = self.startIndex
        var replacements = 0
        while replacements < maxReplacements,
            let foundRange = self.range(of: target, range: searchStart..<self.endIndex)
        {
            result.append(contentsOf: self[searchStart..<foundRange.lowerBound])
            result.append(contentsOf: replacement)
            searchStart = foundRange.upperBound
            replacements += 1
        }
        result.append(contentsOf: self[searchStart..<self.endIndex])
        return result
    }

    @inlinable func range(of aString: String, range searchRange: Range<Self.Index>? = nil) -> Range<Self.Index>? {
        guard !aString.isEmpty else { return nil }

        var current = searchRange?.lowerBound ?? self.startIndex
        let end = searchRange?.upperBound ?? self.endIndex

        while current < end {
            let searchSlice = self[current..<end]

            if searchSlice.hasPrefix(aString) {
                // We found the match, so lets iterate the index until we have a full match.
                var foundEnd = current
                while self[current..<foundEnd] != aString { foundEnd = self.index(after: foundEnd) }
                return current..<foundEnd
            }
            current = self.index(after: current)
        }
        return nil
    }

    /// Returns a new string created by replacing all characters in the string
    /// not unreserved or spaces with percent encoded characters.
    func addingPercentEncodingAllowingUnreservedAndSpace() -> String {
        guard !self.isEmpty else { return String(self) }

        let percent = UInt8(ascii: "%")
        let space = UInt8(ascii: " ")
        let utf8Buffer = self.utf8
        let maxLength = utf8Buffer.count * 3
        return withUnsafeTemporaryAllocation(of: UInt8.self, capacity: maxLength) { outputBuffer in
            var i = 0
            for byte in utf8Buffer {
                if byte.isUnreserved || byte == space {
                    outputBuffer[i] = byte
                    i += 1
                } else {
                    outputBuffer[i] = percent
                    outputBuffer[i + 1] = hexToAscii(byte >> 4)
                    outputBuffer[i + 2] = hexToAscii(byte & 0xF)
                    i += 3
                }
            }
            return String(decoding: outputBuffer[..<i], as: UTF8.self)
        }
    }

    /// A new string made from the string by replacing all percent encoded
    /// sequences with the matching UTF-8 characters.
    func removingPercentEncoding() -> String? {
        let percent = UInt8(ascii: "%")
        let utf8Buffer = self.utf8
        let maxLength = utf8Buffer.count

        return withUnsafeTemporaryAllocation(of: UInt8.self, capacity: maxLength) { outputBuffer -> String? in
            var i = 0
            var byte: UInt8 = 0
            var hexDigitsRequired = 0

            for v in utf8Buffer {
                if v == percent {
                    guard hexDigitsRequired == 0 else { return nil }
                    hexDigitsRequired = 2
                } else if hexDigitsRequired > 0 {
                    guard let hex = asciiToHex(v) else { return nil }

                    if hexDigitsRequired == 2 {
                        byte = hex << 4
                    } else if hexDigitsRequired == 1 {
                        byte += hex
                        outputBuffer[i] = byte
                        i += 1
                        byte = 0
                    }
                    hexDigitsRequired -= 1
                } else {
                    outputBuffer[i] = v
                    i += 1
                }
            }

            guard hexDigitsRequired == 0 else { return nil }

            return String(bytes: outputBuffer[..<i], encoding: .utf8)
        }
    }
}

private func asciiToHex(_ ascii: UInt8) -> UInt8? {
    switch ascii {
    case UInt8(ascii: "0")...UInt8(ascii: "9"): return ascii - UInt8(ascii: "0")
    case UInt8(ascii: "A")...UInt8(ascii: "F"): return ascii - UInt8(ascii: "A") + 10
    case UInt8(ascii: "a")...UInt8(ascii: "f"): return ascii - UInt8(ascii: "a") + 10
    default: return nil
    }
}

private func hexToAscii(_ hex: UInt8) -> UInt8 {
    switch hex {
    case 0x0: return UInt8(ascii: "0")
    case 0x1: return UInt8(ascii: "1")
    case 0x2: return UInt8(ascii: "2")
    case 0x3: return UInt8(ascii: "3")
    case 0x4: return UInt8(ascii: "4")
    case 0x5: return UInt8(ascii: "5")
    case 0x6: return UInt8(ascii: "6")
    case 0x7: return UInt8(ascii: "7")
    case 0x8: return UInt8(ascii: "8")
    case 0x9: return UInt8(ascii: "9")
    case 0xA: return UInt8(ascii: "A")
    case 0xB: return UInt8(ascii: "B")
    case 0xC: return UInt8(ascii: "C")
    case 0xD: return UInt8(ascii: "D")
    case 0xE: return UInt8(ascii: "E")
    case 0xF: return UInt8(ascii: "F")
    default: fatalError("Invalid hex digit: \(hex)")
    }
}

extension UInt8 {
    /// Checks if a byte is an unreserved character per RFC 3986.
    fileprivate var isUnreserved: Bool {
        switch self {
        case UInt8(ascii: "0")...UInt8(ascii: "9"), UInt8(ascii: "A")...UInt8(ascii: "Z"),
            UInt8(ascii: "a")...UInt8(ascii: "z"), UInt8(ascii: "-"), UInt8(ascii: "."), UInt8(ascii: "_"),
            UInt8(ascii: "~"):
            return true
        default: return false
        }
    }
}
