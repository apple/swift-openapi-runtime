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
    ///     - data: The URI-encoded string.
    /// - Returns: The decoded value.
    func decode<T: Decodable>(
        _ type: T.Type = T.self,
        from data: String
    ) throws -> T {
        var parser = URIParser(configuration: configuration, data: data)
        let parsedNode = try parser.parseRoot()
        let decoder = URIValueFromNodeDecoder(
            node: parsedNode,
            explode: configuration.explode
        )
        return try decoder.decodeRoot()
    }
}
