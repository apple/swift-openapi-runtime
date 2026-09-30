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
@_spi(Generated) import OpenAPIRuntime
import HTTPTypes

final class Test_CurrencyTypes: Test_Runtime {

    func testQuery() {
        let cases: [(path: String, query: Substring?)] = [
            ("/pets", nil), ("/pets?", ""), ("/pets?a=1", "a=1"), ("/pets?a=1&b=2", "a=1&b=2"),
            ("/pets?a=1#frag", "a=1"), ("/pets?a=1#frag?x", "a=1"),
            // A question mark inside the fragment doesn't start a query.
            ("/pets#frag", nil), ("/pets#x?y", nil), ("/a#?", nil),
        ]
        for (path, query) in cases {
            let request = HTTPRequest(soar_path: path, method: .get)
            XCTAssertEqual(request.soar_query, query, "Path: \(path)")
        }
    }

    func testPathOnly() {
        let cases: [(path: String, pathOnly: Substring)] = [
            ("/pets", "/pets"), ("/pets?a=1", "/pets"), ("/pets?a=1#frag", "/pets"), ("/pets#frag", "/pets"),
            ("/pets#x?y", "/pets"),
        ]
        for (path, pathOnly) in cases {
            let request = HTTPRequest(soar_path: path, method: .get)
            XCTAssertEqual(request.soar_pathOnly, pathOnly, "Path: \(path)")
        }
    }
}
