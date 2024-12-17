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

public import HTTPTypes

/// A payload value used by undocumented operation responses.
///
/// Each operation's `Output` enum type needs to exhaustively
/// cover all the possible HTTP response status codes, so when
/// not all are defined by the user in the OpenAPI document, an extra
/// `undocumented` enum case is used when such a status code is
/// detected.
public struct UndocumentedPayload: Sendable, Hashable {

    /// The header fields contained in the response.
    public var headerFields: HTTPFields

    /// The body stream of this part, if present.
    public var body: HTTPBody?

    /// Creates a new part.
    /// - Parameters:
    ///   - headerFields: The header fields contained in the response.
    ///   - body: The body stream of this part, if present.
    public init(headerFields: HTTPFields = [:], body: HTTPBody? = nil) {
        self.headerFields = headerFields
        self.body = body
    }
}
