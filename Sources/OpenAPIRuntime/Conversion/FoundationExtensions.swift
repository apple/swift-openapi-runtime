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
}
