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
import HTTPTypes

/// Error thrown by generated code.
internal enum RuntimeError: Error, CustomStringConvertible, LocalizedError, PrettyStringConvertible {

    // Miscs
    case invalidServerURL(String)
    case invalidServerVariableValue(name: String, value: String, allowedValues: [String])
    case invalidExpectedContentType(String)
    case invalidAcceptSubstring(String)
    case invalidHeaderFieldName(String)
    case invalidBase64String(String)

    // Data conversion
    case failedToDecodeStringConvertibleValue(type: String)
    case missingCoderForCustomContentType(contentType: String)

    enum ParameterLocation: String, CustomStringConvertible {
        case query

        var description: String { rawValue }
    }
    case unsupportedParameterStyle(name: String, location: ParameterLocation, style: ParameterStyle, explode: Bool)

    // Headers
    case missingRequiredHeaderField(String)
    case unexpectedContentTypeHeader(expected: String, received: String)
    case unexpectedAcceptHeader(String)
    case malformedAcceptHeader(String)
    case missingOrMalformedContentDispositionName

    // Path
    case missingRequiredPathParameter(String)
    case pathUnset

    // Query
    case missingRequiredQueryParameter(String)

    // Body
    case missingRequiredRequestBody
    case missingRequiredResponseBody
    case failedToParseRequest(DecodingError)

    // Multipart
    case missingRequiredMultipartFormDataContentType
    case missingMultipartBoundaryContentTypeParameter

    // Transport/Handler
    case transportFailed(any Error)
    case middlewareFailed(middlewareType: Any.Type, any Error)
    case handlerFailed(any Error)

    // Unexpected response (thrown by shorthand APIs)
    case unexpectedResponseStatus(expectedStatus: String, response: any Sendable)
    case unexpectedResponseBody(expectedContent: String, body: any Sendable)

    /// A wrapped root cause error, if one was thrown by other code.
    var underlyingError: (any Error)? {
        switch self {
        case .transportFailed(let error), .handlerFailed(let error), .middlewareFailed(_, let error): return error
        case .failedToParseRequest(let decodingError): return decodingError
        default: return nil
        }
    }

    // MARK: CustomStringConvertible

    var description: String { prettyDescription }

    var prettyDescription: String {
        switch self {
        case .invalidServerURL(let string): return "Invalid server URL: \(string)"
        case .invalidServerVariableValue(name: let name, value: let value, allowedValues: let allowedValues):
            return
                "Invalid server variable named: '\(name)', which has the value: '\(value)', but the only allowed values are: \(allowedValues.map { "'\($0)'" }.joined(separator: ", "))"
        case .invalidExpectedContentType(let string): return "Invalid expected content type: '\(string)'"
        case .invalidAcceptSubstring(let string): return "Invalid Accept header content type: '\(string)'"
        case .invalidHeaderFieldName(let name): return "Invalid header field name: '\(name)'"
        case .invalidBase64String(let string):
            return "Invalid base64-encoded string (first 128 bytes): '\(string.prefix(128))'"
        case .failedToDecodeStringConvertibleValue(let string): return "Failed to decode a value of type '\(string)'."
        case .missingCoderForCustomContentType(let contentType):
            return "Missing custom coder for content type '\(contentType)'."
        case .unsupportedParameterStyle(name: let name, location: let location, style: let style, explode: let explode):
            return
                "Unsupported parameter style, parameter name: '\(name)', kind: \(location), style: \(style), explode: \(explode)"
        case .missingRequiredHeaderField(let name): return "The required header field named '\(name)' is missing."
        case .unexpectedContentTypeHeader(expected: let expected, received: let received):
            return "Unexpected content type, expected: \(expected), received: \(received)"
        case .unexpectedAcceptHeader(let accept): return "Unexpected Accept header: \(accept)"
        case .malformedAcceptHeader(let accept): return "Malformed Accept header: \(accept)"
        case .missingOrMalformedContentDispositionName:
            return "Missing or malformed Content-Disposition header or it's missing a name."
        case .missingRequiredPathParameter(let name): return "Missing required path parameter named: \(name)"
        case .pathUnset: return "Path was not set on the request."
        case .missingRequiredQueryParameter(let name): return "Missing required query parameter named: \(name)"
        case .missingRequiredRequestBody: return "Missing required request body"
        case .missingRequiredResponseBody: return "Missing required response body"
        case .missingRequiredMultipartFormDataContentType: return "Expected a 'multipart/form-data' content type."
        case .missingMultipartBoundaryContentTypeParameter:
            return "Missing 'boundary' parameter in the 'multipart/form-data' content type."
        case .transportFailed: return "Transport threw an error."
        case .middlewareFailed(middlewareType: let type, _): return "Middleware of type '\(type)' threw an error."
        case .handlerFailed: return "User handler threw an error."
        case .unexpectedResponseStatus(let expectedStatus, let response):
            return "Unexpected response, expected status code: \(expectedStatus), response: \(response)"
        case .unexpectedResponseBody(let expectedContentType, let body):
            return "Unexpected response body, expected content type: \(expectedContentType), body: \(body)"
        case .failedToParseRequest(let decodingError):
            return "An error occurred while attempting to parse the request: \(decodingError.prettyDescription)."
        }
    }

    // MARK: - LocalizedError

    var errorDescription: String? { description }
}

/// Throws an error to indicate an unexpected HTTP response status.
///
/// - Parameters:
///   - expectedStatus: The expected HTTP response status as a string.
///   - response: The HTTP response data.
/// - Throws: An error indicating an unexpected response status.
@_spi(Generated) public func throwUnexpectedResponseStatus(expectedStatus: String, response: any Sendable) throws
    -> Never
{ throw RuntimeError.unexpectedResponseStatus(expectedStatus: expectedStatus, response: response) }

/// Throws an error to indicate an unexpected response body content.
///
/// - Parameters:
///   - expectedContent: The expected content as a string.
///   - body: The response body data.
/// - Throws: An error indicating an unexpected response body content.
@_spi(Generated) public func throwUnexpectedResponseBody(expectedContent: String, body: any Sendable) throws -> Never {
    throw RuntimeError.unexpectedResponseBody(expectedContent: expectedContent, body: body)
}

/// HTTP Response status definition for ``RuntimeError``.
extension RuntimeError: HTTPResponseConvertible {
    /// HTTP Status code corresponding to each error case
    public var httpStatus: HTTPTypes.HTTPResponse.Status {
        switch self {
        case .invalidServerURL, .invalidServerVariableValue, .pathUnset: .notFound
        case .invalidExpectedContentType, .unexpectedContentTypeHeader: .unsupportedMediaType
        case .missingCoderForCustomContentType: .unprocessableContent
        case .unexpectedAcceptHeader: .notAcceptable
        case .failedToDecodeStringConvertibleValue, .invalidAcceptSubstring, .invalidBase64String,
            .invalidHeaderFieldName, .malformedAcceptHeader, .missingMultipartBoundaryContentTypeParameter,
            .missingOrMalformedContentDispositionName, .missingRequiredHeaderField,
            .missingRequiredMultipartFormDataContentType, .missingRequiredQueryParameter, .missingRequiredPathParameter,
            .missingRequiredRequestBody, .unsupportedParameterStyle, .failedToParseRequest:
            .badRequest
        case .handlerFailed, .middlewareFailed, .missingRequiredResponseBody, .transportFailed,
            .unexpectedResponseStatus, .unexpectedResponseBody:
            .internalServerError
        }
    }
}
