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
struct URISerializer: Sendable {

    struct Configuration {
        // TODO: Add a few prebuilt options.
        struct KeyEncoding {

            // TODO: Hide to avoid adding an enum case being breaking.
            enum DictionaryKeyEncoding {

                /// Put the key between square brackets.
                ///
                /// Example: foo[one]=1&foo[two]=2&foo[three]=3
                case bracketsWithKey

                /// Concatenate components using a period.
                ///
                /// Example: foo.one=1&foo.two=2&foo.three=3
                case concatenatedByPeriods
            }
            var dictionary: DictionaryKeyEncoding = .bracketsWithKey

            // TODO: Hide to avoid adding an enum case being breaking.
            enum ArrayIndexEncoding {

                /// None, just repeat the container's key.
                ///
                /// Example: foo=a&foo=b&foo=c.
                case none

                /// Repeat empty brackets after the container's key.
                ///
                /// Example: foo[]=a&foo[]=b&foo[]=c.
                case emptyBrackets

                /// Put the index in square brackets after the container's key.
                ///
                /// Example: foo[0]=a&foo[1]=b&foo[2]=c.
                case bracketsWithIndex
            }
            var array: ArrayIndexEncoding = .bracketsWithIndex
        }
        var keyEncoding: KeyEncoding = .init()

        //        struct ValueEncoding {
        //            var unescapedCharacterSet: CharacterSet
        //
        //            // TODO: Add a few prebuilt options.
        //    //        static var urlForm: Self {
        //    //
        //    //        }
        //        }
        //        var valueEncoding: ValueEncoding
    }

    let configuration: Configuration

    private var data: String

    init(configuration: Configuration = .init()) {
        self.configuration = configuration
        self.data = ""
    }
}

extension URISerializer {

    mutating func writeNode(
        _ value: URINode,
        forKey keyComponent: KeyComponent
    ) throws -> String {
        defer {
            data.removeAll(keepingCapacity: true)
        }
        try serializeNode(value, forKey: [keyComponent])
        return data
    }
}

extension URISerializer {

    enum KeyComponent {
        case index(Int)
        case key(String)
    }

    enum SerializationError: Swift.Error {
        case topLevelKeyMustBeString
    }

    typealias Key = [KeyComponent]

    private func computeSafeKey(_ unsafeKey: String) -> String {
        // TODO: Escape the key here
        unsafeKey
    }

    private func computeSafeValue(_ unsafeValue: String) -> String {
        // TODO: Escape the value here
        unsafeValue
    }

    private func stringifiedKeyComponent(_ keyComponent: KeyComponent) -> String {
        // TODO: This will differ based on configuration.
        switch keyComponent {
        case .index(let int):
            switch configuration.keyEncoding.array {
            case .none:
                return ""
            case .emptyBrackets:
                return "[]"
            case .bracketsWithIndex:
                return "[\(int)]"
            }
        case .key(let string):
            let safeKey = computeSafeKey(string)
            switch configuration.keyEncoding.dictionary {
            case .bracketsWithKey:
                return "[\(safeKey)]"
            case .concatenatedByPeriods:
                return ".\(safeKey)"
            }
        }
    }

    private func stringifiedKey(_ key: Key) throws -> String {
        // The root key is handled separately.
        guard !key.isEmpty else {
            return ""
        }
        let topLevelKey = key[0]
        guard case .key(let string) = topLevelKey else {
            throw SerializationError.topLevelKeyMustBeString
        }
        let safeTopLevelKey = computeSafeKey(string)
        return
            ([safeTopLevelKey]
            + key
            .dropFirst()
            .map(stringifiedKeyComponent))
            .joined()
    }

    private mutating func serializeNode(_ value: URINode, forKey key: Key) throws {
        switch value {
        case .unset:
            // TODO: Is there a distinction here between `a=` and `a`, in other
            // words between an empty string value and a nil value?
            data.append(try stringifiedKey(key))
            data.append("=")
        case .primitive(let primitive):
            try serializePrimitiveValue(primitive, forKey: key)
        case .array(let array):
            try serializeArray(array, forKey: key)
        case .dictionary(let dictionary):
            try serializeDictionary(dictionary, forKey: key)
        }
    }

    private mutating func serializePrimitiveValue(
        _ value: URINode.Primitive,
        forKey key: Key
    ) throws {
        let stringValue: String
        switch value {
        case .bool(let bool):
            stringValue = bool.description
        case .string(let string):
            stringValue = computeSafeValue(string)
        case .integer(let int):
            stringValue = int.description
        case .double(let double):
            stringValue = double.description
        }
        data.append(try stringifiedKey(key))
        data.append("=")
        data.append(stringValue)
    }

    private mutating func serializeArray(
        _ array: [URINode],
        forKey key: Key
    ) throws {
        try serializeTuples(
            array.enumerated()
                .map { index, element in
                    (key + [.index(index)], element)
                }
        )
    }

    private mutating func serializeDictionary(
        _ dictionary: [String: URINode],
        forKey key: Key
    ) throws {
        try serializeTuples(
            dictionary
                .sorted { a, b in
                    a.key.localizedCaseInsensitiveCompare(b.key)
                        == .orderedAscending
                }
                .map { elementKey, element in
                    (key + [.key(elementKey)], element)
                }
        )
    }

    private mutating func serializeTuples(
        _ items: [(Key, URINode)]
    ) throws {
        guard !items.isEmpty else {
            return
        }
        for (key, element) in items.dropLast() {
            try serializeNode(element, forKey: key)
            data.append("&")
        }
        if let (key, element) = items.last {
            try serializeNode(element, forKey: key)
        }
    }
}
