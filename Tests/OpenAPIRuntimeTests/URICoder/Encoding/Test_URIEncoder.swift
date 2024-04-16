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
@testable import OpenAPIRuntime

final class Test_URIEncoder: Test_Runtime {

    func testEncoding() throws {
        struct Foo: Encodable { var bar: String }
        let serializer = URISerializer(configuration: .formDataExplode)
        let encoder = URIEncoder(serializer: serializer)
        let encodedString = try encoder.encode(Foo(bar: "hello world"), forKey: "root")
        XCTAssertEqual(encodedString, "bar=hello+world")
    }
    func testNestedEncoding() throws {
        struct Foo: Encodable { var bar: String }
        let serializer = URISerializer(configuration: .deepObjectExplode)
        let encoder = URIEncoder(serializer: serializer)
        let encodedString = try encoder.encode(Foo(bar: "hello world"), forKey: "root")
        XCTAssertEqual(encodedString, "root%5Bbar%5D=hello%20world")
    }
}
