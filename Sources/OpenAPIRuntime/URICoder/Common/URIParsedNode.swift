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

/// The type used for keys by `URIParser`.
typealias URIParsedKeyComponent = String.SubSequence

struct URIParsedKey: Hashable, CustomStringConvertible {

    private(set) var components: [URIParsedKeyComponent]

    init(_ components: [URIParsedKeyComponent]) { self.components = components }

    static var empty: Self { .init([]) }

    func appending(_ component: URIParsedKeyComponent) -> Self {
        var copy = self
        copy.components.append(component)
        return copy
    }

    var description: String {
        if components.isEmpty { return "<empty>" }
        return components.joined(separator: "/")
    }
}

/// The type used for values by `URIParser`.
typealias URIParsedValue = String.SubSequence

/// The type used for an array of values by `URIParser`.
typealias URIParsedValueArray = [URIParsedValue]

/// A key-value pair.
struct URIParsedPair: Equatable {
    var key: URIParsedKey
    var value: URIParsedValue
}

typealias URIParsedPairArray = [URIParsedPair]

typealias URIDecodedPrimitive = URIParsedValue

typealias URIDecodedDictionary = [Substring: URIParsedValueArray]

typealias URIDecodedArray = URIParsedValueArray
