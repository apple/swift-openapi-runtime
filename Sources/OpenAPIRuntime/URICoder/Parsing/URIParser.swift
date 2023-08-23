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

/// Parses data from a subset of variable expansions from RFC 6570.
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
struct URIParser: Sendable {

    private let configuration: URISerializationConfiguration
    private typealias Raw = String.SubSequence
    private var data: Raw

    init(configuration: URISerializationConfiguration, data: String) {
        self.configuration = configuration
        self.data = data[...]
    }
}

fileprivate enum ParsingError: Swift.Error {
    case malformedKeyValuePair(String.SubSequence)
}

// MARK: - Parser implementations

extension URIParser {
    mutating func parseRoot() throws -> URIParsedNode {

        // A completely empty string should get parsed as a single
        // empty key with a single element array with an empty string.
        if data.isEmpty {
            return ["": [""]]
        }
        
        switch (configuration.style, configuration.explode) {
        case (.form, true):
            return try parseExplodedFormRoot()
        case (.form, false):
            return try parseUnexplodedFormRoot()
        case (.simple, true):
            return try parseExplodedSimpleRoot()
        case (.simple, false):
            return try parseUnexplodedSimpleRoot()
        }
    }
    
    mutating func parseExplodedFormRoot() throws -> URIParsedNode {
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
    
    mutating func parseUnexplodedFormRoot() throws -> URIParsedNode {
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
                case .foundSecondOrEnd:
                    throw ParsingError.malformedKeyValuePair(firstValue)
                }
                appendPair(key, values)
            }
        }
    }

    mutating func parseExplodedSimpleRoot() throws -> URIParsedNode {
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

    mutating func parseUnexplodedSimpleRoot() throws -> URIParsedNode {
        // Unexploded simple dictionary cannot be told apart from
        // an array, so we just accumulate all pairs as standalone
        // values and add them to the array. It'll be the higher
        // level decoder's responsibility to parse this properly.

        try parseGenericRoot { data, appendPair in
            let pairSeparator: Character = ","
            while !data.isEmpty {
                let value = data.parseUpToCharacterOrEnd(
                    pairSeparator
                )
                appendPair(.init(), [value])
            }
        }
    }
}

// MARK: - URIParser utilities

extension URIParser {
    private mutating func parseGenericRoot(
        _ parser: (inout Raw, (Raw, [Raw]) -> Void) throws -> Void
    ) throws -> URIParsedNode {
        var root = URIParsedNode()
        let spaceEscapingCharacter = configuration.spaceEscapingCharacter
        let unescapeValue: (Raw) -> Raw = {
            Self.unescapeValue($0, spaceEscapingCharacter: spaceEscapingCharacter)
        }
        try parser(&data) { key, values in
            let newItem = [
                unescapeValue(key): values.map(unescapeValue)
            ]
            root.merge(newItem) { $0 + $1 }
        }
        return root
    }
    
    private func unescapeValue(_ escapedValue: Raw) -> Raw {
        Self.unescapeValue(
            escapedValue,
            spaceEscapingCharacter: configuration.spaceEscapingCharacter
        )
    }
    
    private static func unescapeValue(
        _ escapedValue: Raw,
        spaceEscapingCharacter: String
    ) -> Raw {
        // The inverse of URISerializer.computeSafeString.
        let partiallyDecoded = escapedValue.replacingOccurrences(
            of: spaceEscapingCharacter,
            with: " "
        )
        return (partiallyDecoded.removingPercentEncoding ?? "")[...]
    }
}

// MARK: - Substring utilities

extension String.SubSequence {
    
    enum ParseUpToEitherCharacterResult {
        case foundFirst
        case foundSecondOrEnd
    }
    
    mutating func parseUpToEitherCharacterOrEnd(
        first: Character,
        second: Character
    ) -> (ParseUpToEitherCharacterResult, Self) {
        let startIndex = startIndex
        guard startIndex != endIndex else {
            return (.foundSecondOrEnd, .init())
        }
        var currentIndex = startIndex
        
        func finalize(
            _ result: ParseUpToEitherCharacterResult
        ) -> (ParseUpToEitherCharacterResult, Self) {
            let parsed = self[startIndex..<currentIndex]
            if currentIndex == endIndex {
                self = .init()
                return (result, parsed)
            } else {
                self = self[index(after: currentIndex)...]
                return (result, parsed)
            }
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

    mutating func parseUpToCharacterOrEnd(
        _ character: Character
    ) -> Self {
        let startIndex = startIndex
        guard startIndex != endIndex else {
            return .init()
        }
        var currentIndex = startIndex
        
        func finalize() -> Self {
            let parsed = self[startIndex..<currentIndex]
            if currentIndex == endIndex {
                self = .init()
                return parsed
            } else {
                self = self[index(after: currentIndex)...]
                return parsed
            }
        }
        while currentIndex != endIndex {
            let currentChar = self[currentIndex]
            if currentChar == character {
                return finalize()
            } else {
                formIndex(after: &currentIndex)
            }
        }
        return finalize()
    }
}
