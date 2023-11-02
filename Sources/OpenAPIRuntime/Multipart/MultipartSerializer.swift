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

private enum ASCII {
    static let dashes: [UInt8] = [0x2d, 0x2d]
    static let crlf: [UInt8] = [0xd, 0xa]
    static let colonSpace: [UInt8] = [0x3a, 0x20]
}

extension HTTPBody {
    convenience init(_ multipart: MultipartBody, boundary: String) throws {

        /*
         On creation: create HTTPBody with a sequence, copy over the length and iteration behavior.
         Do not start anything on creation, so that this can be iterated multiple times - create things
         only once the iterator is created.
         */
        // TODO: Make HTTPBody.Length and MultipartBody.Length the same? Or not?
        let length: HTTPBody.Length
        switch multipart.length {
        case .known(let count): length = .known(count)
        case .unknown: length = .unknown
        }
        let iterationBehavior: HTTPBody.IterationBehavior
        switch multipart.iterationBehavior {
        case .single: iterationBehavior = .single
        case .multiple: iterationBehavior = .multiple
        }
        let sequence = MultipartSerializationSequence(multipart: multipart, boundary: ArraySlice(boundary.utf8))
        self.init(sequence, length: length, iterationBehavior: iterationBehavior)
    }
    private final class MultipartSerializationSequence: AsyncSequence {
        typealias AsyncIterator = Iterator
        typealias Element = HTTPBody.ByteChunk
        let multipart: MultipartBody
        let boundary: ArraySlice<UInt8>

        init(multipart: MultipartBody, boundary: ArraySlice<UInt8>) {
            self.multipart = multipart
            self.boundary = boundary
        }
        func makeAsyncIterator() -> Iterator { Iterator(upstream: multipart.makeAsyncIterator(), boundary: boundary) }
        struct Iterator: AsyncIteratorProtocol {
            typealias Element = HTTPBody.ByteChunk
            var upstream: MultipartBody.AsyncIterator
            let boundary: ArraySlice<UInt8>
            var isFinished: Bool = false
            init(upstream: MultipartBody.AsyncIterator, boundary: ArraySlice<UInt8>) {
                self.upstream = upstream
                self.boundary = boundary
            }
            mutating func next() async throws -> HTTPBody.ByteChunk? {
                guard !isFinished else { return nil }
                // TODO: Actually make this streaming.
                // We buffer here for now for simplicity during prototyping.

                var parts: [MultipartPartChunk] = []
                while let value = try await upstream.next() { parts.append(value) }
                enum State {
                    case initial
                    case collectingPart(HTTPFields, [ArraySlice<UInt8>])
                    case modifying
                }
                enum SerializationError: Swift.Error, CustomStringConvertible, LocalizedError {
                    case noHeaderFieldsAtStart
                    var description: String {
                        switch self {
                        case .noHeaderFieldsAtStart: return "No header fields found at the start of the multipart body."
                        }
                    }
                    var errorDescription: String? { description }
                }
                var buffer: [UInt8] = []
                func emitPart(headerFields: HTTPFields, bodyChunks: [ArraySlice<UInt8>]) {
                    buffer.append(contentsOf: ASCII.crlf)
                    for headerField in headerFields {
                        buffer.append(contentsOf: headerField.name.canonicalName.utf8)
                        buffer.append(contentsOf: ASCII.colonSpace)
                        buffer.append(contentsOf: headerField.value.utf8)
                        buffer.append(contentsOf: ASCII.crlf)
                    }
                    buffer.append(contentsOf: ASCII.crlf)
                    for bodyChunk in bodyChunks { buffer.append(contentsOf: bodyChunk) }
                    buffer.append(contentsOf: ASCII.crlf)
                    buffer.append(contentsOf: ASCII.dashes)
                    buffer.append(contentsOf: boundary)
                }
                func emitStart() {
                    buffer.append(contentsOf: ASCII.dashes)
                    buffer.append(contentsOf: boundary)
                }
                func emitEnd() {
                    buffer.append(contentsOf: ASCII.dashes)
                    buffer.append(contentsOf: ASCII.crlf)
                    buffer.append(contentsOf: ASCII.crlf)
                }
                emitStart()
                var state: State = .initial
                for part in parts {
                    switch state {
                    case .initial:
                        guard case .headerFields(let headerFields) = part else {
                            throw SerializationError.noHeaderFieldsAtStart
                        }
                        state = .collectingPart(headerFields, [])
                    case .collectingPart(let headerFields, var bodyChunks):
                        state = .modifying
                        switch part {
                        case .headerFields(let newHeaderFields):
                            emitPart(headerFields: headerFields, bodyChunks: bodyChunks)
                            state = .collectingPart(newHeaderFields, [])
                        case .bodyChunk(let chunk):
                            bodyChunks.append(chunk)
                            state = .collectingPart(headerFields, bodyChunks)
                        }
                    case .modifying: preconditionFailure("Invalid state: \(state)")
                    }
                }
                switch state {
                case .initial: break
                case .collectingPart(let headerFields, let bodyChunks):
                    emitPart(headerFields: headerFields, bodyChunks: bodyChunks)
                case .modifying: preconditionFailure("Invalid state: \(state)")
                }
                emitEnd()
                isFinished = true
                return ArraySlice(buffer)
            }
        }
    }
}
