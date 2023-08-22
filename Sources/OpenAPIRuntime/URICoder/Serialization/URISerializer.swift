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

/// Implements form-style query expansion from RFC 6570.
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
struct URISerializer {
    
    struct Configuration {
        
        // TODO: Wrap in a struct.
        enum Style {
            case simple
            case form
        }
        
        var style: Style
        var explode: Bool
        var spaceEscapingCharacter: String
        
        private init(style: Style, explode: Bool, spaceEscapingCharacter: String) {
            self.style = style
            self.explode = explode
            self.spaceEscapingCharacter = spaceEscapingCharacter
        }
        
        static let formExplode: Self = .init(
            style: .form,
            explode: true,
            spaceEscapingCharacter: "%20"
        )
        
        static let formUnexplode: Self = .init(
            style: .form,
            explode: false,
            spaceEscapingCharacter: "%20"
        )
        
        static let simpleExplode: Self = .init(
            style: .simple,
            explode: true,
            spaceEscapingCharacter: "%20"
        )
        
        static let simpleUnexplode: Self = .init(
            style: .simple,
            explode: false,
            spaceEscapingCharacter: "%20"
        )
        
        static let formDataExplode: Self = .init(
            style: .form,
            explode: true,
            spaceEscapingCharacter: "+"
        )
        
        static let formDataUnexplode: Self = .init(
            style: .form,
            explode: false,
            spaceEscapingCharacter: "+"
        )
    }
    
    private let configuration: Configuration
    private var data: String
    
    init(configuration: Configuration) {
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
        let partiallyEncoded = unsafeString.addingPercentEncoding(
            withAllowedCharacters: .unreservedAndSpace
        ) ?? ""
        let fullyEncoded = partiallyEncoded.replacingOccurrences(
            of: " ",
            with: configuration.spaceEscapingCharacter
        )
        return fullyEncoded
    }
}

extension URISerializer {
    
    enum SerializationError: Swift.Error {
        case nestedContainersNotSupported
    }

    mutating func serializeNode(
        _ value: URIEncodableNode,
        forKey key: String
    ) throws -> String {
        defer {
            data.removeAll(keepingCapacity: true)
        }
        try serializeAnyNode(value, forKey: key)
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

    private mutating func serializeAnyNode(_ value: URIEncodableNode, forKey key: String) throws {
        func unwrapPrimitiveValue(_ node: URIEncodableNode) throws -> URIEncodableNode.Primitive {
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
            try serializePrimitiveKeyValuePair(
                primitive,
                forKey: key,
                
                // TODO: Seems strange to assume this, is the API wrong?
                separator: "="
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
        _ value: URIEncodableNode.Primitive
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
        _ value: URIEncodableNode.Primitive,
        forKey key: String,
        separator: String
    ) throws {
        data.append(try stringifiedKey(key))
        data.append(separator)
        try serializePrimitiveValue(value)
    }

    private mutating func serializeArray(
        _ array: [URIEncodableNode.Primitive],
        forKey key: String
    ) throws {
        guard !array.isEmpty else {
            return
        }
        let style = configuration.style
        let explode = configuration.explode
        
        let keyAndValueSeparator: String?
        let pairSeparator: String
        switch (style, explode) {
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
        func serializeNext(_ element: URIEncodableNode.Primitive) throws {
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
        if keyAndValueSeparator == nil {
            data.append(try stringifiedKey(key))
            data.append("=")
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
        _ dictionary: [String: URIEncodableNode.Primitive],
        forKey key: String
    ) throws {
        guard !dictionary.isEmpty else {
            return
        }
        let sortedDictionary = dictionary
            .sorted { a, b in
                a.key.localizedCaseInsensitiveCompare(b.key)
                    == .orderedAscending
            }

        let style = configuration.style
        let explode = configuration.explode
        
        let keyAndValueSeparator: String?
        let pairSeparator: String
        switch (style, explode) {
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
        func serializeNext(_ element: URIEncodableNode.Primitive, forKey elementKey: String) throws {
            if let keyAndValueSeparator {
                try serializePrimitiveKeyValuePair(
                    element,
                    forKey: elementKey,
                    separator: keyAndValueSeparator
                )
            } else {
                try serializePrimitiveValue(element)
            }
        }
        if !explode {
            data.append(try stringifiedKey(key))
            data.append("=")
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
