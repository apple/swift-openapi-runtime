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
#if canImport(Darwin)
import Foundation
#else
@preconcurrency import class Foundation.JSONEncoder
@preconcurrency import class Foundation.JSONDecoder
#endif

/// Converter between generated and HTTP currency types.
@_spi(Generated) public struct Converter: Sendable {

    /// Configuration used to set up the converter.
    public let configuration: Configuration

    /// JSON encoder.
    internal var encoder: JSONEncoder

    /// JSON decoder.
    internal var decoder: JSONDecoder

    /// JSON encoder used for header fields.
    internal var headerFieldEncoder: JSONEncoder

    /// Creates a new converter with the behavior specified by the configuration.
    public init(configuration: Configuration) {
        self.configuration = configuration

        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        self.encoder.dateEncodingStrategy = .from(dateTranscoder: configuration.dateTranscoder)

        self.headerFieldEncoder = JSONEncoder()
        self.headerFieldEncoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        self.headerFieldEncoder.dateEncodingStrategy = .from(dateTranscoder: configuration.dateTranscoder)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .from(dateTranscoder: configuration.dateTranscoder)
    }
}
