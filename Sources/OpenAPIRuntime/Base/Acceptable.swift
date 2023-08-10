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

/// The protocol that all generated `AcceptableContentType` enums conform to.
public protocol AcceptableProtocol: RawRepresentable, Sendable, Equatable, Hashable where RawValue == String {

    /// Returns the default set of acceptable content types for this type, in
    /// the order specified in the OpenAPI document.
    static var defaultValues: [Self] { get }
}

/// A quality value used to describe the order of priority in a comma-separated
/// list of values, such as in the Accept header.
public struct QualityValue: Sendable, Equatable, Hashable {

    /// As the quality value only retains up to and including 3 decimal digits,
    /// we store it in terms of the thousands.
    ///
    /// This allows predictable equality comparisons and sorting.
    ///
    /// For example, 1000 thousands is the quality value of 1.0.
    private let thousands: UInt16

    /// Creates a new quality value of the default value 1.0.
    public init() {
        self.thousands = 1000
    }

    /// Returns a Boolean value indicating whether the quality value is
    /// at its default value 1.0.
    public var isDefault: Bool {
        thousands == 1000
    }

    /// Creates a new quality value from the provided floating-point number.
    ///
    /// - Precondition: The value must be between 0.0 and 1.0, inclusive.
    public init(doubleValue: Double) {
        precondition(
            doubleValue >= 0.0 && doubleValue <= 1.0,
            "Input number into quality value is out of range"
        )
        self.thousands = UInt16(doubleValue * 1000)
    }

    /// The value represented as a floating-point number between 0.0 and 1.0, inclusive.
    public var doubleValue: Double {
        Double(thousands) / 1000
    }
}

extension QualityValue: RawRepresentable {
    public init?(rawValue: String) {
        guard let doubleValue = Double(rawValue) else {
            return nil
        }
        self.init(doubleValue: doubleValue)
    }

    public var rawValue: String {
        String(format: "%0.3f", doubleValue)
    }
}

extension QualityValue: Comparable {
    public static func < (lhs: QualityValue, rhs: QualityValue) -> Bool {
        lhs.thousands > rhs.thousands
    }
}

extension QualityValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: UInt16) {
        self.thousands = value * 1000
    }
}

extension QualityValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self.init(doubleValue: value)
    }
}

/// A wrapper of an individual content type in the accept header.
public struct AcceptHeaderContentType<T: AcceptableProtocol>: Sendable, Equatable, Hashable {

    /// The quality value of this content type.
    ///
    /// Used to describe the order of priority in a comma-separated
    /// list of values.
    ///
    /// Content types with a higher priority should be preferred by the server
    /// when deciding which content type to use in the response.
    ///
    /// Also called the "q-factor" or "q-value".
    public let quality: QualityValue

    /// The value representing the content type.
    public let contentType: T

    /// Creates a new content type from the provided parameters.
    /// - Parameters:
    ///   - quality: The quality of the content type, between 0.0 and 1.0.
    ///   - value: The value representing the content type.
    /// - Precondition: Priority must be in the range 0.0 and 1.0 inclusive.
    public init(quality: QualityValue = 1.0, contentType: T) {
        self.quality = quality
        self.contentType = contentType
    }

    /// Returns the default set of acceptable content types for this type, in
    /// the order specified in the OpenAPI document.
    public static var defaultValues: [Self] {
        T.defaultValues.map { .init(contentType: $0) }
    }
}

extension AcceptHeaderContentType: RawRepresentable {
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
        guard let typeAndSubtype = T.init(rawValue: validMimeType.kind.description.lowercased()) else {
            // Invalid type/subtype.
            return nil
        }
        self.init(quality: quality, contentType: typeAndSubtype)
    }

    public var rawValue: String {
        contentType.rawValue + (quality.isDefault ? "" : "; q=\(quality.rawValue)")
    }
}

extension AcceptHeaderContentType: Comparable {
    public static func < (lhs: AcceptHeaderContentType<T>, rhs: AcceptHeaderContentType<T>) -> Bool {
        lhs.quality < rhs.quality
    }
}
