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

/// A type that encodes an `Encodable` value to an URI-encoded string
/// using the rules from RFC 6570, RFC 1866, and OpenAPI 3.0.3, depending on
/// the configuration.
///
/// [RFC 6570 - Form-style query expansion.](https://datatracker.ietf.org/doc/html/rfc6570#section-3.2.8)
///
/// | Example Template |   Expansion                       |
/// | ---------------- | ----------------------------------|
/// | `{?who}`         | `?who=fred`                       |
/// | `{?half}`        | `?half=50%25`                     |
/// | `{?x,y}`         | `?x=1024&y=768`                   |
/// | `{?x,y,empty}`   | `?x=1024&y=768&empty=`            |
/// | `{?x,y,undef}`   | `?x=1024&y=768`                   |
/// | `{?list}`        | `?list=red,green,blue`            |
/// | `{?list\*}`      | `?list=red&list=green&list=blue`  |
/// | `{?keys}`        | `?keys=semi,%3B,dot,.,comma,%2C`  |
/// | `{?keys\*}`      | `?semi=%3B&dot=.&comma=%2C`       |
///
/// [RFC 6570 - Simple string expansion.](https://datatracker.ietf.org/doc/html/rfc6570#section-3.2.2)
///
/// | Example Template |   Expansion                       |
/// | ---------------- | ----------------------------------|
/// | `{hello}`        | `Hello%20World%21`                |
/// | `{half}`         | `50%25`                           |
/// | `{x,y}`          | `1024,768`                        |
/// | `{x,empty}`      | `1024,`                           |
/// | `{x,undef}`      | `1024`                            |
/// | `{list}`         | `red,green,blue`                  |
/// | `{list\*}`       | `red,green,blue`                  |
/// | `{keys}`         | `semi,%3B,dot,.,comma,%2C`        |
/// | `{keys\*}`       | `semi=%3B,dot=.,comma=%2C`        |
struct URIEncoder: Sendable {

    /// The serializer used to turn `URIEncodedNode` values to a string.
    private let serializer: URISerializer

    /// Creates a new encoder.
    /// - Parameter serializer: The serializer used to turn `URIEncodedNode`
    ///   values to a string.
    init(serializer: URISerializer) {
        self.serializer = serializer
    }

    /// Creates a new encoder.
    /// - Parameter configuration: The configuration instructing the encoder
    ///   how to serialize the value into an URI-encoded string.
    init(configuration: URICoderConfiguration) {
        self.init(serializer: .init(configuration: configuration))
    }
}

extension URIEncoder {

    /// Attempt to encode an object into an URI string.
    ///
    /// Under the hood, `URIEncoder` first encodes the `Encodable` type
    /// into a `URIEncodableNode` using `URIValueToNodeEncoder`, and then
    /// `URISerializer` encodes the `URIEncodableNode` into a string based
    /// on the configured behavior.
    ///
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - key: The key for which to encode the value. Can be an empty key,
    ///     in which case you still get a key-value pair, like `=foo`.
    /// - Returns: The URI string.
    func encode(
        _ value: some Encodable,
        forKey key: String
    ) throws -> String {
        let encoder = URIValueToNodeEncoder()
        let node = try encoder.encodeValue(value)
        var serializer = serializer
        let encodedString = try serializer.serializeNode(node, forKey: key)
        return encodedString
    }

    /// Attempt to encode an object into an URI string, if not nil.
    ///
    /// Under the hood, `URIEncoder` first encodes the `Encodable` type
    /// into a `URIEncodableNode` using `URIValueToNodeEncoder`, and then
    /// `URISerializer` encodes the `URIEncodableNode` into a string based
    /// on the configured behavior.
    ///
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - key: The key for which to encode the value. Can be an empty key,
    ///     in which case you still get a key-value pair, like `=foo`.
    /// - Returns: The URI string.
    func encodeIfPresent(
        _ value: (some Encodable)?,
        forKey key: String
    ) throws -> String {
        guard let value else {
            return ""
        }
        let encoder = URIValueToNodeEncoder()
        let node = try encoder.encodeValue(value)
        var serializer = serializer
        let encodedString = try serializer.serializeNode(node, forKey: key)
        return encodedString
    }
}
