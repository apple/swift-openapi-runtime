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

/// A sequence that parses raw multipart parts from multipart frames.
struct MultipartFramesToRawPartsSequence<Upstream: AsyncSequence & Sendable>: Sendable
where Upstream.Element == MultipartFrame {

    /// The source of multipart frames.
    var upstream: Upstream
}

extension MultipartFramesToRawPartsSequence: AsyncSequence {

    /// The type of element produced by this asynchronous sequence.
    typealias Element = MultipartRawPart

    /// Creates the asynchronous iterator that produces elements of this
    /// asynchronous sequence.
    ///
    /// - Returns: An instance of the `AsyncIterator` type used to produce
    /// elements of the asynchronous sequence.
    func makeAsyncIterator() -> Iterator { Iterator(makeUpstreamIterator: { upstream.makeAsyncIterator() }) }

    /// An iterator that pulls frames from the upstream iterator and provides
    /// raw multipart parts.
    struct Iterator: AsyncIteratorProtocol {

        /// The underlying shared iterator.
        var shared: SharedIterator

        /// The closure invoked to fetch the next byte chunk of the part's body.
        var bodyClosure: @Sendable () async throws -> ArraySlice<UInt8>?

        /// Creates a new iterator.
        /// - Parameter makeUpstreamIterator: A closure that creates the upstream source of frames.
        init(makeUpstreamIterator: @Sendable () -> Upstream.AsyncIterator) {
            let shared = SharedIterator(makeUpstreamIterator: makeUpstreamIterator)
            self.shared = shared
            self.bodyClosure = { try await shared.nextFromBodySubsequence() }
        }

        /// Asynchronously advances to the next element and returns it, or ends the
        /// sequence if there is no next element.
        ///
        /// - Returns: The next element, if it exists, or `nil` to signal the end of
        ///   the sequence.
        mutating func next() async throws -> Element? {
            try await shared.nextFromPartSequence(bodyClosure: bodyClosure)
        }
    }
}

extension AsyncIteratorProtocol {
    /// Asynchronously advances to the next element and returns it, or ends the
    /// sequence if there is no next element.
    ///
    /// - Returns: The next element, if it exists, or `nil` to signal the end of
    ///   the sequence.
    fileprivate mutating func next(isolatedWith actor: isolated (any Actor)?) async throws -> Self.Element? {
        if #available(macOS 15, iOS 18.0, tvOS 18.0, watchOS 11.0, macCatalyst 18.0, visionOS 2.0, *) {
            #if compiler(>=6.0)
            return try await self.next(isolation: actor)
            #else
            return try await self.next()
            #endif
        } else {
            return try await self.next()
        }
    }
}

extension HTTPBody {

    /// Creates a new body from the provided header fields and body closure.
    /// - Parameters:
    ///   - headerFields: The header fields to inspect for a `content-length` header.
    ///   - bodyClosure: A closure invoked to fetch the next byte chunk of the body.
    fileprivate convenience init(
        headerFields: HTTPFields,
        bodyClosure: @escaping @Sendable () async throws -> ArraySlice<UInt8>?
    ) {
        let stream = AsyncThrowingStream(unfolding: bodyClosure)
        let length: HTTPBody.Length
        if let contentLengthString = headerFields[.contentLength], let contentLength = Int(contentLengthString) {
            length = .known(Int64(contentLength))
        } else {
            length = .unknown
        }
        self.init(stream, length: length)
    }
}

extension MultipartFramesToRawPartsSequence {

    /// A state machine representing the frame to raw part parser.
    struct StateMachine {

        /// The possible states of the state machine.
        enum State: Hashable {

            /// Has not started parsing any parts yet.
            case initial

            /// Waiting to send header fields to start a new part.
            ///
            /// Associated value is optional headers.
            /// If they're non-nil, they arrived already, so just send them right away.
            /// If they're nil, you need to fetch the next frame to get them.
            case waitingToSendHeaders(HTTPFields?)

            /// In the process of streaming the byte chunks of a part body.
            case streamingBody

            /// Finished, the terminal state.
            case finished
        }

        /// The current state of the state machine.
        private(set) var state: State

        /// Creates a new state machine.
        init() { self.state = .initial }

        /// An error returned by the state machine.
        enum ActionError: Hashable {

            /// The outer, raw part sequence called next before the current part's body was fully consumed.
            ///
            /// This is a usage error by the consumer of the sequence.
            case partSequenceNextCalledBeforeBodyWasConsumed

