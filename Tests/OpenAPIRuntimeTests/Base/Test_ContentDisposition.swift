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
@_spi(Generated) @testable import OpenAPIRuntime

final class Test_ContentDisposition: Test_Runtime {

    func testParsing() {
        func _test(
            input: String,
            parsed: ContentDisposition?,
            output: String?,
            file: StaticString = #file,
            line: UInt = #line
        ) {
            let value = ContentDisposition(rawValue: input)
            XCTAssertEqual(value, parsed, file: file, line: line)
            XCTAssertEqual(value?.rawValue, output, file: file, line: line)
        }

        // Common
        _test(input: "form-data", parsed: ContentDisposition(dispositionType: .formData), output: "form-data")
        // With an unquoted name parameter.
        _test(
            input: "form-data; name=Foo",
            parsed: ContentDisposition(dispositionType: .formData, parameters: [.name: "Foo"]),
            output: "form-data; name=\"Foo\""
        )

        // With a quoted name parameter.
        _test(
            input: "form-data; name=\"Foo\"",
            parsed: ContentDisposition(dispositionType: .formData, parameters: [.name: "Foo"]),
            output: "form-data; name=\"Foo\""
        )

        // With quoted name and filename parameters.
        _test(
            input: "form-data; name=\"Foo\"; filename=\"foo.txt\"",
            parsed: ContentDisposition(dispositionType: .formData, parameters: [.name: "Foo", .filename: "foo.txt"]),
            output: "form-data; filename=\"foo.txt\"; name=\"Foo\""
        )

        // With an unknown parameter.
        _test(
            input: "form-data; bar=\"Foo\"",
            parsed: ContentDisposition(dispositionType: .formData, parameters: [.other("bar"): "Foo"]),
            output: "form-data; bar=\"Foo\""
        )

        // Other
        _test(
            input: "attachment",
            parsed: ContentDisposition(dispositionType: .other("attachment")),
            output: "attachment"
        )

        // Empty
        _test(input: "", parsed: nil, output: nil)
    }
    func testAccessors() {
        var value = ContentDisposition(dispositionType: .formData, parameters: [.name: "Foo"])
        XCTAssertEqual(value.name, "Foo")
        XCTAssertNil(value.filename)
        value.name = nil
        XCTAssertNil(value.name)
        XCTAssertNil(value.filename)
        value.name = "Foo2"
        value.filename = "foo.txt"
        XCTAssertEqual(value.name, "Foo2")
        XCTAssertEqual(value.filename, "foo.txt")
        XCTAssertEqual(value.rawValue, "form-data; filename=\"foo.txt\"; name=\"Foo2\"")
    }
}
