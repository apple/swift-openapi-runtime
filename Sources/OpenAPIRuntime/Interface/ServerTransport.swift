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

import HTTPTypes

public protocol ServerTransport {

    func register(
        _ handler: @Sendable @escaping (HTTPRequest, HTTPBody?) async throws -> (HTTPResponse, HTTPBody),
        method: HTTPRequest.Method,
        path: String
    ) throws
}

public protocol ServerMiddleware: Sendable {

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?) async throws -> (HTTPResponse, HTTPBody)
    ) async throws -> (HTTPResponse, HTTPBody)
}
