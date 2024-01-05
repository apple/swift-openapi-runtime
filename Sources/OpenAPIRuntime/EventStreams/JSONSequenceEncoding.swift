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

#if canImport(Darwin)
import class Foundation.JSONEncoder
#else
@preconcurrency import class Foundation.JSONEncoder
#endif

/// A sequence that serializes lines by concatenating them using the JSON Sequence format.
public struct JSONSequenceSerializationSequence<Upstream: AsyncSequence & Sendable>: Sendable
where Upstream.Element == ArraySlice<UInt8> {

    /// The upstream sequence.
    private let upstream: Upstream

    /// Creates a new sequence.
    /// - Parameter upstream: The upstream sequence of lines.
    public init(upstream: Upstream) { self.upstream = upstream }
}

extension JSONSequenceSerializationSequence: AsyncSequence {

    /// The type of element produced by this asynchronous sequence.
    public typealias Element = ArraySlice<UInt8>

    /// The iterator of `JSONSequenceSerializationSequence`.
    public struct Iterator<UpstreamIterator: AsyncIteratorProtocol>: AsyncIteratorProtocol
    where UpstreamIterator.Element == Element {

        /// The upstream iterator of lines.
        var upstream: UpstreamIterator

        /// The state machine of the iterator.
        var stateMachine: StateMachine = .init()

        /// Asynchronously advances to the next element and returns it, or ends the
        /// sequence if there is no next element.
        public mutating func next() async throws -> ArraySlice<UInt8>? {
            while true {
                switch stateMachine.next() {
                case .returnNil: return nil
                case .needsMore:
                    let value = try await upstream.next()
                    switch stateMachine.receivedValue(value) {
                    case .returnNil: return nil
                    case .emitBytes(let bytes): return bytes
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

extension AsyncSequence where Element: Encodable & Sendable, Self: Sendable {

    /// Returns another sequence that encodes the events using the provided encoder into a JSON Sequence.
    /// - Parameter encoder: The JSON encoder to use.
    /// - Returns: A sequence that provides the serialized JSON Sequence.
    public func asEncodedJSONSequence(
        encoder: JSONEncoder = {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            return encoder
        }()
    ) -> JSONSequenceSerializationSequence<AsyncThrowingMapSequence<Self, ArraySlice<UInt8>>> {
        .init(upstream: map { event in try ArraySlice(encoder.encode(event)) })
    }
}

extension JSONSequenceSerializationSequence.Iterator {

    /// A state machine representing the JSON Sequence serializer.
    struct StateMachine {

        /// The possible states of the state machine.
        enum State {

            /// Is emitting serialized JSON Sequence events.
            case running

            /// Finished, the terminal state.
            case finished
        }

        /// The current state of the state machine.
        private(set) var state: State
        /// Creates a new state machine.
        init() { self.state = .running }
        /// An action returned by the `next` method.
        enum NextAction {

            /// Return nil to the caller, no more bytes.
            case returnNil

            /// Needs more bytes.
            case needsMore
        }

        /// Read the next byte chunk serialized from upstream lines.
        /// - Returns: An action to perform.
        mutating func next() -> NextAction {
            switch state {
            case .running: return .needsMore
            case .finished: return .returnNil
            }
        }

        /// An action returned by the `receivedValue` method.
        enum ReceivedValueAction {

            /// Return nil to the caller, no more bytes.
            case returnNil

            /// Emit the provided bytes.
            case emitBytes(ArraySlice<UInt8>)
        }

        /// Ingest the provided line.
        /// - Parameter value: A new line. If `nil`, then the source of line is finished.
        /// - Returns: An action to perform.
        mutating func receivedValue(_ value: ArraySlice<UInt8>?) -> ReceivedValueAction {
            switch state {
            case .running:
                if let value {
                    var buffer: [UInt8] = []
                    buffer.reserveCapacity(value.count + 2)
                    buffer.append(ASCII.rs)
                    buffer.append(contentsOf: value)
                    buffer.append(ASCII.lf)
                    return .emitBytes(ArraySlice(buffer))
                } else {
                    state = .finished
                    return .returnNil
                }
            case .finished: preconditionFailure("Invalid state")
            }
        }
    }
}
