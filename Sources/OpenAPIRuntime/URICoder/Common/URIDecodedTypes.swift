//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2024 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A primitive value produced by `URIValueFromNodeDecoder`.
typealias URIDecodedPrimitive = URIParsedValue

/// An array value produced by `URIValueFromNodeDecoder`.
typealias URIDecodedArray = URIParsedValueArray

/// A dictionary value produced by `URIValueFromNodeDecoder`.
typealias URIDecodedDictionary = [Substring: URIParsedValueArray]
