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

// MARK: - Raw parts

@frozen public enum MultipartChunk: Sendable, Hashable {
    case headerFields(HTTPFields)
    case bodyChunk(ArraySlice<UInt8>)
}

public struct MultipartUntypedPart: Sendable, Hashable {
    public var headerFields: HTTPFields
    public var body: HTTPBody
    public init(headerFields: HTTPFields, body: HTTPBody) {
        self.headerFields = headerFields
        self.body = body
    }
}

public typealias MultipartChunks = OpenAPISequence<MultipartChunk>

// MARK: - Untyped parts

//public typealias MultipartUntypedBody = OpenAPISequence<MultipartUntypedPart>

// MARK: - Typed parts

public protocol MultipartTypedPart: Sendable { var name: String { get } }

public typealias MultipartTypedBody<Part: MultipartTypedPart> = OpenAPISequence<Part>

// MARK: - Sequence converting typed -> raw parts

struct MultipartUntypedToChunksSequence<Upstream: AsyncSequence> where Upstream.Element == MultipartUntypedPart {
    var upstream: Upstream
}

extension AsyncSequence where Element == MultipartUntypedPart {
    func asMultipartChunks() -> MultipartUntypedToChunksSequence<Self> { .init(upstream: self) }
}

extension MultipartUntypedToChunksSequence: AsyncSequence {
    typealias Element = MultipartChunk

    func makeAsyncIterator() -> Iterator { Iterator(upstream: upstream.makeAsyncIterator()) }
    struct Iterator: AsyncIteratorProtocol {
        var upstream: Upstream.AsyncIterator
        var isFinished: Bool = false
        var bodyIterator: HTTPBody.AsyncIterator?
        mutating func next() async throws -> Element? {
            guard !isFinished else { return nil }
            if var bodyIterator, let bodyChunk = try await bodyIterator.next() { return .bodyChunk(bodyChunk) }
            guard let part = try await upstream.next() else {
                isFinished = true
                return nil
            }
            bodyIterator = part.body.makeAsyncIterator()
            return .headerFields(part.headerFields)
        }
    }
}
