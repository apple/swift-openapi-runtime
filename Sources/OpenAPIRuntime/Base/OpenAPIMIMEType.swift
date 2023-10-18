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

/// A container for a parsed, valid MIME type.
@_spi(Generated)
public struct OpenAPIMIMEType: Equatable {

    /// The kind of the MIME type.
    public enum Kind: Equatable {

        /// Any, spelled as `*/*`.
        case any

        /// Any subtype of a concrete type, spelled as `type/*`.
        case anySubtype(type: String)

        /// A concrete value, spelled as `type/subtype`.
        case concrete(type: String, subtype: String)

        /// Compares two MIME type kinds for equality.
        ///
        /// - Parameters:
        ///   - lhs: The left-hand side MIME type kind.
        ///   - rhs: The right-hand side MIME type kind.
        ///
        /// - Returns: `true` if the MIME type kinds are equal, otherwise `false`.
        public static func == (lhs: Kind, rhs: Kind) -> Bool {
            switch (lhs, rhs) {
            case (.any, .any):
                return true
            case let (.anySubtype(lhsType), .anySubtype(rhsType)):
                return lhsType.lowercased() == rhsType.lowercased()
            case let (.concrete(lhsType, lhsSubtype), .concrete(rhsType, rhsSubtype)):
                return lhsType.lowercased() == rhsType.lowercased()
                    && lhsSubtype.lowercased() == rhsSubtype.lowercased()
            default:
                return false
            }
        }
    }

    /// The kind of the MIME type.
    public var kind: Kind

    /// Any optional parameters.
    public var parameters: [String: String]

    /// Creates a new MIME type.
    /// - Parameters:
    ///   - kind: The kind of the MIME type.
    ///   - parameters: Any optional parameters.
    public init(kind: Kind, parameters: [String: String] = [:]) {
        self.kind = kind
        self.parameters = parameters
    }

    /// Compares two MIME types for equality.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side MIME type.
    ///   - rhs: The right-hand side MIME type.
    ///
    /// - Returns: `true` if the MIME types are equal, otherwise `false`.
    public static func == (lhs: OpenAPIMIMEType, rhs: OpenAPIMIMEType) -> Bool {
        guard lhs.kind == rhs.kind else {
            return false
        }
        // Parameter names are case-insensitive, parameter values are
        // case-sensitive.
        guard lhs.parameters.count == rhs.parameters.count else {
            return false
        }
        if lhs.parameters.isEmpty {
            return true
        }
        func normalizeKeyValue(key: String, value: String) -> (String, String) {
            (key.lowercased(), value)
        }
        let normalizedLeftParams = Dictionary(
            uniqueKeysWithValues: lhs.parameters.map(normalizeKeyValue)
        )
        let normalizedRightParams = Dictionary(
            uniqueKeysWithValues: rhs.parameters.map(normalizeKeyValue)
        )
        return normalizedLeftParams == normalizedRightParams
    }
}

extension OpenAPIMIMEType.Kind: LosslessStringConvertible {
    /// Initializes a MIME type kind from a string description.
    ///
    /// - Parameter description: A string description of the MIME type kind.
    public init?(_ description: String) {
        let typeAndSubtype =
            description
            .split(separator: "/")
            .map(String.init)
        guard typeAndSubtype.count == 2 else {
            return nil
        }
        switch (typeAndSubtype[0], typeAndSubtype[1]) {
        case ("*", let subtype):
            guard subtype == "*" else {
                return nil
            }
            self = .any
        case (let type, "*"):
            self = .anySubtype(type: type)
        case (let type, let subtype):
            self = .concrete(type: type, subtype: subtype)
        }
    }

    /// A textual representation of the MIME type kind.
    public var description: String {
        switch self {
        case .any:
            return "*/*"
        case .anySubtype(let type):
            return "\(type)/*"
        case .concrete(let type, let subtype):
            return "\(type)/\(subtype)"
        }
    }
}

extension OpenAPIMIMEType: LosslessStringConvertible {
    /// Initializes an `OpenAPIMIMEType` instance based on a string description.
    ///
    /// - Parameter description: A string description of the MIME.
    public init?(_ description: String) {
        var components =
            description
            // Split by semicolon
            .split(separator: ";")
            .map(String.init)
            // Trim leading/trailing spaces
            .map { $0.trimmingLeadingAndTrailingSpaces }
        guard !components.isEmpty else {
            return nil
        }
        let firstComponent = components.removeFirst()
        guard let kind = OpenAPIMIMEType.Kind(firstComponent) else {
            return nil
        }
        func parseParameter(_ string: String) -> (String, String)? {
            let components =
                string
                .split(separator: "=")
                .map(String.init)
            guard components.count == 2 else {
                return nil
            }
            return (components[0], components[1])
        }
        let parameters =
            components
            .compactMap(parseParameter)
        self.init(
            kind: kind,
            parameters: Dictionary(
                parameters,
                // Pick the first value when duplicate parameters are provided.
                uniquingKeysWith: { a, _ in a }
            )
        )
    }

    /// A string description of the MIME type.
    public var description: String {
        ([kind.description]
            + parameters
            .sorted(by: { a, b in a.key < b.key })
            .map { "\($0)=\($1)" })
            .joined(separator: "; ")
    }
}
