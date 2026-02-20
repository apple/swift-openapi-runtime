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

/// A type that converts an `Encodable` type into a `URIEncodableNode` value.
final class URIValueToNodeEncoder {

    /// An entry in the coding stack for `URIEncoder`.
    ///
    /// This is used to keep track of where we are in the encode.
    struct CodingStackEntry {

        /// The key at which to write the node.
        var key: URICoderCodingKey

        /// The node at the key inside its parent.
        var storage: URIEncodedNode
    }

    /// An encoder error.
    enum GeneralError: Swift.Error {

        /// The encoder set a nil value, which isn't supported.
        case nilNotSupported

        /// The encoder set a Data value, which isn't supported.
        case dataNotSupported

        /// The encoder set a value for an index out of range of the container.
        case integerOutOfRange
    }

    /// The stack of nested values within the root node.
    private var _codingPath: [CodingStackEntry]

    /// The current value, which will be added on top of the stack once
    /// finished encoding.
    var currentStackEntry: CodingStackEntry

    /// Creates a new encoder.
    init() {
        self._codingPath = []
        self.currentStackEntry = CodingStackEntry(key: .init(stringValue: ""), storage: .unset)
    }

    /// Encodes the provided value into a node.
    /// - Parameter value: The value to encode.
    /// - Returns: The node with the encoded contents of the value.
    /// - Throws: An error if encoding the value into a node fails.
    func encodeValue(_ value: some Encodable) throws -> URIEncodedNode {
        defer {
            _codingPath = []
            currentStackEntry = CodingStackEntry(key: .init(stringValue: ""), storage: .unset)
        }

        // We have to catch the special values early, otherwise we fall
        // back to their Codable implementations, which don't give us
        // a chance to customize the coding in the containers.
        if let date = value as? Date {
            var container = singleValueContainer()
            try container.encode(date)
        } else {
            try value.encode(to: self)
        }

        let encodedValue = currentStackEntry.storage
        return encodedValue
    }
}

extension URIValueToNodeEncoder {

    /// Pushes a new container on top of the current stack, nesting into the
    /// value at the provided key.
    /// - Parameters:
    ///   - key: The coding key for the new value on top of the stack.
    ///   - newStorage: The node to push on top of the stack.
    func push(key: URICoderCodingKey, newStorage: URIEncodedNode) {
        _codingPath.append(currentStackEntry)
        currentStackEntry = .init(key: key, storage: newStorage)
    }

    /// Pops the top container from the stack and restores the previously top
    /// container to be the current top container.
    func pop() throws {
        // This is called when we've completed the storage in the current container.
        // We can pop the value at the base of the stack, then "insert" the current one
        // into it, and save the new value as the new current.
        let current = currentStackEntry
        var newCurrent = _codingPath.removeLast()
        try newCurrent.storage.insert(current.storage, atKey: current.key)
        currentStackEntry = newCurrent
    }
}

extension URIValueToNodeEncoder: Encoder {

    var codingPath: [any CodingKey] {
        // The coding path meaningful to the types conforming to Codable.
        // 1. Omit the root coding path.
        // 2. Add the current stack entry's coding path.
        (_codingPath.dropFirst().map(\.key) + [currentStackEntry.key]).map { $0 as any CodingKey }
    }

    var userInfo: [CodingUserInfoKey: Any] { [:] }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        KeyedEncodingContainer(URIKeyedEncodingContainer(encoder: self))
    }

    func unkeyedContainer() -> any UnkeyedEncodingContainer { URIUnkeyedEncodingContainer(encoder: self) }

    func singleValueContainer() -> any SingleValueEncodingContainer { URISingleValueEncodingContainer(encoder: self) }
}
