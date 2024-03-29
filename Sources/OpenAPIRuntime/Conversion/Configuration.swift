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
public struct ISO8601DateTranscoder: DateTranscoder, @unchecked Sendable {

    /// The lock protecting the formatter.
    private let lock: NSLock

    /// The underlying date formatter.
    private let locked_formatter: ISO8601DateFormatter

    /// Creates a new transcoder with the provided options.
    /// - Parameter options: Options to override the default ones. If you provide nil here, the default options
    ///   are used.
    public init(options: ISO8601DateFormatter.Options? = nil) {
        let formatter = ISO8601DateFormatter()
        if let options { formatter.formatOptions = options }
        lock = NSLock()
        lock.name = "com.apple.swift-openapi-generator.runtime.ISO8601DateTranscoder"
        locked_formatter = formatter
    }

    /// Creates and returns an ISO 8601 formatted string representation of the specified date.
    public func encode(_ date: Date) throws -> String {
        lock.lock()
        defer { lock.unlock() }
        return locked_formatter.string(from: date)
    }

    /// Creates and returns a date object from the specified ISO 8601 formatted string representation.
    public func decode(_ dateString: String) throws -> Date {
        lock.lock()
        defer { lock.unlock() }
        guard let date = locked_formatter.date(from: dateString) else {
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

    /// A transcoder that transcodes dates as ISO-8601–formatted string (in RFC 3339 format) with fractional seconds.
    public static var iso8601WithFractionalSeconds: Self {
        ISO8601DateTranscoder(options: [.withInternetDateTime, .withFractionalSeconds])
    }
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

/// A type that allows custom content type encoding and decoding.
public protocol CustomCoder: Sendable {

    /// Encodes the given value and returns its custom encoded representation.
    ///
    /// - parameter value: The value to encode.
    /// - returns: A new `Data` value containing the custom encoded data.
    func customEncode<T: Encodable>(_ value: T) throws -> Data

    /// Decodes a value of the given type from the given custom representation.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter data: The data to decode from.
    /// - returns: A value of the requested type.
    func customDecode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T

}

/// A set of configuration values used by the generated client and server types.
public struct Configuration: Sendable {

    /// The transcoder used when converting between date and string values.
    public var dateTranscoder: any DateTranscoder

    /// The generator to use when creating mutlipart bodies.
    public var multipartBoundaryGenerator: any MultipartBoundaryGenerator

    public var customCoders: [String: any CustomCoder]
    
    /// Creates a new configuration with the specified values.
    ///
    /// - Parameters:
    ///   - dateTranscoder: The transcoder to use when converting between date
    ///   and string values.
    ///   - multipartBoundaryGenerator: The generator to use when creating mutlipart bodies.
    ///   - customCoders: Array of custom coder to use for encoding and decoding unsupported content types.
    public init(
        dateTranscoder: any DateTranscoder = .iso8601,
        multipartBoundaryGenerator: any MultipartBoundaryGenerator = .random,
        customCoders: [String: any CustomCoder] = [:]
    ) {
        self.dateTranscoder = dateTranscoder
        self.multipartBoundaryGenerator = multipartBoundaryGenerator
        self.customCoders = customCoders
    }

    public func customCoder(for contentType: String) -> (any CustomCoder)? {
        self.customCoders[contentType]
    }

}
