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
struct URIEncoder: Sendable {
    
    private let serializer: URISerializer
    
    init(serializer: URISerializer) {
        self.serializer = serializer
    }
    
    init(serializerConfiguration: URISerializationConfiguration) {
        self.init(serializer: .init(configuration: serializerConfiguration))
    }
}

extension URIEncoder {

    /// Attempt to encode an object into an URI string.
    ///
    /// Under the hood, URIEncoder first encodes the Encodable type
    /// into a URIEncodableNode using URIValueToNodeEncoder, and then
    /// URISerializer encodes the URIEncodableNode into a string based
    /// on the configured behavior.
    ///
    /// - Parameters:
    ///     - value: The value to encode.
    ///     - key: The key for which to encode the value. Can be an empty key,
    ///       in which case you still get a key-value pair, like `=foo`.
    /// - Returns: The URI string.
    public func encode(
        _ value: some Encodable,
        forKey key: String
    ) throws -> String {
        let translator = URIValueToNodeEncoder()
        let node = try translator.translateValue(value)
        var serializer = serializer
        let encodedString = try serializer.serializeNode(node, forKey: key)
        return encodedString
    }
}
