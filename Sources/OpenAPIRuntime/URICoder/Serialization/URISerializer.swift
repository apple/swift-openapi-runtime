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

/// A type that serializes a `URIEncodedNode` to a URI-encoded string.
struct URISerializer {

    /// The configuration instructing the serializer how to format the raw
    /// string.
    private let configuration: URICoderConfiguration

    /// The underlying raw string storage.
    private var data: String

    /// Creates a new serializer.
    /// - Parameter configuration: The configuration instructing the serializer
    /// how to format the raw string.
    init(configuration: URICoderConfiguration) {
        self.configuration = configuration
        self.data = ""
    }

    /// Serializes the provided node into the underlying string.
    /// - Parameters:
    ///   - value: The node to serialize.
    ///   - key: The key to serialize the node under (details depend on the
    ///     style and explode parameters in the configuration).
    /// - Returns: The URI-encoded data for the provided node.
    /// - Throws: An error if serialization of the node fails.
    mutating func serializeNode(
        _ value: URIEncodedNode,
        forKey key: String
    ) throws -> String {
        defer {
            data.removeAll(keepingCapacity: true)
        }
        try serializeTopLevelNode(value, forKey: key)
        return data
    }
}

extension CharacterSet {

    /// A character set of unreserved symbols only from RFC 6570 (excludes
    /// alphanumeric characters).
    fileprivate static let unreservedSymbols: CharacterSet = .init(charactersIn: "-._~")

    /// A character set of unreserved characters from RFC 6570.
    fileprivate static let unreserved: CharacterSet = .alphanumerics.union(unreservedSymbols)

    /// A character set with only the space character.
    fileprivate static let space: CharacterSet = .init(charactersIn: " ")

    /// A character set of unreserved characters and a space.
    fileprivate static let unreservedAndSpace: CharacterSet = .unreserved.union(space)
}

extension URISerializer {

    /// A serializer error.
    private enum SerializationError: Swift.Error {

        /// Nested containers are not supported.
        case nestedContainersNotSupported
    }

    /// Computes an escaped version of the provided string.
    /// - Parameter unsafeString: A string that needs escaping.
    /// - Returns: The provided string with percent-escaping applied.
    private func computeSafeString(_ unsafeString: String) -> String {
        // The space character needs to be encoded based on the config,
        // so first allow it to be unescaped, and then we'll do a second
        // pass and only encode the space based on the config.
        let partiallyEncoded =
            unsafeString.addingPercentEncoding(
                withAllowedCharacters: .unreservedAndSpace
            ) ?? ""
        let fullyEncoded = partiallyEncoded.replacingOccurrences(
            of: " ",
            with: configuration.spaceEscapingCharacter.rawValue
        )
        return fullyEncoded
    }

    /// Provides a raw string value for the provided key.
    /// - Parameter key: The key to stringify.
    /// - Returns: The escaped version of the provided key.
    /// - Throws: An error if the key cannot be converted to an escaped string.
    private func stringifiedKey(_ key: String) throws -> String {
        // The root key is handled separately.
        guard !key.isEmpty else {
            return ""
        }
        let safeTopLevelKey = computeSafeString(key)
        return safeTopLevelKey
    }

    /// Serializes the provided value into the underlying string.
    /// - Parameters:
    ///   - value: The value to serialize.
    ///   - key: The key to serialize the value under (details depend on the
    ///     style and explode parameters in the configuration).
    /// - Throws: An error if serialization of the value fails.
    private mutating func serializeTopLevelNode(
        _ value: URIEncodedNode,
        forKey key: String
    ) throws {
        func unwrapPrimitiveValue(_ node: URIEncodedNode) throws -> URIEncodedNode.Primitive {
            guard case let .primitive(primitive) = node else {
                throw SerializationError.nestedContainersNotSupported
            }
            return primitive
        }
        switch value {
        case .unset:
            // Nothing to serialize.
            break
        case .primitive(let primitive):
            let keyAndValueSeparator: String?
            switch configuration.style {
            case .form:
                keyAndValueSeparator = "="
            case .simple:
                keyAndValueSeparator = nil
            }
            try serializePrimitiveKeyValuePair(
                primitive,
                forKey: key,
                separator: keyAndValueSeparator
            )
        case .array(let array):
            try serializeArray(
                array.map(unwrapPrimitiveValue),
                forKey: key
            )
        case .dictionary(let dictionary):
            try serializeDictionary(
                dictionary.mapValues(unwrapPrimitiveValue),
                forKey: key
            )
        }
    }

