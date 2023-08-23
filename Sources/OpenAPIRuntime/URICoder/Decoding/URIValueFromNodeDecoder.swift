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
    private var codingStack: [CodingStackEntry]
    
    init(node: URIParsedNode) {
        self.node = node
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
    }
    
    /// An entry in the coding stack for URIValueFromNodeDecoder.
    ///
    /// This is used to keep track of where we are in the decode.
    private struct CodingStackEntry {
        var key: URICoderCodingKey
        var element: URIParsedNode
    }
    
    /// The element at the current head of the coding stack.
    private var currentElement: URIParsedNode? {
        self.codingStack.last.map { $0.element }
    }
}

extension URIValueFromNodeDecoder: Decoder {
    
    var codingPath: [any CodingKey] {
        // TODO: Fill in
        []
    }
    
    var userInfo: [CodingUserInfoKey : Any] {
        [:]
    }
    
    func container<Key>(
        keyedBy type: Key.Type
    ) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        fatalError()
    }
    
    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        fatalError()
    }
    
    func singleValueContainer() throws -> any SingleValueDecodingContainer {
        
        func throwMismatch(_ message: String) throws -> Never {
            throw DecodingError.typeMismatch(
                String.self,
                .init(
                    codingPath: codingPath,
                    debugDescription: message
                )
            )
        }
        
        // A single value can be parsed from a node that:
        // 1. Has a single key-value pair
        // 2. The value array has a single element.
        
        guard !node.isEmpty else {
            try throwMismatch("Cannot parse a single value from an empty node.")
        }
        guard node.count == 1 else {
            try throwMismatch("Cannot parse a single value from a node with multiple key-value pairs.")
        }
        let values = node.first!.value
        guard !values.isEmpty else {
            try throwMismatch("Cannot parse a single value from a node with an empty value array.")
        }
        guard values.count == 1 else {
            try throwMismatch("Cannot parse a single value from a node with multiple values.")
        }
        let value = values[0]
        return URISingleValueDecodingContainer(
            _codingPath: codingPath,
            value: value
        )
    }
}
