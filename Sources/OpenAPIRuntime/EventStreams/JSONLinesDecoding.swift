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

#if canImport(FoundationEssentials)
public import FoundationEssentials
#else
public import Foundation
#endif

/// A sequence that parses arbitrary byte chunks into lines using the JSON Lines format.
public struct JSONLinesDeserializationSequence<Upstream: AsyncSequence & Sendable>: Sendable
where Upstream.Element == ArraySlice<UInt8> {

    /// The upstream sequence.
    private let upstream: Upstream

    /// Creates a new sequence.
    /// - Parameter upstream: The upstream sequence of arbitrary byte chunks.
    public init(upstream: Upstream) { self.upstream = upstream }
}

extension JSONLinesDeserializationSequence: AsyncSequence {

    /// The type of element produced by this asynchronous sequence.
    public typealias Element = ArraySlice<UInt8>

    /// The iterator of `JSONLinesDeserializationSequence`.
    public struct Iterator<UpstreamIterator: AsyncIteratorProtocol>: AsyncIteratorProtocol
    where UpstreamIterator.Element == Element {

        /// The upstream iterator of arbitrary byte chunks.
        var upstream: UpstreamIterator

        /// The state machine of the iterator.
        var stateMachine: StateMachine = .init()

        /// Asynchronously advances to the next element and returns it, or ends the
        /// sequence if there is no next element.
        public mutating func next() async throws -> ArraySlice<UInt8>? {
            while true {
                switch stateMachine.next() {
                case .returnNil: return nil
                case .emitLine(let line): return line
                case .needsMore:
                    let value = try await upstream.next()
                    switch stateMachine.receivedValue(value) {
                    case .returnNil: return nil
                    case .emitLine(let line): return line
                    case .noop: continue
                    }
                }
            }
        }
    }

    /// Creates the asynchronous iterator that produces elements of this
    /// asynchronous sequence.
    public func makeAsyncIterator() -> Iterator<Upstream.AsyncIterator> {
        Iterator(upstream: upstream.makeAsyncIterator())
    }
}

@available(*, unavailable) extension JSONLinesDeserializationSequence.Iterator: Sendable {}

extension AsyncSequence where Element == ArraySlice<UInt8> {

    /// Returns another sequence that decodes each JSON Lines event as the provided type using the provided decoder.
    /// - Parameters:
    ///   - eventType: The type to decode the JSON event into.
    ///   - decoder: The JSON decoder to use.
    /// - Returns: A sequence that provides the decoded JSON events.
    public func asDecodedJSONLines<Event: Decodable & _OpenAPIRuntimeSendableMetatype>(
        of eventType: Event.Type = Event.self,
        decoder: JSONDecoder = .init()
    ) -> AsyncThrowingMapSequence<JSONLinesDeserializationSequence<Self>, Event> {
        JSONLinesDeserializationSequence(upstream: self)
            .map { line in try decoder.decode(Event.self, from: Data(line)) }
    }
}

extension JSONLinesDeserializationSequence.Iterator {

    /// A state machine representing the JSON Lines deserializer.
    struct StateMachine {

        /// The possible states of the state machine.
        enum State: Hashable {

            /// Is waiting for the end of line.
            case waitingForDelimiter(buffer: [UInt8])

            /// Finished, the terminal state.
            case finished

            /// Helper state to avoid copy-on-write copies.
            case mutating
        }

        /// The current state of the state machine.
        private(set) var state: State

        /// Creates a new state machine.
        init() { self.state = .waitingForDelimiter(buffer: []) }

        /// An action returned by the `next` method.
        enum NextAction {

            /// Return nil to the caller, no more bytes.
            case returnNil

            /// Emit a full line.
            case emitLine(ArraySlice<UInt8>)

            /// The line is not complete yet, needs more bytes.
            case needsMore
        }

        /// Read the next line parsed from upstream bytes.
        /// - Returns: An action to perform.
        mutating func next() -> NextAction {
            switch state {
            case .waitingForDelimiter(var buffer):
                state = .mutating
                guard let indexOfNewline = buffer.firstIndex(of: ASCII.lf) else {
                    state = .waitingForDelimiter(buffer: buffer)
                    return .needsMore
                }
                let line = buffer[..<indexOfNewline]
                buffer.removeSubrange(...indexOfNewline)
                state = .waitingForDelimiter(buffer: buffer)
                return .emitLine(line)
            case .finished: return .returnNil
            case .mutating: preconditionFailure("Invalid state")
            }
        }

        /// An action returned by the `receivedValue` method.
        enum ReceivedValueAction {

            /// Return nil to the caller, no more lines.
            case returnNil

            /// Emit a full line.
            case emitLine(ArraySlice<UInt8>)

            /// No action, rerun the parsing loop.
            case noop
        }

        /// Ingest the provided bytes.
        /// - Parameter value: A new byte chunk. If `nil`, then the source of bytes is finished.
        /// - Returns: An action to perform.
        mutating func receivedValue(_ value: ArraySlice<UInt8>?) -> ReceivedValueAction {
            switch state {
            case .waitingForDelimiter(var buffer):
                if let value {
                    state = .mutating
                    buffer.append(contentsOf: value)
                    state = .waitingForDelimiter(buffer: buffer)
                    return .noop
                } else {
                    let line = ArraySlice(buffer)
                    buffer = []
                    state = .finished
                    if line.isEmpty { return .returnNil } else { return .emitLine(line) }
                }
            case .finished, .mutating: preconditionFailure("Invalid state")
            }
        }
    }
}
