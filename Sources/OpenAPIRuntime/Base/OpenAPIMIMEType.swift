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
@_spi(Generated) public struct OpenAPIMIMEType: Equatable, Sendable {

    /// XML MIME type
    public static let xml: OpenAPIMIMEType = .init(kind: .concrete(type: "application", subtype: "xml"))

    /// The kind of the MIME type.
    public enum Kind: Equatable, Sendable {

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
            case (.any, .any): return true
            case let (.anySubtype(lhsType), .anySubtype(rhsType)): return lhsType.lowercased() == rhsType.lowercased()
            case let (.concrete(lhsType, lhsSubtype), .concrete(rhsType, rhsSubtype)):
                return lhsType.lowercased() == rhsType.lowercased()
                    && lhsSubtype.lowercased() == rhsSubtype.lowercased()
            default: return false
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
        guard lhs.kind == rhs.kind else { return false }
        // Parameter names are case-insensitive, parameter values are
        // case-sensitive.
        guard lhs.parameters.count == rhs.parameters.count else { return false }
        if lhs.parameters.isEmpty { return true }
        func normalizeKeyValue(key: String, value: String) -> (String, String) { (key.lowercased(), value) }
        let normalizedLeftParams = Dictionary(uniqueKeysWithValues: lhs.parameters.map(normalizeKeyValue))
        let normalizedRightParams = Dictionary(uniqueKeysWithValues: rhs.parameters.map(normalizeKeyValue))
        return normalizedLeftParams == normalizedRightParams
    }
}

extension OpenAPIMIMEType.Kind: LosslessStringConvertible {
    /// Initializes a MIME type kind from a string description.
    ///
    /// - Parameter description: A string description of the MIME type kind.
    public init?(_ description: String) {
        let typeAndSubtype = description.split(separator: "/").map(String.init)
        guard typeAndSubtype.count == 2 else { return nil }
        switch (typeAndSubtype[0], typeAndSubtype[1]) {
        case ("*", let subtype):
            guard subtype == "*" else { return nil }
            self = .any
        case (let type, "*"): self = .anySubtype(type: type)
        case (let type, let subtype): self = .concrete(type: type, subtype: subtype)
        }
    }

    /// A textual representation of the MIME type kind.
    public var description: String {
        switch self {
        case .any: return "*/*"
        case .anySubtype(let type): return "\(type)/*"
        case .concrete(let type, let subtype): return "\(type)/\(subtype)"
        }
    }
}

extension OpenAPIMIMEType: LosslessStringConvertible {
    /// Initializes an `OpenAPIMIMEType` instance based on a string description.
    ///
    /// - Parameter description: A string description of the MIME.
    public init?(_ description: String) {
        var components =
            description  // Split by semicolon
            .split(separator: ";").map(String.init)  // Trim leading/trailing spaces
            .map { $0.trimmingLeadingAndTrailingSpaces }
        guard !components.isEmpty else { return nil }
        let firstComponent = components.removeFirst()
        guard let kind = OpenAPIMIMEType.Kind(firstComponent) else { return nil }
        func parseParameter(_ string: String) -> (String, String)? {
            let components = string.split(separator: "=").map(String.init)
            guard components.count == 2 else { return nil }
            return (components[0], components[1])
        }
        let parameters = components.compactMap(parseParameter)
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
        ([kind.description] + parameters.sorted(by: { a, b in a.key < b.key }).map { "\($0)=\($1)" })
            .joined(separator: "; ")
    }
}

// MARK: - Internals

extension OpenAPIMIMEType {

    /// The result of a match evaluation between two MIME types.
    enum Match: Hashable {

        /// The reason why two types are incompatible.
        enum IncompatibilityReason: Hashable {

            /// The types don't match.
            case type

            /// The subtypes don't match.
            case subtype

            /// The parameter of the provided name is missing or doesn't match.
            case parameter(name: String)
        }

        /// The types are incompatible for the provided reason.
        case incompatible(IncompatibilityReason)

        /// The types match based on a full wildcard `*/*`.
        case wildcard

        /// The types match based on a subtype wildcard, such as `image/*`.
        case subtypeWildcard

        /// The types match across the type, subtype, and the provided number
        /// of parameters.
        case typeAndSubtype(matchedParameterCount: Int)

        /// A numeric representation of the quality of the match, the higher
        /// the closer the types are.
        var score: Int {
            switch self {
            case .incompatible: return 0
            case .wildcard: return 1
            case .subtypeWildcard: return 2
            case .typeAndSubtype(let matchedParameterCount): return 3 + matchedParameterCount
            }
        }
    }

