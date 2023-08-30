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

    /// Adds the provided URI snippet to the URL's query.
    ///
    /// Percent encoding is already applied.
    /// - Parameters:
    ///   - snippet: A full URI snippet.
    mutating func addEscapedQuerySnippet(_ snippet: String) {
        let prefix: String
        if let query {
            prefix = query + "&"
        } else {
            prefix = ""
        }
        query = prefix + snippet
    }
}

extension String {

    /// Returns the string with leading and trailing whitespace (such as spaces
    /// and newlines) removed.
    var trimmingLeadingAndTrailingSpaces: Self {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
