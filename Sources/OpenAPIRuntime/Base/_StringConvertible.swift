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

/// This marker protocol represents types that are representable as a string,
/// usable in headers, path parameters, query items, and text bodies.
///
/// Cannot be marked as SPI, as it's added on public types, but should be
/// considered an internal implementation detail of the generator.
public protocol _StringConvertible: LosslessStringConvertible {}

extension String: _StringConvertible {}
extension Bool: _StringConvertible {}
extension Int: _StringConvertible {}
extension Int64: _StringConvertible {}
extension Int32: _StringConvertible {}
extension Float: _StringConvertible {}
extension Double: _StringConvertible {}
