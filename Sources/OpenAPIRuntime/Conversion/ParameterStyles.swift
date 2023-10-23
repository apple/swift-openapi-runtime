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

/// The serialization style used by a parameter.
///
/// Details: https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.3.md#fixed-fields-10
@_spi(Generated)
public enum ParameterStyle: Sendable {

    /// The form style.
    ///
    /// Details: https://datatracker.ietf.org/doc/html/rfc6570#section-3.2.8
    case form

    /// The simple style.
    ///
    /// Details: https://datatracker.ietf.org/doc/html/rfc6570#section-3.2.2
    case simple
}

extension ParameterStyle {

    /// The default style for path parameters.
    static let defaultForPathParameters: Self = .simple

    /// The default style for query items.
    static let defaultForQueryItems: Self = .form

    /// The default style for query items.
    static let defaultForHeaderFields: Self = .simple

    /// The default style for cookies.
    static let defaultForCookies: Self = .form

    /// Returns the default value of the explode field for the given style
    /// - Parameter style: The parameter style.
    /// - Returns: Bool - True if the style is form, otherwise false
    static func defaultExplodeFor(forStyle style: ParameterStyle) -> Bool {
        style == .form
    }
}

extension URICoderConfiguration.Style {
    init(_ style: ParameterStyle) {
        switch style {
        case .form:
            self = .form
        case .simple:
            self = .simple
        }
    }
}
