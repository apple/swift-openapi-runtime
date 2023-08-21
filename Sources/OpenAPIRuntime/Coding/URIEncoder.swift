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

/// A type that encodes an `Encodable` objects to an URL-encoded string
/// using the rules from RFC 6570, RFC 1866, and OpenAPI 3.0.3, depending on
/// the configuration.
///
/// - [OpenAPI 3.0.3 styles](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.3.md#style-examples)
public struct URIEncoder: Sendable {
    public init() {}
}

extension URIEncoder {

    public enum KeyComponent {
        case index(Int)
        case key(String)
    }

    /// Attempt to encode an object into an URI string.
    ///
    /// - Parameters:
    ///     - value: The value to encode.
    ///     - key: The key for which to encode the value. Can be an empty key,
    ///       in which case you still get a key-value pair, like `=foo`.
    /// - Returns: The URI string.
    public func encode(
        _ value: some Encodable,
        forKey key: KeyComponent
    ) throws -> String {

        // Under the hood, URIEncoder first encodes the Encodable type
        // into a URINode using URITranslator, and then
        // URISerializer encodes the URINode into a string based
        // on the configured behavior.

        let translator = URITranslator()
        var serializer = URISerializer()
        let node = try translator.translateValue(value)

        let convertedKey: URISerializer.KeyComponent
        switch key {
        case .index(let int):
            convertedKey = .index(int)
        case .key(let string):
            convertedKey = .key(string)
        }
        let encodedString = try serializer.writeNode(node, forKey: convertedKey)
        return encodedString
    }
}
