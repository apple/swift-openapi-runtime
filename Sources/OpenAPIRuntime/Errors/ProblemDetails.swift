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
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return encoder
    }()

    let type: String = "about:blank"
    let status: Int
    let title: String
    let details: String
    let extras: (any Encodable)?

    private enum CodingKeys: String, CodingKey {
        case type, status, title, details
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(status, forKey: .status)
        try container.encode(title, forKey: .title)
        try container.encode(details, forKey: .details)

        if let extras {
            try extras.encode(to: encoder)
        }
    }
}