    /// Computes whether two MIME types match.
    /// - Parameters:
    ///   - receivedType: The type component of the received MIME type.
    ///   - receivedSubtype: The subtype component of the received MIME type.
    ///   - receivedParameters: The parameters of the received MIME type.
    ///   - option: The MIME type to match against.
    /// - Returns: The match result.
    static func evaluate(
        receivedType: String,
        receivedSubtype: String,
        receivedParameters: [String: String],
        against option: OpenAPIMIMEType
    ) -> Match {
        switch option.kind {
        case .any: return .wildcard
        case .anySubtype(let expectedType):
            guard receivedType.lowercased() == expectedType.lowercased() else { return .incompatible(.type) }
            return .subtypeWildcard
        case .concrete(let expectedType, let expectedSubtype):
            let receivedTypeLowercased = receivedType.lowercased()
            let expectedTypeLowercased = expectedType.lowercased()
            guard receivedTypeLowercased == expectedTypeLowercased else { return .incompatible(.type) }

            let receivedSubtypeLowercased = receivedSubtype.lowercased()
            let expectedSubtypeLowercased = expectedSubtype.lowercased()
            let isExactSubtypeMatch = receivedSubtypeLowercased == expectedSubtypeLowercased
            if !isExactSubtypeMatch {
                let isStructuredSyntaxSuffixMatch =
                    Self.structuredSyntaxSuffix(of: receivedSubtypeLowercased) == expectedSubtypeLowercased
                let isStructuredSyntaxWildcardMatch: Bool
                if let structuredSyntaxWildcardSuffix = Self.structuredSyntaxWildcardSuffix(of: expectedSubtypeLowercased) {
                    isStructuredSyntaxWildcardMatch =
                        receivedSubtypeLowercased == structuredSyntaxWildcardSuffix
                        || Self.structuredSyntaxSuffix(of: receivedSubtypeLowercased) == structuredSyntaxWildcardSuffix
                } else {
                    isStructuredSyntaxWildcardMatch = false
                }
                guard isStructuredSyntaxSuffixMatch || isStructuredSyntaxWildcardMatch else {
                    return .incompatible(.subtype)
                }
            }

            // A full concrete match, so also check parameters.
            // The rule is:
            //   1. If a received parameter is not found in the option,
            //      that's okay and gets ignored.
            //   2. If an option parameter is not received, this is an
            //      incompatible content type match.
            // This means we can just iterate over option parameters and
            // check them against the received parameters, but we can
            // ignore any received parameters that didn't appear in the
            // option parameters.

            // According to RFC 2045: https://www.rfc-editor.org/rfc/rfc2045#section-5.1
            // "Type, subtype, and parameter names are case-insensitive."
            // Inferred: Parameter values are case-sensitive.

            let receivedNormalizedParameters = Dictionary(
                uniqueKeysWithValues: receivedParameters.map { ($0.key.lowercased(), $0.value) }
            )
            var matchedParameterCount = 0
            for optionParameter in option.parameters {
                let normalizedParameterName = optionParameter.key.lowercased()
                guard let receivedValue = receivedNormalizedParameters[normalizedParameterName],
                    receivedValue == optionParameter.value
                else { return .incompatible(.parameter(name: normalizedParameterName)) }
                matchedParameterCount += 1
            }
            return .typeAndSubtype(matchedParameterCount: matchedParameterCount)
        }
    }

    /// Returns the structured syntax suffix component of a subtype, if present.
    /// For example, returns `"json"` for `"problem+json"`.
    static func structuredSyntaxSuffix(of subtype: String) -> String? {
        guard let plusIndex = subtype.lastIndex(of: "+") else { return nil }
        let suffixStart = subtype.index(after: plusIndex)
        guard suffixStart < subtype.endIndex else { return nil }
        return String(subtype[suffixStart...])
    }

    /// Returns the structured syntax suffix of a wildcard subtype, if present.
    /// For example, returns `"json"` for `"*+json"`.
    static func structuredSyntaxWildcardSuffix(of subtype: String) -> String? {
        guard subtype.hasPrefix("*+") else { return nil }
        let suffixStart = subtype.index(subtype.startIndex, offsetBy: 2)
        guard suffixStart < subtype.endIndex else { return nil }
        return String(subtype[suffixStart...])
    }
}
