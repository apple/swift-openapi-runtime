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

/// A sequence that serializes multipart frames into bytes.
struct MultipartFramesToBytesSequence<Upstream: AsyncSequence & Sendable>: Sendable
where Upstream.Element == MultipartFrame {

    /// The source of multipart frames.
    var upstream: Upstream

    /// The boundary string used to separate multipart parts.
    var boundary: String
}

extension MultipartFramesToBytesSequence: AsyncSequence {

    /// The type of element produced by this asynchronous sequence.
    typealias Element = ArraySlice<UInt8>

    /// Creates the asynchronous iterator that produces elements of this
    /// asynchronous sequence.
    ///
    /// - Returns: An instance of the `AsyncIterator` type used to produce
    /// elements of the asynchronous sequence.
    func makeAsyncIterator() -> Iterator<Upstream.AsyncIterator> {
        Iterator(upstream: upstream.makeAsyncIterator(), boundary: boundary)
    }

    /// An iterator that pulls frames from the upstream iterator and provides
    /// serialized byte chunks.
    struct Iterator<UpstreamIterator: AsyncIteratorProtocol>: AsyncIteratorProtocol
    where UpstreamIterator.Element == MultipartFrame {

        /// The iterator that provides the multipart frames.
        private var upstream: UpstreamIterator

        /// The multipart frame serializer.
        private var serializer: MultipartSerializer

        /// Creates a new iterator from the provided source of frames and a boundary string.
        /// - Parameters:
        ///   - upstream: The iterator that provides the multipart frames.
        ///   - boundary: The boundary separating the multipart parts.
        init(upstream: UpstreamIterator, boundary: String) {
            self.upstream = upstream
            self.serializer = .init(boundary: boundary)
        }

        /// Asynchronously advances to the next element and returns it, or ends the
        /// sequence if there is no next element.
        ///
        /// - Returns: The next element, if it exists, or `nil` to signal the end of
        ///   the sequence.
        mutating func next() async throws -> ArraySlice<UInt8>? {
            try await serializer.next { try await upstream.next() }
        }
    }
}

/// A serializer of multipart frames into bytes.
struct MultipartSerializer {

    /// The boundary that separates parts.
    private let boundary: ArraySlice<UInt8>

    /// The underlying state machine.
    private var stateMachine: StateMachine

    /// The buffer of bytes ready to be written out.
    private var outBuffer: [UInt8]

    /// Creates a new serializer.
    /// - Parameter boundary: The boundary that separates parts.
    init(boundary: String) {
        self.boundary = ArraySlice(boundary.utf8)
        self.stateMachine = .init()
        self.outBuffer = []
    }
    /// Requests the next byte chunk.
    /// - Parameter fetchFrame: A closure that is called when the serializer is ready to serialize the next frame.
    /// - Returns: A byte chunk.
    /// - Throws: When a serialization error is encountered.
    mutating func next(_ fetchFrame: () async throws -> MultipartFrame?) async throws -> ArraySlice<UInt8>? {

        func flushedBytes() -> ArraySlice<UInt8> {
            let outChunk = ArraySlice(outBuffer)
            outBuffer.removeAll(keepingCapacity: true)
            return outChunk
        }

        while true {
            switch stateMachine.next() {
            case .returnNil: return nil
            case .emitStart:
                emitStart()
                return flushedBytes()
            case .needsMore:
                let frame = try await fetchFrame()
                switch stateMachine.receivedFrame(frame) {
                case .returnNil: return nil
                case .emitEvents(let events):
                    for event in events {
                        switch event {
                        case .headerFields(let headerFields): emitHeaders(headerFields)
                        case .bodyChunk(let chunk): emitBodyChunk(chunk)
                        case .endOfPart: emitEndOfPart()
                        case .start: emitStart()
                        case .end: emitEnd()
                        }
                    }
                    return flushedBytes()
                case .emitError(let error): throw SerializerError(error: error)
                }
            }
        }
    }
}

extension MultipartSerializer {

    /// An error thrown by the serializer.
    struct SerializerError: Swift.Error, CustomStringConvertible, LocalizedError {

        /// The underlying error emitted by the state machine.
        var error: StateMachine.ActionError

        var description: String {
            switch error {
            case .noHeaderFieldsAtStart: return "No header fields found at the start of the multipart body."
            }
        }

        var errorDescription: String? { description }
    }
}

extension MultipartSerializer {

    /// Writes the provided header fields into the buffer.
    /// - Parameter headerFields: The header fields to serialize.
    private mutating func emitHeaders(_ headerFields: HTTPFields) {
        outBuffer.append(contentsOf: ASCII.crlf)
        let sortedHeaders = headerFields.sorted { a, b in a.name.canonicalName < b.name.canonicalName }
        for headerField in sortedHeaders {
            outBuffer.append(contentsOf: headerField.name.canonicalName.utf8)
            outBuffer.append(contentsOf: ASCII.colonSpace)
            outBuffer.append(contentsOf: headerField.value.utf8)
            outBuffer.append(contentsOf: ASCII.crlf)
        }
        outBuffer.append(contentsOf: ASCII.crlf)
    }

