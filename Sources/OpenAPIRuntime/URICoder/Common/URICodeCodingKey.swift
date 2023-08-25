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

import Foundation

/// The coding key used by the URI encoder and decoder.
struct URICoderCodingKey {

    /// The string to use in a named collection (e.g. a string-keyed dictionary).
    var stringValue: String

    /// The value to use in an integer-indexed collection (e.g. an int-keyed
    /// dictionary).
    var intValue: Int?

    /// Creates a new key with the same string and int value as the provided key.
    /// - Parameter key: The key whose values to copy.
    init(_ key: some CodingKey) {
        self.stringValue = key.stringValue
        self.intValue = key.intValue
    }
}

extension URICoderCodingKey: CodingKey {

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
