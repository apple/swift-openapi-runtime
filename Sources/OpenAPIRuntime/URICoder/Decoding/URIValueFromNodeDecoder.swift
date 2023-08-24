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

import Foundation

final class URIValueFromNodeDecoder {

    private let node: URIParsedNode
    private let rootKey: URIParsedKey
    private let style: URICoderConfiguration.Style
    private let explode: Bool
    private var codingStack: [CodingStackEntry]

    init(
        node: URIParsedNode,
        rootKey: URIParsedKey,
        style: URICoderConfiguration.Style,
        explode: Bool
    ) {
        self.node = node
        self.rootKey = rootKey
        self.style = style
        self.explode = explode
        self.codingStack = []
    }

    func decodeRoot<T: Decodable>(_ type: T.Type = T.self) throws -> T {
        precondition(codingStack.isEmpty)
        defer {
            precondition(codingStack.isEmpty)
        }
        return try T.init(from: self)
    }
}

extension URIValueFromNodeDecoder {
    enum GeneralError: Swift.Error {
        case unsupportedType(Any.Type)
        case nestedContainersNotSupported
        case reachedEndOfUnkeyedContainer
        case codingKeyNotInt
        case codingKeyOutOfBounds
        case codingKeyNotFound
    }

    private enum URIDecodedNode {
        case single(URIParsedValue)
        case array(URIParsedValueArray)
        case dictionary(URIParsedNode)
    }

    /// An entry in the coding stack for URIValueFromNodeDecoder.
    ///
    /// This is used to keep track of where we are in the decode.
    private struct CodingStackEntry {
        var key: URICoderCodingKey
        var element: URIDecodedNode
    }

    /// The element at the current head of the coding stack.
    private var currentElement: URIDecodedNode {
        codingStack.last?.element ?? .dictionary(node)
    }

    func push(_ codingKey: URICoderCodingKey) throws {
        let nextElement: URIDecodedNode
        if let intValue = codingKey.intValue {
            let value = try nestedValueInCurrentElementAsArray(at: intValue)
            nextElement = .single(value)
        } else {
            let values = try nestedValuesInCurrentElementAsDictionary(forKey: codingKey.stringValue)
            nextElement = .array(values)
        }
        codingStack.append(CodingStackEntry(key: codingKey, element: nextElement))
    }

    func pop() {
        codingStack.removeLast()
    }

    private func throwMismatch(_ message: String) throws -> Never {
        throw DecodingError.typeMismatch(
            String.self,
            .init(
                codingPath: codingPath,
                debugDescription: message
            )
        )
    }

    private func rootValue(in node: URIParsedNode) throws -> URIParsedValueArray {
        guard let value = node[rootKey] else {
            if style == .simple, let valueForFallbackKey = node[""] {
                // The simple style doesn't encode the key, so single values
                // get encoded as a value only, and parsed under the empty
                // string key.
                return valueForFallbackKey
            }
            throw DecodingError.keyNotFound(
                URICoderCodingKey(stringValue: String(rootKey)),
                .init(codingPath: codingPath, debugDescription: "Value for root key not found.")
            )
        }
        return value
    }

    private func currentElementAsDictionary() throws -> URIParsedNode {
        try nodeAsDictionary(currentElement)
    }

    private func nodeAsDictionary(_ node: URIDecodedNode) throws -> URIParsedNode {
        // There are multiple ways a valid dictionary is represented in a node,
        // depends on the explode parameter.
        // 1. exploded: Key-value pairs in the node: ["R":["100"]]
        // 2. unexploded form: Flattened key-value pairs in the only top level
        //    key's value array: ["<root key>":["R","100"]]
        // To simplify the code, when asked for a keyed container here and explode
        // is false, we convert (2) to (1), and then treat everything as (1).
        // The conversion only works if the number of values is even, including 0.
        if explode {
            guard case let .dictionary(values) = node else {
                try throwMismatch("Cannot treat a single value or an array as a dictionary.")
            }
            return values
        }
        let values = try nodeAsArray(node)
        guard values.count % 2 == 0 else {
            try throwMismatch("Cannot parse an unexploded dictionary an odd number of elements.")
        }
        let pairs = stride(
            from: values.startIndex,
            to: values.endIndex,
            by: 2
        )
        .map { firstIndex in
            (values[firstIndex], [values[firstIndex + 1]])
        }
        let convertedNode = Dictionary(pairs, uniquingKeysWith: { $0 + $1 })
        return convertedNode
    }

    private func currentElementAsArray() throws -> URIParsedValueArray {
        try nodeAsArray(currentElement)
    }

    private func nodeAsArray(_ node: URIDecodedNode) throws -> URIParsedValueArray {
        switch node {
        case .single(let value):
            return [value]
        case .array(let values):
            return values
        case .dictionary(let values):
            return try rootValue(in: values)
        }
    }

    private func currentElementAsSingleValue() throws -> URIParsedValue {
        try nodeAsSingleValue(currentElement)
    }

    private func nodeAsSingleValue(_ node: URIDecodedNode) throws -> URIParsedValue {
        // A single value can be parsed from a node that:
        // 1. Has a single key-value pair
        // 2. The value array has a single element.
        let array: URIParsedValueArray
        switch node {
        case .single(let value):
            return value
        case .array(let values):
            array = values
        case .dictionary(let values):
            array = try rootValue(in: values)
        }
        guard array.count == 1 else {
            try throwMismatch("Cannot parse a value from a node with multiple values.")
        }
        let value = array[0]
        return value
    }

    private func nestedValueInCurrentElementAsArray(
        at index: Int
    ) throws -> URIParsedValue {
        let values = try currentElementAsArray()
        guard index < values.count else {
            throw GeneralError.codingKeyOutOfBounds
        }
        return values[index]
    }

    private func nestedValuesInCurrentElementAsDictionary(
        forKey key: String
    ) throws -> URIParsedValueArray {
        let values = try currentElementAsDictionary()
        guard let value = values[key[...]] else {
            throw GeneralError.codingKeyNotFound
        }
        return value
    }
}

extension URIValueFromNodeDecoder: Decoder {

    var codingPath: [any CodingKey] {
        codingStack.map(\.key)
    }

    var userInfo: [CodingUserInfoKey: Any] {
        [:]
    }

    func container<Key>(
        keyedBy type: Key.Type
    ) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        let values = try currentElementAsDictionary()
        return .init(
            URIKeyedDecodingContainer(
                decoder: self,
                values: values
            )
        )
    }

    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        let values = try currentElementAsArray()
        return URIUnkeyedDecodingContainer(
            decoder: self,
            values: values
        )
    }

    func singleValueContainer() throws -> any SingleValueDecodingContainer {
        let value = try currentElementAsSingleValue()
        return URISingleValueDecodingContainer(
            codingPath: codingPath,
            value: value
        )
    }
}
