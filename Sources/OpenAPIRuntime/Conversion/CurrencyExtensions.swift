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

extension Array where Element == HeaderField {

    /// Adds a header for the provided name and value.
    /// - Parameters:
    ///   - name: Header name.
    ///   - value: Header value. If nil, the header is not added.
    mutating func add(name: String, value: String?) {
        guard let value = value else {
            return
        }
        append(.init(name: name, value: value))
    }
    
    /// Adds headers for the provided name and values.
    /// - Parameters:
    ///   - name: Header name.
    ///   - value: Header values.
    mutating func add(name: String, values: [String]?) {
        guard let values = values else {
            return
        }
        for value in values {
            append(.init(name: name, value: value))
        }
    }

    /// Removes all headers matching the provided (case-insensitive) name.
    /// - Parameters:
    ///   - name: Header name.
    mutating func removeAll(named name: String) {
        removeAll {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    /// Returns the first header value for the provided (case-insensitive) name.
    /// - Parameter name: Header name.
    /// - Returns: First value for the given name. Nil if one does not exist.
    func firstValue(name: String) -> String? {
        first { $0.name.caseInsensitiveCompare(name) == .orderedSame }?.value
    }

    /// Returns all header values for the given (case-insensitive) name.
    /// - Parameter name: Header name.
    /// - Returns: All values for the given name, might be empty if none are found.
    func values(name: String) -> [String] {
        filter { $0.name.caseInsensitiveCompare(name) == .orderedSame }.map { $0.value }
    }
}
