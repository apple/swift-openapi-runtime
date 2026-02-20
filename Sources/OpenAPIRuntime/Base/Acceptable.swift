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

// Full Foundation needed for String(format:)
import Foundation

/// The protocol that all generated `AcceptableContentType` enums conform to.
public protocol AcceptableProtocol: RawRepresentable, Sendable, Hashable, CaseIterable where RawValue == String {}

/// A quality value used to describe the order of priority in a comma-separated
/// list of values, such as in the Accept header.
public struct QualityValue: Sendable, Hashable {

    /// As the quality value only retains up to and including 3 decimal digits,
    /// we store it in terms of the thousands.
    ///
    /// This allows predictable equality comparisons and sorting.
    ///
    /// For example, 1000 thousands is the quality value of 1.0.
    private let thousands: UInt16

    /// Returns a Boolean value indicating whether the quality value is
    /// at its default value 1.0.
    public var isDefault: Bool { thousands == 1000 }

    /// Creates a new quality value from the provided floating-point number.
    ///
    /// - Parameter doubleValue: The floating-point number representing the quality value.
    /// - Precondition: The `doubleValue` must be between 0.0 and 1.0, inclusive.
    public init(doubleValue: Double) {
        precondition(
            doubleValue >= 0.0 && doubleValue <= 1.0,
            "Provided quality number is out of range, must be between 0.0 and 1.0, inclusive."
        )
        self.thousands = UInt16(doubleValue * 1000)
    }

    /// The value represented as a floating-point number between 0.0 and 1.0, inclusive.
    public var doubleValue: Double { Double(thousands) / 1000 }
}

extension QualityValue: RawRepresentable {
    /// Creates a new `QualityValue` instance from a raw string value.
    ///
    /// - Parameter rawValue: A string representing the quality value.
    public init?(rawValue: String) {
        guard let doubleValue = Double(rawValue) else { return nil }
        self.init(doubleValue: doubleValue)
    }

    /// The raw string representation of the `QualityValue`.
    public var rawValue: String { String(format: "%0.3f", doubleValue) }
}

extension QualityValue: ExpressibleByIntegerLiteral {
    /// Creates a new `QualityValue` instance from an integer literal value.
    ///
    /// - Parameter value: An integer literal value representing the quality value.
    /// - Precondition: The `integerLiteral` must be between 0.0 and 1.0, inclusive.
    public init(integerLiteral value: UInt16) {
        precondition(
            value >= 0 && value <= 1,
            "Provided quality number is out of range, must be between 0 and 1, inclusive."
        )
        self.thousands = value * 1000
    }
}

extension QualityValue: ExpressibleByFloatLiteral {
    /// Creates a new `QualityValue` instance from a floating-point literal value.
    ///
    /// - Parameter value: A floating-point literal value representing the quality value.
    public init(floatLiteral value: Double) { self.init(doubleValue: value) }
}

extension Array {

    /// Returns the default values for the acceptable type.
    public static func defaultValues<T: AcceptableProtocol>() -> [AcceptHeaderContentType<T>]
    where Element == AcceptHeaderContentType<T> { T.allCases.map { .init(contentType: $0) } }
}

/// A wrapper of an individual content type in the accept header.
public struct AcceptHeaderContentType<ContentType: AcceptableProtocol>: Sendable, Hashable {

    /// The value representing the content type.
    public var contentType: ContentType

    /// The quality value of this content type.
    ///
    /// Used to describe the order of priority in a comma-separated
    /// list of values.
    ///
    /// Content types with a higher priority should be preferred by the server
    /// when deciding which content type to use in the response.
    ///
    /// Also called the "q-factor" or "q-value".
    public var quality: QualityValue

    /// Creates a new content type from the provided parameters.
    ///
    /// - Parameters:
    ///   - contentType: The value representing the content type.
    ///   - quality: The quality of the content type, between 0.0 and 1.0.
    public init(contentType: ContentType, quality: QualityValue = 1.0) {
        self.quality = quality
        self.contentType = contentType
    }

    /// Returns the default set of acceptable content types for this type, in
    /// the order specified in the OpenAPI document.
    public static var defaultValues: [Self] { ContentType.allCases.map { .init(contentType: $0) } }
}

extension AcceptHeaderContentType: RawRepresentable {
    /// Initializes an `AcceptHeaderContentType` instance from its raw string value.
    ///
    /// - Parameter rawValue: The raw string value representing the content type.
    public init?(rawValue: String) {
        guard let validMimeType = OpenAPIMIMEType(rawValue) else {
            // Invalid MIME type.
            return nil
        }
        let quality: QualityValue
        if let rawQuality = validMimeType.parameters["q"] {
            guard let parsedQuality = QualityValue(rawValue: rawQuality) else {
                // Invalid quality parameter.
                return nil
            }
            quality = parsedQuality
        } else {
            quality = 1.0
        }
        guard let typeAndSubtype = ContentType(rawValue: validMimeType.kind.description.lowercased()) else {
            // Invalid type/subtype.
            return nil
        }
        self.init(contentType: typeAndSubtype, quality: quality)
    }

    /// The raw representation of the content negotiation as a MIME type string.
    public var rawValue: String { contentType.rawValue + (quality.isDefault ? "" : "; q=\(quality.rawValue)") }
}

extension Array {

    /// Returns the array sorted by the quality value, highest quality first.
    public func sortedByQuality<T: AcceptableProtocol>() -> [AcceptHeaderContentType<T>]
    where Element == AcceptHeaderContentType<T> { sorted { a, b in a.quality.doubleValue > b.quality.doubleValue } }
}
