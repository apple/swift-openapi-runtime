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

/// A hint to the data encoding and decoding logic.
///
/// Derived from the content type.
@_spi(Generated)
public struct CodingStrategy: Equatable, Hashable, Sendable {

    /// Describes the underlying coding strategy.
    private enum _Strategy: String, Equatable, Hashable, Sendable {

        /// A strategy using JSONEncoder/JSONDecoder.
        case codable

        /// A strategy using LosslessStringConvertible.
        case string

        /// A strategy for letting the type choose the appropriate option.
        case deferredToType
    }

    private let strategy: _Strategy

    /// A strategy using JSONEncoder/JSONDecoder.
    public static var codable: Self {
        .init(strategy: .codable)
    }

    /// A strategy using LosslessStringConvertible.
    public static var string: Self {
        .init(strategy: .string)
    }

    /// A strategy for letting the type choose the appropriate option.
    public static var deferredToType: Self {
        .init(strategy: .deferredToType)
    }
}
