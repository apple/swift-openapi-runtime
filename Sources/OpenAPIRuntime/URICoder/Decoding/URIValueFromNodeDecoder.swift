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

/// A type that allows decoding `Decodable` values from `URIParser`'s output.
final class URIValueFromNodeDecoder {

    private let data: Substring

    private let configuration: URICoderConfiguration
    let dateTranscoder: any DateTranscoder
    private let parser: URIParser
    struct ParsedState {
        var primitive: Result<URIDecodedPrimitive?, any Error>?
        var array: Result<URIDecodedArray, any Error>?
        var dictionary: Result<URIDecodedDictionary, any Error>?
    }
    private var state: ParsedState
    /// The key of the root value in the node.
    let rootKey: URIParsedKeyComponent

    /// The stack of nested values within the root node.
    private var codingStack: [CodingStackEntry]

    /// Creates a new decoder.
    /// - Parameters:
    ///   - data: The data to parse.
    ///   - rootKey: The key of the root value in the node.
    ///   - configuration: The configuration of the decoder.
    init(data: Substring, rootKey: URIParsedKeyComponent, configuration: URICoderConfiguration) {
        self.configuration = configuration
        self.dateTranscoder = configuration.dateTranscoder
        self.data = data
        self.parser = .init(configuration: configuration, data: data)
        self.state = .init()
        self.rootKey = rootKey
        self.codingStack = []
    }

    /// Decodes the provided type from the root node.
    /// - Parameter type: The type to decode from the decoder.
    /// - Returns: The decoded value.
    /// - Throws: When a decoding error occurs.
    func decodeRoot<T: Decodable>(_ type: T.Type = T.self) throws -> T {
        precondition(codingStack.isEmpty)
        defer { precondition(codingStack.isEmpty) }

        // We have to catch the special values early, otherwise we fall
        // back to their Codable implementations, which don't give us
        // a chance to customize the coding in the containers.
        let value: T
        switch type {
        case is Date.Type: value = try singleValueContainer().decode(Date.self) as! T
        default: value = try T.init(from: self)
        }
        return value
    }

