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

/// A type that allows decoding `Decodable` values from a `URIParsedNode`.
final class URIValueFromNodeDecoder {

    /// The coder used for serializing Date values.
    let dateTranscoder: any DateTranscoder

    /// The underlying root node.
    private let node: URIParsedNode

    /// The key of the root value in the node.
    private let rootKey: URIParsedKey

    /// The variable expansion style.
    private let style: URICoderConfiguration.Style

    /// The explode parameter of the expansion style.
    private let explode: Bool

    /// The stack of nested values within the root node.
    private var codingStack: [CodingStackEntry]

    /// Creates a new decoder.
    /// - Parameters:
    ///   - node: The underlying root node.
    ///   - rootKey: The key of the root value in the node.
    ///   - style: The variable expansion style.
    ///   - explode: The explode parameter of the expansion style.
    ///   - dateTranscoder: The coder used for serializing Date values.
    init(
        node: URIParsedNode,
        rootKey: URIParsedKey,
        style: URICoderConfiguration.Style,
        explode: Bool,
        dateTranscoder: any DateTranscoder
    ) {
        self.node = node
        self.rootKey = rootKey
        self.style = style
        self.explode = explode
        self.dateTranscoder = dateTranscoder
        self.codingStack = []
    }

    /// Decodes the provided type from the root node.
    /// - Parameter type: The type to decode from the decoder.
    /// - Returns: The decoded value.
    /// - Throws: When a decoding error occurs.
    func decodeRoot<T: Decodable>(_ type: T.Type = T.self) throws -> T {
        precondition(codingStack.isEmpty)
        defer {
            precondition(codingStack.isEmpty)
        }

        // We have to catch the special values early, otherwise we fall
        // back to their Codable implementations, which don't give us
        // a chance to customize the coding in the containers.
        let value: T
        switch type {
        case is Date.Type:
            value = try singleValueContainer().decode(Date.self) as! T
        default:
            value = try T.init(from: self)
        }
        return value
    }

    /// Decodes the provided type from the root node.
    /// - Parameter type: The type to decode from the decoder.
    /// - Returns: The decoded value.
    /// - Throws: When a decoding error occurs.
    func decodeRootIfPresent<T: Decodable>(_ type: T.Type = T.self) throws -> T? {
        // The root is only nil if the node is empty.
        if try currentElementAsArray().isEmpty {
            return nil
        }
        return try decodeRoot(type)
    }
}

extension URIValueFromNodeDecoder {

    /// A decoder error.
    enum GeneralError: Swift.Error {

        /// The decoder was asked to create a nested container.
        case nestedContainersNotSupported

        /// The decoder was asked for more items, but it was already at the
        /// end of the unkeyed container.
        case reachedEndOfUnkeyedContainer

        /// The provided coding key does not have a valid integer value, but
        /// it is being used for accessing items in an unkeyed container.
        case codingKeyNotInt

        /// The provided coding key is out of bounds of the unkeyed container.
        case codingKeyOutOfBounds

        /// The coding key is of a value not found in the keyed container.
        case codingKeyNotFound
    }

    /// A node materialized by the decoder.
    private enum URIDecodedNode {

        /// A single value.
        case single(URIParsedValue)

        /// An array of values.
        case array(URIParsedValueArray)

        /// A dictionary of values.
        case dictionary(URIParsedNode)
    }

    /// An entry in the coding stack for `URIValueFromNodeDecoder`.
    ///
    /// This is used to keep track of where we are in the decode.
    private struct CodingStackEntry {

        /// The key at which the entry was found.
        var key: URICoderCodingKey

        /// The node at the key inside its parent.
        var element: URIDecodedNode
    }

    /// The element at the current head of the coding stack.
    private var currentElement: URIDecodedNode {
        codingStack.last?.element ?? .dictionary(node)
    }

    /// Pushes a new container on top of the current stack, nesting into the
    /// value at the provided key.
    /// - Parameter codingKey: The coding key for the value that is then put
    ///   at the top of the stack.
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

