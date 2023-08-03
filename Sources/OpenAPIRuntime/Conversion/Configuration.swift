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
    public func encode(_ date: Date) throws -> String {
        ISO8601DateFormatter().string(from: date)
    }

    /// Creates and returns a date object from the specified ISO 8601 formatted string representation.
    public func decode(_ dateString: String) throws -> Date {
        let iso8601DateFormatter = ISO8601DateFormatter()

        if dateString.contains(".") {
            iso8601DateFormatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
        } else if dateString.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression, range: nil, locale: nil) != nil {
            iso8601DateFormatter.formatOptions = [.withFullDate]
        }

        guard let date = iso8601DateFormatter.date(from: dateString) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Expected date string to be ISO8601-formatted."
                )
            )
        }
        return date
    }
}

extension DateTranscoder where Self == ISO8601DateTranscoder {
    /// A transcoder that transcodes dates as ISO-8601–formatted string (in RFC 3339 format).
    public static var iso8601: Self {
        ISO8601DateTranscoder()
    }
}

extension JSONEncoder.DateEncodingStrategy {
    /// Encode the `Date` as a custom value encoded using the given ``DateTranscoder``.
    static func from(dateTranscoder: any DateTranscoder) -> Self {
        return .custom { date, encoder in
            let dateAsString = try dateTranscoder.encode(date)
            var container = encoder.singleValueContainer()
            try container.encode(dateAsString)
        }
    }
}

extension JSONDecoder.DateDecodingStrategy {
    /// Decode the `Date` as a custom value decoded by the given ``DateTranscoder``.
    static func from(dateTranscoder: any DateTranscoder) -> Self {
        return .custom { decoder in
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

    /// Creates a new configuration with the specified values.
    ///
    /// - Parameters:
    ///   - dateTranscoder: The transcoder to use when converting between date
    ///   and string values.
    public init(
        dateTranscoder: any DateTranscoder = .iso8601
    ) {
        self.dateTranscoder = dateTranscoder
    }
}
