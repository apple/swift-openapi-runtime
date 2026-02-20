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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import XCTest
@_spi(Generated) @testable import OpenAPIRuntime

final class Test_MultipartBody: XCTestCase {

    func testIterationBehavior_single() async throws {
        let sourceSequence = (0..<Int.random(in: 2..<10)).map { _ in UUID().uuidString }
        let body = MultipartBody(sourceSequence, iterationBehavior: .single)

        XCTAssertFalse(body.testing_iteratorCreated)

        let iterated = try await body.reduce("") { $0 + $1 }
        XCTAssertEqual(iterated, sourceSequence.joined())

        XCTAssertTrue(body.testing_iteratorCreated)

        do {
            for try await _ in body {}
            XCTFail("Expected an error to be thrown")
        } catch {}
    }

    func testIterationBehavior_multiple() async throws {
        let sourceSequence = (0..<Int.random(in: 2..<10)).map { _ in UUID().uuidString }
        let body = MultipartBody(sourceSequence, iterationBehavior: .multiple)

        XCTAssertFalse(body.testing_iteratorCreated)
        for _ in 0..<2 {
            let iterated = try await body.reduce("") { $0 + $1 }
            XCTAssertEqual(iterated, sourceSequence.joined())
            XCTAssertTrue(body.testing_iteratorCreated)
        }
    }

}
