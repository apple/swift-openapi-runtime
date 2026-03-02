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

#if canImport(Darwin)
import Darwin
#elseif os(Windows)
import ucrt
import WinSDK
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Android)
import Android
#elseif canImport(Musl)
import Musl
#elseif canImport(Bionic)
import Bionic
#elseif canImport(WASILibc)
import WASILibc
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
}

extension Double {
    func toFixed(precision: Int) -> String {
        guard self.isFinite else { return String(describing: self) }

        let isNegative = self < 0
        let absValue = abs(self)

        let multiplier: Double = pow(10, 3)
        let roundedValue = (absValue * multiplier).rounded() / multiplier

        let integerPart = UInt64(roundedValue)
        let fractionalPartDouble = (roundedValue - Double(integerPart)) * multiplier
        let fractionalPart = UInt64(fractionalPartDouble.rounded())

        var fractionalString = String(fractionalPart)
        while fractionalString.count < precision { fractionalString = "0" + fractionalString }

        return "\(isNegative ? "-" : "")\(integerPart).\(fractionalString)"
    }
}
