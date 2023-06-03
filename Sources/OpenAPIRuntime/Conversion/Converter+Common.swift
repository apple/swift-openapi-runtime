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

@_spi(Generated)
public extension Array where Element == HeaderField {

    /// Adds a header for the provided name and value.
    /// - Parameters:
    ///   - name: Header name.
    ///   - value: Header value. If nil, the header is not added.
    @_spi(Generated)
    mutating func add(name: String, value: String?) {
        guard let value = value else {
            return
        }
        append(.init(name: name, value: value))
    }

    /// Removes all headers matching the provided (case-insensitive) name.
    /// - Parameters:
    ///   - name: Header name.
    @_spi(Generated)
    mutating func removeAll(named name: String) {
        removeAll {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    /// Returns the first header value for the provided (case-insensitive) name.
    /// - Parameter name: Header name.
    /// - Returns: First value for the given name. Nil if one does not exist.
    @_spi(Generated)
    func firstValue(name: String) -> String? {
        first { $0.name.caseInsensitiveCompare(name) == .orderedSame }?.value
    }

    /// Returns all header values for the given (case-insensitive) name.
    /// - Parameter name: Header name.
    /// - Returns: All values for the given name, might be empty if none are found.
    @_spi(Generated)
    func values(name: String) -> [String] {
        filter { $0.name.caseInsensitiveCompare(name) == .orderedSame }.map { $0.value }
    }
}

extension Converter {

    // MARK: Miscs

    /// Validates that the Content-Type header field (if present)
    /// is compatible with the provided content-type substring.
    ///
    /// Succeeds if no Content-Type header is found in the response headers.
    ///
    /// - Parameters:
    ///   - headerFields: Header fields to inspect for a content type.
    ///   - substring: Expected content type.
    /// - Throws: If the response's Content-Type value is not compatible with the provided substring.
    public func validateContentTypeIfPresent(
        in headerFields: [HeaderField],
        substring: String
    ) throws {
        guard
            let contentType = try headerFieldGetOptional(
                in: headerFields,
                strategy: .string,
                name: "content-type",
                as: String.self
            )
        else {
            return
        }
        guard contentType.localizedCaseInsensitiveContains(substring) else {
            throw RuntimeError.unexpectedContentTypeHeader(contentType)
        }
    }

    // MARK: Headers - Date

    /// Adds a header field with the provided name and Date value.
    /// - Parameters:
    ///   - headerFields: Collection of header fields to add to.
    ///   - strategy: A hint about which coding strategy to use.
    ///   - name: The name of the header field.
    ///   - value: Date value. If nil, header is not added.
    public func headerFieldAdd(
        in headerFields: inout [HeaderField],
        strategy: ParameterCodingStrategy,
        name: String,
        value: Date?
    ) throws {
        guard let value = value else {
            return
        }
        let stringValue = try self.configuration.dateTranscoder.encode(value)
        headerFields.add(name: name, value: stringValue)
    }

    /// Returns the value for the first header field with given name.
    /// - Parameters:
    ///   - headerFields: Collection of header fields to retrieve the field from.
    ///   - strategy: A hint about which coding strategy to use.
    ///   - name: The name of the header field (case-insensitive).
    ///   - type: Date type.
    /// - Returns: First value for the given name, if one exists.
    public func headerFieldGetOptional(
        in headerFields: [HeaderField],
        strategy: ParameterCodingStrategy,
        name: String,
        as type: Date.Type
    ) throws -> Date? {
        guard let dateString = headerFields.firstValue(name: name) else {
            return nil
        }
        return try self.configuration.dateTranscoder.decode(dateString)
    }

    /// Returns the value for the first header field with the given name.
    /// - Parameters:
    ///   - headerFields: Collection of header fields to retrieve the field from.
    ///   - strategy: A hint about which coding strategy to use.
    ///   - name: Header name (case-insensitive).
    ///   - type: Date type.
    /// - Returns: First value for the given name.
    public func headerFieldGetRequired(
        in headerFields: [HeaderField],
        strategy: ParameterCodingStrategy,
        name: String,
        as type: Date.Type
    ) throws -> Date {
        guard
            let value = try headerFieldGetOptional(
                in: headerFields,
                strategy: strategy,
                name: name,
                as: type
            )
        else {
            throw RuntimeError.missingRequiredHeader(name)
        }
        return value
    }

    // MARK: Headers - Complex

    /// Adds a header field with the provided name and encodable value.
    ///
    /// Encodes the value into minimized JSON.
    /// - Parameters:
    ///   - headerFields: Collection of header fields to add to.
    ///   - strategy: A hint about which coding strategy to use.
    ///   - name: Header name.
    ///   - value: Encodable header value.
    public func headerFieldAdd<T: Encodable>(
        in headerFields: inout [HeaderField],
        strategy: ParameterCodingStrategy,
        name: String,
        value: T?
    ) throws {
        guard let value else {
            return
        }
        if let value = value as? _StringParameterConvertible,
            strategy != .codable
        {
            headerFields.add(name: name, value: value.description)
            return
        }
        let data = try headerFieldEncoder.encode(value)
        guard let stringValue = String(data: data, encoding: .utf8) else {
            throw RuntimeError.failedToEncodeJSONHeaderIntoString(name: name)
        }
        headerFields.add(name: name, value: stringValue)
    }

    /// Returns the value of the first header field for the given name.
    ///
    /// Decodes the value from JSON.
    /// - Parameters:
    ///   - headerFields: Collection of header fields to retrieve the field from.
    ///   - strategy: A hint about which coding strategy to use.
    ///   - name: Header name (case-insensitive).
    ///   - type: Date type.
    /// - Returns: First value for the given name, if one exists.
    public func headerFieldGetOptional<T: Decodable>(
        in headerFields: [HeaderField],
        strategy: ParameterCodingStrategy,
        name: String,
        as type: T.Type
    ) throws -> T? {
        guard let stringValue = headerFields.firstValue(name: name) else {
            return nil
        }
        if let myType = T.self as? _StringParameterConvertible.Type,
            strategy != .codable
        {
            return myType.init(stringValue).map { $0 as! T }
        }
        let data = Data(stringValue.utf8)
        return try decoder.decode(T.self, from: data)
    }

    /// Returns the first header value for the given (case-insensitive) name.
    ///
    /// Decodes the value from JSON.
    /// - Parameters:
    ///   - headerFields: Collection of header fields to retrieve the field from.
    ///   - strategy: A hint about which coding strategy to use.
    ///   - name: Header name (case-insensitive).
    ///   - type: Date type.
    /// - Returns: First value for the given name.
    public func headerFieldGetRequired<T: Decodable>(
        in headerFields: [HeaderField],
        strategy: ParameterCodingStrategy,
        name: String,
        as type: T.Type
    ) throws -> T {
        guard
            let value = try headerFieldGetOptional(
                in: headerFields,
                strategy: strategy,
                name: name,
                as: type
            )
        else {
            throw RuntimeError.missingRequiredHeader(name)
        }
        return value
    }
}
