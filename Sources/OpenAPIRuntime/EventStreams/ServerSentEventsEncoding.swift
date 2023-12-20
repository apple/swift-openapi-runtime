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

/// A sequence that serializes Server-sent Events.
public struct ServerSentEventsSerializationSequence<Upstream: AsyncSequence & Sendable>: Sendable
where Upstream.Element == ServerSentEvent {

    /// The upstream sequence.
    private let upstream: Upstream

    /// Creates a new sequence.
    /// - Parameter upstream: The upstream sequence of events.
    public init(upstream: Upstream) { self.upstream = upstream }
}

extension ServerSentEventsSerializationSequence: AsyncSequence {

    /// The type of element produced by this asynchronous sequence.
    public typealias Element = ArraySlice<UInt8>

    /// The iterator of `ServerSentEventsSerializationSequence`.
    public struct Iterator<UpstreamIterator: AsyncIteratorProtocol>: AsyncIteratorProtocol
    where UpstreamIterator.Element == ServerSentEvent {

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
                    case .returnBytes(let bytes): return bytes
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

extension AsyncSequence {

    /// Returns another sequence that encodes Server-sent Events that have a JSON value in the data field.
    /// - Parameter encoder: The JSON encoder to use.
    /// - Returns: A sequence that provides the serialized JSON Lines.
    public func asEncodedServerSentEventsWithJSONData<JSONDataType: Encodable>(
        encoder: JSONEncoder = {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            return encoder
        }()
    ) -> ServerSentEventsSerializationSequence<AsyncThrowingMapSequence<Self, ServerSentEvent>>
    where Element == ServerSentEventWithJSONData<JSONDataType> {
        ServerSentEventsSerializationSequence(
            upstream: map { event in
                ServerSentEvent(
                    id: event.id,
                    event: event.event,
                    data: try event.data.flatMap { try String(decoding: encoder.encode($0), as: UTF8.self) },
                    retry: event.retry
                )
            }
        )
    }
}

extension ServerSentEventsSerializationSequence.Iterator {

    /// A state machine representing the JSON Lines serializer.
    struct StateMachine {

        /// The possible states of the state machine.
        enum State {

            /// Is emitting serialized JSON Lines events.
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
            case returnBytes(ArraySlice<UInt8>)
        }

        /// Ingest the provided event.
        /// - Parameter value: A new event. If `nil`, then the source of events is finished.
        /// - Returns: An action to perform.
        mutating func receivedValue(_ value: ServerSentEvent?) -> ReceivedValueAction {
            switch state {
            case .running:
                if let value {
                    var buffer: [UInt8] = []
                    func encodeField(name: String, value: some StringProtocol) {
                        buffer.append(contentsOf: name.utf8)
                        buffer.append(ASCII.colon)
                        buffer.append(ASCII.space)
                        buffer.append(contentsOf: value.utf8)
                        buffer.append(ASCII.lf)
                    }
                    if let id = value.id { encodeField(name: "id", value: id) }
                    if let event = value.event { encodeField(name: "event", value: event) }
                    if let retry = value.retry { encodeField(name: "retry", value: String(retry)) }
                    if let data = value.data {
                        // Normalize the data section by replacing CRLF and CR with just LF.
                        // Then split the section into individual field/value pairs.
                        let lines = data.replacingOccurrences(of: "\r\n", with: "\n")
                            .replacingOccurrences(of: "\r", with: "\n")
                            .split(separator: "\n", omittingEmptySubsequences: false)
                        for line in lines { encodeField(name: "data", value: line) }
                    }
                    // End the event.
                    buffer.append(ASCII.lf)
                    return .returnBytes(ArraySlice(buffer))
                } else {
                    state = .finished
                    return .returnNil
                }
            case .finished: preconditionFailure("Invalid state")
            }
        }
    }
}
