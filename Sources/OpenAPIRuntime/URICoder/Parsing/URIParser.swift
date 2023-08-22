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

/// Converts an URINode value into a string.
struct URIParser: Sendable {

    private typealias Raw = String.SubSequence
    private var data: Raw

    init(data: String) {
        self.data = data[...]
    }
}

extension URIParser {

//    mutating func parseRoot() throws -> URIParsedNode.Root {
//    }
}

fileprivate enum ParsingError: Swift.Error {
    case unexpectadlyFoundEnd
    case malformedBracketedString
}

extension String.SubSequence {
    
    mutating func parseUntilOrEnd(character: Character) -> Self {
        let startIndex = startIndex
        var index = startIndex
        while index != endIndex && self[index] != character {
            formIndex(after: &index)
        }
        let parsed = self[startIndex..<index]
        self = self[index...]
        return parsed
    }

    mutating func parseUntil(character: Character) throws -> Self {
        let parsed = parseUntilOrEnd(character: character)
        guard !isEmpty else {
            throw ParsingError.unexpectadlyFoundEnd
        }
        return parsed
    }
    
    mutating func parseUpTo(character: Character) throws -> Self {
        let startIndex = startIndex
        var index = startIndex
        while index != endIndex && self[index] != character {
            formIndex(after: &index)
        }
        if index == endIndex {
            throw ParsingError.unexpectadlyFoundEnd
        }
        let parsed = self[startIndex...index]
        formIndex(after: &index)
        self = self[index...]
        return parsed
    }
    
    mutating func stripSquareBrackets() throws {
        guard let first, let last, first == "[" && last == "]" else {
            throw ParsingError.malformedBracketedString
        }
        let newStart = index(after: startIndex)
        let newEnd = index(before: endIndex)
        self = self[newStart..<newEnd]
    }
}

extension URIParser {

    private enum KeyComponent {
        case index(Int)
        case key(Raw)
        
        init(rawValue: Raw) {
            // TODO: Not the most reliable way probably, but fine to start.
            if let int = Int(rawValue) {
                self = .index(int)
            } else {
                self = .key(rawValue)
            }
        }
    }

    private typealias Key = [KeyComponent]

    private func unescapeValue(_ escapedValue: String) -> String {
        // TODO: Unescape the value here
        escapedValue
    }
    
    private func parsedKey(_ rawKey: Raw) throws -> Key {
        // TODO: This will differ based on configuration.
        
        var rawKey = rawKey
        
        // First subsequence until "[" is found is the first component.
        let rootKey = rawKey.parseUntilOrEnd(character: "[")
        
        var childComponents: [KeyComponent] = []
        while !rawKey.isEmpty {
            var parsedKey = try rawKey.parseUpTo(character: "]")
            try parsedKey.stripSquareBrackets()
            childComponents.append(.init(rawValue: parsedKey))
        }
        return [.key(rootKey)] + childComponents
    }

//    private func stringifiedKey(_ key: Key) throws -> String {
//        // The root key is handled separately.
//        guard !key.isEmpty else {
//            return ""
//        }
//        let topLevelKey = key[0]
//        guard case .key(let string) = topLevelKey else {
//            throw SerializationError.topLevelKeyMustBeString
//        }
//        let safeTopLevelKey = computeSafeKey(string)
//        return
//            ([safeTopLevelKey]
//            + key
//            .dropFirst()
//            .map(stringifiedKeyComponent))
//            .joined()
//    }
//
//    private mutating func serializeNode(_ value: URIEncodableNode, forKey key: Key) throws {
//        switch value {
//        case .unset:
//            // TODO: Is there a distinction here between `a=` and `a`, in other
//            // words between an empty string value and a nil value?
//            data.append(try stringifiedKey(key))
//            data.append("=")
//        case .primitive(let primitive):
//            try serializePrimitiveValue(primitive, forKey: key)
//        case .array(let array):
//            try serializeArray(array, forKey: key)
//        case .dictionary(let dictionary):
//            try serializeDictionary(dictionary, forKey: key)
//        }
//    }
//
//    private mutating func serializePrimitiveValue(
//        _ value: URIEncodableNode.Primitive,
//        forKey key: Key
//    ) throws {
//        let stringValue: String
//        switch value {
//        case .bool(let bool):
//            stringValue = bool.description
//        case .string(let string):
//            stringValue = computeSafeValue(string)
//        case .integer(let int):
//            stringValue = int.description
//        case .double(let double):
//            stringValue = double.description
//        }
//        data.append(try stringifiedKey(key))
//        data.append("=")
//        data.append(stringValue)
//    }
//
//    private mutating func serializeArray(
//        _ array: [URIEncodableNode],
//        forKey key: Key
//    ) throws {
//        try serializeTuples(
//            array.enumerated()
//                .map { index, element in
//                    (key + [.index(index)], element)
//                }
//        )
//    }
//
//    private mutating func serializeDictionary(
//        _ dictionary: [String: URIEncodableNode],
//        forKey key: Key
//    ) throws {
//        try serializeTuples(
//            dictionary
//                .sorted { a, b in
//                    a.key.localizedCaseInsensitiveCompare(b.key)
//                        == .orderedAscending
//                }
//                .map { elementKey, element in
//                    (key + [.key(elementKey[...])], element)
//                }
//        )
//    }
//
//    private mutating func serializeTuples(
//        _ items: [(Key, URIEncodableNode)]
//    ) throws {
//        guard !items.isEmpty else {
//            return
//        }
//        for (key, element) in items.dropLast() {
//            try serializeNode(element, forKey: key)
//            data.append("&")
//        }
//        if let (key, element) = items.last {
//            try serializeNode(element, forKey: key)
//        }
//    }
}
