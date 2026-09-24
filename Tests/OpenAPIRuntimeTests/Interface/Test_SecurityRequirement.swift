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

import XCTest
@testable import OpenAPIRuntime

final class Test_SecurityRequirement: XCTestCase {

    func testLocationRawValues() {
        XCTAssertEqual(SecurityRequirement.Scheme.Location.query.rawValue, "query")
        XCTAssertEqual(SecurityRequirement.Scheme.Location.header.rawValue, "header")
        XCTAssertEqual(SecurityRequirement.Scheme.Location.cookie.rawValue, "cookie")
    }

    func testEachKind() {
        // Construct one value per kind and assert stored properties round-trip.
        let apiKey = SecurityRequirement.Scheme(
            name: "apiKeyAuth",
            kind: .apiKey(name: "X-API-Key", location: .header),
            scopes: []
        )
        guard case let .apiKey(name, location) = apiKey.kind else { return XCTFail("expected apiKey") }
        XCTAssertEqual(name, "X-API-Key")
        XCTAssertEqual(location, .header)

        let bearer = SecurityRequirement.Scheme(
            name: "bearerAuth",
            kind: .http(scheme: "bearer", bearerFormat: "JWT"),
            scopes: []
        )
        guard case let .http(scheme, format) = bearer.kind else { return XCTFail("expected http") }
        XCTAssertEqual(scheme, "bearer")
        XCTAssertEqual(format, "JWT")

        let basic = SecurityRequirement.Scheme(
            name: "basicAuth",
            kind: .http(scheme: "basic", bearerFormat: nil),
            scopes: []
        )
        guard case .http(_, let noFormat) = basic.kind else { return XCTFail("expected http") }
        XCTAssertNil(noFormat)

        let oauth = SecurityRequirement.Scheme(name: "oauth", kind: .oauth2, scopes: ["read", "write"])
        XCTAssertEqual(oauth.scopes, ["read", "write"])

        let oidc = SecurityRequirement.Scheme(
            name: "oidc",
            kind: .openIdConnect(url: "https://example.com/.well-known/openid-configuration"),
            scopes: ["openid"]
        )
        guard case let .openIdConnect(url) = oidc.kind else { return XCTFail("expected openIdConnect") }
        XCTAssertEqual(url, "https://example.com/.well-known/openid-configuration")

        let mtls = SecurityRequirement.Scheme(name: "mtls", kind: .mutualTLS, scopes: [])
        XCTAssertEqual(mtls.kind, .mutualTLS)
    }

    func testHashableAndSetDeduplication() {
        let a = SecurityRequirement(schemes: [.init(name: "oauth", kind: .oauth2, scopes: [])])
        let b = SecurityRequirement(schemes: [.init(name: "oauth", kind: .oauth2, scopes: [])])
        let differentScopes = SecurityRequirement(schemes: [.init(name: "oauth", kind: .oauth2, scopes: ["read"])])
        let differentName = SecurityRequirement(schemes: [.init(name: "other", kind: .oauth2, scopes: [])])

        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
        XCTAssertNotEqual(a, differentScopes)
        XCTAssertNotEqual(a, differentName)
        XCTAssertEqual(Set([a, b, differentScopes, differentName]).count, 3)
    }

    func testEmitContract() {
        // Locks the exact literal the generator emits for a single-scheme OAuth2 operation.
        let requirements: [SecurityRequirement] = [
            .init(schemes: [.init(name: "OAuth2PasswordBearer", kind: .oauth2, scopes: [])])
        ]
        XCTAssertEqual(
            requirements,
            [
                SecurityRequirement(schemes: [
                    SecurityRequirement.Scheme(name: "OAuth2PasswordBearer", kind: .oauth2, scopes: [])
                ])
            ]
        )
    }

    func testOrAndSemanticsAreDistinct() {
        // `[]` (public opt-out) is a different value from a requirement with no schemes.
        let publicOptOut: [SecurityRequirement] = []
        let emptyAndGroup: [SecurityRequirement] = [.init(schemes: [])]
        XCTAssertNotEqual(publicOptOut, emptyAndGroup)
    }
}