    /// Writes the part body chunk into the buffer.
    /// - Parameter bodyChunk: The body chunk to write.
    private mutating func emitBodyChunk(_ bodyChunk: ArraySlice<UInt8>) { outBuffer.append(contentsOf: bodyChunk) }

    /// Writes an end of part boundary into the buffer.
    private mutating func emitEndOfPart() {
        outBuffer.append(contentsOf: ASCII.crlf)
        outBuffer.append(contentsOf: ASCII.dashes)
        outBuffer.append(contentsOf: boundary)
    }

    /// Writes the start boundary into the buffer.
    private mutating func emitStart() {
        outBuffer.append(contentsOf: ASCII.dashes)
        outBuffer.append(contentsOf: boundary)
    }

    /// Writes the end double dash to the buffer.
    private mutating func emitEnd() {
        outBuffer.append(contentsOf: ASCII.dashes)
        outBuffer.append(contentsOf: ASCII.crlf)
        outBuffer.append(contentsOf: ASCII.crlf)
    }
}

extension MultipartSerializer {

    /// A state machine representing the multipart frame serializer.
    struct StateMachine {

        /// The possible states of the state machine.
        enum State: Hashable {

            /// Has not yet written any bytes.
            case initial

            /// Emitted start, but no frames yet.
            case startedNothingEmittedYet

            /// Finished, the terminal state.
            case finished

            /// Last emitted a header fields frame.
            case emittedHeaders

            /// Last emitted a part body chunk frame.
            case emittedBodyChunk
        }

        /// The current state of the state machine.
        private(set) var state: State

        /// Creates a new state machine.
        init() { self.state = .initial }

        /// An error returned by the state machine.
        enum ActionError: Hashable {

            /// The first frame from upstream was not a header fields frame.
            case noHeaderFieldsAtStart
        }

        /// An action returned by the `next` method.
        enum NextAction: Hashable {

            /// Return nil to the caller, no more bytes.
            case returnNil

            /// Emit the initial boundary.
            case emitStart

            /// Ready for the next frame.
            case needsMore
        }

        /// Read the next byte chunk serialized from upstream frames.
        /// - Returns: An action to perform.
        mutating func next() -> NextAction {
            switch state {
            case .initial:
                state = .startedNothingEmittedYet
                return .emitStart
            case .finished: return .returnNil
            case .startedNothingEmittedYet, .emittedHeaders, .emittedBodyChunk: return .needsMore
            }
        }

        /// An event to serialize to bytes.
        enum Event: Hashable {

            /// The header fields of a part.
            case headerFields(HTTPFields)

            /// A byte chunk of a part.
            case bodyChunk(ArraySlice<UInt8>)

            /// A boundary between parts.
            case endOfPart

            /// The initial boundary.
            case start

            /// The final dashes.
            case end
        }

        /// An action returned by the `receivedFrame` method.
        enum ReceivedFrameAction: Hashable {

            /// Return nil to the caller, no more bytes.
            case returnNil

            /// Write the provided events as bytes.
            case emitEvents([Event])

            /// Throw the provided error.
            case emitError(ActionError)
        }

        /// Ingest the provided frame.
        /// - Parameter frame: A new frame. If `nil`, then the source of frames is finished.
        /// - Returns: An action to perform.
        mutating func receivedFrame(_ frame: MultipartFrame?) -> ReceivedFrameAction {
            switch state {
            case .initial: preconditionFailure("Invalid state: \(state)")
            case .finished: return .returnNil
            case .startedNothingEmittedYet, .emittedHeaders, .emittedBodyChunk: break
            }
            switch (state, frame) {
            case (.initial, _), (.finished, _): preconditionFailure("Already handled above.")
            case (_, .none):
                state = .finished
                return .emitEvents([.endOfPart, .end])
            case (.startedNothingEmittedYet, .headerFields(let headerFields)):
                state = .emittedHeaders
                return .emitEvents([.headerFields(headerFields)])
            case (.startedNothingEmittedYet, .bodyChunk):
                state = .finished
                return .emitError(.noHeaderFieldsAtStart)
            case (.emittedHeaders, .headerFields(let headerFields)),
                (.emittedBodyChunk, .headerFields(let headerFields)):
                state = .emittedHeaders
                return .emitEvents([.endOfPart, .headerFields(headerFields)])
            case (.emittedHeaders, .bodyChunk(let bodyChunk)), (.emittedBodyChunk, .bodyChunk(let bodyChunk)):
                state = .emittedBodyChunk
                return .emitEvents([.bodyChunk(bodyChunk)])
            }
        }
    }
}
