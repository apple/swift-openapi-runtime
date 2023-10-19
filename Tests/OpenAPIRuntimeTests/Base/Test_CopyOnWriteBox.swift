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

final class Test_CopyOnWriteBox: Test_Runtime {

    struct Node: Codable, Equatable {
        var id: Int
        var parent: CopyOnWriteBox<Node>?
    }

    func testModification() throws {
        var value = Node(
            id: 3,
            parent: .init(
                value: .init(
                    id: 2
                )
            )
        )
        XCTAssertEqual(
            value,
            Node(
                id: 3,
                parent: .init(
                    value: .init(
                        id: 2
                    )
                )
            )
        )
        value.parent!.value.parent = .init(value: .init(id: 1))
        XCTAssertEqual(
            value,
            Node(
                id: 3,
                parent: .init(
                    value: .init(
                        id: 2,
                        parent: .init(
                            value: .init(id: 1)
                        )
                    )
                )
            )
        )
    }

    func testSerialization() throws {
        let value = CopyOnWriteBox(value: "Hello")
        try testRoundtrip(
            value,
            expectedJSON: #""Hello""#
        )
    }

    func testIntegration() throws {
        let value = Node(
            id: 3,
            parent: .init(
                value: .init(
                    id: 2,
                    parent: .init(
                        value: .init(id: 1)
                    )
                )
            )
        )
        try testRoundtrip(
            value,
            expectedJSON: #"""
                {
                  "id" : 3,
                  "parent" : {
                    "id" : 2,
                    "parent" : {
                      "id" : 1
                    }
                  }
                }
                """#
        )
    }
}
