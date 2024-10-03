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
import class Foundation.JSONDecoder
#else
@preconcurrency import class Foundation.JSONDecoder
#endif
import struct Foundation.Data

/// A sequence that parses arbitrary byte chunks into events using the Server-sent Events format.
///
/// https://html.spec.whatwg.org/multipage/server-sent-events.html#server-sent-events
public struct ServerSentEventsDeserializationSequence<Upstream: AsyncSequence & Sendable>: Sendable
where Upstream.Element == ArraySlice<UInt8> {

    /// The upstream sequence.
    private let upstream: Upstream

    /// A closure that determines whether the given byte chunk should be forwarded to the consumer.
    /// - Parameter: A byte chunk.
    /// - Returns: `true` if the byte chunk should be forwarded, `false` if this byte chunk is the terminating sequence.
    private let predicate: @Sendable (ArraySlice<UInt8>) -> Bool

    /// Creates a new sequence.
    /// - Parameters:
    ///     - upstream: The upstream sequence of arbitrary byte chunks.
    ///     - predicate: A closure that determines whether the given byte chunk should be forwarded to the consumer.
    public init(upstream: Upstream, while predicate: @escaping @Sendable (ArraySlice<UInt8>) -> Bool) {
        self.upstream = upstream
        self.predicate = predicate
    }
}

extension ServerSentEventsDeserializationSequence: AsyncSequence {

    /// The type of element produced by this asynchronous sequence.
    public typealias Element = ServerSentEvent

    /// The iterator of `ServerSentEventsDeserializationSequence`.
    public struct Iterator<UpstreamIterator: AsyncIteratorProtocol>: AsyncIteratorProtocol
    where UpstreamIterator.Element == ArraySlice<UInt8> {

        /// The upstream iterator of arbitrary byte chunks.
        var upstream: UpstreamIterator

        /// The state machine of the iterator.
        var stateMachine: StateMachine

        /// Creates a new sequence.
        /// - Parameters:
        ///     - upstream: The upstream sequence of arbitrary byte chunks.
        ///     - predicate: A closure that determines whether the given byte chunk should be forwarded to the consumer.
        init(upstream: UpstreamIterator, while predicate: @escaping ((ArraySlice<UInt8>) -> Bool)) {
            self.upstream = upstream
            self.stateMachine = .init(while: predicate)
        }

        /// Asynchronously advances to the next element and returns it, or ends the
        /// sequence if there is no next element.
        public mutating func next() async throws -> ServerSentEvent? {
            while true {
                switch stateMachine.next() {
                case .returnNil: return nil
                case .emitEvent(let event): return event
                case .noop: continue
                case .needsMore:
                    let value = try await upstream.next()
                    switch stateMachine.receivedValue(value) {
                    case .returnNil: return nil
                    case .noop: continue
                    }
                }
            }
        }
    }

    /// Creates the asynchronous iterator that produces elements of this
    /// asynchronous sequence.
    public func makeAsyncIterator() -> Iterator<Upstream.AsyncIterator> {
        Iterator(upstream: upstream.makeAsyncIterator(), while: predicate)
    }
}

extension AsyncSequence where Element == ArraySlice<UInt8>, Self: Sendable {

    /// Returns another sequence that decodes each event's data as the provided type using the provided decoder.
    ///
    /// Use this method if the event's `data` field is not JSON, or if you don't want to parse it using `asDecodedServerSentEventsWithJSONData`.
    /// - Parameter: A closure that determines whether the given byte chunk should be forwarded to the consumer.
    /// - Returns: A sequence that provides the events.
    public func asDecodedServerSentEvents(while predicate: @escaping @Sendable (ArraySlice<UInt8>) -> Bool = { _ in true }) -> ServerSentEventsDeserializationSequence<
        ServerSentEventsLineDeserializationSequence<Self>
    > { .init(upstream: ServerSentEventsLineDeserializationSequence(upstream: self), while: predicate) }
    
    /// Returns another sequence that decodes each event's data as the provided type using the provided decoder.
    ///
    /// Use this method if the event's `data` field is JSON.
    /// - Parameters:
    ///   - dataType: The type to decode the JSON data into.
    ///   - decoder: The JSON decoder to use.
    ///   - predicate: A closure that determines whether the given byte sequence is the terminating byte sequence defined by the API.
    /// - Returns: A sequence that provides the events with the decoded JSON data.
    public func asDecodedServerSentEventsWithJSONData<JSONDataType: Decodable>(
        of dataType: JSONDataType.Type = JSONDataType.self,
        decoder: JSONDecoder = .init(),
        while predicate: @escaping @Sendable (ArraySlice<UInt8>) -> Bool = { _ in true }
    ) -> AsyncThrowingMapSequence<
        ServerSentEventsDeserializationSequence<ServerSentEventsLineDeserializationSequence<Self>>,
        ServerSentEventWithJSONData<JSONDataType>
    > {
        asDecodedServerSentEvents(while: predicate)
            .map { event in
                ServerSentEventWithJSONData(
                    event: event.event,
                    data: try event.data.flatMap { stringData in
                        try decoder.decode(JSONDataType.self, from: Data(stringData.utf8))
                    },
                    id: event.id,
                    retry: event.retry
                )
            }
    }
}

