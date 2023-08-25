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

/// A type that decodes a `Decodable` objects from an URI-encoded string
/// using the rules from RFC 6570, RFC 1866, and OpenAPI 3.0.3, depending on
/// the configuration.
struct URIDecoder: Sendable {

    private let configuration: URICoderConfiguration

    init(configuration: URICoderConfiguration) {
        self.configuration = configuration
    }
}

extension URIDecoder {

    /// Attempt to decode an object from an URI string.
    ///
    /// Under the hood, URIDecoder first parses the string into a URIParsedNode
    /// using URIParser, and then uses URIValueFromNodeDecoder to decode
    /// the Decodable value.
    ///
    /// - Parameters:
    ///     - type: The type to decode.
    ///     - key: The key of the decoded value. Only used with certain styles
    ///       and explode options, ignored otherwise.
    ///     - data: The URI-encoded string.
    /// - Returns: The decoded value.
    func decode<T: Decodable>(
        _ type: T.Type = T.self,
        forKey key: String = "",
        from data: String
    ) throws -> T {
        try withCachedParser(from: data) { decoder in
            try decoder.decode(type, forKey: key)
        }
    }

    /// Make multiple decode calls on the parsed URI.
    ///
    /// Use to avoid repeatedly reparsing the raw string.
    /// - Parameters:
    ///   - data: The URI-encoded string.
    ///   - calls: The closure that contains 0 or more calls to
    ///     URICachedDecoder's decode method.
    /// - Returns: The result of the closure invocation.
    func withCachedParser<R>(
        from data: String,
        calls: (URICachedDecoder) throws -> R
    ) throws -> R {
        var parser = URIParser(configuration: configuration, data: data)
        let parsedNode = try parser.parseRoot()
        let decoder = URICachedDecoder(configuration: configuration, node: parsedNode)
        return try calls(decoder)
    }
}

struct URICachedDecoder {

    fileprivate let configuration: URICoderConfiguration
    fileprivate let node: URIParsedNode

    /// Attempt to decode an object from an URI string.
    ///
    /// Under the hood, URICachedDecoder already has a pre-parsed URIParsedNode
    /// and uses URIValueFromNodeDecoder to decode the Decodable value.
    ///
    /// - Parameters:
    ///     - type: The type to decode.
    ///     - key: The key of the decoded value. Only used with certain styles
    ///       and explode options, ignored otherwise.
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
}
