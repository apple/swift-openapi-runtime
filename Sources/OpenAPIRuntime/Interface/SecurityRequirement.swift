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

/// A security requirement of an OpenAPI operation.
///
/// A security requirement is an *AND-group* of security schemes: to satisfy the
/// requirement, a request must satisfy *every* scheme in ``schemes``.
///
/// An operation carries an array of security requirements, which is an
/// *OR-group* of alternatives: satisfying any one requirement in the array
/// authorizes the request. An empty array (`[]`) means the operation explicitly
/// opts out of security and is public.
public struct SecurityRequirement: Sendable, Hashable {

    /// The security schemes that must all be satisfied to fulfill this requirement.
    public var schemes: [Scheme]

    /// Creates a new security requirement.
    /// - Parameter schemes: The security schemes that must all be satisfied.
    public init(schemes: [Scheme]) { self.schemes = schemes }

    /// A named security scheme used by an operation, together with the scopes
    /// the operation requires for it.
    public struct Scheme: Sendable, Hashable {

        /// The name of the security scheme, as declared in the OpenAPI
        /// document's `components.securitySchemes`.
        public var name: String

        /// The kind of the security scheme, describing how and where a
        /// credential is provided.
        public var kind: Kind

        /// The scopes the operation requires for this scheme.
        ///
        /// Meaningful only for ``Kind/oauth2`` and ``Kind/openIdConnect(url:)``
        /// schemes; empty for all others.
        public var scopes: [String]

        /// Creates a new security scheme reference.
        /// - Parameters:
        ///   - name: The name of the security scheme.
        ///   - kind: The kind of the security scheme.
        ///   - scopes: The scopes the operation requires for this scheme.
        public init(name: String, kind: Kind, scopes: [String]) {
            self.name = name
            self.kind = kind
            self.scopes = scopes
        }

        /// The kind of an OpenAPI security scheme.
        ///
        /// Models the security scheme types defined by the OpenAPI
        /// Specification. Describes the scheme definition — how a credential is
        /// carried — not the per-operation scopes, which live on
        /// ``Scheme/scopes``.
        public enum Kind: Sendable, Hashable {

            /// An API key carried in a header field, query item, or cookie.
            /// - Parameters:
            ///   - name: The name of the header field, query item, or cookie.
            ///   - location: Where the API key is carried in the request.
            case apiKey(name: String, location: Location)

            /// An HTTP authentication scheme, for example `basic` or `bearer`.
            /// - Parameters:
            ///   - scheme: The HTTP Authorization scheme, lowercased, for
            ///     example `bearer`.
            ///   - bearerFormat: A hint describing the bearer token format, if
            ///     provided by the document.
            case http(scheme: String, bearerFormat: String?)

            /// An OAuth 2.0 security scheme.
            ///
            /// The scopes the operation requires are carried on
            /// ``Scheme/scopes``.
            case oauth2

            /// An OpenID Connect security scheme.
            /// - Parameter url: The OpenID Connect discovery URL, as written in
            ///   the OpenAPI document.
            case openIdConnect(url: String)

            /// A mutual-TLS security scheme (OpenAPI 3.1).
            case mutualTLS
        }

        /// The location in an HTTP request where a security credential is carried.
        public enum Location: String, Sendable, Hashable {

            /// Carried in a URL query item.
            case query

            /// Carried in an HTTP header field.
            case header

            /// Carried in a cookie.
            case cookie
        }
    }
}
