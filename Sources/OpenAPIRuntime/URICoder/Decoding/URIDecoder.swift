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

/// A type that decodes a `Decodable` value from an URI-encoded string
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
struct URIDecoder: Sendable {

    /// The configuration instructing the decoder how to interpret the raw
    /// string.
    private let configuration: URICoderConfiguration

    /// Creates a new decoder with the provided configuration.
    /// - Parameter configuration: The configuration used by the decoder.
    init(configuration: URICoderConfiguration) {
        self.configuration = configuration
    }
}

extension URIDecoder {

    /// Attempt to decode an object from an URI string.
    ///
    /// Under the hood, `URIDecoder` first parses the string into a
    /// `URIParsedNode` using `URIParser`, and then uses
    /// `URIValueFromNodeDecoder` to decode the `Decodable` value.
    ///
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - key: The key of the decoded value. Only used with certain styles
    ///     and explode options, ignored otherwise.
    ///   - data: The URI-encoded string.
    /// - Returns: The decoded value.
    func decode<T: Decodable>(
        _ type: T.Type = T.self,
        forKey key: String = "",
        from data: Substring
    ) throws -> T {
        try withCachedParser(from: data) { decoder in
            try decoder.decode(type, forKey: key)
        }
    }

    /// Attempt to decode an object from an URI string, if present.
    ///
    /// Under the hood, `URIDecoder` first parses the string into a
    /// `URIParsedNode` using `URIParser`, and then uses
    /// `URIValueFromNodeDecoder` to decode the `Decodable` value.
    ///
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - key: The key of the decoded value. Only used with certain styles
    ///     and explode options, ignored otherwise.
    ///   - data: The URI-encoded string.
    /// - Returns: The decoded value.
    func decodeIfPresent<T: Decodable>(
        _ type: T.Type = T.self,
        forKey key: String = "",
        from data: Substring
    ) throws -> T? {
        try withCachedParser(from: data) { decoder in
            try decoder.decodeIfPresent(type, forKey: key)
        }
    }

    /// Make multiple decode calls on the parsed URI.
    ///
    /// Use to avoid repeatedly reparsing the raw string.
    /// - Parameters:
    ///   - data: The URI-encoded string.
    ///   - calls: The closure that contains 0 or more calls to
    ///     the `decode` method on `URICachedDecoder`.
    /// - Returns: The result of the closure invocation.
    func withCachedParser<R>(
        from data: Substring,
        calls: (URICachedDecoder) throws -> R
    ) throws -> R {
        var parser = URIParser(configuration: configuration, data: data)
        let parsedNode = try parser.parseRoot()
        let decoder = URICachedDecoder(configuration: configuration, node: parsedNode)
        return try calls(decoder)
    }
}

struct URICachedDecoder {

    /// The configuration used by the decoder.
    fileprivate let configuration: URICoderConfiguration

    /// The node from which to decode a value on demand.
    fileprivate let node: URIParsedNode

    /// Attempt to decode an object from an URI-encoded string.
    ///
    /// Under the hood, `URICachedDecoder` already has a pre-parsed
    /// `URIParsedNode` and uses `URIValueFromNodeDecoder` to decode
    /// the `Decodable` value.
    ///
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - key: The key of the decoded value. Only used with certain styles
    ///     and explode options, ignored otherwise.
    /// - Returns: The decoded value.
    func decode<T: Decodable>(
        _ type: T.Type = T.self,
        forKey key: String = ""
    ) throws -> T {
        let decoder = URIValueFromNodeDecoder(
            node: node,
            rootKey: key[...],
            style: configuration.style,
            explode: configuration.explode,
            dateTranscoder: configuration.dateTranscoder
        )
        return try decoder.decodeRoot()
    }

    /// Attempt to decode an object from an URI-encoded string, if present.
    ///
    /// Under the hood, `URICachedDecoder` already has a pre-parsed
    /// `URIParsedNode` and uses `URIValueFromNodeDecoder` to decode
    /// the `Decodable` value.
    ///
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - key: The key of the decoded value. Only used with certain styles
    ///     and explode options, ignored otherwise.
    /// - Returns: The decoded value.
    func decodeIfPresent<T: Decodable>(
        _ type: T.Type = T.self,
        forKey key: String = ""
    ) throws -> T? {
        let decoder = URIValueFromNodeDecoder(
            node: node,
            rootKey: key[...],
            style: configuration.style,
            explode: configuration.explode,
            dateTranscoder: configuration.dateTranscoder
        )
        return try decoder.decodeRootIfPresent()
    }
}
