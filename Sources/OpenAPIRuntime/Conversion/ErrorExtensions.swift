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
    ///   - errors: The errors encountered when decoding individual cases.
    /// - Returns: A decoding error.
    static func failedToDecodeAnySchema(type: Any.Type, codingPath: [any CodingKey], errors: [any Error]) -> Self {
        DecodingError.valueNotFound(
            type,
            DecodingError.Context.init(
                codingPath: codingPath,
                debugDescription: "The anyOf structure did not decode into any child schema.",
                underlyingError: MultiError(errors: errors)
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
    ///   - errors: The errors encountered when decoding individual cases.
    /// - Returns: A decoding error.
    @_spi(Generated) public static func failedToDecodeOneOfSchema(
        type: Any.Type,
        codingPath: [any CodingKey],
        errors: [any Error]
    ) -> Self {
        DecodingError.valueNotFound(
            type,
            DecodingError.Context.init(
                codingPath: codingPath,
                debugDescription: "The oneOf structure did not decode into any child schema.",
                underlyingError: MultiError(errors: errors)
            )
        )
    }

    /// Returns a decoding error used by the oneOf decoder when
    /// the discriminator property contains an unknown schema name.
    /// - Parameters:
    ///   - discriminatorKey: The discriminator coding key.
    ///   - discriminatorValue: The unknown value of the discriminator.
    ///   - codingPath: The coding path to the decoder that attempted to decode
    ///   the type, with the discriminator value as the last component.
    /// - Returns: A decoding error.
    @_spi(Generated) public static func unknownOneOfDiscriminator(
        discriminatorKey: any CodingKey,
        discriminatorValue: String,
        codingPath: [any CodingKey]
    ) -> Self {
        DecodingError.keyNotFound(
            discriminatorKey,
            DecodingError.Context.init(
                codingPath: codingPath,
                debugDescription:
                    "The oneOf structure does not contain the provided discriminator value '\(discriminatorValue)'."
            )
        )
    }

    /// Verifies that the anyOf decoder successfully decoded at least one
    /// child schema, and throws an error otherwise.
    /// - Parameters:
    ///   - values: An array of optional values to check.
    ///   - type: The type representing the anyOf schema in which the decoding
    ///   occurred.
    ///   - codingPath: The coding path to the decoder that attempted to decode
    ///   the type.
    ///   - errors: The errors encountered when decoding individual cases.
    /// - Throws: An error of type `DecodingError.failedToDecodeAnySchema` if none of the child schemas were successfully decoded.
    @_spi(Generated) public static func verifyAtLeastOneSchemaIsNotNil(
        _ values: [Any?],
        type: Any.Type,
        codingPath: [any CodingKey],
        errors: [any Error]
    ) throws {
        guard values.contains(where: { $0 != nil }) else {
            throw DecodingError.failedToDecodeAnySchema(type: type, codingPath: codingPath, errors: errors)
        }
    }
}

/// A wrapper of multiple errors, for example collected during a parallelized
/// operation from the individual subtasks.
struct MultiError: Swift.Error, LocalizedError, CustomStringConvertible {

    /// The multiple underlying errors.
    var errors: [any Error]

    var description: String {
        let combinedDescription =
            errors.map { error in
                guard let error = error as? (any PrettyStringConvertible) else { return "\(error)" }
                return error.prettyDescription
            }
            .enumerated().map { ($0.offset + 1, $0.element) }.map { "Error \($0.0): [\($0.1)]" }.joined(separator: ", ")
        return "MultiError (contains \(errors.count) error\(errors.count == 1 ? "" : "s")): \(combinedDescription)"
    }

    var errorDescription: String? {
        if let first = errors.first {
            return "Multiple errors encountered, first one: \(first)."
        } else {
            return "No errors"
        }
    }
}
