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
            var state: State
            init(upstream: MultipartBody.AsyncIterator, boundary: ArraySlice<UInt8>) {
                self.upstream = upstream
                self.boundary = boundary
                self.state = .notYetStarted
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
            enum State {
                case notYetStarted
                case startedNothingEmittedYet
                case finished
                case emittedHeaders
                case emittedBodyChunk
            }
            mutating func next() async throws -> HTTPBody.ByteChunk? {
                print("MultipartSerializationSequence - start next (state: \(state))")
                defer { print("MultipartSerializationSequence - end next (state: \(state))") }
                // Events
                var buffer: [UInt8] = []
                func emitHeaders(_ headerFields: HTTPFields) {
                    buffer.append(contentsOf: ASCII.crlf)
                    for headerField in headerFields {
                        buffer.append(contentsOf: headerField.name.canonicalName.utf8)
                        buffer.append(contentsOf: ASCII.colonSpace)
                        buffer.append(contentsOf: headerField.value.utf8)
                        buffer.append(contentsOf: ASCII.crlf)
                    }
                    buffer.append(contentsOf: ASCII.crlf)
                }
                func emitBodyChunk(_ bodyChunk: ArraySlice<UInt8>) { buffer.append(contentsOf: bodyChunk) }
                func emitEndOfPart() {
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
                // Serializer
                switch state {
                case .notYetStarted:
                    emitStart()
                    state = .startedNothingEmittedYet
                    return buffer[...]
                case .finished: return nil
                case .startedNothingEmittedYet, .emittedBodyChunk, .emittedHeaders:
                    // Handled below.
                    break
                }
                guard let partChunk = try await upstream.next() else {
                    emitEndOfPart()
                    emitEnd()
                    state = .finished
                    return buffer[...]
                }

                switch (state, partChunk) {
                case (.notYetStarted, _), (.finished, _): preconditionFailure("Already handled above.")
                case (.startedNothingEmittedYet, .headerFields(let headerFields)):
                    emitHeaders(headerFields)
                    state = .emittedHeaders
                case (.startedNothingEmittedYet, .bodyChunk):
                    state = .finished
                    throw SerializationError.noHeaderFieldsAtStart
                case (.emittedHeaders, .headerFields(let headerFields)),
                    (.emittedBodyChunk, .headerFields(let headerFields)):
                    emitEndOfPart()
                    emitHeaders(headerFields)
                    state = .emittedHeaders
                case (.emittedHeaders, .bodyChunk(let bodyChunk)), (.emittedBodyChunk, .bodyChunk(let bodyChunk)):
                    emitBodyChunk(bodyChunk)
                    state = .emittedBodyChunk
                }
                return buffer[...]
            }
        }
    }
}
