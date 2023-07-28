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

/// A wrapper of a body value with its content type.
@_spi(Generated)
@available(*, deprecated)
public struct EncodableBodyContent<T: Equatable>: Equatable {

    /// An encodable body value.
    public var value: T

    /// The header value of the content type, for example `application/json`.
    public var contentType: String

    /// Creates a new content wrapper.
    /// - Parameters:
    ///   - value: An encodable body value.
    ///   - contentType: The header value of the content type.
    public init(
        value: T,
        contentType: String
    ) {
        self.value = value
        self.contentType = contentType
    }
}
