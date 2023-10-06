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

/// Provides a route to encode or decode base64-encoded data
///
/// This type holds raw, unencoded, data as a slice of bytes. It can be used to encode that
/// data to a provided `Encoder` as base64-encoded data or to decode from base64 encoding when
/// initialized from a decoder.
///
/// There is a convenience initializer to create an instance backed by provided data in the form
/// of a slice of bytes:
/// ```swift
/// let bytes: ArraySlice<UInt8> = ...
/// let base64EncodedData = Base64EncodedData(data: bytes)
/// ```
///
/// To decode base64-encoded data it is possible to call the initializer directly, providing a decoder:
/// ```swift
/// let base64EncodedData = Base64EncodedData(from: decoder)
///```
///
/// However more commonly the decoding initializer would be called by a decoder, for example:
/// ```swift
/// let encodedData: Data = ...
/// let decoded = try JSONDecoder().decode(Base64EncodedData.self, from: encodedData)
///```
///
/// Once an instance is holding data, it may be base64 encoded to a provided encoder:
/// ```swift
/// let bytes: ArraySlice<UInt8> = ...
/// let base64EncodedData = Base64EncodedData(data: bytes)
/// base64EncodedData.encode(to: encoder)
/// ```
///
/// However more commonly it would be called by an encoder, for example:
/// ```swift
/// let bytes: ArraySlice<UInt8> = ...
/// let encodedData = JSONEncoder().encode(encodedBytes)
/// ```
public struct Base64EncodedData: Sendable, Hashable {
    /// A container of the raw bytes.
    public var data: ArraySlice<UInt8>

    /// Initializes an instance of ``Base64EncodedData`` wrapping the provided slice of bytes.
    /// - Parameter data: The underlying bytes to wrap.
    public init(data: ArraySlice<UInt8>) {
        self.data = data
    }
}

extension Base64EncodedData: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let base64EncodedString = try container.decode(String.self)

        // permissive decoding
        let options = Data.Base64DecodingOptions.ignoreUnknownCharacters

        guard let data = Data(base64Encoded: base64EncodedString, options: options) else {
            throw RuntimeError.invalidBase64String(base64EncodedString)
        }
        self.init(data: ArraySlice(data))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        // https://datatracker.ietf.org/doc/html/rfc4648#section-3.1
        // "Implementations MUST NOT add line feeds to base-encoded data unless
        // the specification referring to this document explicitly directs base
        // encoders to add line feeds after a specific number of characters."
        let options = Data.Base64EncodingOptions()

        let base64String = Data(data).base64EncodedString(options: options)
        try container.encode(base64String)
    }
}
