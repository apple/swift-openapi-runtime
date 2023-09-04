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
import protocol Foundation.LocalizedError

public struct ServerError: Error {

    public var operationID: String

    public var request: HTTPRequest

    public var requestBody: HTTPBody?

    public var operationInput: (any Sendable)?

    public var operationOutput: (any Sendable)?

    public var underlyingError: any Error

    public init(
        operationID: String,
        request: HTTPRequest,
        requestBody: HTTPBody?,
        operationInput: (any Sendable)? = nil,
        operationOutput: (any Sendable)? = nil,
        underlyingError: (any Error)
    ) {
        self.operationID = operationID
        self.request = request
        self.requestBody = requestBody
        self.operationInput = operationInput
        self.operationOutput = operationOutput
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

// TODO: Make pretty printable (except the body)

extension ServerError: CustomStringConvertible {
    public var description: String {
        "Server error - operationID: \(operationID), underlying error: \(underlyingErrorDescription)"
    }
}

extension ServerError: LocalizedError {
    public var errorDescription: String? {
        description
    }
}
