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

/// A type that parses a `URIParsedNode` from a URI-encoded string.
struct URIParser: Sendable {

    /// The configuration instructing the parser how to interpret the raw
    /// string.
    private let configuration: URICoderConfiguration

    /// The underlying raw string storage.
    private var data: Raw

    /// Creates a new parser.
    /// - Parameters:
    ///   - configuration: The configuration instructing the parser how
    ///   to interpret the raw string.
    ///   - data: The string to parse.
    init(configuration: URICoderConfiguration, data: Substring) {
        self.configuration = configuration
        self.data = data[...]
    }
}

/// A typealias for the underlying raw string storage.
typealias Raw = String.SubSequence

/// A parser error.
enum ParsingError: Swift.Error, Hashable {

    /// A malformed key-value pair was detected.
    case malformedKeyValuePair(Raw)
    /// An invalid configuration was detected.
    case invalidConfiguration(String)
}

// MARK: - Parser implementations

extension URIParser {

    /// Parses the root node from the underlying string, selecting the logic
    /// based on the configuration.
    /// - Returns: The parsed root node.
    /// - Throws: An error if parsing fails.
    mutating func parseRoot() throws -> URIParsedNode {
        // A completely empty string should get parsed as a single
        // empty key with a single element array with an empty string
        // if the style is simple, otherwise it's an empty dictionary.
        if data.isEmpty {
            switch configuration.style {
            case .form: return [:]
            case .simple: return ["": [""]]
            case .deepObject: return [:]
            }
        }
        switch (configuration.style, configuration.explode) {
        case (.form, true): return try parseExplodedFormRoot()
        case (.form, false): return try parseUnexplodedFormRoot()
        case (.simple, true): return try parseExplodedSimpleRoot()
        case (.simple, false): return try parseUnexplodedSimpleRoot()
        case (.deepObject, true): return try parseExplodedDeepObjectRoot()
        case (.deepObject, false):
            let reason = "Deep object style is only valid with explode set to true"
            throw ParsingError.invalidConfiguration(reason)
        }
    }

    /// Parses the root node assuming the raw string uses the form style
    /// and the explode parameter is enabled.
    /// - Returns: The parsed root node.
    /// - Throws: An error if parsing fails.
    private mutating func parseExplodedFormRoot() throws -> URIParsedNode {
        try parseGenericRoot { data, appendPair in
            let keyValueSeparator: Character = "="
            let pairSeparator: Character = "&"

            while !data.isEmpty {
                let (firstResult, firstValue) = data.parseUpToEitherCharacterOrEnd(
                    first: keyValueSeparator,
                    second: pairSeparator
                )
                let key: Raw
                let value: Raw
                switch firstResult {
                case .foundFirst:
                    // Hit the key/value separator, so a value will follow.
                    let secondValue = data.parseUpToCharacterOrEnd(pairSeparator)
                    key = firstValue
                    value = secondValue
                case .foundSecondOrEnd:
                    // No key/value separator, treat the string as the key.
                    key = firstValue
                    value = .init()
                }
                appendPair(key, [value])
            }
        }
    }

    /// Parses the root node assuming the raw string uses the form style
    /// and the explode parameter is disabled.
    /// - Returns: The parsed root node.
    /// - Throws: An error if parsing fails.
    private mutating func parseUnexplodedFormRoot() throws -> URIParsedNode {
        try parseGenericRoot { data, appendPair in
            let keyValueSeparator: Character = "="
            let pairSeparator: Character = "&"
            let valueSeparator: Character = ","

            while !data.isEmpty {
                let (firstResult, firstValue) = data.parseUpToEitherCharacterOrEnd(
                    first: keyValueSeparator,
                    second: pairSeparator
                )
                let key: Raw
                let values: [Raw]
                switch firstResult {
                case .foundFirst:
                    // Hit the key/value separator, so one or more values will follow.
                    var accumulatedValues: [Raw] = []
                    valueLoop: while !data.isEmpty {
                        let (secondResult, secondValue) = data.parseUpToEitherCharacterOrEnd(
                            first: valueSeparator,
                            second: pairSeparator
                        )
                        accumulatedValues.append(secondValue)
                        switch secondResult {
                        case .foundFirst:
                            // Hit the value separator, so ended one value and
                            // another one is coming.
                            continue
                        case .foundSecondOrEnd:
                            // Hit the pair separator or the end, this is the
                            // last value.
                            break valueLoop
                        }
                    }
                    if accumulatedValues.isEmpty {
                        // We hit the key/value separator, so always write
                        // at least one empty value.
                        accumulatedValues.append("")
                    }
                    key = firstValue
                    values = accumulatedValues
                case .foundSecondOrEnd: throw ParsingError.malformedKeyValuePair(firstValue)
                }
                appendPair(key, values)
            }
        }
    }

