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

/// Suppress "variable was never mutated, change to let" warnings.
///
/// In the generator logic, it is complicated to know in advance whether any generated
/// local variable will be mutable or immutable.
///
/// Being able to always generate the variables, and do so as `let`s simplifies the
/// generator logic significantly. However, to get around complier warnings, we insert
/// a call to this function for each such local mutable variable.
///
/// There should be no runtime impact in release builds, as the function is inlined and
/// has no executable code.
@_spi(Generated)
@inline(__always)
public func suppressMutabilityWarning<T>(_ value: inout T) {}

/// Suppress "variable unused" warnings.
///
/// In the generator logic, it is complicated to know in advance whether any generated
/// local variable will be used at all.
///
/// Being able to always generate the variables simplifies the generator logic significantly.
/// However, to get around complier warnings, we insert a call to this function for each
/// such local mutable variable.
///
/// There should be no runtime impact in release builds, as the function is inlined and
/// has no executable code.
@_spi(Generated)
@inline(__always)
public func suppressUnusedWarning<T>(_ value: T) {}
