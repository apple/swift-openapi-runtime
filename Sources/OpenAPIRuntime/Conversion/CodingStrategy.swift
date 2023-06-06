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

/// A hint to the data encoding and decoding logic for parameters.
///
/// Derived from the content type.
///
/// Parameters can optionally provide an explicit content type using
/// the `content` mapping. Otherwise, their `schema` parameter is used
/// to decide the Swift type.
///
/// A parameter can be either explicitly specified to use a stringly type
/// (`.string`) or a codable type (`.codable`), when instructed by
/// the `content` mapping.
///
/// If no `content` is provided, only `schema`, the case `.deferredToType` is
/// used to let the compiler choose the best converter method based on the
/// Swift type of the parameter (for example: `Int`, `Date`, and so on).
@available(*, deprecated, message: "stop using")
@_spi(Generated)
public struct ParameterCodingStrategy: Equatable, Hashable, Sendable {

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

/// A hint to the data encoding and decoding logic for request and response
/// bodies.
///
/// Derived from the content type.
///
/// Request and response bodies always specify a content type, so unlike
/// in the case of ``ParameterCodingStrategy``, there is no `.deferredToType`
/// case for bodies, only explicit strategies for the three fundamental ways
/// bodies can be treated: as a stringly type, a codable type, or raw data.
@available(*, deprecated, message: "stop using")
@_spi(Generated)
public struct BodyCodingStrategy: Equatable, Hashable, Sendable {

    /// Describes the underlying coding strategy.
    private enum _Strategy: String, Equatable, Hashable, Sendable {

        /// A strategy using JSONEncoder/JSONDecoder.
        case codable

        /// A strategy using LosslessStringConvertible.
        case string

        /// A strategy passing through data unmodified.
        case data
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

    /// A strategy passing through data unmodified.
    public static var data: Self {
        .init(strategy: .data)
    }
}
