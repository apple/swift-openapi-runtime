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

extension Data {
    /// Returns a pretty representation of the Data.
    ///
    /// First tries to decode it as UTF-8, if that fails, tries ASCII,
    /// if that fails too, stringifies the value itself.
    var pretty: String {
        String(data: self, encoding: .utf8) ?? String(data: self, encoding: .ascii) ?? String(describing: self)
    }

    /// Returns a prefix of a pretty representation of the Data.
    var prettyPrefix: String {
        prefix(256).pretty
    }
}

extension Request {
    /// Allows modifying the parsed query parameters of the request.
    mutating func mutatingQuery(_ closure: (inout URLComponents) throws -> Void) rethrows {
        var urlComponents: URLComponents = .init()
        if let query {
            urlComponents.percentEncodedQuery = query
        }
        try closure(&urlComponents)
        query = urlComponents.percentEncodedQuery
    }
}

extension URLComponents {
    /// Adds a query item using the provided name and typed value.
    /// - Parameters:
    ///   - name: Query name.
    ///   - value: Typed value.
    mutating func addQueryItem<T: _StringParameterConvertible>(
        name: String,
        value: T?
    ) {
        guard let value = value else {
            return
        }
        queryItems =
            (queryItems ?? []) + [
                .init(name: name, value: value.description)
            ]
    }

    /// Adds query items using the provided name and typed values.
    /// - Parameters:
    ///   - name: Query name.
    ///   - value: Array of typed values.
    mutating func addQueryItem<T: _StringParameterConvertible>(
        name: String,
        value: [T]?
    ) {
        guard let items = value else {
            return
        }
        for item in items {
            addQueryItem(name: name, value: item)
        }
    }
}
