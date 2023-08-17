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

extension DecodingError {

    /// Returns a decoding error used by the anyOf decoder when not a single
    /// child schema decodes the received payload.
    /// - Parameters:
    ///   - type: The type representing the anyOf schema in which the decoding
    ///   occurred.
    ///   - codingPath: The coding path to the decoder that attempted to decode
    ///   the type.
    /// - Returns: A decoding error.
    static func failedToDecodeAnySchema(
        type: Any.Type,
        codingPath: [any CodingKey]
    ) -> Self {
        DecodingError.valueNotFound(
            type,
            DecodingError.Context.init(
                codingPath: codingPath,
                debugDescription: "The anyOf structure did not decode into any child schema."
            )
        )
    }

    /// Returns a decoding error used by the oneOf decoder when not a single
    /// child schema decodes the received payload.
    /// - Parameters:
    ///   - type: The type representing the oneOf schema in which the decoding
    ///   occurred.
    ///   - codingPath: The coding path to the decoder that attempted to decode
    ///   the type.
    /// - Returns: A decoding error.
    static func failedToDecodeOneOfSchema(
        type: Any.Type,
        codingPath: [any CodingKey]
    ) -> Self {
        DecodingError.valueNotFound(
            type,
            DecodingError.Context.init(
                codingPath: codingPath,
                debugDescription: "The oneOf structure did not decode into any child schema."
            )
        )
    }
}

@_spi(Generated)
extension DecodingError {

    /// Verifies that the anyOf decoder successfully decoded at least one
    /// child schema, and throws an error otherwise.
    /// - Parameters:
    ///   - values: An array of optional values to check.
    ///   - type: The type representing the anyOf schema in which the decoding
    ///   occurred.
    ///   - codingPath: The coding path to the decoder that attempted to decode
    ///   the type.
    public static func verifyAtLeastOneSchemaIsNotNil(
        _ values: [Any?],
        type: Any.Type,
        codingPath: [any CodingKey]
    ) throws {
        guard values.contains(where: { $0 != nil }) else {
            throw DecodingError.failedToDecodeAnySchema(
                type: type,
                codingPath: codingPath
            )
        }
    }
}
