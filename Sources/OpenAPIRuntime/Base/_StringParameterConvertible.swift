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

/// This marker protocol represents types used in parameters
/// (headers, path parameters, query items, ...).
///
/// Cannot be marked as SPI, as it's added on public types, but should be
/// considered an internal implementation detail of the generator.
public protocol _StringParameterConvertible: LosslessStringConvertible {}

extension String: _StringParameterConvertible {}
extension Bool: _StringParameterConvertible {}
extension Int: _StringParameterConvertible {}
extension Int64: _StringParameterConvertible {}
extension Int32: _StringParameterConvertible {}
extension Float: _StringParameterConvertible {}
extension Double: _StringParameterConvertible {}