    /// Decodes the provided type from the root node.
    /// - Parameter type: The type to decode from the decoder.
    /// - Returns: The decoded value.
    /// - Throws: When a decoding error occurs.
    func decodeRootIfPresent<T: Decodable>(_ type: T.Type = T.self) throws -> T? {
        switch configuration.style {
        case .simple:
            // Root is never nil, empty data just means an element with an empty string.
            break
        case .form:
            // Try to parse as an array, check the number of elements.
            if try withParsedRootAsArray({ $0.count == 0 }) { return nil }
        case .deepObject:
            // Try to parse as a dictionary, check the number of elements.
            if try withParsedRootAsDictionary({ $0.count == 0 }) { return nil }
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
    }

    /// An entry in the coding stack for `URIValueFromNodeDecoder`.
    ///
    /// This is used to keep track of where we are in the decode.
    private struct CodingStackEntry {

        /// The key at which the entry was found.
        var key: URICoderCodingKey
    }

    /// Pushes a new container on top of the current stack, nesting into the
    /// value at the provided key.
    /// - Parameter codingKey: The coding key for the value that is then put
    ///   at the top of the stack.
    func push(_ codingKey: URICoderCodingKey) { codingStack.append(CodingStackEntry(key: codingKey)) }

    /// Pops the top container from the stack and restores the previously top
    /// container to be the current top container.
    func pop() { codingStack.removeLast() }

    /// Throws a type mismatch error with the provided message.
    /// - Parameter message: The message to be embedded as debug description
    ///   inside the thrown `DecodingError`.
    /// - Throws: A `DecodingError` with a type mismatch error if this function is called.
    private func throwMismatch(_ message: String) throws -> Never {
        throw DecodingError.typeMismatch(String.self, .init(codingPath: codingPath, debugDescription: message))
    }

    // MARK: - withParsed methods

    private func withParsedRootAsPrimitive<R>(_ work: (URIDecodedPrimitive?) throws -> R) throws -> R {
        let value: URIDecodedPrimitive?
        if let cached = state.primitive {
            value = try cached.get()
        } else {
            let result: Result<URIDecodedPrimitive?, any Error>
            do {
                value = try parser.parseRootAsPrimitive(rootKey: rootKey)?.value
                result = .success(value)
            } catch {
                result = .failure(error)
                throw error
            }
            state.primitive = result
        }
        return try work(value)
    }

    private func withParsedRootAsDictionary<R>(_ work: (URIDecodedDictionary) throws -> R) throws -> R {
        let value: URIDecodedDictionary
        if let cached = state.dictionary {
            value = try cached.get()
        } else {
            let result: Result<URIDecodedDictionary, any Error>
            do {
                func normalizedDictionaryKey(_ key: URIParsedKey) throws -> Substring {
                    func validateComponentCount(_ count: Int) throws {
                        guard key.components.count == count else {
                            try throwMismatch(
                                "Decoding a dictionary key encountered an unexpected number of components (expected: \(count), got: \(key.components.count)."
                            )
                        }
                    }
                    switch (configuration.style, configuration.explode) {
                    case (.form, true), (.simple, _):
                        try validateComponentCount(1)
                        return key.components[0]
                    case (.form, false), (.deepObject, true):
                        try validateComponentCount(2)
                        return key.components[1]
                    case (.deepObject, false): try throwMismatch("Decoding deepObject + unexplode is not supported.")
                    }
                }

                let tuples = try parser.parseRootAsDictionary(rootKey: rootKey)
                let normalizedTuples: [(Substring, [URIParsedValue])] = try tuples.map { pair in
                    try (normalizedDictionaryKey(pair.key), [pair.value])
                }
                value = Dictionary(normalizedTuples, uniquingKeysWith: +)
                result = .success(value)
            } catch {
                result = .failure(error)
                throw error
            }
            state.dictionary = result
        }
        return try work(value)
    }

    private func withParsedRootAsArray<R>(_ work: (URIDecodedArray) throws -> R) throws -> R {
        let value: URIDecodedArray
        if let cached = state.array {
            value = try cached.get()
        } else {
            let result: Result<URIDecodedArray, any Error>
            do {
                value = try parser.parseRootAsArray(rootKey: rootKey).map(\.value)
                result = .success(value)
            } catch {
                result = .failure(error)
                throw error
            }
            state.array = result
        }
        return try work(value)
    }

    // MARK: - decoding utilities
    func primitiveValue(forKey key: String, in dictionary: URIDecodedDictionary) throws -> URIParsedValue? {
        let values = dictionary[key[...], default: []]
        if values.isEmpty { return nil }
        if values.count > 1 { try throwMismatch("Dictionary value contains multiple values.") }
        return values[0]
    }
    // MARK: - withCurrent methods

    private func withCurrentPrimitiveElement<R>(_ work: (URIDecodedPrimitive?) throws -> R) throws -> R {
        if !codingStack.isEmpty {
            // Nesting is involved.
            // There are exactly three scenarios we support:
            // - primitive in a top level array
            // - primitive in a top level dictionary
            // - primitive in a nested array inside a top level dictionary
            if codingStack.count == 1 {
                let key = codingStack[0].key
                if let intKey = key.intValue {
                    // Top level array.
                    return try withParsedRootAsArray { array in try work(array[intKey]) }
                } else {
                    // Top level dictionary.
                    return try withParsedRootAsDictionary { dictionary in
                        try work(primitiveValue(forKey: key.stringValue, in: dictionary))
                    }
                }
            } else if codingStack.count == 2 {
                // Nested array within a top level dictionary.
                let dictionaryKey = codingStack[0].key.stringValue[...]
                guard let nestedArrayKey = codingStack[1].key.intValue else {
                    try throwMismatch("Nested coding key is not an integer, hinting at unsupported nesting.")
                }
                return try withParsedRootAsDictionary { dictionary in
                    try work(dictionary[dictionaryKey, default: []][nestedArrayKey])
                }
            } else {
                try throwMismatch("Arbitrary nesting of containers is not supported.")
            }
        } else {
            // Top level primitive.
            return try withParsedRootAsPrimitive { try work($0) }
        }
    }

    private func withCurrentArrayElements<R>(_ work: (URIDecodedArray) throws -> R) throws -> R {
        if let nestedArrayParentKey = codingStack.first?.key {
            // Top level is dictionary, first level nesting is array.
            // Get all the elements that match this rootKey + nested key path.
            return try withParsedRootAsDictionary { dictionary in
                try work(dictionary[nestedArrayParentKey.stringValue[...]] ?? [])
            }
        } else {
            // Top level array.
            return try withParsedRootAsArray { try work($0) }
        }
    }

    private func withCurrentDictionaryElements<R>(_ work: (URIDecodedDictionary) throws -> R) throws -> R {
        if !codingStack.isEmpty {
            try throwMismatch("Nesting a dictionary inside another container is not supported.")
        } else {
            // Top level dictionary.
            return try withParsedRootAsDictionary { try work($0) }
        }
    }

    // MARK: - metadata and data accessors

    func currentElementAsSingleValue() throws -> URIParsedValue? { try withCurrentPrimitiveElement { $0 } }

    func countOfCurrentArray() throws -> Int { try withCurrentArrayElements { $0.count } }

    func nestedElementInCurrentArray(atIndex index: Int) throws -> URIParsedValue {
        try withCurrentArrayElements { $0[index] }
    }
    func nestedElementInCurrentDictionary(forKey key: String) throws -> URIParsedValue? {
        try withCurrentDictionaryElements { dictionary in try primitiveValue(forKey: key, in: dictionary) }
    }
    func containsElementInCurrentDictionary(forKey key: String) throws -> Bool {
        try withCurrentDictionaryElements { dictionary in dictionary[key[...]] != nil }
    }
    func elementKeysInCurrentDictionary() throws -> [String] {
        try withCurrentDictionaryElements { dictionary in dictionary.keys.map(String.init) }
    }
}

extension URIValueFromNodeDecoder: Decoder {

    var codingPath: [any CodingKey] { codingStack.map(\.key) }

    var userInfo: [CodingUserInfoKey: Any] { [:] }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        KeyedDecodingContainer(URIKeyedDecodingContainer(decoder: self))
    }

    func unkeyedContainer() throws -> any UnkeyedDecodingContainer { URIUnkeyedDecodingContainer(decoder: self) }

    func singleValueContainer() throws -> any SingleValueDecodingContainer {
        URISingleValueDecodingContainer(decoder: self)
    }
}
