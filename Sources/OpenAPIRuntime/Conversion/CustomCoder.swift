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

/// A type that allows custom content type encoding and decoding.
public protocol CustomCoder: Sendable {

    /// Encodes the given value and returns its custom encoded representation.
    ///
    /// - Parameter value: The value to encode.
    /// - Returns: A new `Data` value containing the custom encoded data.
    /// - Throws: An error if encoding fails.
    func customEncode<T: Encodable>(_ value: T) throws -> Data

    /// Decodes a value of the given type from the given custom representation.
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode.
    ///   - data: The data to decode from.
    /// - Returns: A value of the requested type.
    /// - Throws: An error if decoding fails.
    func customDecode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T

    /// Updates the coder to use the provided date transcoder.
    /// - Parameter dateTranscoder: The type to use for transcoding dates.
    func updateDateTranscoder(_ dateTranscoder: any DateTranscoder)
}

extension CustomCoder {
    /// Updates the coder to use the provided date transcoder.
    /// - Parameter dateTranscoder: The type to use for transcoding dates.
    public func updateDateTranscoder(_ dateTranscoder: any DateTranscoder) {
        // A defaulted implementation, no-op.
    }
}

/// A coder that uses the `JSONEncoder` and `JSONDecoder` types from the `Foundation` library.
public struct FoundationJSONCoder: Sendable {

    /// The JSON encoder.
    internal let encoder: JSONEncoder

    /// The JSON decoder.
    internal let decoder: JSONDecoder

    /// Creates a new coder.
    /// - Parameters:
    ///   - encoder: The JSON encoder.
    ///   - decoder: The JSON decoder.
    public init(encoder: JSONEncoder, decoder: JSONDecoder) {
        self.encoder = encoder
        self.decoder = decoder
    }
    /// Creates a new coder.
    /// - Parameter outputFormatting: The output formatting provided to the `JSONEncoder`.
    public init(outputFormatting: JSONEncoder.OutputFormatting = [.sortedKeys, .prettyPrinted]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = outputFormatting
        let decoder = JSONDecoder()
        self.init(encoder: encoder, decoder: decoder)
    }
}

extension FoundationJSONCoder: CustomCoder {

    /// Encodes the given value and returns its custom encoded representation.
    ///
    /// - Parameter value: The value to encode.
    /// - Returns: A new `Data` value containing the custom encoded data.
    /// - Throws: An error if encoding fails.
    public func customEncode<T>(_ value: T) throws -> Data where T: Encodable { try encoder.encode(value) }

    /// Decodes a value of the given type from the given custom representation.
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode.
    ///   - data: The data to decode from.
    /// - Returns: A value of the requested type.
    /// - Throws: An error if decoding fails.
    public func customDecode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        try decoder.decode(type, from: data)
    }

    /// Updates the coder to use the provided date transcoder.
    /// - Parameter dateTranscoder: The type to use for transcoding dates.
    public func updateDateTranscoder(_ dateTranscoder: any DateTranscoder) {
        self.encoder.dateEncodingStrategy = .from(dateTranscoder: dateTranscoder)
        self.decoder.dateDecodingStrategy = .from(dateTranscoder: dateTranscoder)
    }
}
