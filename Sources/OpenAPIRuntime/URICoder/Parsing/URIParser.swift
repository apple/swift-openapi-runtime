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

/// A type that can parse a primitive, array, and a dictionary from a URI-encoded string.
struct URIParser: Sendable {

    /// The configuration of the parser.
    private let configuration: URICoderConfiguration

    /// The string to parse.
    private let data: Raw

    /// Creates a new parser.
    /// - Parameters:
    ///   - configuration: The configuration of the parser.
    ///   - data: The string to parse.
    init(configuration: URICoderConfiguration, data: Substring) {
        self.configuration = configuration
        self.data = data
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
    /// Parses the string as a primitive value.
    /// - Parameter rootKey: The key of the root object, used to filter out unrelated values.
    /// - Returns: The parsed primitive value, or nil if not found.
    /// - Throws: When parsing the root fails.
    func parseRootAsPrimitive(rootKey: URIParsedKeyComponent) throws -> URIParsedPair? {
        var data = data
        switch (configuration.style, configuration.explode) {
        case (.form, _):
            let keyValueSeparator: Character = "="
            let pairSeparator: Character = "&"
            while !data.isEmpty {
                let (firstResult, firstValue) = data.parseUpToEitherCharacterOrEnd(
                    first: keyValueSeparator,
                    second: pairSeparator
                )
                switch firstResult {
                case .foundFirst:
                    let unescapedKey = unescapeValue(firstValue)
                    if unescapedKey == rootKey {
                        let secondValue = data.parseUpToCharacterOrEnd(pairSeparator)
                        let key = URIParsedKey([unescapedKey])
                        return .init(key: key, value: unescapeValue(secondValue))
                    } else {
                        // Ignore the value, skip to the end of the pair.
                        _ = data.parseUpToCharacterOrEnd(pairSeparator)
                    }
                case .foundSecondOrEnd: throw ParsingError.malformedKeyValuePair(firstValue)
                }
            }
            return nil
        case (.simple, _): return .init(key: .empty, value: unescapeValue(data))
        case (.deepObject, true):
            throw ParsingError.invalidConfiguration("deepObject does not support primitive values, only dictionaries")
        case (.deepObject, false):
            throw ParsingError.invalidConfiguration("deepObject + explode: false is not supported")
        }
    }

    /// Parses the string as an array.
    /// - Parameter rootKey: The key of the root object, used to filter out unrelated values.
    /// - Returns: The parsed array.
    /// - Throws: When parsing the root fails.
    func parseRootAsArray(rootKey: URIParsedKeyComponent) throws -> URIParsedPairArray {
        var data = data
        switch (configuration.style, configuration.explode) {
        case (.form, true):
            let keyValueSeparator: Character = "="
            let pairSeparator: Character = "&"
            var items: URIParsedPairArray = []
            while !data.isEmpty {
                let (firstResult, firstValue) = data.parseUpToEitherCharacterOrEnd(
                    first: keyValueSeparator,
                    second: pairSeparator
                )
                switch firstResult {
                case .foundFirst:
                    let unescapedKey = unescapeValue(firstValue)
                    if unescapedKey == rootKey {
                        let secondValue = data.parseUpToCharacterOrEnd(pairSeparator)
                        let key = URIParsedKey([unescapedKey])
                        items.append(.init(key: key, value: unescapeValue(secondValue)))
                    } else {
                        // Ignore the value, skip to the end of the pair.
                        _ = data.parseUpToCharacterOrEnd(pairSeparator)
                    }
                case .foundSecondOrEnd: throw ParsingError.malformedKeyValuePair(firstValue)
                }
            }
            return items
        case (.form, false):
            let keyValueSeparator: Character = "="
            let pairSeparator: Character = "&"
            let arrayElementSeparator: Character = ","
            var items: URIParsedPairArray = []
            while !data.isEmpty {
                let (firstResult, firstValue) = data.parseUpToEitherCharacterOrEnd(
                    first: keyValueSeparator,
                    second: pairSeparator
                )
                switch firstResult {
                case .foundFirst:
                    let unescapedKey = unescapeValue(firstValue)
                    if unescapedKey == rootKey {
                        let key = URIParsedKey([unescapedKey])
                        elementScan: while !data.isEmpty {
                            let (secondResult, secondValue) = data.parseUpToEitherCharacterOrEnd(
                                first: arrayElementSeparator,
                                second: pairSeparator
                            )
                            items.append(.init(key: key, value: unescapeValue(secondValue)))
                            switch secondResult {
                            case .foundFirst: continue elementScan
                            case .foundSecondOrEnd: break elementScan
                            }
                        }
                    } else {
                        // Ignore the value, skip to the end of the pair.
                        _ = data.parseUpToCharacterOrEnd(pairSeparator)
                    }
                case .foundSecondOrEnd: throw ParsingError.malformedKeyValuePair(firstValue)
                }
            }
            return items
        case (.simple, _):
            let pairSeparator: Character = ","
            var items: URIParsedPairArray = []
            while !data.isEmpty {
                let value = data.parseUpToCharacterOrEnd(pairSeparator)
                items.append(.init(key: .empty, value: unescapeValue(value)))
            }
            return items
        case (.deepObject, true):
            throw ParsingError.invalidConfiguration("deepObject does not support array values, only dictionaries")
        case (.deepObject, false):
            throw ParsingError.invalidConfiguration("deepObject + explode: false is not supported")
        }
    }

    /// Parses the string as a dictionary.
    /// - Parameter rootKey: The key of the root object, used to filter out unrelated values.
    /// - Returns: The parsed key/value pairs as an array.
    /// - Throws: When parsing the root fails.
    func parseRootAsDictionary(rootKey: URIParsedKeyComponent) throws -> URIParsedPairArray {
        var data = data
        switch (configuration.style, configuration.explode) {
        case (.form, true):
            let keyValueSeparator: Character = "="
            let pairSeparator: Character = "&"
            var items: URIParsedPairArray = []
            while !data.isEmpty {
                let (firstResult, firstValue) = data.parseUpToEitherCharacterOrEnd(
                    first: keyValueSeparator,
                    second: pairSeparator
                )
                switch firstResult {
                case .foundFirst:
                    let secondValue = data.parseUpToCharacterOrEnd(pairSeparator)
                    let key = URIParsedKey([unescapeValue(firstValue)])
                    items.append(.init(key: key, value: unescapeValue(secondValue)))
                case .foundSecondOrEnd: throw ParsingError.malformedKeyValuePair(firstValue)
                }
            }
            return items
        case (.form, false):
            let keyValueSeparator: Character = "="
            let pairSeparator: Character = "&"
            let arrayElementSeparator: Character = ","
            var items: URIParsedPairArray = []
            while !data.isEmpty {
                let (firstResult, firstValue) = data.parseUpToEitherCharacterOrEnd(
                    first: keyValueSeparator,
                    second: pairSeparator
                )
                switch firstResult {
                case .foundFirst:
                    let unescapedKey = unescapeValue(firstValue)
                    if unescapedKey == rootKey {
                        elementScan: while !data.isEmpty {
                            let (innerKeyResult, innerKeyValue) = data.parseUpToEitherCharacterOrEnd(
                                first: arrayElementSeparator,
                                second: pairSeparator
                            )
                            switch innerKeyResult {
                            case .foundFirst:
                                let (innerValueResult, innerValueValue) = data.parseUpToEitherCharacterOrEnd(
                                    first: arrayElementSeparator,
                                    second: pairSeparator
                                )
                                items.append(
                                    .init(
                                        key: URIParsedKey([unescapedKey, innerKeyValue]),
                                        value: unescapeValue(innerValueValue)
                                    )
                                )
                                switch innerValueResult {
                                case .foundFirst: continue elementScan
                                case .foundSecondOrEnd: break elementScan
                                }
                            case .foundSecondOrEnd: throw ParsingError.malformedKeyValuePair(innerKeyValue)
                            }
                        }
                    } else {
                        // Ignore the value, skip to the end of the pair.
                        _ = data.parseUpToCharacterOrEnd(pairSeparator)
                    }
                case .foundSecondOrEnd: throw ParsingError.malformedKeyValuePair(firstValue)
                }
            }
            return items
        case (.simple, true):
            let keyValueSeparator: Character = "="
            let pairSeparator: Character = ","
            var items: URIParsedPairArray = []
            while !data.isEmpty {
                let (firstResult, firstValue) = data.parseUpToEitherCharacterOrEnd(
                    first: keyValueSeparator,
                    second: pairSeparator
                )
                let key: URIParsedKey
                let value: URIParsedValue
                switch firstResult {
                case .foundFirst:
                    let secondValue = data.parseUpToCharacterOrEnd(pairSeparator)
                    key = URIParsedKey([unescapeValue(firstValue)])
                    value = secondValue
                    items.append(.init(key: key, value: unescapeValue(value)))
                case .foundSecondOrEnd: throw ParsingError.malformedKeyValuePair(firstValue)
                }
            }
            return items
        case (.simple, false):
            let pairSeparator: Character = ","
            var items: URIParsedPairArray = []
            while !data.isEmpty {
                let rawKey = data.parseUpToCharacterOrEnd(pairSeparator)
                let value: URIParsedValue
                if data.isEmpty { value = "" } else { value = data.parseUpToCharacterOrEnd(pairSeparator) }
                let key = URIParsedKey([unescapeValue(rawKey)])
                items.append(.init(key: key, value: unescapeValue(value)))
            }
            return items
        case (.deepObject, true):
            let keyValueSeparator: Character = "="
            let pairSeparator: Character = "&"
            let nestedKeyStart: Character = "["
            let nestedKeyEnd: Character = "]"
            var items: URIParsedPairArray = []
            while !data.isEmpty {
                let (firstResult, firstValue) = data.parseUpToEitherCharacterOrEnd(
                    first: keyValueSeparator,
                    second: pairSeparator
                )
                switch firstResult {
                case .foundFirst:
                    var unescapedComposedKey = unescapeValue(firstValue)
                    if unescapedComposedKey.contains("[") && unescapedComposedKey.contains("]") {
                        // Do a quick check whether this is even a deepObject-encoded key, as
                        // we need to safely skip any unrelated keys, which might be formatted
                        // some other way.
                        let parentParsedKey = unescapedComposedKey.parseUpToCharacterOrEnd(nestedKeyStart)
                        let childParsedKey = unescapedComposedKey.parseUpToCharacterOrEnd(nestedKeyEnd)
                        if parentParsedKey == rootKey {
                            let key = URIParsedKey([parentParsedKey, childParsedKey])
                            let secondValue = data.parseUpToCharacterOrEnd(pairSeparator)
                            items.append(.init(key: key, value: unescapeValue(secondValue)))
                            continue
                        }
                    }
                    // Ignore the value, skip to the end of the pair.
                    _ = data.parseUpToCharacterOrEnd(pairSeparator)
                case .foundSecondOrEnd: throw ParsingError.malformedKeyValuePair(firstValue)
                }
            }
            return items
        case (.deepObject, false):
            throw ParsingError.invalidConfiguration("deepObject + explode: false is not supported")
        }
    }
}

// MARK: - URIParser utilities

extension URIParser {

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
