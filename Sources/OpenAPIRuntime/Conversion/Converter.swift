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
import class Foundation.JSONEncoder
#else
@preconcurrency import class Foundation.JSONEncoder
#endif
import class Foundation.JSONDecoder

/// Converter between generated and HTTP currency types.
@_spi(Generated) public struct Converter: Sendable {

    /// Configuration used to set up the converter.
    public let configuration: Configuration

    /// JSON coder for body data.
    internal var jsonCoder: any CustomCoder

    /// JSON encoder used for header fields.
    internal var headerFieldJSONEncoder: JSONEncoder

    /// Creates a new converter with the behavior specified by the configuration.
    public init(configuration: Configuration) {
        self.configuration = configuration

        self.jsonCoder = configuration.jsonCoder
        self.headerFieldJSONEncoder = Self.newHeaderFieldJSONEncoder(dateTranscoder: configuration.dateTranscoder)
    }
}

extension Converter {
    /// Creates a new JSON encoder specifically for header fields.
    /// - Parameter dateTranscoder: The transcoder for dates.
    /// - Returns: The configured JSON encoder.
    internal static func newHeaderFieldJSONEncoder(dateTranscoder: any DateTranscoder) -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .from(dateTranscoder: dateTranscoder)
        return encoder
    }
}
