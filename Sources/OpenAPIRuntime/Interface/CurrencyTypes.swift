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

/// A container for request metadata already parsed and validated
/// by the server transport.
public struct ServerRequestMetadata: Hashable, Sendable {

    /// The path parameters parsed from the URL of the HTTP request.
    public var pathParameters: [String: Substring]

    /// Creates a new metadata wrapper with the specified path and query parameters.
    /// - Parameters:
    ///   - pathParameters: Path parameters parsed from the URL of the HTTP
    ///   request.
    public init(
        pathParameters: [String: Substring] = [:]
    ) {
        self.pathParameters = pathParameters
    }
}
