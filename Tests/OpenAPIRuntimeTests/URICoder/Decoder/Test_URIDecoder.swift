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

final class Test_URIDecoder: Test_Runtime {

    func testDecoding() throws {
        struct Foo: Decodable, Equatable {
            var bar: String
        }
        let decoder = URIDecoder(configuration: .formDataExplode)
        let decodedValue = try decoder.decode(
            Foo.self, 
            forKey: "",
            from: "bar=hello+world"
        )
        XCTAssertEqual(decodedValue, Foo(bar: "hello world"))
    }
}
