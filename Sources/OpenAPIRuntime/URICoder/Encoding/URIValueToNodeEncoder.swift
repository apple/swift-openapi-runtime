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

/// Converts an Encodable type into a URIEncodableNode.
final class URIValueToNodeEncoder {

    /// An entry in the coding stack for \_URIEncoder.
    ///
    /// This is used to keep track of where we are in the encode.
    struct CodingStackEntry {
        var key: URICoderCodingKey
        var storage: URIEncodedNode
    }

    enum GeneralError: Swift.Error {
        case nilNotSupported
        case dataNotSupported
        case invalidEncoderCallForValue
        case integerOutOfRange
        case nestedValueInSingleValueContainer
    }

    var _codingPath: [CodingStackEntry]
    var currentStackEntry: CodingStackEntry
    init() {
        self._codingPath = []
        self.currentStackEntry = CodingStackEntry(
            key: .init(stringValue: ""),
            storage: .unset
        )
    }

    func encodeValue(_ value: some Encodable) throws -> URIEncodedNode {
        defer {
            _codingPath = []
            currentStackEntry = CodingStackEntry(
                key: .init(stringValue: ""),
                storage: .unset
            )
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

extension URIValueToNodeEncoder: Encoder {
    var codingPath: [any CodingKey] {
        // The coding path meaningful to the types conforming to Codable.
        // 1. Omit the root coding path.
        // 2. Add the current stack entry's coding path.
        (_codingPath
            .dropFirst()
            .map(\.key)
            + [currentStackEntry.key])
            .map { $0 as any CodingKey }
    }

    var userInfo: [CodingUserInfoKey: Any] {
        [:]
    }

    func push(key: URICoderCodingKey, newStorage: URIEncodedNode) {
        _codingPath.append(currentStackEntry)
        currentStackEntry = .init(key: key, storage: newStorage)
    }

    func pop() throws {
        // This is called when we've completed the storage in the current container.
        // We can pop the value at the base of the stack, then "insert" the current one
        // into it, and save the new value as the new current.
        let current = currentStackEntry
        var newCurrent = _codingPath.removeLast()
        try newCurrent.storage.insert(current.storage, atKey: current.key)
        currentStackEntry = newCurrent
    }

    func container<Key>(
        keyedBy type: Key.Type
    ) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        KeyedEncodingContainer(URIKeyedEncodingContainer(encoder: self))
    }

    func unkeyedContainer() -> any UnkeyedEncodingContainer {
        URIUnkeyedEncodingContainer(encoder: self)
    }

    func singleValueContainer() -> any SingleValueEncodingContainer {
        URISingleValueEncodingContainer(encoder: self)
    }
}