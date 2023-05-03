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

extension HeaderField: CustomStringConvertible {
    public var description: String {
        let value: String
        if HeaderField.redactedHeaderFields.contains(name.lowercased()) {
            value = "<redacted>"
        } else {
            value = self.value
        }
        return "\(name): \(value)"
    }
}

extension Request: CustomStringConvertible {
    public var description: String {
        "path: \(path), query: \(query ?? "<nil>"), method: \(method), header fields: \(headerFields.description), body (prefix): \(body?.prettyPrefix ?? "<nil>")"
    }
}

extension Response: CustomStringConvertible {
    public var description: String {
        "status: \(statusCode), header fields: \(headerFields.description), body: \(body.prettyPrefix)"
    }
}

extension ServerRequestMetadata: CustomStringConvertible {
    public var description: String {
        "path parameters: \(pathParameters.description), query parameters: \(queryParameters.description)"
    }
}
