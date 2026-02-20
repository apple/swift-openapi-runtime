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

    func testDecoding_string() throws {
        _test(
            "hello world",
            forKey: "message",
            from: .init(
                formExplode: "message=hello%20world",
                formUnexplode: "message=hello%20world",
                simpleExplode: "hello%20world",
                simpleUnexplode: "hello%20world",
                formDataExplode: "message=hello+world",
                formDataUnexplode: "message=hello+world",
                deepObjectExplode: nil
            )
        )
    }

    func testDecoding_maxNesting() throws {
        struct Filter: Decodable, Equatable {
            enum State: String, Decodable, Equatable {
                case enabled
                case disabled
            }
            var state: [State]
        }
        _test(
            Filter(state: [.enabled, .disabled]),
            forKey: "filter",
            from: .init(
                formExplode: "state=enabled&state=disabled",
                formUnexplode: "filter=state,enabled,state,disabled",
                simpleExplode: "state=enabled,state=disabled",
                simpleUnexplode: "state,enabled,state,disabled",
                formDataExplode: "state=enabled&state=disabled",
                formDataUnexplode: "filter=state,enabled,state,disabled",
                deepObjectExplode: "filter%5Bstate%5D=enabled&filter%5Bstate%5D=disabled"
            )
        )
    }

    func testDecoding_array() throws {
        _test(
            ["hello world", "goodbye world"],
            forKey: "message",
            from: .init(
                formExplode: "message=hello%20world&message=goodbye%20world",
                formUnexplode: "message=hello%20world,goodbye%20world",
                simpleExplode: "hello%20world,goodbye%20world",
                simpleUnexplode: "hello%20world,goodbye%20world",
                formDataExplode: "message=hello+world&message=goodbye+world",
                formDataUnexplode: "message=hello+world,goodbye+world",
                deepObjectExplode: nil
            )
        )
    }

    func testDecoding_struct() throws {
        struct Foo: Decodable, Equatable { var bar: String }
        _test(
            Foo(bar: "hello world"),
            forKey: "message",
            from: .init(
                formExplode: "bar=hello%20world",
                formUnexplode: "message=bar,hello%20world",
                simpleExplode: "bar=hello%20world",
                simpleUnexplode: "bar,hello%20world",
                formDataExplode: "bar=hello+world",
                formDataUnexplode: "message=bar,hello+world",
                deepObjectExplode: "message%5Bbar%5D=hello%20world"
            )
        )
    }

    func testDecoding_structWithOptionalProperty() throws {
        struct Foo: Decodable, Equatable {
            var bar: String?
            var baz: Int
        }
        let decoder = URIDecoder(configuration: .formDataExplode)
        do {
            let decodedValue = try decoder.decode(Foo.self, forKey: "", from: "baz=1&bar=hello+world")
            XCTAssertEqual(decodedValue, Foo(bar: "hello world", baz: 1))
        }
        do {
            let decodedValue = try decoder.decode(Foo.self, forKey: "", from: "baz=1")
            XCTAssertEqual(decodedValue, Foo(baz: 1))
        }
    }

    func testDecoding_freeformObject() throws {
        let decoder = URIDecoder(configuration: .formDataExplode)
        do {
            let decodedValue = try decoder.decode(
                OpenAPIObjectContainer.self,
                forKey: "",
                from: "baz=1&bar=hello+world&bar=goodbye+world"
            )
            XCTAssertEqual(
                decodedValue,
                try .init(unvalidatedValue: ["bar": ["hello world", "goodbye world"], "baz": 1])
            )
        }
    }

    func testDecoding_rootValue() throws {
        let decoder = URIDecoder(configuration: .formDataExplode)
        do {
            let decodedValue = try decoder.decode(Int.self, forKey: "root", from: "root=1")
            XCTAssertEqual(decodedValue, 1)
        }
        do {
            let decodedValue = try decoder.decodeIfPresent(Int.self, forKey: "root", from: "baz=1")
            XCTAssertEqual(decodedValue, nil)
        }
        do {
            let decodedValue = try decoder.decodeIfPresent(Int.self, forKey: "root", from: "")
            XCTAssertEqual(decodedValue, nil)
        }
    }

    func testDecoding_percentEncodedCommaToString() throws {
        let decoder = URIDecoder(configuration: .simpleUnexplode)

        do {
            let decodedValue = try decoder.decode(String.self, forKey: "", from: "foo%2C%20bar")
            XCTAssertEqual(decodedValue, "foo, bar")
        }
    }

    func testDecoding_nonPercentEncodedCommaToString() throws {
        let decoder = URIDecoder(configuration: .simpleUnexplode)

        do {
            let decodedValue = try decoder.decode(String.self, forKey: "", from: "foo, bar")
            XCTAssertEqual(decodedValue, "foo, bar")
        }
    }
}

extension Test_URIDecoder {

    struct Inputs {
        var formExplode: Substring?
        var formUnexplode: Substring?
        var simpleExplode: Substring?
        var simpleUnexplode: Substring?
        var formDataExplode: Substring?
        var formDataUnexplode: Substring?
        var deepObjectExplode: Substring?
    }

    func _test<T: Decodable & Equatable>(
        _ value: T,
        forKey key: String,
        from inputs: Inputs,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        func _run(name: String, configuration: URICoderConfiguration, sourceString: Substring) {
            let decoder = URIDecoder(configuration: configuration)
            do {
                let decodedValue = try decoder.decode(T.self, forKey: key, from: sourceString)
                XCTAssertEqual(decodedValue, value, "Failed in \(name)", file: file, line: line)
            } catch { XCTFail("Threw an error in \(name): \(error)", file: file, line: line) }
        }
        if let value = inputs.formExplode {
            _run(name: "formExplode", configuration: .formExplode, sourceString: value)
        }
        if let value = inputs.formUnexplode {
            _run(name: "formUnexplode", configuration: .formUnexplode, sourceString: value)
        }
        if let value = inputs.simpleExplode {
            _run(name: "simpleExplode", configuration: .simpleExplode, sourceString: value)
        }
        if let value = inputs.simpleUnexplode {
            _run(name: "simpleUnexplode", configuration: .simpleUnexplode, sourceString: value)
        }
        if let value = inputs.formDataExplode {
            _run(name: "formDataExplode", configuration: .formDataExplode, sourceString: value)
        }
        if let value = inputs.formDataUnexplode {
            _run(name: "formDataUnexplode", configuration: .formDataUnexplode, sourceString: value)
        }
        if let value = inputs.deepObjectExplode {
            _run(name: "deepObjectExplode", configuration: .deepObjectExplode, sourceString: value)
        }
    }
}
