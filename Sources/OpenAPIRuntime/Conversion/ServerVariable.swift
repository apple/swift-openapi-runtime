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

extension URL {
    /// Returns a validated server URL created from the URL template, or
    /// throws an error.
    /// - Parameter
    ///   - string: A URL string.
    ///   - variables: A map of variable values to substitute into the URL
    ///     template.
    /// - Throws: If the provided string doesn't convert to URL.
    @_spi(Generated)
    public init(
        validatingOpenAPIServerURL string: String,
        variables: [ServerVariable]
    ) throws {
        var urlString = string
        for variable in variables {
            let name = variable.name
            let value = variable.value
            if let allowedValues = variable.allowedValues {
                guard allowedValues.contains(value) else {
                    throw RuntimeError.invalidServerVariableValue(
                        name: name,
                        value: value,
                        allowedValues: allowedValues
                    )
                }
            }
            urlString = urlString.replacingOccurrences(of: "{\(name)}", with: value)
        }
        guard let url = Self(string: urlString) else {
            throw RuntimeError.invalidServerURL(urlString)
        }
        self = url
    }
}

/// A variable of a server URL template in the OpenAPI document.
@_spi(Generated)
public struct ServerVariable {

    /// The name of the variable.
    public var name: String

    /// The value to be substituted into the URL template.
    public var value: String

    /// A list of allowed values from the OpenAPI document.
    ///
    /// Nil means that any value is allowed.
    public var allowedValues: [String]?

    /// Creates a new server variable.
    /// - Parameters:
    ///   - name: The name of the variable.
    ///   - value: The value to be substituted into the URL template.
    ///   - allowedValues: A list of allowed values from the OpenAPI document.
    public init(name: String, value: String, allowedValues: [String]? = nil) {
        self.name = name
        self.value = value
        self.allowedValues = allowedValues
    }
}
