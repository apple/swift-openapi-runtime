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
import XCTest
@_spi(Generated) import OpenAPIRuntime

final class Test_OpenAPIMIMEType: Test_Runtime {
    func test() throws {
        let cases: [(String, OpenAPIMIMEType?, String?)] = [

            // Common
            (
                "application/json",
                OpenAPIMIMEType(kind: .concrete(type: "application", subtype: "json")),
                "application/json"
            ),

            // Subtype wildcard
            (
                "application/*",
                OpenAPIMIMEType(kind: .anySubtype(type: "application")),
                "application/*"
            ),

            // Type wildcard
            (
                "*/*",
                OpenAPIMIMEType(kind: .any),
                "*/*"
            ),

            // Common with a parameter
            (
                "application/json; charset=UTF-8",
                OpenAPIMIMEType(
                    kind: .concrete(type: "application", subtype: "json"),
                    parameters: [
                        "charset": "UTF-8"
                    ]
                ),
                "application/json; charset=UTF-8"
            ),

            // Common with two parameters
            (
                "application/json; charset=UTF-8; boundary=1234",
                OpenAPIMIMEType(
                    kind: .concrete(type: "application", subtype: "json"),
                    parameters: [
                        "charset": "UTF-8",
                        "boundary": "1234",
                    ]
                ),
                "application/json; boundary=1234; charset=UTF-8"
            ),

            // Common case preserving, but case insensitive equality
            (
                "APPLICATION/JSON;CHARSET=UTF-8",
                OpenAPIMIMEType(
                    kind: .concrete(type: "application", subtype: "json"),
                    parameters: [
                        "charset": "UTF-8"
                    ]
                ),
                "APPLICATION/JSON; CHARSET=UTF-8"
            ),

            // Invalid
            ("application", nil, nil),
            ("application/foo/bar", nil, nil),
            ("", nil, nil),
        ]
        for (inputString, expectedMIME, outputString) in cases {
            let mime = OpenAPIMIMEType(inputString)
            XCTAssertEqual(mime, expectedMIME)
            XCTAssertEqual(mime?.description, outputString)
        }
    }
}
