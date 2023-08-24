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
    var pretty: String {
        String(decoding: self, as: UTF8.self)
    }

    /// Returns a prefix of a pretty representation of the Data.
    var prettyPrefix: String {
        prefix(256).pretty
    }
}

extension Request {
    /// Allows modifying the parsed query parameters of the request.
    mutating func mutateQuery(_ closure: (inout URLComponents) throws -> Void) rethrows {
        var urlComponents = URLComponents()
        if let query {
            urlComponents.percentEncodedQuery = query
        }
        try closure(&urlComponents)
        query = urlComponents.percentEncodedQuery
    }

    /// Adds the provided name and value to the URL's query.
    /// - Parameters:
    ///   - name: The name of the query item.
    ///   - value: The value of the query item.
    ///   - explode: A Boolean value indicating whether query items with the
    ///   same name should be provided as separate key-value pairs (`true`) or
    ///   if all the values for one key should be concatenated with a comma
    ///   and provided as a single key-value pair (`false`).
    mutating func addQueryItem(name: String, value: String, explode: Bool) {
        mutateQuery { urlComponents in
            urlComponents.addStringQueryItem(
                name: name,
                value: value,
                explode: explode
            )
        }
    }
}

extension URLComponents {

    /// Adds the provided name and value to the URL's query.
    /// - Parameters:
    ///   - name: The name of the query item.
    ///   - value: The value of the query item.
    ///   - explode: A Boolean value indicating whether query items with the
    ///   same name should be provided as separate key-value pairs (`true`) or
    ///   if all the values for one key should be concatenated with a comma
    ///   and provided as a single key-value pair (`false`).
    mutating func addStringQueryItem(
        name: String,
        value: String,
        explode: Bool
    ) {
        if explode {
            queryItems =
                (queryItems ?? []) + [
                    .init(name: name, value: value)
                ]
            return
        }
        // When explode is false, we need to collect all the potential existing
        // values from the array with the same name, add the new one, and
        // concatenate them with a comma.
        let originalQueryItems = queryItems ?? []
        struct GroupedQueryItems {
            var matchingValues: [String] = []
            var otherItems: [URLQueryItem] = []
        }
        let groups =
            originalQueryItems
            .reduce(into: GroupedQueryItems()) { partialResult, item in
                if item.name == name {
                    partialResult.matchingValues.append(item.value ?? "")
                } else {
                    partialResult.otherItems.append(item)
                }
            }
        let newItem = URLQueryItem(
            name: name,
            value: (groups.matchingValues + [value]).joined(separator: ",")
        )
        queryItems = groups.otherItems + [newItem]
    }
}

extension String {

    /// Returns the string with leading and trailing whitespace (such as spaces
    /// and newlines) removed.
    var trimmingLeadingAndTrailingSpaces: Self {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
