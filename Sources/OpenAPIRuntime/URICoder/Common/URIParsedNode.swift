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

/// The type used for keys by `URIParser`.
typealias URIParsedKey = String.SubSequence

/// The type used for values by `URIParser`.
typealias URIParsedValue = String.SubSequence

/// The type used for an array of values by `URIParser`.
typealias URIParsedValueArray = [URIParsedValue]

/// The type used for a node and a dictionary by `URIParser`.
typealias URIParsedNode = [URIParsedKey: URIParsedValueArray]
