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

/// A type that decodes a `Decodable` value from an URI-encoded string
/// using the rules from RFC 6570, RFC 1866, and OpenAPI 3.0.4, depending on
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
///
/// [OpenAPI 3.0.4 - Deep object expansion.](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.4.md#style-examples)
///
/// | Example Template |   Expansion                                               |
/// | ---------------- | ----------------------------------------------------------|
/// | `{?keys\*}`      | `?keys%5Bsemi%5D=%3B&keys%5Bdot%5D=.&keys%5Bcomma%5D=%2C` |
///
struct URIDecoder: Sendable {

    /// The configuration instructing the decoder how to interpret the raw
    /// string.
    private let configuration: URICoderConfiguration

    /// Creates a new decoder with the provided configuration.
    /// - Parameter configuration: The configuration used by the decoder.
    init(configuration: URICoderConfiguration) { self.configuration = configuration }
}

extension URIDecoder {

    /// Attempt to decode an object from an URI string.
    ///
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - key: The key of the decoded value. Only used with certain styles
    ///     and explode options, ignored otherwise.
    ///   - data: The URI-encoded string.
    /// - Returns: The decoded value.
    /// - Throws: An error if decoding fails, for example, due to incompatible data or key.
    func decode<T: Decodable>(_ type: T.Type = T.self, forKey key: String = "", from data: Substring) throws -> T {
        let decoder = URIValueFromNodeDecoder(data: data, rootKey: key[...], configuration: configuration)
        return try decoder.decodeRoot(type)
    }

    /// Attempt to decode an object from an URI string, if present.
    ///
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - key: The key of the decoded value. Only used with certain styles
    ///     and explode options, ignored otherwise.
    ///   - data: The URI-encoded string.
    /// - Returns: The decoded value.
    /// - Throws: An error if decoding fails, for example, due to incompatible data or key.
    func decodeIfPresent<T: Decodable>(_ type: T.Type = T.self, forKey key: String = "", from data: Substring) throws
        -> T?
    {
        let decoder = URIValueFromNodeDecoder(data: data, rootKey: key[...], configuration: configuration)
        return try decoder.decodeRootIfPresent(type)
    }
}
