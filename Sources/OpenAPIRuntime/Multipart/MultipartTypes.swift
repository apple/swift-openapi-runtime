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
import HTTPTypes

// TODO: These names are bad, once we have all we need rename to better ones.

// TODO: Go through and make as many things as possible private/internal/spi

// MARK: - Raw parts

@frozen public enum MultipartChunk: Sendable, Hashable {
    case headerFields(HTTPFields)
    case bodyChunk(ArraySlice<UInt8>)
}

typealias MultipartChunks = OpenAPISequence<MultipartChunk>

// MARK: - Untyped parts

public struct MultipartUntypedPart: Sendable, Hashable {
    public var headerFields: HTTPFields
    public var body: HTTPBody
    public init(headerFields: HTTPFields, body: HTTPBody) {
        self.headerFields = headerFields
        self.body = body
    }
}

extension MultipartUntypedPart: MultipartValidatablePart {}

extension MultipartUntypedPart {
    public init(name: String?, filename: String? = nil, headerFields: HTTPFields, body: HTTPBody) {
        var contentDisposition = ContentDisposition(dispositionType: .formData, parameters: [:])
        if let name { contentDisposition.parameters[.name] = name }
        if let filename { contentDisposition.parameters[.filename] = filename }
        var headerFields = headerFields
        headerFields[.contentDisposition] = contentDisposition.rawValue
        self.init(headerFields: headerFields, body: body)
    }
    public var name: String? {
        get {
            guard let contentDispositionString = headerFields[.contentDisposition],
                let contentDisposition = ContentDisposition(rawValue: contentDispositionString),
                let name = contentDisposition.name
            else { return nil }
            return name
        }
        set {
            guard let contentDispositionString = headerFields[.contentDisposition],
                var contentDisposition = ContentDisposition(rawValue: contentDispositionString)
            else {
                if let newValue {
                    headerFields[.contentDisposition] =
                        ContentDisposition(dispositionType: .formData, parameters: [.name: newValue]).rawValue
                }
                return
            }
            contentDisposition.name = newValue
            headerFields[.contentDisposition] = contentDisposition.rawValue
        }
    }
    public var filename: String? {
        get {
            guard let contentDispositionString = headerFields[.contentDisposition],
                let contentDisposition = ContentDisposition(rawValue: contentDispositionString),
                let filename = contentDisposition.filename
            else { return nil }
            return filename
        }
        set {
            guard let contentDispositionString = headerFields[.contentDisposition],
                var contentDisposition = ContentDisposition(rawValue: contentDispositionString)
            else {
                if let newValue {
                    headerFields[.contentDisposition] =
                        ContentDisposition(dispositionType: .formData, parameters: [.filename: newValue]).rawValue
                }
                return
            }
            contentDisposition.filename = newValue
            headerFields[.contentDisposition] = contentDisposition.rawValue
        }
    }
}

// MARK: - Typed parts

public protocol MultipartTypedPart: Sendable {
    var name: String? { get }
    var filename: String? { get }
}

public typealias MultipartTypedBody<Part: MultipartTypedPart> = OpenAPISequence<Part>

public struct MultipartPartWithInfo<PartPayload: Sendable & Hashable>: Sendable, Hashable {
    public var payload: PartPayload
    public var filename: String?
    public init(payload: PartPayload, filename: String? = nil) {
        self.payload = payload
        self.filename = filename
    }
}
