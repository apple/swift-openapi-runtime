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

/// A protocol that provides a RawRepresentable type with a default
/// LosslessStringConvertible implementation.
///
/// Used by generated string-based enum types.
///
/// Cannot be marked as SPI, as it's added on public types, but should be
/// considered an internal implementation detail of the generator.
public protocol _AutoLosslessStringConvertible:
    RawRepresentable, LosslessStringConvertible, _StringConvertible
where RawValue == String {}

extension _AutoLosslessStringConvertible {
    public init?(_ description: String) {
        self.init(rawValue: description)
    }
    public var description: String {
        rawValue
    }
}