    /// Parses the root node assuming the raw string uses the simple style
    /// and the explode parameter is enabled.
    /// - Returns: The parsed root node.
    /// - Throws: An error if parsing fails.
    private mutating func parseExplodedSimpleRoot() throws -> URIParsedNode {
        try parseGenericRoot { data, appendPair in
            let keyValueSeparator: Character = "="
            let pairSeparator: Character = ","

            while !data.isEmpty {
                let (firstResult, firstValue) = data.parseUpToEitherCharacterOrEnd(
                    first: keyValueSeparator,
                    second: pairSeparator
                )
                let key: Raw
                let value: Raw
                switch firstResult {
                case .foundFirst:
                    // Hit the key/value separator, so a value will follow.
                    let secondValue = data.parseUpToCharacterOrEnd(pairSeparator)
                    key = firstValue
                    value = secondValue
                case .foundSecondOrEnd:
                    // No key/value separator, treat the string as the value.
                    key = .init()
                    value = firstValue
                }
                appendPair(key, [value])
            }
        }
    }

    /// Parses the root node assuming the raw string uses the simple style
    /// and the explode parameter is disabled.
    /// - Returns: The parsed root node.
    /// - Throws: An error if parsing fails.
    private mutating func parseUnexplodedSimpleRoot() throws -> URIParsedNode {
        // Unexploded simple dictionary cannot be told apart from
        // an array, so we just accumulate all pairs as standalone
        // values and add them to the array. It'll be the higher
        // level decoder's responsibility to parse this properly.

        try parseGenericRoot { data, appendPair in
            let pairSeparator: Character = ","
            while !data.isEmpty {
                let value = data.parseUpToCharacterOrEnd(pairSeparator)
                appendPair(.init(), [value])
            }
        }
    }
    /// Parses the root node assuming the raw string uses the deepObject style
    /// and the explode parameter is enabled.
    /// - Returns: The parsed root node.
    /// - Throws: An error if parsing fails.
    private mutating func parseExplodedDeepObjectRoot() throws -> URIParsedNode {
        let parseNode = try parseGenericRoot { data, appendPair in
            let keyValueSeparator: Character = "="
            let pairSeparator: Character = "&"
            let nestedKeyStartingCharacter: Character = "["
            let nestedKeyEndingCharacter: Character = "]"
            func nestedKey(from deepObjectKey: String.SubSequence) -> Raw {
                var unescapedDeepObjectKey = Substring(deepObjectKey.removingPercentEncoding ?? "")
                let topLevelKey = unescapedDeepObjectKey.parseUpToCharacterOrEnd(nestedKeyStartingCharacter)
                let nestedKey = unescapedDeepObjectKey.parseUpToCharacterOrEnd(nestedKeyEndingCharacter)
                return nestedKey.isEmpty ? topLevelKey : nestedKey
            }
            while !data.isEmpty {
                let (firstResult, firstValue) = data.parseUpToEitherCharacterOrEnd(
                    first: keyValueSeparator,
                    second: pairSeparator
                )
                guard case .foundFirst = firstResult else { throw ParsingError.malformedKeyValuePair(firstValue) }
                // Hit the key/value separator, so a value will follow.
                let secondValue = data.parseUpToCharacterOrEnd(pairSeparator)
                let key = nestedKey(from: firstValue)
                let value = secondValue
                appendPair(key, [value])
            }
        }
        return parseNode
    }
}

// MARK: - URIParser utilities

extension URIParser {

