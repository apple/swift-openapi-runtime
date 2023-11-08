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

/// A generator of a new boundary string used by multipart messages to separate parts.
public protocol MultipartBoundaryGenerator: Sendable {

    /// Generates a boundary string for a multipart message.
    /// - Returns: A boundary string.
    func makeBoundary() -> String
}

/// A generator that always returns the same constant boundary string.
public struct ConstantMultipartBoundaryGenerator: MultipartBoundaryGenerator {

    /// The boundary string to return.
    public let boundary: String
    /// Creates a new generator.
    /// - Parameter boundary: The boundary string to return every time.
    public init(boundary: String = "__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__") { self.boundary = boundary }

    /// Generates a boundary string for a multipart message.
    /// - Returns: A boundary string.
    public func makeBoundary() -> String { boundary }
}

/// A generator that returns a boundary containg a constant prefix and a randomized suffix.
public struct RandomizedMultipartBoundaryGenerator: MultipartBoundaryGenerator {

    /// The constant prefix of each boundary.
    public let boundaryPrefix: String
    /// The length, in bytes, of the randomized boundary suffix.
    public let randomNumberSuffixLenght: Int

    /// The options for the random bytes suffix.
    private let values: [UInt8] = Array("0123456789".utf8)

    /// Create a new generator.
    /// - Parameters:
    ///   - boundaryPrefix: The constant prefix of each boundary.
    ///   - randomNumberSuffixLenght: The length, in bytes, of the randomized boundary suffix.
    public init(boundaryPrefix: String = "__X_SWIFT_OPENAPI_", randomNumberSuffixLenght: Int = 20) {
        self.boundaryPrefix = boundaryPrefix
        self.randomNumberSuffixLenght = randomNumberSuffixLenght
    }
    /// Generates a boundary string for a multipart message.
    /// - Returns: A boundary string.
    public func makeBoundary() -> String {
        var randomSuffix = [UInt8](repeating: 0, count: randomNumberSuffixLenght)
        for i in randomSuffix.startIndex..<randomSuffix.endIndex { randomSuffix[i] = values.randomElement()! }
        return boundaryPrefix.appending(String(decoding: randomSuffix, as: UTF8.self))
    }
}

extension MultipartBoundaryGenerator where Self == ConstantMultipartBoundaryGenerator {

    /// A generator that always returns the same boundary string.
    public static var constant: Self { ConstantMultipartBoundaryGenerator() }
}
extension MultipartBoundaryGenerator where Self == RandomizedMultipartBoundaryGenerator {

    /// A generator that produces a random boundary every time.
    public static var randomized: Self { RandomizedMultipartBoundaryGenerator() }
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

    /// The generator to use when creating mutlipart bodies.
    public var multipartBoundaryGenerator: any MultipartBoundaryGenerator

    /// Creates a new configuration with the specified values.
    ///
    /// - Parameters:
    ///   - dateTranscoder: The transcoder to use when converting between date
    ///   and string values.
    ///   - multipartBoundaryGenerator: The generator to use when creating mutlipart bodies.
    public init(
        dateTranscoder: any DateTranscoder = .iso8601,
        multipartBoundaryGenerator: any MultipartBoundaryGenerator = .randomized
    ) {
        self.dateTranscoder = dateTranscoder
        self.multipartBoundaryGenerator = multipartBoundaryGenerator
    }
}

extension Configuration {
    /// Creates a new configuration with the specified values.
    ///
    /// - Parameter dateTranscoder: The transcoder to use when converting between date
    ///   and string values.
    @available(*, deprecated, renamed: "init(dateTranscoder:multipartBoundaryGenerator:)") @_disfavoredOverload
    public init(dateTranscoder: any DateTranscoder) {
        self.init(dateTranscoder: dateTranscoder, multipartBoundaryGenerator: .randomized)
    }
}