extension ServerSentEventsDeserializationSequence.Iterator {

    /// A state machine representing the Server-sent Events deserializer.
    struct StateMachine {

        /// The possible states of the state machine.
        enum State {

            /// Accumulating an event, which hasn't been emitted yet.
            case accumulatingEvent(ServerSentEvent, buffer: [ArraySlice<UInt8>], predicate: (ArraySlice<UInt8>) -> Bool)

            /// Finished, the terminal state.
            case finished

            /// Helper state to avoid copy-on-write copies.
            case mutating
        }

        /// The current state of the state machine.
        private(set) var state: State

        /// Creates a new state machine.
        init(while predicate: @escaping (ArraySlice<UInt8>) -> Bool) {
            self.state = .accumulatingEvent(.init(), buffer: [], predicate: predicate)
        }

        /// An action returned by the `next` method.
        enum NextAction {

            /// Return nil to the caller, no more bytes.
            case returnNil

            /// Emit a completed event.
            case emitEvent(ServerSentEvent)

            /// The line is not complete yet, needs more bytes.
            case needsMore

            /// Rerun the parsing loop.
            case noop
        }

        /// Read the next line parsed from upstream bytes.
        /// - Returns: An action to perform.
        mutating func next() -> NextAction {
            switch state {
            case .accumulatingEvent(var event, var buffer, let predicate):
                guard let line = buffer.first else { return .needsMore }
                state = .mutating
                buffer.removeFirst()
                if line.isEmpty {
                    // Dispatch the accumulated event.
                    // If the last character of data is a newline, strip it.
                    if event.data?.hasSuffix("\n") ?? false { event.data?.removeLast() }
                    
                    if let data = event.data, !predicate(ArraySlice(data.utf8)) {
                        state = .finished
                        return .returnNil
                    }
                    state = .accumulatingEvent(.init(), buffer: buffer, predicate: predicate)
                    return .emitEvent(event)
                }
                if line.first! == ASCII.colon {
                    // A comment, skip this line.
                    state = .accumulatingEvent(event, buffer: buffer, predicate: predicate)
                    return .noop
                }
                // Parse the field name and value.
                let field: String
                let value: String?
                if let indexOfFirstColon = line.firstIndex(of: ASCII.colon) {
                    field = String(decoding: line[..<indexOfFirstColon], as: UTF8.self)
                    let valueBytes = line[line.index(after: indexOfFirstColon)...]
                    let resolvedValueBytes: ArraySlice<UInt8>
                    if valueBytes.isEmpty {
                        resolvedValueBytes = []
                    } else if valueBytes.first! == ASCII.space {
                        resolvedValueBytes = valueBytes.dropFirst()
                    } else {
                        resolvedValueBytes = valueBytes
                    }
                    value = String(decoding: resolvedValueBytes, as: UTF8.self)
                } else {
                    field = String(decoding: line, as: UTF8.self)
                    value = nil
                }
                guard let value else {
                    // An unknown type of event, skip.
                    state = .accumulatingEvent(event, buffer: buffer, predicate: predicate)
                    return .noop
                }
                // Process the field.
                switch field {
                case "event": event.event = value
                case "data":
                    var data = event.data ?? ""
                    data.append(value)
                    data.append("\n")
                    event.data = data
                case "id": event.id = value
                case "retry":
                    if let retry = Int64(value) {
                        event.retry = retry
                    } else {
                        // Skip this line.
                        fallthrough
                    }
                default:
                    // An unknown or invalid field, skip.
                    state = .accumulatingEvent(event, buffer: buffer, predicate: predicate)
                    return .noop
                }
                // Processed the field, continue.
                state = .accumulatingEvent(event, buffer: buffer, predicate: predicate)
                return .noop
            case .finished: return .returnNil
            case .mutating: preconditionFailure("Invalid state")
            }
        }

        /// An action returned by the `receivedValue` method.
        enum ReceivedValueAction {

            /// Return nil to the caller, no more lines.
            case returnNil

            /// No action, rerun the parsing loop.
            case noop
        }

