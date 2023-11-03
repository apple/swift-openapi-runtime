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

/// A type that allows customization of Date encoding and decoding.
///
/// See ``ISO8601DateTranscoder``.
public protocol DateTranscoder: Sendable {
    /// Encodes the `Date` as a `String`.
    func encode(_: Date) throws -> String

    /// Decodes a `String` as a `Date`.
    func decode(_: String) throws -> Date
}

/// A transcoder for dates encoded as an ISO-8601 string (in RFC 3339 format).
public struct ISO8601DateTranscoder: DateTranscoder {

    /// Creates and returns an ISO 8601 formatted string representation of the specified date.
    public func encode(_ date: Date) throws -> String { ISO8601DateFormatter().string(from: date) }

    /// Creates and returns a date object from the specified ISO 8601 formatted string representation.
    public func decode(_ dateString: String) throws -> Date {
        guard let date = ISO8601DateFormatter().date(from: dateString) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Expected date string to be ISO8601-formatted.")
            )
        }
        return date
    }
}

extension DateTranscoder where Self == ISO8601DateTranscoder {
    /// A transcoder that transcodes dates as ISO-8601–formatted string (in RFC 3339 format).
    public static var iso8601: Self { ISO8601DateTranscoder() }
}

public protocol MultipartBoundaryGenerator: Sendable { func makeBoundary() -> String }

public struct ConstantMultipartBoundaryGenerator: MultipartBoundaryGenerator {
    public var boundary: String
    public init(boundary: String) { self.boundary = boundary }
    public func makeBoundary() -> String { boundary }
}

extension MultipartBoundaryGenerator where Self == ConstantMultipartBoundaryGenerator {
    public static var constant: Self {
        ConstantMultipartBoundaryGenerator(boundary: "__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__")
    }
    #warning(
        "Add a random suffix to each boundary variant and make it the default. Constant is better for debugging/testing."
    )
}

extension JSONEncoder.DateEncodingStrategy {
    /// Encode the `Date` as a custom value encoded using the given ``DateTranscoder``.
    static func from(dateTranscoder: any DateTranscoder) -> Self {
        .custom { date, encoder in
            let dateAsString = try dateTranscoder.encode(date)
            var container = encoder.singleValueContainer()
            try container.encode(dateAsString)
        }
    }
}

extension JSONDecoder.DateDecodingStrategy {
    /// Decode the `Date` as a custom value decoded by the given ``DateTranscoder``.
    static func from(dateTranscoder: any DateTranscoder) -> Self {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            return try dateTranscoder.decode(dateString)
        }
    }
}

/// A set of configuration values used by the generated client and server types.
public struct Configuration: Sendable {

    /// The transcoder used when converting between date and string values.
    public var dateTranscoder: any DateTranscoder
    public var multipartBoundaryGenerator: any MultipartBoundaryGenerator

    /// Creates a new configuration with the specified values.
    ///
    /// - Parameter dateTranscoder: The transcoder to use when converting between date
    ///   and string values.
    public init(
        dateTranscoder: any DateTranscoder = .iso8601,
        multipartBoundaryGenerator: any MultipartBoundaryGenerator = .constant
    ) {
        self.dateTranscoder = dateTranscoder
        self.multipartBoundaryGenerator = multipartBoundaryGenerator
    }
}
