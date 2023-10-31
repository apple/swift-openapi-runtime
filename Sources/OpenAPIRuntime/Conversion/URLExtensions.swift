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
    /// Returns the default server URL of "/".
    ///
    /// Specification: https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.3.md#fixed-fields
    public static let defaultOpenAPIServerURL: Self = {
        guard let url = URL(string: "/") else { fatalError("Failed to create an URL with the string '/'.") }
        return url
    }()

    /// Returns a validated server URL, or throws an error.
    /// - Parameter string: A URL string.
    /// - Throws: If the provided string doesn't convert to URL.
    public init(validatingOpenAPIServerURL string: String) throws {
        guard let url = Self(string: string) else { throw RuntimeError.invalidServerURL(string) }
        self = url
    }
}
