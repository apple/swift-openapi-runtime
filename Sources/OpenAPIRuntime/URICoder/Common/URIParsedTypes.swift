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

/// A component of a `URIParsedKey`.
typealias URIParsedKeyComponent = String.SubSequence

/// A parsed key for a parsed value.
///
/// For example, `foo=bar` in a `form` string would parse the key as `foo` (single component).
/// In an unexploded `form` string `root=foo,bar`, the key would be `root/foo` (two components).
/// In a `simple` string `bar`, the key would be empty (0 components).
struct URIParsedKey: Hashable {

    /// The individual string components.
    let components: [URIParsedKeyComponent]

    /// Creates a new parsed key.
    /// - Parameter components: The key components.
    init(_ components: [URIParsedKeyComponent]) { self.components = components }

    /// A new empty key.
    static var empty: Self { .init([]) }
}

/// A primitive value produced by `URIParser`.
typealias URIParsedValue = String.SubSequence

/// An array of primitive values produced by `URIParser`.
typealias URIParsedValueArray = [URIParsedValue]

/// A key-value produced by `URIParser`.
struct URIParsedPair: Equatable {

    /// The key of the pair.
    ///
    /// In `foo=bar`, `foo` is the key.
    var key: URIParsedKey

    /// The value of the pair.
    ///
    /// In `foo=bar`, `bar` is the value.
    var value: URIParsedValue
}

/// An array of key-value pairs produced by `URIParser`.
typealias URIParsedPairArray = [URIParsedPair]

// MARK: - Extensions

extension URIParsedKey: CustomStringConvertible {
    // swift-format-ignore: AllPublicDeclarationsHaveDocumentation
    var description: String {
        if components.isEmpty { return "<empty>" }
        return components.joined(separator: "/")
    }
}
