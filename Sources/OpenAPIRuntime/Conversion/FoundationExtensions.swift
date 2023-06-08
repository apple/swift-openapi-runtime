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
        var urlComponents: URLComponents = .init()
        if let query {
            urlComponents.percentEncodedQuery = query
        }
        try closure(&urlComponents)
        query = urlComponents.percentEncodedQuery
    }

    /// Allows modifying the parsed query parameters of the request.
    mutating func addQueryItem(name: String, value: String) {
        mutateQuery { urlComponents in
            urlComponents.addStringQueryItem(name: name, value: value)
        }
    }
}

extension URLComponents {

    /// Adds the provided name and value to the URL's query.
    mutating func addStringQueryItem(
        name: String,
        value: String
    ) {
        queryItems =
            (queryItems ?? []) + [
                .init(name: name, value: value)
            ]
    }
}
