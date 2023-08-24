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

/// Serializes data into a subset of variable expansions from RFC 6570.
///
/// [RFC 6570 - Form-style query expansion.](https://datatracker.ietf.org/doc/html/rfc6570#section-3.2.8)
///
/// | Example Template |   Expansion                       |
/// | ---------------- | ----------------------------------|
/// | `{?who}`         | `?who=fred`                       |
/// | `{?half}`        | `?half=50%25`                     |
/// | `{?x,y}`         | `?x=1024&y=768`                   |
/// | `{?x,y,empty}`   | `?x=1024&y=768&empty=`            |
/// | `{?x,y,undef}`   | `?x=1024&y=768`                   |
/// | `{?list}`        | `?list=red,green,blue`            |
/// | `{?list\*}`      | `?list=red&list=green&list=blue`  |
/// | `{?keys}`        | `?keys=semi,%3B,dot,.,comma,%2C`  |
/// | `{?keys\*}`      | `?semi=%3B&dot=.&comma=%2C`       |
///
/// [RFC 6570 - Simple string expansion.](https://datatracker.ietf.org/doc/html/rfc6570#section-3.2.2)
///
/// | Example Template |   Expansion                       |
/// | ---------------- | ----------------------------------|
/// | `{hello}`        | `Hello%20World%21`                |
/// | `{half}`         | `50%25`                           |
/// | `{x,y}`          | `1024,768`                        |
/// | `{x,empty}`      | `1024,`                           |
/// | `{x,undef}`      | `1024`                            |
/// | `{list}`         | `red,green,blue`                  |
/// | `{list\*}`       | `red,green,blue`                  |
/// | `{keys}`         | `semi,%3B,dot,.,comma,%2C`        |
/// | `{keys\*}`       | `semi=%3B,dot=.,comma=%2C`        |
struct URISerializer {

    private let configuration: URICoderConfiguration
    private var data: String

    init(configuration: URICoderConfiguration) {
        self.configuration = configuration
        self.data = ""
    }
}

extension CharacterSet {
    fileprivate static let unreservedSymbols: CharacterSet = .init(charactersIn: "-._~")
    fileprivate static let unreserved: CharacterSet = .alphanumerics.union(unreservedSymbols)
    fileprivate static let space: CharacterSet = .init(charactersIn: " ")
    fileprivate static let unreservedAndSpace: CharacterSet = .unreserved.union(space)
}

extension URISerializer {

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
}

extension URISerializer {

    private enum SerializationError: Swift.Error {
        case nestedContainersNotSupported
    }

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

    private func stringifiedKey(_ key: String) throws -> String {
        // The root key is handled separately.
        guard !key.isEmpty else {
            return ""
        }
        let safeTopLevelKey = computeSafeString(key)
        return safeTopLevelKey
    }

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
        }
        data.append(stringValue)
    }

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
    fileprivate var containerKeyAndValueSeparator: String? {
        switch (style, explode) {
        case (.form, false):
            return "="
        default:
            return nil
        }
    }
}
