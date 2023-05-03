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

extension DecodingError: PrettyStringConvertible {
    var prettyDescription: String {
        let output: String
        switch self {
        case .dataCorrupted(let context):
            output = "dataCorrupted - \(context.debugDescription)"
        case .keyNotFound(let key, let context):
            output = "keyNotFound \(key) - \(context.debugDescription)"
        case .typeMismatch(let type, let context):
            output = "typeMismatch \(type) - in \(context.debugDescription)"
        case .valueNotFound(let type, let context):
            output = "valueNotFound \(type) - \(context.debugDescription)"
        @unknown default:
            output = "unknown: \(localizedDescription)"
        }
        return "DecodingError: \(output)"
    }
}

extension EncodingError: PrettyStringConvertible {
    var prettyDescription: String {
        let output: String
        switch self {
        case .invalidValue(let value, let context):
            output = "invalidValue \(value) - \(context)"
        @unknown default:
            output = "unknown: \(localizedDescription)"
        }
        return "EncodingError: \(output)"
    }
}
