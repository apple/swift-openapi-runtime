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

enum URIEncodedNode: Equatable {

    case unset
    case primitive(Primitive)
    case array([Self])
    case dictionary([String: Self])

    enum Primitive: Equatable {
        case bool(Bool)
        case string(String)
        case integer(Int)
        case double(Double)
        case date(Date)
    }
}

extension URIEncodedNode {

    enum InsertionError: Swift.Error {
        case settingPrimitiveValueAgain
        case settingValueOnAContainer
        case appendingToNonArrayContainer
        case insertingChildValueIntoNonContainer
        case insertingChildValueIntoArrayUsingNonIntValueKey
    }

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
