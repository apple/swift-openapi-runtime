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

enum TestAcceptable: AcceptableProtocol {
    case json
    case other(String)

    init?(rawValue: String) {
        switch rawValue {
        case "application/json":
            self = .json
        default:
            self = .other(rawValue)
        }
    }

    var rawValue: String {
        switch self {
        case .json:
            return "application/json"
        case .other(let string):
            return string
        }
    }

    static var allCases: [TestAcceptable] {
        [.json]
    }
}

final class Test_AcceptHeaderContentType: Test_Runtime {
    func test() throws {
        do {
            let contentType = AcceptHeaderContentType(contentType: TestAcceptable.json)
            XCTAssertEqual(contentType.contentType, .json)
            XCTAssertEqual(contentType.quality, 1.0)
            XCTAssertEqual(contentType.rawValue, "application/json")
            XCTAssertEqual(
                AcceptHeaderContentType<TestAcceptable>(rawValue: "application/json"),
                contentType
            )
        }
        do {
            let contentType = AcceptHeaderContentType(
                contentType: TestAcceptable.json,
                quality: 0.5
            )
            XCTAssertEqual(contentType.contentType, .json)
            XCTAssertEqual(contentType.quality, 0.5)
            XCTAssertEqual(contentType.rawValue, "application/json; q=0.500")
            XCTAssertEqual(
                AcceptHeaderContentType<TestAcceptable>(rawValue: "application/json; q=0.500"),
                contentType
            )
        }
        do {
            XCTAssertEqual(
                AcceptHeaderContentType<TestAcceptable>.defaultValues,
                [
                    .init(contentType: .json)
                ]
            )
        }
        do {
            let unsorted: [AcceptHeaderContentType<TestAcceptable>] = [
                .init(contentType: .other("*/*"), quality: 0.3),
                .init(contentType: .json, quality: 0.5),
            ]
            XCTAssertEqual(
                unsorted.sortedByQuality(),
                [
                    .init(contentType: .json, quality: 0.5),
                    .init(contentType: .other("*/*"), quality: 0.3),
                ]
            )
        }
    }
}

final class Test_QualityValue: Test_Runtime {
    func test() {
        XCTAssertEqual(QualityValue().doubleValue, 1.0)
        XCTAssertTrue(QualityValue().isDefault)
        XCTAssertFalse(QualityValue(doubleValue: 0.5).isDefault)
        XCTAssertEqual(QualityValue(doubleValue: 0.5).doubleValue, 0.5)
        XCTAssertEqual(QualityValue(floatLiteral: 0.5).doubleValue, 0.5)
        XCTAssertEqual(QualityValue(integerLiteral: 0).doubleValue, 0)
        XCTAssertEqual(QualityValue(rawValue: "1.0")?.doubleValue, 1.0)
        XCTAssertEqual(QualityValue(rawValue: "0.0")?.doubleValue, 0.0)
        XCTAssertEqual(QualityValue(rawValue: "0.3")?.doubleValue, 0.3)
        XCTAssertEqual(QualityValue(rawValue: "0.5")?.rawValue, "0.500")
        XCTAssertNil(QualityValue(rawValue: "hi"))
    }
}
