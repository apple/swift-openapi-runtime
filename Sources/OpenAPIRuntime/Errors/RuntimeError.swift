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
    case invalidExpectedContentType(String)
    case invalidHeaderFieldName(String)
    case invalidBase64String(String)

    // Data conversion
    case failedToDecodeStringConvertibleValue(type: String)

    enum ParameterLocation: String, CustomStringConvertible {
        case query

        var description: String {
            rawValue
        }
    }
    case unsupportedParameterStyle(name: String, location: ParameterLocation, style: ParameterStyle, explode: Bool)

    // Headers
    case missingRequiredHeaderField(String)
    case unexpectedContentTypeHeader(String)
    case unexpectedAcceptHeader(String)
    case malformedAcceptHeader(String)

    // Path
    case missingRequiredPathParameter(String)
    case pathUnset

    // Query
    case missingRequiredQueryParameter(String)

    // Body
    case missingRequiredRequestBody
    case missingRequiredResponseBody

    // Transport/Handler
    case transportFailed(any Error)
    case handlerFailed(any Error)

    // Unexpected response (thrown by shorthand APIs)
    case unexpectedResponseStatus(expectedStatus: String, response: any Sendable)
    case unexpectedResponseBody(expectedContent: String, body: any Sendable)

    // MARK: CustomStringConvertible

    var description: String {
        prettyDescription
    }

    var prettyDescription: String {
        switch self {
        case .invalidServerURL(let string):
            return "Invalid server URL: \(string)"
        case .invalidExpectedContentType(let string):
            return "Invalid expected content type: '\(string)'"
        case .invalidHeaderFieldName(let name):
            return "Invalid header field name: '\(name)'"
        case .invalidBase64String(let string):
            return "Invalid base64-encoded string (first 128 bytes): '\(string.prefix(128))'"
        case .failedToDecodeStringConvertibleValue(let string):
            return "Failed to decode a value of type '\(string)'."
        case .unsupportedParameterStyle(name: let name, location: let location, style: let style, explode: let explode):
            return
                "Unsupported parameter style, parameter name: '\(name)', kind: \(location), style: \(style), explode: \(explode)"
        case .missingRequiredHeaderField(let name):
            return "The required header field named '\(name)' is missing."
        case .unexpectedContentTypeHeader(let contentType):
            return "Unexpected Content-Type header: \(contentType)"
        case .unexpectedAcceptHeader(let accept):
            return "Unexpected Accept header: \(accept)"
        case .malformedAcceptHeader(let accept):
            return "Malformed Accept header: \(accept)"
        case .missingRequiredPathParameter(let name):
            return "Missing required path parameter named: \(name)"
        case .pathUnset:
            return "Path was not set on the request."
        case .missingRequiredQueryParameter(let name):
            return "Missing required query parameter named: \(name)"
        case .missingRequiredRequestBody:
            return "Missing required request body"
        case .missingRequiredResponseBody:
            return "Missing required response body"
        case .transportFailed(let underlyingError):
            return "Transport failed with error: \(underlyingError.localizedDescription)"
        case .handlerFailed(let underlyingError):
            return "User handler failed with error: \(underlyingError.localizedDescription)"
        case .unexpectedResponseStatus(let expectedStatus, let response):
            return "Unexpected response, expected status code: \(expectedStatus), response: \(response)"
        case .unexpectedResponseBody(let expectedContentType, let body):
            return "Unexpected response body, expected content type: \(expectedContentType), body: \(body)"
        }
    }
}

/// Throws an error to indicate an unexpected HTTP response status.
///
/// - Parameters:
///   - expectedStatus: The expected HTTP response status as a string.
///   - response: The HTTP response data.
/// - Throws: An error indicating an unexpected response status.
@_spi(Generated)
public func throwUnexpectedResponseStatus(expectedStatus: String, response: any Sendable) throws -> Never {
    throw RuntimeError.unexpectedResponseStatus(expectedStatus: expectedStatus, response: response)
}

/// Throws an error to indicate an unexpected response body content.
///
/// - Parameters:
///   - expectedContent: The expected content as a string.
///   - body: The response body data.
/// - Throws: An error indicating an unexpected response body content.
@_spi(Generated)
public func throwUnexpectedResponseBody(expectedContent: String, body: any Sendable) throws -> Never {
    throw RuntimeError.unexpectedResponseBody(expectedContent: expectedContent, body: body)
}
