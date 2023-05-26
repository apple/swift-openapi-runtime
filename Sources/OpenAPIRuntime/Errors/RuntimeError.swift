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
import protocol Foundation.LocalizedError
import struct Foundation.Data

/// Error thrown by generated code.
internal enum RuntimeError: Error, CustomStringConvertible, LocalizedError, PrettyStringConvertible {

    // Miscs
    case invalidServerURL(String)

    // Headers
    case missingRequiredHeader(String)
    case unexpectedContentTypeHeader(String)
    case unexpectedAcceptHeader(String)
    case failedToEncodeJSONHeaderIntoString(name: String)

    // Path
    case missingRequiredPathParameter(String)
    case failedToDecodePathParameter(name: String, type: String)

    // Query
    case missingRequiredQueryParameter(String)
    case failedToDecodeQueryParameter(name: String, type: String)

    // Body
    case missingRequiredRequestBody
    case failedToEncodePrimitiveBodyIntoData
    case failedToDecodePrimitiveBodyFromData

    // Transport/Handler
    case transportFailed(Error)
    case handlerFailed(Error)

    // MARK: CustomStringConvertible

    var description: String {
        prettyDescription
    }

    var prettyDescription: String {
        switch self {
        case .invalidServerURL(let string):
            return "Invalid server URL: \(string)"
        case .missingRequiredHeader(let name):
            return "The required header named '\(name)' is missing."
        case .unexpectedContentTypeHeader(let contentType):
            return "Unexpected Content-Type header: \(contentType)"
        case .unexpectedAcceptHeader(let accept):
            return "Unexpected Accept header: \(accept)"
        case .failedToEncodeJSONHeaderIntoString(let name):
            return "Failed to encode JSON header named '\(name)' into a string"
        case .missingRequiredPathParameter(let name):
            return "Missing required path parameter named: \(name)"
        case .failedToDecodePathParameter(let name, let type):
            return "Failed to decode path parameter named '\(name)' to type \(type)."
        case .missingRequiredQueryParameter(let name):
            return "Missing required query parameter named: \(name)"
        case .failedToDecodeQueryParameter(let name, let type):
            return "Failed to decode query parameter named '\(name)' to type \(type)."
        case .missingRequiredRequestBody:
            return "Missing required request body"
        case .failedToEncodePrimitiveBodyIntoData:
            return "Failed to encode a primitive body into data"
        case .failedToDecodePrimitiveBodyFromData:
            return "Failed to decode a primitive body from data"
        case .transportFailed(let underlyingError):
            return "Transport failed with error: \(underlyingError.localizedDescription)"
        case .handlerFailed(let underlyingError):
            return "User handler failed with error: \(underlyingError.localizedDescription)"
        }
    }
}
