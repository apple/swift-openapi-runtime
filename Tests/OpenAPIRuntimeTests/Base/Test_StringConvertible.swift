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
@_spi(Generated)@testable import OpenAPIRuntime

final class Test_StringConvertible: XCTestCase {

    func testConformances() throws {
        let values: [(any _StringConvertible, String)] = [
            ("hello" as String, "hello"),
            (1 as Int, "1"),
            (1 as Int32, "1"),
            (1 as Int64, "1"),
            (0.5 as Float, "0.5"),
            (0.5 as Double, "0.5"),
            (true as Bool, "true"),
        ]
        for (value, stringified) in values {
            XCTAssertEqual(value.description, stringified)
        }
    }
}
