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

#if canImport(Darwin)
import Foundation
#else
@preconcurrency import struct Foundation.URL
@preconcurrency import protocol Foundation.LocalizedError
#endif

public struct ClientError: Error {

    public var operationID: String

    public var operationInput: any Sendable

    public var request: HTTPRequest?

    public var requestBody: HTTPBody?

    public var baseURL: URL?

    public var response: HTTPResponse?

    public var responseBody: HTTPBody?

    public var underlyingError: any Error

    public init(
        operationID: String,
        operationInput: any Sendable,
        request: HTTPRequest? = nil,
        requestBody: HTTPBody? = nil,
        baseURL: URL? = nil,
        response: HTTPResponse? = nil,
        responseBody: HTTPBody? = nil,
        underlyingError: any Error
    ) {
        self.operationID = operationID
        self.operationInput = operationInput
        self.request = request
        self.requestBody = requestBody
        self.baseURL = baseURL
        self.response = response
        self.responseBody = responseBody
        self.underlyingError = underlyingError
    }

    // MARK: Private

    fileprivate var underlyingErrorDescription: String {
        guard let prettyError = underlyingError as? (any PrettyStringConvertible) else {
            return underlyingError.localizedDescription
        }
        return prettyError.prettyDescription
    }
}

// TODO: Adopt pretty descriptions here (except the bodies).

extension ClientError: CustomStringConvertible {
    public var description: String {
        // TODO: Bring back all the fields for easier debugging.
        "Client error - operationID: \(operationID), underlying error: \(underlyingErrorDescription)"
    }
}

extension ClientError: LocalizedError {
    public var errorDescription: String? {
        description
    }
}
