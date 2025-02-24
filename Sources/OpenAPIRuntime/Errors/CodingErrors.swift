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
        case .dataCorrupted(let context): output = "dataCorrupted - \(context.prettyDescription)"
        case .keyNotFound(let key, let context): output = "keyNotFound \(key) - \(context.prettyDescription)"
        case .typeMismatch(let type, let context): output = "typeMismatch \(type) - \(context.prettyDescription)"
        case .valueNotFound(let type, let context): output = "valueNotFound \(type) - \(context.prettyDescription)"
        @unknown default: output = "unknown: \(self)"
        }
        return "DecodingError: \(output)"
    }
}

extension DecodingError.Context: PrettyStringConvertible {
    var prettyDescription: String {
        let path = codingPath.map(\.description).joined(separator: "/")
        return "at \(path): \(debugDescription) (underlying error: \(underlyingError.map { "\($0)" } ?? "<nil>"))"
    }
}

extension EncodingError: PrettyStringConvertible {
    var prettyDescription: String {
        let output: String
        switch self {
        case .invalidValue(let value, let context): output = "invalidValue \(value) - \(context.prettyDescription)"
        @unknown default: output = "unknown: \(self)"
        }
        return "EncodingError: \(output)"
    }
}

extension EncodingError.Context: PrettyStringConvertible {
    var prettyDescription: String {
        let path = codingPath.map(\.description).joined(separator: "/")
        return "at \(path): \(debugDescription) (underlying error: \(underlyingError.map { "\($0)" } ?? "<nil>"))"
    }
}
