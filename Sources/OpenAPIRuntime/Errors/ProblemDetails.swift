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
        case unexpectedAcceptHeader(expected: [String], received: [String])

        /// The unique URL that identifies the problem type.
        var type: URL {
            switch self {
            case .unexpectedAcceptHeader:
                URL(string:  "https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/swift-openapi-runtime/problemdetails/unexpected-accept-header")!
            }
        }

        /// A short human-readable description of the problem type.
        var title: String {
            switch self {
            case .unexpectedAcceptHeader:
                "Unexpected Accept header"
            }
        }

        /// Additional data specific to the problem type.
        var extras: (any Encodable)? {
            switch self {
            case let .unexpectedAcceptHeader(expected, received):
                ["expectedContentTypes": expected, "receivedContentTypes": received]
            }
        }
    }

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return encoder
    }()

    /// The problem type.
    let problemType: ProblemType
    /// A human-readable explanation specific to this occurrence of the problem.
    let detail: String
    /// The HTTP status for this occurrence of the problem.
    let status: Int

    private enum CodingKeys: String, CodingKey {
        case type, status, title, detail
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(problemType.type, forKey: .type)
        try container.encode(status, forKey: .status)
        try container.encode(problemType.title, forKey: .title)
        try container.encode(detail, forKey: .detail)

        if let extras = problemType.extras {
            try extras.encode(to: encoder)
        }
    }
}