        /// Ingest the provided bytes.
        /// - Parameter value: A new byte chunk. If `nil`, then the source of bytes is finished.
        /// - Returns: An action to perform.
        mutating func receivedValue(_ value: ArraySlice<UInt8>?) -> ReceivedValueAction {
            switch state {
            case .accumulatingEvent(let event, var buffer, let predicate):
                if let value {
                    state = .mutating
                    buffer.append(value)
                    state = .accumulatingEvent(event, buffer: buffer, predicate: predicate)
                    return .noop
                } else {
                    // If no value is received, drop the existing event on the floor.
                    // The specification explicitly states this.
                    // > Once the end of the file is reached, any pending data must be discarded.
                    // > (If the file ends in the middle of an event, before the final empty line,
                    // > the incomplete event is not dispatched.)
                    // Source: https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation
                    state = .finished
                    return .returnNil
                }
            case .finished, .mutating: preconditionFailure("Invalid state")
            }
        }
    }
}

/// A sequence that parses arbitrary byte chunks into lines using the Server-sent Events format.
public struct ServerSentEventsLineDeserializationSequence<Upstream: AsyncSequence & Sendable>: Sendable
where Upstream.Element == ArraySlice<UInt8> {

    /// The upstream sequence.
    private let upstream: Upstream

    /// Creates a new sequence.
    /// - Parameter upstream: The upstream sequence of arbitrary byte chunks.
    public init(upstream: Upstream) { self.upstream = upstream }
}

extension ServerSentEventsLineDeserializationSequence: AsyncSequence {

    /// The type of element produced by this asynchronous sequence.
    public typealias Element = ArraySlice<UInt8>

    /// The iterator of `ServerSentEventsLineDeserializationSequence`.
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
                case .noop: continue
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

extension ServerSentEventsLineDeserializationSequence.Iterator {

    /// A state machine for parsing lines in Server-Sent Events.
    ///
    /// https://html.spec.whatwg.org/multipage/server-sent-events.html#parsing-an-event-stream
    ///
    /// This is not trivial to do with a streaming parser, as the end of line can be:
    /// - LF
    /// - CR
    /// - CRLF
    ///
    /// So when we get CR, but have no more data, we want to be able to emit the previous line,
    /// however we need to discard a LF if one comes.
    struct StateMachine {

        /// A state machine representing the Server-sent Events deserializer.
        enum State {

            /// Is waiting for the end of line.
            case waitingForEndOfLine(buffer: [UInt8])

            /// Consumed a `<CR>` character, so possibly the end of line.
            case consumedCR(buffer: [UInt8])

            /// Finished, the terminal state.
            case finished

            /// Helper state to avoid copy-on-write copies.
            case mutating
        }

        /// The current state of the state machine.
        private(set) var state: State

        /// Creates a new state machine.
        init() { self.state = .waitingForEndOfLine(buffer: []) }

        /// An action returned by the `next` method.
        enum NextAction {

            /// Return nil to the caller, no more bytes.
            case returnNil

            /// Emit a full line.
            case emitLine(ArraySlice<UInt8>)

            /// The line is not complete yet, needs more bytes.
            case needsMore

            /// No action, rerun the parsing loop.
            case noop
        }

        mutating func next() -> NextAction {
            switch state {
            case .waitingForEndOfLine(var buffer):
                switch buffer.matchOfOneOf(first: ASCII.lf, second: ASCII.cr) {
                case .noMatch: return .needsMore
                case .first(let index):
                    // Just a LF, so consume the line and move onto the next line.
                    state = .mutating
                    let line = buffer[..<index]
                    buffer.removeSubrange(...index)
                    state = .waitingForEndOfLine(buffer: buffer)
                    return .emitLine(line)
                case .second(let index):
                    // Got a CR, which can either be the only delimiter, or can be followed by a LF.
                    // Consume the line, but move to a state that ensures a LF as the first next
                    // character is discarded.
                    state = .mutating
                    let line = buffer[..<index]
                    buffer.removeSubrange(...index)
                    state = .consumedCR(buffer: buffer)
                    return .emitLine(line)
                }
            case .consumedCR(var buffer):
                guard !buffer.isEmpty else { return .needsMore }
                state = .mutating
                if buffer.first! == ASCII.lf { buffer.removeFirst() }
                state = .waitingForEndOfLine(buffer: buffer)
                return .noop
            case .finished: return .returnNil
            case .mutating: preconditionFailure("Invalid state")
            }
        }

        /// An action returned by the `receivedValue` method.
        enum ReceivedValueAction {

            /// Return nil to the caller, no more bytes.
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
            case .waitingForEndOfLine(var buffer):
                if let value {
                    state = .mutating
                    buffer.append(contentsOf: value)
                    state = .waitingForEndOfLine(buffer: buffer)
                    return .noop
                } else {
                    let line = ArraySlice(buffer)
                    buffer = []
                    state = .finished
                    if line.isEmpty { return .returnNil } else { return .emitLine(line) }
                }
            case .consumedCR(var buffer):
                if let value {
                    state = .mutating
                    buffer.append(contentsOf: value)
                    state = .consumedCR(buffer: buffer)
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
