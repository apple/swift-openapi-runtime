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

/// A type that allows decoding `Decodable` values from a URI-encoded string.
final class URIValueFromNodeDecoder {

    /// The key of the root object.
    let rootKey: URIParsedKeyComponent

    /// The date transcoder used for decoding the `Date` type.
    let dateTranscoder: any DateTranscoder

    /// The coder configuration.
    private let configuration: URICoderConfiguration

    /// The URIParser used to parse the provided URI-encoded string into
    /// an intermediate representation.
    private let parser: URIParser

    /// The cached parsing state of the decoder.
    private struct ParsingCache {

        /// The cached result of parsing the string as a primitive value.
        var primitive: Result<URIParsedValue?, any Error>?

        /// The cached result of parsing the string as an array.
        var array: Result<[URIParsedValue], any Error>?

        /// The cached result of parsing the string as a dictionary.
        var dictionary: Result<[URIParsedKeyComponent: [URIParsedValue]], any Error>?
    }

    /// A cache holding the parsed intermediate representation.
    private var cache: ParsingCache

    /// The stack of nested keys within the root node.
    ///
    /// Represents the currently parsed container.
    private var codingStack: [URICoderCodingKey]

    /// Creates a new decoder.
    /// - Parameters:
    ///   - data: The data to parse.
    ///   - rootKey: The key of the root object.
    ///   - configuration: The configuration of the decoder.
    init(data: Substring, rootKey: URIParsedKeyComponent, configuration: URICoderConfiguration) {
        self.rootKey = rootKey
        self.dateTranscoder = configuration.dateTranscoder
        self.configuration = configuration
        self.parser = .init(configuration: configuration, data: data)
        self.cache = .init()
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

    /// Decodes the provided type from the root node, if it's present.
    /// - Parameter type: The type to decode from the decoder.
    /// - Returns: The decoded value, or nil if not found.
    /// - Throws: When a decoding error occurs.
    func decodeRootIfPresent<T: Decodable>(_ type: T.Type = T.self) throws -> T? {
        switch configuration.style {
        case .simple:
            // Root is never nil, empty data just means an element with an empty string.
            break
        case .form:
            // Try to parse as an array, check the number of elements.
            if try parsedRootAsArray().count == 0 { return nil }
        case .deepObject:
            // Try to parse as a dictionary, check the number of elements.
            if try parsedRootAsDictionary().count == 0 { return nil }
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

    /// Pushes a new container on top of the current stack, nesting into the
    /// value at the provided key.
    /// - Parameter codingKey: The coding key for the value that is then put
    ///   at the top of the stack.
    func push(_ codingKey: URICoderCodingKey) { codingStack.append(codingKey) }

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

    /// Parse the root parsed as a specific type, with automatic caching.
    /// - Parameters:
    ///   - valueKeyPath: A key path to the parsing cache for storing the cached value.
    ///   - parsingClosure: Gets the value from the parser.
    /// - Returns: The parsed value.
    /// - Throws: If the parsing closure fails.
    private func cachedRoot<ValueType>(
        as valueKeyPath: WritableKeyPath<ParsingCache, Result<ValueType, any Error>?>,
        parse parsingClosure: (URIParser) throws -> ValueType
    ) throws -> ValueType {
        let value: ValueType
        if let cached = cache[keyPath: valueKeyPath] {
            value = try cached.get()
        } else {
            let result: Result<ValueType, any Error>
            do {
                value = try parsingClosure(parser)
                result = .success(value)
            } catch {
                result = .failure(error)
                throw error
            }
            cache[keyPath: valueKeyPath] = result
        }
        return value
    }

    /// Parse the root as a primitive value.
    ///
    /// Can be nil if the underlying URI is valid, just doesn't contain any value.
    ///
    /// For example, an empty string input into an exploded form decoder (expecting pairs in the form `key=value`)
    /// would result in a nil returned value.
    /// - Returns: The parsed value.
    /// - Throws: When parsing the root fails.
    private func parsedRootAsPrimitive() throws -> URIParsedValue? {
        try cachedRoot(as: \.primitive, parse: { try $0.parseRootAsPrimitive(rootKey: rootKey)?.value })
    }

    /// Parse the root as an array.
    /// - Returns: The parsed value.
    /// - Throws: When parsing the root fails.
    private func parsedRootAsArray() throws -> [URIParsedValue] {
        try cachedRoot(as: \.array, parse: { try $0.parseRootAsArray(rootKey: rootKey).map(\.value) })
    }

    /// Parse the root as a dictionary.
    /// - Returns: The parsed value.
    /// - Throws: When parsing the root fails.
    private func parsedRootAsDictionary() throws -> [URIParsedKeyComponent: [URIParsedValue]] {
        try cachedRoot(
            as: \.dictionary,
            parse: { parser in
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
                return Dictionary(normalizedTuples, uniquingKeysWith: +)
            }
        )
    }

    // MARK: - decoding utilities

    /// Returns a dictionary value.
    /// - Parameters:
    ///   - key: The key for which to return the value.
    ///   - dictionary: The dictionary in which to find the value.
    /// - Returns: The value in the dictionary, or nil if not found.
    /// - Throws: When multiple values are found for the key.
    func primitiveValue(forKey key: String, in dictionary: [URIParsedKeyComponent: [URIParsedValue]]) throws
        -> URIParsedValue?
    {
        let values = dictionary[key[...], default: []]
        if values.isEmpty { return nil }
        if values.count > 1 { try throwMismatch("Dictionary value contains multiple values.") }
        return values[0]
    }

    // MARK: - withCurrent methods

    /// Use the current top of the stack as a primitive value.
    ///
    /// Can be nil if the underlying URI is valid, just doesn't contain any value.
    ///
    /// For example, an empty string input into an exploded form decoder (expecting pairs in the form `key=value`)
    /// would result in a nil returned value.
    /// - Parameter work: The closure in which to use the value.
    /// - Returns: Any value returned from the closure.
    /// - Throws: When parsing the root fails.
    private func withCurrentPrimitiveElement<R>(_ work: (URIParsedValue?) throws -> R) throws -> R {
        if !codingStack.isEmpty {
            // Nesting is involved.
            // There are exactly three scenarios we support:
            // - primitive in a top level array
            // - primitive in a top level dictionary
            // - primitive in a nested array inside a top level dictionary
            if codingStack.count == 1 {
                let key = codingStack[0]
                if let intKey = key.intValue {
                    // Top level array.
                    return try work(parsedRootAsArray()[intKey])
                } else {
                    // Top level dictionary.
                    return try work(primitiveValue(forKey: key.stringValue, in: parsedRootAsDictionary()))
                }
            } else if codingStack.count == 2 {
                // Nested array within a top level dictionary.
                let dictionaryKey = codingStack[0].stringValue[...]
                guard let nestedArrayKey = codingStack[1].intValue else {
                    try throwMismatch("Nested coding key is not an integer, hinting at unsupported nesting.")
                }
                return try work(parsedRootAsDictionary()[dictionaryKey, default: []][nestedArrayKey])
            } else {
                try throwMismatch("Arbitrary nesting of containers is not supported.")
            }
        } else {
            // Top level primitive.
            return try work(parsedRootAsPrimitive())
        }
    }

    /// Use the current top of the stack as an array.
    /// - Parameter work: The closure in which to use the value.
    /// - Returns: Any value returned from the closure.
    /// - Throws: When parsing the root fails.
    private func withCurrentArrayElements<R>(_ work: ([URIParsedValue]) throws -> R) throws -> R {
        if let nestedArrayParentKey = codingStack.first {
            // Top level is dictionary, first level nesting is array.
            // Get all the elements that match this rootKey + nested key path.
            return try work(parsedRootAsDictionary()[nestedArrayParentKey.stringValue[...]] ?? [])
        } else {
            // Top level array.
            return try work(parsedRootAsArray())
        }
    }

    /// Use the current top of the stack as a dictionary.
    /// - Parameter work: The closure in which to use the value.
    /// - Returns: Any value returned from the closure.
    /// - Throws: When parsing the root fails or if there is unsupported extra nesting of containers.
    private func withCurrentDictionaryElements<R>(_ work: ([URIParsedKeyComponent: [URIParsedValue]]) throws -> R)
        throws -> R
    {
        if !codingStack.isEmpty {
            try throwMismatch("Nesting a dictionary inside another container is not supported.")
        } else {
            // Top level dictionary.
            return try work(parsedRootAsDictionary())
        }
    }

    // MARK: - metadata and data accessors

    /// Returns the current top-of-stack as a primitive value.
    ///
    /// Can be nil if the underlying URI is valid, just doesn't contain any value.
    ///
    /// For example, an empty string input into an exploded form decoder (expecting pairs in the form `key=value`)
    /// would result in a nil returned value.
    /// - Returns: The primitive value, or nil if not found.
    /// - Throws: When parsing the root fails.
    func currentElementAsSingleValue() throws -> URIParsedValue? { try withCurrentPrimitiveElement { $0 } }

    /// Returns the count of elements in the current top-of-stack array.
    /// - Returns: The number of elements.
    /// - Throws: When parsing the root fails.
    func countOfCurrentArray() throws -> Int { try withCurrentArrayElements { $0.count } }

    /// Returns an element from the current top-of-stack array.
    /// - Parameter index: The position in the array to return.
    /// - Returns: The primitive value from the array.
    /// - Throws: When parsing the root fails.
    func nestedElementInCurrentArray(atIndex index: Int) throws -> URIParsedValue {
        try withCurrentArrayElements { $0[index] }
    }

    /// Returns an element from the current top-of-stack dictionary.
    /// - Parameter key: The key to find a value for.
    /// - Returns: The value for the key, or nil if not found.
    /// - Throws: When parsing the root fails.
    func nestedElementInCurrentDictionary(forKey key: String) throws -> URIParsedValue? {
        try withCurrentDictionaryElements { dictionary in try primitiveValue(forKey: key, in: dictionary) }
    }

    /// Returns a Boolean value that represents whether the current top-of-stack dictionary
    /// contains a value for the provided key.
    /// - Parameter key: The key for which to look for a value.
    /// - Returns: `true` if a value was found, `false` otherwise.
    func containsElementInCurrentDictionary(forKey key: String) -> Bool {
        (try? withCurrentDictionaryElements({ dictionary in dictionary[key[...]] != nil })) ?? false
    }

    /// Returns a list of keys found in the current top-of-stack dictionary.
    /// - Returns: A list of keys from the dictionary.
    /// - Throws: When parsing the root fails.
    func elementKeysInCurrentDictionary() -> [String] {
        (try? withCurrentDictionaryElements { dictionary in dictionary.keys.map(String.init) }) ?? []
    }
}

extension URIValueFromNodeDecoder: Decoder {

    var codingPath: [any CodingKey] { codingStack }

    var userInfo: [CodingUserInfoKey: Any] { [:] }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        KeyedDecodingContainer(URIKeyedDecodingContainer(decoder: self))
    }

    func unkeyedContainer() throws -> any UnkeyedDecodingContainer { URIUnkeyedDecodingContainer(decoder: self) }

    func singleValueContainer() throws -> any SingleValueDecodingContainer {
        URISingleValueDecodingContainer(decoder: self)
    }
}