    /// Serializes the provided value into the underlying string.
    /// - Parameter value: The primitive value to serialize.
    /// - Throws: An error if serialization of the primitive value fails.
    private mutating func serializePrimitiveValue(
        _ value: URIEncodedNode.Primitive
    ) throws {
        let stringValue: String
        switch value {
        case .bool(let bool):
            stringValue = bool.description
        case .string(let string):
            stringValue = computeSafeString(string)
        case .integer(let int):
            stringValue = int.description
        case .double(let double):
            stringValue = double.description
        case .date(let date):
            stringValue = try computeSafeString(configuration.dateTranscoder.encode(date))
        }
        data.append(stringValue)
    }

    /// Serializes the provided key-value pair into the underlying string.
    /// - Parameters:
    ///   - value: The value to serialize.
    ///   - key: The key to serialize the value under (details depend on the
    ///     style and explode parameters in the configuration).
    ///   - separator: The separator to use, if nil, the key is not serialized,
    ///     only the value.
    /// - Throws: An error if serialization of the key-value pair fails.
    private mutating func serializePrimitiveKeyValuePair(
        _ value: URIEncodedNode.Primitive,
        forKey key: String,
        separator: String?
    ) throws {
        if let separator {
            data.append(try stringifiedKey(key))
            data.append(separator)
        }
        try serializePrimitiveValue(value)
    }

    /// Serializes the provided array into the underlying string.
    /// - Parameters:
    ///   - array: The value to serialize.
    ///   - key: The key to serialize the value under (details depend on the
    ///     style and explode parameters in the configuration).
    /// - Throws: An error if serialization of the array fails.
    private mutating func serializeArray(
        _ array: [URIEncodedNode.Primitive],
        forKey key: String
    ) throws {
        guard !array.isEmpty else {
            return
        }
        let keyAndValueSeparator: String?
        let pairSeparator: String
        switch (configuration.style, configuration.explode) {
        case (.form, true):
            keyAndValueSeparator = "="
            pairSeparator = "&"
        case (.form, false):
            keyAndValueSeparator = nil
            pairSeparator = ","
        case (.simple, _):
            keyAndValueSeparator = nil
            pairSeparator = ","
        }
        func serializeNext(_ element: URIEncodedNode.Primitive) throws {
            if let keyAndValueSeparator {
                try serializePrimitiveKeyValuePair(
                    element,
                    forKey: key,
                    separator: keyAndValueSeparator
                )
            } else {
                try serializePrimitiveValue(element)
            }
        }
        if let containerKeyAndValue = configuration.containerKeyAndValueSeparator {
            data.append(try stringifiedKey(key))
            data.append(containerKeyAndValue)
        }
        for element in array.dropLast() {
            try serializeNext(element)
            data.append(pairSeparator)
        }
        if let element = array.last {
            try serializeNext(element)
        }
    }

    /// Serializes the provided dictionary into the underlying string.
    /// - Parameters:
    ///   - dictionary: The value to serialize.
    ///   - key: The key to serialize the value under (details depend on the
    ///     style and explode parameters in the configuration).
    /// - Throws: An error if serialization of the dictionary fails.
    private mutating func serializeDictionary(
        _ dictionary: [String: URIEncodedNode.Primitive],
        forKey key: String
    ) throws {
        guard !dictionary.isEmpty else {
            return
        }
        let sortedDictionary =
            dictionary
            .sorted { a, b in
                a.key.localizedCaseInsensitiveCompare(b.key)
                    == .orderedAscending
            }

        let keyAndValueSeparator: String
        let pairSeparator: String
        switch (configuration.style, configuration.explode) {
        case (.form, true):
            keyAndValueSeparator = "="
            pairSeparator = "&"
        case (.form, false):
            keyAndValueSeparator = ","
            pairSeparator = ","
        case (.simple, true):
            keyAndValueSeparator = "="
            pairSeparator = ","
        case (.simple, false):
            keyAndValueSeparator = ","
            pairSeparator = ","
        }

        func serializeNext(_ element: URIEncodedNode.Primitive, forKey elementKey: String) throws {
            try serializePrimitiveKeyValuePair(
                element,
                forKey: elementKey,
                separator: keyAndValueSeparator
            )
        }
        if let containerKeyAndValue = configuration.containerKeyAndValueSeparator {
            data.append(try stringifiedKey(key))
            data.append(containerKeyAndValue)
        }
        for (elementKey, element) in sortedDictionary.dropLast() {
            try serializeNext(element, forKey: elementKey)
            data.append(pairSeparator)
        }
        if let (elementKey, element) = sortedDictionary.last {
            try serializeNext(element, forKey: elementKey)
        }
    }
}

extension URICoderConfiguration {

    /// Returns the separator of a key and value in a pair for
    /// the configuration. Can be nil, in which case no key should be
    /// serialized, only the value.
    fileprivate var containerKeyAndValueSeparator: String? {
        switch (style, explode) {
        case (.form, false):
            return "="
        default:
            return nil
        }
    }
}
