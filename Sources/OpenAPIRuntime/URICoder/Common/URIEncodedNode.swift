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

/// A node produced by `URIValueToNodeEncoder`.
enum URIEncodedNode: Equatable {

    /// No value.
    case unset

    /// A single primitive value.
    case primitive(Primitive)

    /// An array of nodes.
    case array([Self])

    /// A dictionary with node values.
    case dictionary([String: Self])

    /// A primitive value.
    enum Primitive: Equatable {

        /// A boolean value.
        case bool(Bool)

        /// A string value.
        case string(String)

        /// An integer value.
        case integer(Int)

        /// A floating-point value.
        case double(Double)

        /// A date value.
        case date(Date)
    }
}

extension URIEncodedNode {

    /// An error thrown by the methods modifying `URIEncodedNode`.
    enum InsertionError: Swift.Error {

        /// The encoder encoded a second primitive value.
        case settingPrimitiveValueAgain

        /// The encoder set a single value on a container.
        case settingValueOnAContainer

        /// The encoder appended to a node that wasn't an array.
        case appendingToNonArrayContainer

        /// The encoder inserted a value for key into a node that wasn't
        /// a dictionary.
        case insertingChildValueIntoNonContainer

        /// The encoder added a value to an array, but the key was not a valid
        /// integer key.
        case insertingChildValueIntoArrayUsingNonIntValueKey
    }

    /// Sets the node to be a primitive node with the provided value.
    /// - Parameter value: The primitive value to set into the node.
    /// - Throws: If the node is already set.
    mutating func set(_ value: Primitive) throws {
        switch self {
        case .unset:
            self = .primitive(value)
        case .primitive:
            throw InsertionError.settingPrimitiveValueAgain
        case .array, .dictionary:
            throw InsertionError.settingValueOnAContainer
        }
    }

    /// Inserts a value for a key into the node, which is interpreted as a
    /// dictionary.
    /// - Parameters:
    ///   - childValue: The value to save under the provided key.
    ///   - key: The key to save the value for into the dictionary.
    /// - Throws: If the node is already set to be anything else but a
    /// dictionary.
    mutating func insert<Key: CodingKey>(
        _ childValue: Self,
        atKey key: Key
    ) throws {
        switch self {
        case .dictionary(var dictionary):
            self = .unset
            dictionary[key.stringValue] = childValue
            self = .dictionary(dictionary)
        case .array(var array):
            // Check that this is a valid key for an unkeyed container,
            // but don't actually extract the index, we only support appending
            // here.
            guard let intValue = key.intValue else {
                throw InsertionError.insertingChildValueIntoArrayUsingNonIntValueKey
            }
            precondition(
                intValue == array.count,
                "Unkeyed container inserting at an incorrect index"
            )
            self = .unset
            array.append(childValue)
            self = .array(array)
        case .unset:
            if let _ = key.intValue {
                self = .array([childValue])
            } else {
                self = .dictionary([key.stringValue: childValue])
            }
        default:
            throw InsertionError.insertingChildValueIntoNonContainer
        }
    }

    /// Appends a value to the array node.
    /// - Parameter childValue: The node to append to the underlying array.
    /// - Throws: If the node is already set to be anything else but an array.
    mutating func append(_ childValue: Self) throws {
        switch self {
        case .array(var items):
            self = .unset
            items.append(childValue)
            self = .array(items)
        case .unset:
            self = .array([childValue])
        default:
            throw InsertionError.appendingToNonArrayContainer
        }
    }
}
