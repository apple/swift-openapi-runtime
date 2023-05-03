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
import OpenAPIRuntime

final class Test_CurrencyTypes: Test_Runtime {

    func _resetRedactedHeaderFields() {
        HeaderField.redactedHeaderFields = HeaderField.defaultRedactedHeaderFields
    }

    func _test(unredactedNames: Set<String>, redactedNames: Set<String>) {
        for name in unredactedNames.sorted() {
            XCTAssertEqual(
                HeaderField(name: name, value: "cleartext").description,
                "\(name): cleartext"
            )
        }
        for name in redactedNames.sorted() {
            XCTAssertEqual(
                HeaderField(name: name, value: "cleartext").description,
                "\(name): <redacted>"
            )
        }
    }

    override func tearDown() async throws {
        _resetRedactedHeaderFields()
        try await super.tearDown()
    }

    func testDefaultRedactedHeaderFields() {
        XCTAssertEqual(
            HeaderField.redactedHeaderFields,
            ["authorization", "cookie", "set-cookie"]
        )
        _test(
            unredactedNames: ["x-secret", "x-not-secret"],
            redactedNames: ["authorization", "cookie", "set-cookie"]
        )
    }

    func testCustomizeExtraRedactedHeaderField() {
        XCTAssertEqual(
            HeaderField.redactedHeaderFields,
            ["authorization", "cookie", "set-cookie"]
        )
        _test(
            unredactedNames: ["x-secret", "x-not-secret"],
            redactedNames: ["authorization", "cookie", "set-cookie"]
        )
        HeaderField.redactedHeaderFields.insert("x-secret")
        XCTAssertEqual(
            HeaderField.redactedHeaderFields,
            ["authorization", "cookie", "set-cookie", "x-secret"]
        )
        _test(
            unredactedNames: ["x-not-secret"],
            redactedNames: ["authorization", "cookie", "set-cookie", "x-secret"]
        )
        HeaderField.redactedHeaderFields.remove("authorization")
        XCTAssertEqual(
            HeaderField.redactedHeaderFields,
            ["cookie", "set-cookie", "x-secret"]
        )
        _test(
            unredactedNames: ["x-not-secret", "authorization"],
            redactedNames: ["cookie", "set-cookie", "x-secret"]
        )
    }
}
