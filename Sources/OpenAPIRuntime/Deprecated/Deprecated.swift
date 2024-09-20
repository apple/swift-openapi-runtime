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
import HTTPTypes

// MARK: - Functionality to be removed in the future

extension UndocumentedPayload {
    /// Creates a new payload.
    @available(*, deprecated, renamed: "init(headerFields:body:)") @_disfavoredOverload public init() {
        self.init(headerFields: [:], body: nil)
    }
}

extension Configuration {
    /// Creates a new configuration with the specified values.
    ///
    /// - Parameters:
    ///   - dateTranscoder: The transcoder to use when converting between date
    ///   and string values.
    ///   - multipartBoundaryGenerator: The generator to use when creating mutlipart bodies.
    @available(*, deprecated, renamed: "init(dateTranscoder:multipartBoundaryGenerator:xmlCoder:)") @_disfavoredOverload
    public init(
        dateTranscoder: any DateTranscoder = .iso8601,
        multipartBoundaryGenerator: any MultipartBoundaryGenerator = .random
    ) {
        self.init(dateTranscoder: dateTranscoder, multipartBoundaryGenerator: multipartBoundaryGenerator, xmlCoder: nil)
    }

    /// Creates a new configuration with the specified values.
    ///
    /// - Parameters:
    ///   - dateTranscoder: The transcoder to use when converting between date
    ///   and string values.
    ///   - multipartBoundaryGenerator: The generator to use when creating mutlipart bodies.
    ///   - xmlCoder: Custom XML coder for encoding and decoding xml bodies. Only required when using XML body payloads.
    @available(*, deprecated, renamed: "init(dateTranscoder:jsonEncodingOptions:multipartBoundaryGenerator:xmlCoder:)")
    @_disfavoredOverload public init(
        dateTranscoder: any DateTranscoder = .iso8601,
        multipartBoundaryGenerator: any MultipartBoundaryGenerator = .random,
        xmlCoder: (any CustomCoder)? = nil
    ) {
        self.init(
            dateTranscoder: dateTranscoder,
            jsonEncodingOptions: [.sortedKeys, .prettyPrinted],
            multipartBoundaryGenerator: multipartBoundaryGenerator,
            xmlCoder: xmlCoder
        )
    }
}

extension AsyncSequence where Element == ArraySlice<UInt8>, Self: Sendable {
    /// Returns another sequence that decodes each event's data as the provided type using the provided decoder.
    ///
    /// Use this method if the event's `data` field is not JSON, or if you don't want to parse it using `asDecodedServerSentEventsWithJSONData`.
    /// - Returns: A sequence that provides the events.
    @available(*, deprecated, renamed: "asDecodedServerSentEvents(while:)")
    @_disfavoredOverload public func asDecodedServerSentEvents() -> ServerSentEventsDeserializationSequence<
        ServerSentEventsLineDeserializationSequence<Self>
    > { asDecodedServerSentEvents(while: { _ in true }) }
}
