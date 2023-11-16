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
import HTTPTypes

/// A raw multipart part containing the header fields and the body stream.
public struct MultipartRawPart: Sendable, Hashable {

    /// The header fields contained in this part, such as `content-disposition`.
    public var headerFields: HTTPFields

    /// The body stream of this part.
    public var body: HTTPBody

    /// Creates a new part.
    /// - Parameters:
    ///   - headerFields: The header fields contained in this part, such as `content-disposition`.
    ///   - body: The body stream of this part.
    public init(headerFields: HTTPFields, body: HTTPBody) {
        self.headerFields = headerFields
        self.body = body
    }
}
