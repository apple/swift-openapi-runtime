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
import Foundation

final class Test_MultipartBoundaryGenerator: Test_Runtime {

    func testConstant() throws {
        let generator = ConstantMultipartBoundaryGenerator(boundary: "__abcd__")
        let firstBoundary = generator.makeBoundary()
        let secondBoundary = generator.makeBoundary()
        XCTAssertEqual(firstBoundary, "__abcd__")
        XCTAssertEqual(secondBoundary, "__abcd__")
    }

    func testRandom() throws {
        let generator = RandomMultipartBoundaryGenerator(boundaryPrefix: "__abcd__", randomNumberSuffixLenght: 8)
        let firstBoundary = generator.makeBoundary()
        let secondBoundary = generator.makeBoundary()
        XCTAssertNotEqual(firstBoundary, secondBoundary)
        XCTAssertTrue(firstBoundary.hasPrefix("__abcd__"))
        XCTAssertTrue(secondBoundary.hasPrefix("__abcd__"))
    }
}
