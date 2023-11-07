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

struct MultipartRawToFrameSequence<Upstream: AsyncSequence> where Upstream.Element == MultipartRawPart {
    var upstream: Upstream
}

extension MultipartRawToFrameSequence: AsyncSequence {
    typealias Element = MultipartFrame

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

struct MultipartFrameToRawSequence<Upstream: AsyncSequence> where Upstream.Element == MultipartFrame {
    var upstream: Upstream
}

extension MultipartFrameToRawSequence: AsyncSequence {
    typealias Element = MultipartRawPart

    func makeAsyncIterator() -> Iterator { Iterator(upstream: upstream.makeAsyncIterator()) }
    struct Iterator: AsyncIteratorProtocol {

        var shared: SharedIterator
        var bodyClosure: @Sendable () async throws -> ArraySlice<UInt8>?
        init(upstream: Upstream.AsyncIterator) {
            let shared = SharedIterator(upstream: upstream)
            self.shared = shared
            self.bodyClosure = { try await shared.nextFromBodySubsequence() }
        }

        mutating func next() async throws -> Element? {
            try await shared.nextFromPartSequence(bodyClosure: bodyClosure)
        }
    }
    actor SharedIterator {
        private var upstream: Upstream.AsyncIterator
        private var state: StateMachine
        init(upstream: Upstream.AsyncIterator) {
            self.upstream = upstream
            self.state = .init()
        }
        struct IteratorError: Swift.Error { var error: StateMachine.StateError }
        func nextFromPartSequence(bodyClosure: @escaping @Sendable () async throws -> ArraySlice<UInt8>?) async throws
            -> Element?
        {
            switch state.nextFromPartSequence(bodyClosure: bodyClosure) {
            case .returnNil: return nil
            case .fetchFrame:
                var upstream = upstream
                let frame = try await upstream.next()
                self.upstream = upstream
                switch state.partReceivedFrame(frame, bodyClosure: bodyClosure) {
                case .returnNil: return nil
                case .emitError(let error): throw IteratorError(error: error)
                case .emitPart(let headers, let body): return .init(headerFields: headers, body: body)
                }
            case .emitError(let error): throw IteratorError(error: error)
            case .emitPart(let headers, let body): return .init(headerFields: headers, body: body)
            }
        }
        func nextFromBodySubsequence() async throws -> ArraySlice<UInt8>? {
            switch state.nextFromBodySubsequence() {
            case .returnNil: return nil
            case .fetchFrame:
                var upstream = upstream
                let frame = try await upstream.next()
                self.upstream = upstream
                switch state.bodyReceivedFrame(frame) {
                case .returnNil: return nil
                case .returnChunk(let bodyChunk): return bodyChunk
                case .emitError(let error): throw IteratorError(error: error)
                }
            case .emitError(let error): throw IteratorError(error: error)
            }
        }
    }
    struct StateMachine: CustomStringConvertible {
        private var state: State
        init() { self.state = .initial }
        var description: String { "\(state)" }
        func makeBody(headers: HTTPFields, bodyClosure: @escaping @Sendable () async throws -> ArraySlice<UInt8>?)
            -> HTTPBody
        {
            let stream = AsyncThrowingStream(unfolding: bodyClosure)
            let length: HTTPBody.Length
            if let contentLengthString = headers[.contentLength], let contentLength = Int(contentLengthString) {
                length = .known(contentLength)
            } else {
                length = .unknown
            }
            let body = HTTPBody(stream, length: length)
            return body
        }
        enum State {
            case initial
            /// Associated value is optional headers.
            /// If they're non-nil, they came already, so just send them.
            /// If they're nil, need to get the next chunk for them.
            case waitingToSendHeaders(HTTPFields?)
            case streamingBody
            case partFinished
            case finished
        }
        enum StateError {
            case partSequenceNextCalledBeforeBodyWasConsumed
            case receivedBodyChunkInInitial
            case receivedBodyChunkWhenWaitingForHeaders
            case receivedFrameWhenAlreadyHasUnsentHeaders
        }
        enum NextFromPartSequenceAction {
            case returnNil
            case fetchFrame
            case emitError(StateError)
            case emitPart(HTTPFields, HTTPBody)
        }
        mutating func nextFromPartSequence(bodyClosure: @escaping @Sendable () async throws -> ArraySlice<UInt8>?)
            -> NextFromPartSequenceAction
        {
            switch state {
            case .initial, .partFinished:
                state = .waitingToSendHeaders(nil)
                return .fetchFrame
            case .waitingToSendHeaders(.some(let headers)):
                state = .streamingBody
                let body = makeBody(headers: headers, bodyClosure: bodyClosure)
                return .emitPart(headers, body)
            case .waitingToSendHeaders(.none), .streamingBody:
                state = .finished
                return .emitError(.partSequenceNextCalledBeforeBodyWasConsumed)
            case .finished: return .returnNil
            }
        }
        enum PartReceivedFrameAction {
            case returnNil
            case emitError(StateError)
            case emitPart(HTTPFields, HTTPBody)
        }
        mutating func partReceivedFrame(
            _ frame: MultipartFrame?,
            bodyClosure: @escaping @Sendable () async throws -> ArraySlice<UInt8>?
        ) -> PartReceivedFrameAction {
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
                        let body = makeBody(headers: headers, bodyClosure: bodyClosure)
                        return .emitPart(headers, body)
                    case .bodyChunk:
                        state = .finished
                        return .emitError(.receivedBodyChunkWhenWaitingForHeaders)
                    }
                } else {
                    state = .finished
                    return .returnNil
                }
            case .streamingBody, .partFinished:
                state = .finished
                return .emitError(.partSequenceNextCalledBeforeBodyWasConsumed)
            case .finished: return .returnNil
            }
        }

        enum NextFromBodySubsequenceAction {
            case returnNil
            case fetchFrame
            case emitError(StateError)
        }
        mutating func nextFromBodySubsequence() -> NextFromBodySubsequenceAction {
            switch state {
            case .initial:
                state = .finished
                return .emitError(.receivedBodyChunkInInitial)
            case .waitingToSendHeaders:
                state = .finished
                return .emitError(.receivedBodyChunkWhenWaitingForHeaders)
            case .streamingBody: return .fetchFrame
            case .finished, .partFinished: return .returnNil
            }
        }
        enum BodyReceivedFrameAction {
            case returnNil
            case returnChunk(ArraySlice<UInt8>)
            case emitError(StateError)
        }
        mutating func bodyReceivedFrame(_ frame: MultipartFrame?) -> BodyReceivedFrameAction {
            switch state {
            case .initial: preconditionFailure("Haven't asked for a frame, how did we receive one?")
            case .waitingToSendHeaders, .partFinished:
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
                    state = .partFinished
                    return .returnNil
                }
            case .finished: return .returnNil
            }
        }
    }
}
