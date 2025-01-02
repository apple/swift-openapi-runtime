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
import HTTPTypes

final class Test_MultipartValidationSequence: Test_Runtime {
    func test() async throws {
        let firstBody: HTTPBody = "24"
        let secondBody: HTTPBody = "{}"
        let parts: [MultipartRawPart] = [
            .init(headerFields: [.contentDisposition: #"form-data; name="name""#], body: firstBody),
            .init(headerFields: [.contentDisposition: #"form-data; name="info""#], body: secondBody),
        ]
        var upstreamIterator = parts.makeIterator()
        let upstream = AsyncStream { upstreamIterator.next() }
        let sequence = MultipartValidationSequence(
            upstream: upstream,
            requirements: .init(
                allowsUnknownParts: true,
                requiredExactlyOncePartNames: ["name"],
                requiredAtLeastOncePartNames: [],
                atMostOncePartNames: ["info"],
                zeroOrMoreTimesPartNames: []
            )
        )
        var outParts: [MultipartRawPart] = []
        for try await part in sequence { outParts.append(part) }
        let expectedParts: [MultipartRawPart] = [
            .init(headerFields: [.contentDisposition: #"form-data; name="name""#], body: firstBody),
            .init(headerFields: [.contentDisposition: #"form-data; name="info""#], body: secondBody),
        ]
        XCTAssertEqual(outParts, expectedParts)
    }
}

final class Test_MultipartValidationSequenceValidator: Test_Runtime {
    func test() async throws {
        let firstBody: HTTPBody = "24"
        let secondBody: HTTPBody = "{}"
        let parts: [MultipartRawPart] = [
            .init(headerFields: [.contentDisposition: #"form-data; name="name""#], body: firstBody),
            .init(headerFields: [.contentDisposition: #"form-data; name="info""#], body: secondBody),
        ]
        var validator = MultipartValidationSequence<AsyncStream<MultipartRawPart>>
            .Validator(
                requirements: .init(
                    allowsUnknownParts: true,
                    requiredExactlyOncePartNames: ["name"],
                    requiredAtLeastOncePartNames: [],
                    atMostOncePartNames: ["info"],
                    zeroOrMoreTimesPartNames: []
                )
            )
        let outParts: [MultipartRawPart?] = try await [validator.next(parts[0]), validator.next(parts[1])]
        let expectedParts: [MultipartRawPart] = [
            .init(headerFields: [.contentDisposition: #"form-data; name="name""#], body: firstBody),
            .init(headerFields: [.contentDisposition: #"form-data; name="info""#], body: secondBody),
        ]
        XCTAssertEqual(outParts, expectedParts)
    }
}

private func newStateMachine(
    allowsUnknownParts: Bool,
    requiredExactlyOncePartNames: Set<String>,
    requiredAtLeastOncePartNames: Set<String>,
    atMostOncePartNames: Set<String>,
    zeroOrMoreTimesPartNames: Set<String>
) -> MultipartValidationSequence<AsyncStream<MultipartRawPart>>.StateMachine {
    .init(
        allowsUnknownParts: allowsUnknownParts,
        requiredExactlyOncePartNames: requiredExactlyOncePartNames,
        requiredAtLeastOncePartNames: requiredAtLeastOncePartNames,
        atMostOncePartNames: atMostOncePartNames,
        zeroOrMoreTimesPartNames: zeroOrMoreTimesPartNames
    )
}

final class Test_MultipartValidationSequenceStateMachine: Test_Runtime {

    func testTwoParts() throws {
        let parts: [MultipartRawPart] = [
            .init(headerFields: [.contentDisposition: #"form-data; name="name""#], body: "24"),
            .init(headerFields: [.contentDisposition: #"form-data; name="info""#], body: "{}"),
        ]
        var stateMachine = newStateMachine(
            allowsUnknownParts: true,
            requiredExactlyOncePartNames: ["name"],
            requiredAtLeastOncePartNames: [],
            atMostOncePartNames: ["info"],
            zeroOrMoreTimesPartNames: []
        )
        XCTAssertEqual(
            stateMachine.state,
            .init(
                allowsUnknownParts: true,
                exactlyOncePartNames: ["name"],
                atLeastOncePartNames: [],
                atMostOncePartNames: ["info"],
                zeroOrMoreTimesPartNames: [],
                remainingExactlyOncePartNames: ["name"],
                remainingAtLeastOncePartNames: [],
                remainingAtMostOncePartNames: ["info"]
            )
        )
        XCTAssertEqual(stateMachine.next(parts[0]), .emitPart(parts[0]))
        XCTAssertEqual(
            stateMachine.state,
            .init(
                allowsUnknownParts: true,
                exactlyOncePartNames: ["name"],
                atLeastOncePartNames: [],
                atMostOncePartNames: ["info"],
                zeroOrMoreTimesPartNames: [],
                remainingExactlyOncePartNames: [],
                remainingAtLeastOncePartNames: [],
                remainingAtMostOncePartNames: ["info"]
            )
        )
        XCTAssertEqual(stateMachine.next(parts[1]), .emitPart(parts[1]))
        XCTAssertEqual(
            stateMachine.state,
            .init(
                allowsUnknownParts: true,
                exactlyOncePartNames: ["name"],
                atLeastOncePartNames: [],
                atMostOncePartNames: ["info"],
                zeroOrMoreTimesPartNames: [],
                remainingExactlyOncePartNames: [],
                remainingAtLeastOncePartNames: [],
                remainingAtMostOncePartNames: []
            )
        )
        XCTAssertEqual(stateMachine.next(nil), .returnNil)
    }
    func testUnknownWithName() throws {
        let parts: [MultipartRawPart] = [
            .init(headerFields: [.contentDisposition: #"form-data; name="name""#], body: "24")
        ]
        var stateMachine = newStateMachine(
            allowsUnknownParts: false,
            requiredExactlyOncePartNames: [],
            requiredAtLeastOncePartNames: [],
            atMostOncePartNames: [],
            zeroOrMoreTimesPartNames: []
        )
        XCTAssertEqual(stateMachine.next(parts[0]), .emitError(.receivedUnknownPart("name")))
    }

    func testUnnamed_disallowed() throws {
        let parts: [MultipartRawPart] = [.init(headerFields: [.contentDisposition: #"form-data"#], body: "24")]
        var stateMachine = newStateMachine(
            allowsUnknownParts: false,
            requiredExactlyOncePartNames: [],
            requiredAtLeastOncePartNames: [],
            atMostOncePartNames: [],
            zeroOrMoreTimesPartNames: []
        )
        XCTAssertEqual(stateMachine.next(parts[0]), .emitError(.receivedUnnamedPart))
    }
    func testUnnamed_allowed() throws {
        let parts: [MultipartRawPart] = [.init(headerFields: [.contentDisposition: #"form-data"#], body: "24")]
        var stateMachine = newStateMachine(
            allowsUnknownParts: true,
            requiredExactlyOncePartNames: [],
            requiredAtLeastOncePartNames: [],
            atMostOncePartNames: [],
            zeroOrMoreTimesPartNames: []
        )
        XCTAssertEqual(stateMachine.next(parts[0]), .emitPart(parts[0]))
    }
    func testUnknown_disallowed_zeroOrMore() throws {
        let parts: [MultipartRawPart] = [
            .init(headerFields: [.contentDisposition: #"form-data; name="name""#], body: "24")
        ]
        var stateMachine = newStateMachine(
            allowsUnknownParts: false,
            requiredExactlyOncePartNames: [],
            requiredAtLeastOncePartNames: [],
            atMostOncePartNames: [],
            zeroOrMoreTimesPartNames: ["name"]
        )
        XCTAssertEqual(stateMachine.next(parts[0]), .emitPart(parts[0]))
        XCTAssertEqual(stateMachine.next(parts[0]), .emitPart(parts[0]))
    }
    func testUnknown_allowed() throws {
        let parts: [MultipartRawPart] = [
            .init(headerFields: [.contentDisposition: #"form-data; name="name""#], body: "24")
        ]
        var stateMachine = newStateMachine(
            allowsUnknownParts: true,
            requiredExactlyOncePartNames: [],
            requiredAtLeastOncePartNames: [],
            atMostOncePartNames: [],
            zeroOrMoreTimesPartNames: []
        )
        XCTAssertEqual(stateMachine.next(parts[0]), .emitPart(parts[0]))
    }

    func testMissingRequiredExactlyOnce() throws {
        var stateMachine = newStateMachine(
            allowsUnknownParts: false,
            requiredExactlyOncePartNames: ["name"],
            requiredAtLeastOncePartNames: [],
            atMostOncePartNames: [],
            zeroOrMoreTimesPartNames: []
        )
        XCTAssertEqual(
            stateMachine.next(nil),
            .emitError(.missingRequiredParts(expectedExactlyOnce: ["name"], expectedAtLeastOnce: []))
        )
    }

    func testMissingRequiredAtLeastOnce_once() throws {
        var stateMachine = newStateMachine(
            allowsUnknownParts: false,
            requiredExactlyOncePartNames: [],
            requiredAtLeastOncePartNames: ["info"],
            atMostOncePartNames: [],
            zeroOrMoreTimesPartNames: []
        )
        XCTAssertEqual(
            stateMachine.next(nil),
            .emitError(.missingRequiredParts(expectedExactlyOnce: [], expectedAtLeastOnce: ["info"]))
        )
    }
    func testMissingRequiredAtLeastOnce_multipleTimes() throws {
        let parts: [MultipartRawPart] = [
            .init(headerFields: [.contentDisposition: #"form-data; name="name""#], body: "24")
        ]
        var stateMachine = newStateMachine(
            allowsUnknownParts: false,
            requiredExactlyOncePartNames: [],
            requiredAtLeastOncePartNames: ["name"],
            atMostOncePartNames: [],
            zeroOrMoreTimesPartNames: []
        )
        XCTAssertEqual(stateMachine.next(parts[0]), .emitPart(parts[0]))
        XCTAssertEqual(stateMachine.next(parts[0]), .emitPart(parts[0]))
    }

    func testMissingRequiredExactlyOnce_multipleTimes() throws {
        let parts: [MultipartRawPart] = [
            .init(headerFields: [.contentDisposition: #"form-data; name="name""#], body: "24")
        ]
        var stateMachine = newStateMachine(
            allowsUnknownParts: false,
            requiredExactlyOncePartNames: ["name"],
            requiredAtLeastOncePartNames: [],
            atMostOncePartNames: [],
            zeroOrMoreTimesPartNames: []
        )
        XCTAssertEqual(stateMachine.next(parts[0]), .emitPart(parts[0]))
        XCTAssertEqual(stateMachine.next(parts[0]), .emitError(.receivedMultipleValuesForSingleValuePart("name")))
    }

    func testMissingRequiredAtMostOnce() throws {
        let parts: [MultipartRawPart] = [
            .init(headerFields: [.contentDisposition: #"form-data; name="name""#], body: "24")
        ]
        var stateMachine = newStateMachine(
            allowsUnknownParts: false,
            requiredExactlyOncePartNames: [],
            requiredAtLeastOncePartNames: [],
            atMostOncePartNames: ["name"],
            zeroOrMoreTimesPartNames: []
        )
        XCTAssertEqual(stateMachine.next(parts[0]), .emitPart(parts[0]))
        XCTAssertEqual(stateMachine.next(parts[0]), .emitError(.receivedMultipleValuesForSingleValuePart("name")))
    }
}
