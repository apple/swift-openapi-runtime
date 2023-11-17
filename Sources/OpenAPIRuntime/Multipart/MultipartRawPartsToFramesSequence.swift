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

import HTTPTypes
import Foundation

/// A sequence that serializes raw multipart parts into multipart frames.
struct MultipartRawPartsToFramesSequence<Upstream: AsyncSequence & Sendable>: Sendable
where Upstream.Element == MultipartRawPart {

    /// The source of raw parts.
    var upstream: Upstream
}

extension MultipartRawPartsToFramesSequence: AsyncSequence {

    /// The type of element produced by this asynchronous sequence.
    typealias Element = MultipartFrame

    /// Creates the asynchronous iterator that produces elements of this
    /// asynchronous sequence.
    ///
    /// - Returns: An instance of the `AsyncIterator` type used to produce
    /// elements of the asynchronous sequence.
    func makeAsyncIterator() -> Iterator { Iterator(upstream: upstream.makeAsyncIterator()) }

    /// An iterator that pulls raw parts from the upstream iterator and provides
    /// multipart frames.
    struct Iterator: AsyncIteratorProtocol {

        /// The iterator that provides the raw parts.
        var upstream: Upstream.AsyncIterator

        /// The underlying parts to frames serializer.
        var serializer: Serializer

        /// Creates a new iterator.
        /// - Parameter upstream: The iterator that provides the raw parts.
        init(upstream: Upstream.AsyncIterator) {
            self.upstream = upstream
            self.serializer = .init(upstream: upstream)
        }

        /// Asynchronously advances to the next element and returns it, or ends the
        /// sequence if there is no next element.
        ///
        /// - Returns: The next element, if it exists, or `nil` to signal the end of
        ///   the sequence.
        mutating func next() async throws -> Element? { try await serializer.next() }
    }
}

extension MultipartRawPartsToFramesSequence {

    /// A state machine representing the raw part to frame serializer.
    struct StateMachine {

        /// The possible states of the state machine.
        enum State {

            /// Has not emitted any frames yet.
            case initial

            /// Waiting for the next part.
            case waitingForPart

            /// Returning body chunks from the current part's body.
            case streamingBody(HTTPBody.AsyncIterator)

            /// Finished, the terminal state.
            case finished
        }

        /// The current state of the state machine.
        private(set) var state: State

        /// Creates a new state machine.
        init() { self.state = .initial }

        /// An action returned by the `next` method.
        enum NextAction {

            /// Return nil to the caller, no more parts.
            case returnNil

            /// Fetch the next part.
            case fetchPart

            /// Fetch the next body chunk from the provided iterator.
            case fetchBodyChunk(HTTPBody.AsyncIterator)
        }

        /// Read the next part from the upstream frames.
        /// - Returns: An action to perform.
        mutating func next() -> NextAction {
            switch state {
            case .initial:
                state = .waitingForPart
                return .fetchPart
            case .streamingBody(let iterator): return .fetchBodyChunk(iterator)
            case .finished: return .returnNil
            case .waitingForPart: preconditionFailure("Invalid state: \(state)")
            }
        }

        /// An action returned by the `receivedPart` method.
        enum ReceivedPartAction: Hashable {

            /// Return nil to the caller, no more frames.
            case returnNil

            /// Return the provided header fields.
            case emitHeaderFields(HTTPFields)
        }

        /// Ingest the provided part.
        /// - Parameter part: A new part. If `nil`, then the source of parts is finished.
        /// - Returns: An action to perform.
        mutating func receivedPart(_ part: MultipartRawPart?) -> ReceivedPartAction {
            switch state {
            case .waitingForPart:
                if let part {
                    state = .streamingBody(part.body.makeAsyncIterator())
                    return .emitHeaderFields(part.headerFields)
                } else {
                    state = .finished
                    return .returnNil
                }
            case .finished: return .returnNil
            case .initial, .streamingBody: preconditionFailure("Invalid state: \(state)")
            }
        }

        /// An action returned by the `receivedBodyChunk` method.
        enum ReceivedBodyChunkAction: Hashable {

            /// Return nil to the caller, no more frames.
            case returnNil

            /// Fetch the next part.
            case fetchPart

            /// Return the provided body chunk.
            case emitBodyChunk(ArraySlice<UInt8>)
        }

        /// Ingest the provided part.
        /// - Parameter bodyChunk: A new body chunk. If `nil`, then the current part's body is finished.
        /// - Returns: An action to perform.
        mutating func receivedBodyChunk(_ bodyChunk: ArraySlice<UInt8>?) -> ReceivedBodyChunkAction {
            switch state {
            case .streamingBody:
                if let bodyChunk {
                    return .emitBodyChunk(bodyChunk)
                } else {
                    state = .waitingForPart
                    return .fetchPart
                }
            case .finished: return .returnNil
            case .initial, .waitingForPart: preconditionFailure("Invalid state: \(state)")
            }
        }
    }
}

extension MultipartRawPartsToFramesSequence {

    /// A serializer of multipart raw parts into multipart frames.
    struct Serializer {

        /// The upstream source of raw parts.
        private var upstream: Upstream.AsyncIterator

        /// The underlying state machine.
        private var stateMachine: StateMachine

        /// Creates a new iterator.
        /// - Parameter upstream: The upstream source of raw parts.
        init(upstream: Upstream.AsyncIterator) {
            self.upstream = upstream
            self.stateMachine = .init()
        }

        /// Requests the next frame.
        /// - Returns: A frame.
        /// - Throws: When a serialization error is encountered.
        mutating func next() async throws -> MultipartFrame? {
            func handleFetchPart() async throws -> MultipartFrame? {
                let part = try await upstream.next()
                switch stateMachine.receivedPart(part) {
                case .returnNil: return nil
                case .emitHeaderFields(let headerFields): return .headerFields(headerFields)
                }
            }
            switch stateMachine.next() {
            case .returnNil: return nil
            case .fetchPart: return try await handleFetchPart()
            case .fetchBodyChunk(var iterator):
                let bodyChunk = try await iterator.next()
                switch stateMachine.receivedBodyChunk(bodyChunk) {
                case .returnNil: return nil
                case .fetchPart: return try await handleFetchPart()
                case .emitBodyChunk(let bodyChunk): return .bodyChunk(bodyChunk)
                }
            }
        }
    }
}