            /// The first frame received was a body chunk instead of header fields, which is invalid.
            ///
            /// This indicates an issue in the source of frames.
            case receivedBodyChunkInInitial

            /// Received a body chunk when waiting for header fields, which is invalid.
            ///
            /// This indicates an issue in the source of frames.
            case receivedBodyChunkWhenWaitingForHeaders

            /// Received another frame before having had a chance to send out header fields, this is an error caused
            /// by the driver of the state machine.
            case receivedFrameWhenAlreadyHasUnsentHeaders
        }

        /// An action returned by the `nextFromPartSequence` method.
        enum NextFromPartSequenceAction: Hashable {

            /// Return nil to the caller, no more parts.
            case returnNil

            /// Fetch the next frame.
            case fetchFrame

            /// Throw the provided error.
            case emitError(ActionError)

            /// Emit a part with the provided header fields.
            case emitPart(HTTPFields)
        }

        /// Read the next part from the upstream frames.
        /// - Returns: An action to perform.
        mutating func nextFromPartSequence() -> NextFromPartSequenceAction {
            switch state {
            case .initial:
                state = .waitingToSendHeaders(nil)
                return .fetchFrame
            case .waitingToSendHeaders(.some(let headers)):
                state = .streamingBody
                return .emitPart(headers)
            case .waitingToSendHeaders(.none), .streamingBody:
                state = .finished
                return .emitError(.partSequenceNextCalledBeforeBodyWasConsumed)
            case .finished: return .returnNil
            }
        }

        /// An action returned by the `partReceivedFrame` method.
        enum PartReceivedFrameAction: Hashable {

            /// Return nil to the caller, no more parts.
            case returnNil

            /// Throw the provided error.
            case emitError(ActionError)

            /// Emit a part with the provided header fields.
            case emitPart(HTTPFields)
        }

        /// Ingest the provided frame, requested by the part sequence.
        /// - Parameter frame: A new frame. If `nil`, then the source of frames is finished.
        /// - Returns: An action to perform.
        mutating func partReceivedFrame(_ frame: MultipartFrame?) -> PartReceivedFrameAction {
            switch state {
            case .initial: preconditionFailure("Haven't asked for a part chunk, how did we receive one?")
            case .waitingToSendHeaders(.some):
                state = .finished
                return .emitError(.receivedFrameWhenAlreadyHasUnsentHeaders)
            case .waitingToSendHeaders(.none):
                if let frame {
                    switch frame {
                    case .headerFields(let headers):
                        state = .streamingBody
                        return .emitPart(headers)
                    case .bodyChunk:
                        state = .finished
                        return .emitError(.receivedBodyChunkWhenWaitingForHeaders)
                    }
                } else {
                    state = .finished
                    return .returnNil
                }
            case .streamingBody:
                state = .finished
                return .emitError(.partSequenceNextCalledBeforeBodyWasConsumed)
            case .finished: return .returnNil
            }
        }

        /// An action returned by the `nextFromBodySubsequence` method.
        enum NextFromBodySubsequenceAction: Hashable {

            /// Return nil to the caller, no more byte chunks.
            case returnNil

            /// Fetch the next frame.
            case fetchFrame

            /// Throw the provided error.
            case emitError(ActionError)
        }

        /// Read the next byte chunk requested by the current part's body sequence.
        /// - Returns: An action to perform.
        mutating func nextFromBodySubsequence() -> NextFromBodySubsequenceAction {
            switch state {
            case .initial:
                state = .finished
                return .emitError(.receivedBodyChunkInInitial)
            case .waitingToSendHeaders:
                state = .finished
                return .emitError(.receivedBodyChunkWhenWaitingForHeaders)
            case .streamingBody: return .fetchFrame
            case .finished: return .returnNil
            }
        }

        /// An action returned by the `bodyReceivedFrame` method.
        enum BodyReceivedFrameAction: Hashable {

            /// Return nil to the caller, no more byte chunks.
            case returnNil

            /// Return the provided byte chunk.
            case returnChunk(ArraySlice<UInt8>)

            /// Throw the provided error.
            case emitError(ActionError)
        }

