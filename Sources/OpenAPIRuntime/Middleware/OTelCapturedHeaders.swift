//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2025 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if Logging && OTelSemanticConventions

public import HTTPTypes
import Logging

/// Define the strategy for the list of headers a Logging Middleware should collect.
public struct OTelCapturedHeaders: Sendable, Hashable {
    private enum Storage: Sendable, Hashable {
        case none
        case all
        case exclude(Set<HTTPField.Name>)
        case include(Set<HTTPField.Name>)
    }

    private let storage: Storage

    /// Captures no header fields.
    public static var none: OTelCapturedHeaders { OTelCapturedHeaders(storage: .none) }

    /// Captures every header field.
    ///
    /// - Important: This records the values of `Authorization`, `Cookie`, and `Set-Cookie`, among
    ///   others. Prefer naming the header fields to capture.
    public static var all: OTelCapturedHeaders { OTelCapturedHeaders(storage: .all) }

    /// Captures the named header fields.
    /// - Parameter names: The names of the header fields to capture.
    /// - Returns: A value that captures the named header fields, and no others.
    public static func include(_ names: Set<HTTPField.Name>) -> OTelCapturedHeaders {
        OTelCapturedHeaders(storage: names.isEmpty ? .none : .include(names))
    }

    /// Captures all headers except the named header fields.
    /// - Parameter names: The names of the header fields not to capture.
    /// - Returns: A value that does not capture the named header fields.
    public static func exclude(_ names: Set<HTTPField.Name>) -> OTelCapturedHeaders {
        OTelCapturedHeaders(storage: names.isEmpty ? .all : .exclude(names))
    }
}

extension OTelCapturedHeaders: ExpressibleByArrayLiteral {
    /// Captures the named header fields.
    /// - Parameter elements: The names of the header fields to capture.
    public init(arrayLiteral elements: HTTPField.Name...) { self = .include(Set(elements)) }
}

extension OTelCapturedHeaders {
    /// Attaches the logging metadata for the given `HTTPFields` according to the given configuration.
    /// - Parameters:
    ///   - fields: The header fields to capture from.
    ///   - prefix: The attribute name the field name is appended to, such as `http.request.header`.
    ///   - logger: The logger to attach metadata to.
    func addMetadata(for fields: HTTPFields, prefix: String, to logger: inout Logger) {
        // A name repeated across fields must produce a single attribute, so the fields are reduced
        // to their distinct names before the values of each are looked up.
        let names: Set<HTTPField.Name>

        switch self.storage {
        case .none: return
        case .all: names = Set(fields.map(\.name))
        case let .include(captured): names = captured
        case let .exclude(captured): names = Set(fields.filter { !captured.contains($0.name) }.map(\.name))
        }

        for name in names {
            let values = fields[values: name]
            guard !values.isEmpty else { continue }

            logger[metadataKey: "\(prefix).\(name.canonicalName)"] = .array(values.map { .string($0) })
        }
    }
}

#endif
