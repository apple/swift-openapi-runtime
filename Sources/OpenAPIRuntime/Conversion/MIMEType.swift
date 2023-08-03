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
public struct MIMEType: Equatable {
    
    /// The value of the type or subtype in the MIME type.
    public enum Token: Equatable {
        
        /// Any value, represented as `*`.
        case wildcard
        
        /// A concrete value.
        case concrete(String)
        
        public static func ==(lhs: Token, rhs: Token) -> Bool {
            // Case-insensitive
            lhs.description.lowercased() == rhs.description.lowercased()
        }
    }
        
    /// The type – the first token.
    public var type: Token
    
    /// The subtype – the second token.
    public var subtype: Token
    
    /// Any optional parameters.
    public var parameters: [String: String]
    
    /// Creates a new MIME type.
    /// - Parameters:
    ///   - type: The type – the first token.
    ///   - subtype: The subtype – the second token.
    ///   - parameters: Any optional parameters.
    public init(type: Token, subtype: Token, parameters: [String: String] = [:]) {
        self.type = type
        self.subtype = subtype
        self.parameters = parameters
    }
    
    public static func ==(lhs: MIMEType, rhs: MIMEType) -> Bool {
        guard lhs.type == rhs.type else {
            return false
        }
        guard lhs.subtype == rhs.subtype else {
            return false
        }
        // Parameter names are case-insensitive, parameter values are
        // case-sensitive.
        guard lhs.parameters.count == rhs.parameters.count else {
            return false
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

extension MIMEType.Token: LosslessStringConvertible {
    public init?(_ description: String) {
        if description == "*" {
            self = .wildcard
        } else {
            self = .concrete(description)
        }
    }
    
    public var description: String {
        switch self {
        case .wildcard:
            return "*"
        case .concrete(let string):
            return string
        }
    }
}

extension MIMEType: LosslessStringConvertible {
    public init?(_ description: String) {
        var components = description
            // Split by semicolon
            .split(separator: ";")
            .map(String.init)
            // Trim leading/trailing spaces
            .map { $0.soar_trimmingLeadingAndTrailingSpaces }
        guard !components.isEmpty else {
            return nil
        }
        let firstComponent = components.removeFirst()
        let typeAndSubtype = firstComponent
            .split(separator: "/")
            .map(String.init)
            .compactMap(MIMEType.Token.init)
        guard typeAndSubtype.count == 2 else {
            return nil
        }
        func parseParameter(_ string: String) -> (String, String)? {
            let components = string
                .split(separator: "=")
                .map(String.init)
            guard components.count == 2 else {
                return nil
            }
            return (components[0], components[1])
        }
        let parameters = components
            .compactMap(parseParameter)
        self.init(
            type: typeAndSubtype[0],
            subtype: typeAndSubtype[1],
            parameters: Dictionary(
                parameters,
                uniquingKeysWith: { a, _ in a }
            )
        )
    }
    
    public var description: String {
        (["\(type.description)/\(subtype.description)"]
         + parameters
            .sorted(by: { a, b in a.key < b.key })
            .map { "\($0)=\($1)" })
        .joined(separator: "; ")
    }
}

extension String {
    fileprivate var soar_trimmingLeadingAndTrailingSpaces: Self {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