        /// Ingest the provided frame, requested by the body sequence.
        /// - Parameter frame: A new frame. If `nil`, then the source of frames is finished.
        /// - Returns: An action to perform.
        mutating func bodyReceivedFrame(_ frame: MultipartFrame?) -> BodyReceivedFrameAction {
            switch state {
            case .initial: preconditionFailure("Haven't asked for a frame, how did we receive one?")
            case .waitingToSendHeaders:
                state = .finished
                return .emitError(.receivedBodyChunkWhenWaitingForHeaders)
            case .streamingBody:
                if let frame {
                    switch frame {
                    case .headerFields(let headers):
                        state = .waitingToSendHeaders(headers)
                        return .returnNil
                    case .bodyChunk(let bodyChunk): return .returnChunk(bodyChunk)
                    }
                } else {
                    state = .finished
                    return .returnNil
                }
            case .finished: return .returnNil
            }
        }
    }
}

extension MultipartFramesToRawPartsSequence {

    /// A type-safe iterator shared by the outer part sequence iterator and an inner body sequence iterator.
    ///
    /// It enforces that when a new part is emitted by the outer sequence, that the new part's body is then fully
    /// consumed before the outer sequence is asked for the next part.
    ///
    /// This is required as the source of bytes is a single stream, so without the current part's body being consumed,
    /// we can't move on to the next part.
    actor SharedIterator {

        /// The upstream source of frames.
        private var upstream: Upstream.AsyncIterator

        /// The underlying state machine.
        private var stateMachine: StateMachine

        /// Creates a new iterator.
        /// - Parameter makeUpstreamIterator: A closure that creates the upstream source of frames.
        init(makeUpstreamIterator: @Sendable () -> Upstream.AsyncIterator) {
            let upstream = makeUpstreamIterator()
            self.upstream = upstream
            self.stateMachine = .init()
        }

        /// An error thrown by the shared iterator.
        struct IteratorError: Swift.Error, CustomStringConvertible, LocalizedError {

            /// The underlying error emitted by the state machine.
            let error: StateMachine.ActionError

            var description: String {
                switch error {
                case .partSequenceNextCalledBeforeBodyWasConsumed:
                    return
                        "The outer part sequence was asked for the next element before the current part's inner body sequence was fully consumed."
                case .receivedBodyChunkInInitial:
                    return
                        "Received a body chunk from the upstream sequence as the first element, instead of header fields."
                case .receivedBodyChunkWhenWaitingForHeaders:
                    return "Received a body chunk from the upstream sequence when expecting header fields."
                case .receivedFrameWhenAlreadyHasUnsentHeaders:
                    return "Received another frame before the current frame with header fields was written out."
                }
            }

            var errorDescription: String? { description }
        }

        /// Request the next element from the outer part sequence.
        /// - Parameter bodyClosure: The closure invoked to fetch the next byte chunk of the part's body.
        /// - Returns: The next element, or `nil` if finished.
        /// - Throws: When a parsing error is encountered.
        func nextFromPartSequence(bodyClosure: @escaping @Sendable () async throws -> ArraySlice<UInt8>?) async throws
            -> Element?
        {
            switch stateMachine.nextFromPartSequence() {
            case .returnNil: return nil
            case .fetchFrame:
                var upstream = upstream
                let frame = try await upstream.next(isolatedWith: self)
                self.upstream = upstream
                switch stateMachine.partReceivedFrame(frame) {
                case .returnNil: return nil
                case .emitError(let error): throw IteratorError(error: error)
                case .emitPart(let headers):
                    let body = HTTPBody(headerFields: headers, bodyClosure: bodyClosure)
                    return .init(headerFields: headers, body: body)
                }
            case .emitError(let error): throw IteratorError(error: error)
            case .emitPart(let headers):
                let body = HTTPBody(headerFields: headers, bodyClosure: bodyClosure)
                return .init(headerFields: headers, body: body)
            }
        }

        /// Request the next element from the inner body bytes sequence.
        /// - Returns: The next element, or `nil` if finished.
        func nextFromBodySubsequence() async throws -> ArraySlice<UInt8>? {
            switch stateMachine.nextFromBodySubsequence() {
            case .returnNil: return nil
            case .fetchFrame:
                var upstream = upstream
                let frame = try await upstream.next(isolatedWith: self)
                self.upstream = upstream
                switch stateMachine.bodyReceivedFrame(frame) {
                case .returnNil: return nil
                case .returnChunk(let bodyChunk): return bodyChunk
                case .emitError(let error): throw IteratorError(error: error)
                }
            case .emitError(let error): throw IteratorError(error: error)
            }
        }
    }
}