    /// Pops the top container from the stack and restores the previously top
    /// container to be the current top container.
    func pop() {
        codingStack.removeLast()
    }

    /// Throws a type mismatch error with the provided message.
    /// - Parameter message: The message to be embedded as debug description
    ///   inside the thrown `DecodingError`.
    private func throwMismatch(_ message: String) throws -> Never {
        throw DecodingError.typeMismatch(
            String.self,
            .init(
                codingPath: codingPath,
                debugDescription: message
            )
        )
    }

    /// Extracts the root value of the provided node using the root key.
    /// - Parameter node: The node which to expect for the root key.
    /// - Returns: The value found at the root key in the provided node.
    private func rootValue(in node: URIParsedNode) throws -> URIParsedValueArray {
        guard let value = node[rootKey] else {
            if style == .simple, let valueForFallbackKey = node[""] {
                // The simple style doesn't encode the key, so single values
                // get encoded as a value only, and parsed under the empty
                // string key.
                return valueForFallbackKey
            }
            return []
        }
        return value
    }

    /// Extracts the node at the top of the coding stack and tries to treat it
    /// as a dictionary.
    /// - Returns: The value if it can be treated as a dictionary.
    private func currentElementAsDictionary() throws -> URIParsedNode {
        try nodeAsDictionary(currentElement)
    }

    /// Checks if the provided node can be treated as a dictionary, and returns
    /// it if so.
    /// - Parameter node: The node to check.
    /// - Returns: The value if it can be treated as a dictionary.
    /// - Throws: An error if the node cannot be treated as a valid dictionary.
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
        if values == [""] && style == .simple {
            // An unexploded simple combination produces a ["":[""]] for an
            // empty string. It should be parsed as an empty dictionary.
            return ["": [""]]
        }
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

    /// Extracts the node at the top of the coding stack and tries to treat it
    /// as an array.
    /// - Returns: The value if it can be treated as an array.
    private func currentElementAsArray() throws -> URIParsedValueArray {
        try nodeAsArray(currentElement)
    }

    /// Checks if the provided node can be treated as an array, and returns
    /// it if so.
    /// - Parameter node: The node to check.
    /// - Returns: The value if it can be treated as an array.
    /// - Throws: An error if the node cannot be treated as a valid array.
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

    /// Extracts the node at the top of the coding stack and tries to treat it
    /// as a primitive value.
    /// - Returns: The value if it can be treated as a primitive value.
    func currentElementAsSingleValue() throws -> URIParsedValue {
        try nodeAsSingleValue(currentElement)
    }

    /// Checks if the provided node can be treated as a primitive value, and
    /// returns it if so.
    /// - Parameter node: The node to check.
    /// - Returns: The value if it can be treated as a primitive value.
    /// - Throws: An error if the node cannot be treated as a primitive value.
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
            let reason = array.isEmpty ? "an empty node" : "a node with multiple values"
            try throwMismatch("Cannot parse a value from \(reason).")
        }
        let value = array[0]
        return value
    }

    /// Returns the nested value at the provided index inside the node at the
    /// top of the coding stack.
    /// - Parameter index: The index of the nested value.
    /// - Returns: The nested value.
    /// - Throws: An error if the current node is not a valid array, or if the
    ///   index is out of bounds.
    private func nestedValueInCurrentElementAsArray(
        at index: Int
    ) throws -> URIParsedValue {
        let values = try currentElementAsArray()
        guard index < values.count else {
            throw GeneralError.codingKeyOutOfBounds
        }
        return values[index]
    }

    /// Returns the nested value at the provided key inside the node at the
    /// top of the coding stack.
    /// - Parameter key: The key of the nested value.
    /// - Returns: The nested value.
    /// - Throws: An error if the current node is not a valid dictionary, or
    /// if no value exists for the key.
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
        return URISingleValueDecodingContainer(decoder: self)
    }
}