    /// Parses the underlying string using a parser closure.
    /// - Parameter parser: A closure that accepts another closure, which should
    ///   be called 0 or more times, once for each parsed key-value pair.
    /// - Returns: The accumulated node.
    /// - Throws: An error if parsing using the provided parser closure fails,
    private mutating func parseGenericRoot(_ parser: (inout Raw, (Raw, [Raw]) -> Void) throws -> Void) throws
        -> URIParsedNode
    {
        var root = URIParsedNode()
        let spaceEscapingCharacter = configuration.spaceEscapingCharacter
        let unescapeValue: (Raw) -> Raw = { Self.unescapeValue($0, spaceEscapingCharacter: spaceEscapingCharacter) }
        try parser(&data) { key, values in
            let newItem = [unescapeValue(key): values.map(unescapeValue)]
            root.merge(newItem) { $0 + $1 }
        }
        return root
    }

    /// Removes escaping from the provided string.
    /// - Parameter escapedValue: An escaped string.
    /// - Returns: The provided string with escaping removed.
    private func unescapeValue(_ escapedValue: Raw) -> Raw {
        Self.unescapeValue(escapedValue, spaceEscapingCharacter: configuration.spaceEscapingCharacter)
    }

    /// Removes escaping from the provided string.
    /// - Parameters:
    ///   - escapedValue: An escaped string.
    ///   - spaceEscapingCharacter: The character used to escape the space
    ///     character.
    /// - Returns: The provided string with escaping removed.
    private static func unescapeValue(
        _ escapedValue: Raw,
        spaceEscapingCharacter: URICoderConfiguration.SpaceEscapingCharacter
    ) -> Raw {
        // The inverse of URISerializer.computeSafeString.
        let partiallyDecoded = escapedValue.replacingOccurrences(of: spaceEscapingCharacter.rawValue, with: " ")
        return (partiallyDecoded.removingPercentEncoding ?? "")[...]
    }
}

// MARK: - Substring utilities

extension String.SubSequence {

    /// A result of calling `parseUpToEitherCharacterOrEnd`.
    fileprivate enum ParseUpToEitherCharacterResult {

        /// The first character was detected.
        case foundFirst

        /// The second character was detected, or the end was reached.
        case foundSecondOrEnd
    }

    /// Accumulates characters until one of the parameter characters is found,
    /// or the end is reached. Moves the underlying startIndex.
    /// - Parameters:
    ///   - first: A character to stop at.
    ///   - second: Another character to stop at.
    /// - Returns: A result indicating which character was detected, if any, and
    ///   the accumulated substring.
    fileprivate mutating func parseUpToEitherCharacterOrEnd(first: Character, second: Character) -> (
        ParseUpToEitherCharacterResult, Self
    ) {
        let startIndex = startIndex
        guard startIndex != endIndex else { return (.foundSecondOrEnd, .init()) }
        var currentIndex = startIndex

        func finalize(_ result: ParseUpToEitherCharacterResult) -> (ParseUpToEitherCharacterResult, Self) {
            let parsed = self[startIndex..<currentIndex]
            guard currentIndex == endIndex else {
                self = self[index(after: currentIndex)...]
                return (result, parsed)
            }
            self = .init()
            return (result, parsed)
        }
        while currentIndex != endIndex {
            let currentChar = self[currentIndex]
            if currentChar == first {
                return finalize(.foundFirst)
            } else if currentChar == second {
                return finalize(.foundSecondOrEnd)
            } else {
                formIndex(after: &currentIndex)
            }
        }
        return finalize(.foundSecondOrEnd)
    }

    /// Accumulates characters until the provided character is found,
    /// or the end is reached. Moves the underlying startIndex.
    /// - Parameter character: A character to stop at.
    /// - Returns: The accumulated substring.
    fileprivate mutating func parseUpToCharacterOrEnd(_ character: Character) -> Self {
        let startIndex = startIndex
        guard startIndex != endIndex else { return .init() }
        var currentIndex = startIndex

        func finalize() -> Self {
            let parsed = self[startIndex..<currentIndex]
            guard currentIndex == endIndex else {
                self = self[index(after: currentIndex)...]
                return parsed
            }
            self = .init()
            return parsed
        }
        while currentIndex != endIndex {
            let currentChar = self[currentIndex]
            if currentChar == character { return finalize() } else { formIndex(after: &currentIndex) }
        }
        return finalize()
    }
}
