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

typealias MultipartChunks = OpenAPISequence<MultipartChunk>

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

// MARK: - Sequence converting untyped parts -> raw

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

// MARK: - Sequence converting raw -> untyped parts

struct MultipartChunksToUntypedSequence<Upstream: AsyncSequence> where Upstream.Element == MultipartChunk {
    var upstream: Upstream
}

extension AsyncSequence where Element == MultipartChunk {
    func asUntypedParts() -> MultipartChunksToUntypedSequence<Self> { .init(upstream: self) }
}

extension MultipartChunksToUntypedSequence: AsyncSequence {
    typealias Element = MultipartUntypedPart

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
            print("MultipartChunksToUntypedSequence - nextFromPartSequence start - \(state)")
            defer { print("MultipartChunksToUntypedSequence - nextFromPartSequence end - \(state)") }
            switch state.nextFromPartSequence(bodyClosure: bodyClosure) {
            case .returnNil: return nil
            case .fetchChunk:
                var upstream = upstream
                let chunk = try await upstream.next()
                self.upstream = upstream
                switch state.partReceivedChunk(chunk, bodyClosure: bodyClosure) {
                case .returnNil: return nil
                case .emitError(let error): throw IteratorError(error: error)
                case .emitPart(let headers, let body): return .init(headerFields: headers, body: body)
                }
            case .emitError(let error): throw IteratorError(error: error)
            case .emitPart(let headers, let body): return .init(headerFields: headers, body: body)
            }
        }
        func nextFromBodySubsequence() async throws -> ArraySlice<UInt8>? {
            print("MultipartChunksToUntypedSequence - nextFromBodySubsequence start - \(state)")
            defer { print("MultipartChunksToUntypedSequence - nextFromBodySubsequence end - \(state)") }
            switch state.nextFromBodySubsequence() {
            case .returnNil: return nil
            case .fetchChunk:
                var upstream = upstream
                let chunk = try await upstream.next()
                self.upstream = upstream
                switch state.bodyReceivedChunk(chunk) {
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
            let length: ByteLength
            if let contentLengthString = headers[.contentLength], let contentLength = Int64(contentLengthString) {
                length = .known(Int(contentLength) /* TODO: remove cast */)
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
            case receivedChunkWhenAlreadyHasUnsentHeaders
        }
        enum NextFromPartSequenceAction {
            case returnNil
            case fetchChunk
            case emitError(StateError)
            case emitPart(HTTPFields, HTTPBody)
        }
        mutating func nextFromPartSequence(bodyClosure: @escaping @Sendable () async throws -> ArraySlice<UInt8>?)
            -> NextFromPartSequenceAction
        {
            switch state {
            case .initial, .partFinished:
                state = .waitingToSendHeaders(nil)
                return .fetchChunk
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
        enum PartReceivedChunkAction {
            case returnNil
            case emitError(StateError)
            case emitPart(HTTPFields, HTTPBody)
        }
        mutating func partReceivedChunk(
            _ chunk: MultipartChunk?,
            bodyClosure: @escaping @Sendable () async throws -> ArraySlice<UInt8>?
        ) -> PartReceivedChunkAction {
            switch state {
            case .initial: preconditionFailure("Haven't asked for a part chunk, how did we receive one?")
            case .waitingToSendHeaders(.some):
                state = .finished
                return .emitError(.receivedChunkWhenAlreadyHasUnsentHeaders)
            case .waitingToSendHeaders(.none):
                if let chunk {
                    switch chunk {
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
            case fetchChunk
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
            case .streamingBody: return .fetchChunk
            case .finished, .partFinished: return .returnNil
            }
        }
        enum BodyReceivedChunkAction {
            case returnNil
            case returnChunk(ArraySlice<UInt8>)
            case emitError(StateError)
        }
        mutating func bodyReceivedChunk(_ chunk: MultipartChunk?) -> BodyReceivedChunkAction {
            switch state {
            case .initial: preconditionFailure("Haven't asked for a body chunk, how did we receive one?")
            case .waitingToSendHeaders, .partFinished:
                state = .finished
                return .emitError(.receivedBodyChunkWhenWaitingForHeaders)
            case .streamingBody:
                if let chunk {
                    switch chunk {
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
