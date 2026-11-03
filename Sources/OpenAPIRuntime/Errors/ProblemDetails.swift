//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A model representing RFC 9457 problem details for HTTP error responses.
internal struct ProblemDetails: Encodable {
    /// The type of the problem, defining RFC 9457 fields common to all instances of that problem type.
    enum ProblemType {

        /// Extra metadata about the "Response content type not acceptable" error.
        struct ResponseContentTypeNotAcceptableExtras: Encodable {

            /// The content type of the response that the server tried to send.
            var responseContentType: String

            /// The content types listed in the request's Accept header field, without parameters.
            var acceptableContentTypes: [String]
        }

        /// An error indicating that the content type of the response isn't acceptable
        /// according to the request's Accept header field.
        case responseContentTypeNotAcceptable(ResponseContentTypeNotAcceptableExtras)

        /// The unique URL stub that identifies the problem type.
        ///
        /// Must match the file name of the problem type's article in the `ProblemDetails` documentation folder.
        var urlStub: String {
            switch self {
            case .responseContentTypeNotAcceptable: "response-content-type-not-acceptable"
            }
        }

        /// The unique URL that identifies the problem type, pointing to its documentation page.
        var type: URL {
            let documentationBaseURL =
                "https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime"
            return URL(string: "\(documentationBaseURL)/\(urlStub)")!
        }

        /// A short human-readable description of the problem type.
        var title: String {
            switch self {
            case .responseContentTypeNotAcceptable: "Response content type not acceptable"
            }
        }

        /// Additional data specific to the problem type.
        var extras: (any Encodable)? {
            switch self {
            case let .responseContentTypeNotAcceptable(extras): extras
            }
        }
    }

    /// The encoder used to serialize problem details into an HTTP response body.
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes, .prettyPrinted]
        return encoder
    }()

    /// The problem type.
    let problemType: ProblemType

    /// A human-readable explanation specific to this occurrence of the problem.
    let detail: String

    /// The HTTP status for this occurrence of the problem.
    let status: Int

    /// The coding keys for the standard RFC 9457 members.
    private enum CodingKeys: String, CodingKey { 
        case type
        case status
        case title
        case detail
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(problemType.type, forKey: .type)
        try container.encode(status, forKey: .status)
        try container.encode(problemType.title, forKey: .title)
        try container.encode(detail, forKey: .detail)

        if let extras = problemType.extras { try extras.encode(to: encoder) }
    }
}
