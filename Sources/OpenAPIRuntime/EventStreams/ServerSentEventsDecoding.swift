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

/// https://html.spec.whatwg.org/multipage/server-sent-events.html#server-sent-events

public struct ServerSentEventsDeserializationSequence<Upstream: AsyncSequence & Sendable>: Sendable where Upstream.Element == ArraySlice<UInt8> {
    var upstream: Upstream
    public init(upstream: Upstream) {
        self.upstream = upstream
    }
}

extension ServerSentEventsDeserializationSequence: AsyncSequence {
    public typealias Element = ServerSentEvent
    
    public struct Iterator<UpstreamIterator: AsyncIteratorProtocol>: AsyncIteratorProtocol where UpstreamIterator.Element == ArraySlice<UInt8> {
        var upstream: UpstreamIterator
        var stateMachine: ServerSentEventsDeserializerStateMachine = .init()
        public mutating func next() async throws -> ServerSentEvent? {
            while true {
                switch stateMachine.next() {
                case .returnNil:
                    return nil
                case .emitEvent(let event):
                    return event
                case .noop:
                    continue
                case .needsMore:
                    let value = try await upstream.next()
                    switch stateMachine.receivedValue(value) {
                    case .returnNil:
                        return nil
                    case .noop:
                        continue
                    }
                }
            }
        }
    }
    
    public func makeAsyncIterator() -> Iterator<Upstream.AsyncIterator> {
        Iterator(upstream: upstream.makeAsyncIterator())
    }
}

extension AsyncSequence where Element == ArraySlice<UInt8> {

    public func asDecodedServerSentEvents() -> ServerSentEventsDeserializationSequence<ServerSentEventsLineDeserializationSequence<Self>> {
        .init(upstream: asParsedServerSentEventLines())
    }

    public func asDecodedServerSentEventsWithJSONData<JSONDataType: Decodable>(
        of dataType: JSONDataType.Type = JSONDataType.self,
        using decoder: JSONDecoder = .init()
    ) -> AsyncThrowingMapSequence<
        ServerSentEventsDeserializationSequence<ServerSentEventsLineDeserializationSequence<Self>>,
        ServerSentEventWithJSONData<JSONDataType>
    > {
        asDecodedServerSentEvents().map { event in
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

struct ServerSentEventsDeserializerStateMachine {
    
    enum State {
        case accumulatingEvent(ServerSentEvent, buffer: [ArraySlice<UInt8>])
        case finished
        case mutating
    }
    private(set) var state: State = .accumulatingEvent(.init(), buffer: [])
    
    enum NextAction {
        case returnNil
        case emitEvent(ServerSentEvent)
        case needsMore
        case noop
    }
    
    mutating func next() -> NextAction {
        switch state {
        case .accumulatingEvent(var event, var buffer):
            guard let line = buffer.first else {
                return .needsMore
            }
            state = .mutating
            buffer.removeFirst()
            if line.isEmpty {
                // Dispatch the accumulated event.
                state = .accumulatingEvent(.init(), buffer: buffer)
                // If the last character of data is a newline, strip it.
                if event.data?.hasSuffix("\n") ?? false {
                    event.data?.removeLast()
                }
                return .emitEvent(event)
            }
            if line.first! == ASCII.colon {
                // A comment, skip this line.
                state = .accumulatingEvent(event, buffer: buffer)
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
                state = .accumulatingEvent(event, buffer: buffer)
                return .noop
            }
            // Process the field.
            switch field {
            case "event":
                event.event = value
            case "data":
                var data = event.data ?? ""
                data.append(value)
                data.append("\n")
                event.data = data
            case "id":
                event.id = value
            case "retry":
                if let retry = Int64(value) {
                    event.retry = retry
                } else {
                    // Skip this line.
                    fallthrough
                }
            default:
                // An unknown or invalid field, skip.
                state = .accumulatingEvent(event, buffer: buffer)
                return .noop
            }
            // Processed the field, continue.
            state = .accumulatingEvent(event, buffer: buffer)
            return .noop
        case .finished:
            return .returnNil
        case .mutating:
            preconditionFailure("Invalid state")
        }
    }
    
    enum ReceivedValueAction {
        case returnNil
        case noop
    }
    
    mutating func receivedValue(_ value: ArraySlice<UInt8>?) -> ReceivedValueAction {
        switch state {
        case .accumulatingEvent(let event, var buffer):
            if let value {
                state = .mutating
                buffer.append(value)
                state = .accumulatingEvent(event, buffer: buffer)
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
        case .finished, .mutating:
            preconditionFailure("Invalid state")
        }
    }
}

public struct ServerSentEventsLineDeserializationSequence<Upstream: AsyncSequence & Sendable>: Sendable where Upstream.Element == ArraySlice<UInt8> {
    var upstream: Upstream
    public init(upstream: Upstream) {
        self.upstream = upstream
    }
}

extension ServerSentEventsLineDeserializationSequence: AsyncSequence {
    public typealias Element = ArraySlice<UInt8>

    public struct Iterator<UpstreamIterator: AsyncIteratorProtocol>: AsyncIteratorProtocol where UpstreamIterator.Element == Element {
        var upstream: UpstreamIterator
        var stateMachine: ServerSentEventsLineDeserializerStateMachine = .init()
        public mutating func next() async throws -> ArraySlice<UInt8>? {
            while true {
                switch stateMachine.next() {
                case .returnNil:
                    return nil
                case .returnLine(let line):
                    return line
                case .noop:
                    continue
                case .needsMore:
                    let value = try await upstream.next()
                    switch stateMachine.receivedValue(value) {
                    case .returnNil:
                        return nil
                    case .returnLine(let line):
                        return line
                    case .noop:
                        continue
                    }
                }
            }
        }
    }

    public func makeAsyncIterator() -> Iterator<Upstream.AsyncIterator> {
        Iterator(upstream: upstream.makeAsyncIterator())
    }
}

extension AsyncSequence where Element == ArraySlice<UInt8> {
    func asParsedServerSentEventLines() -> ServerSentEventsLineDeserializationSequence<Self> {
        .init(upstream: self)
    }
}

/// A state machine for parsing lines in server-sent events.
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
struct ServerSentEventsLineDeserializerStateMachine {

    enum State {
        case waitingForEndOfLine([UInt8])
        case consumedCR([UInt8])
        case finished
        case mutating
    }
    private(set) var state: State = .waitingForEndOfLine([])

    enum NextAction {
        case returnNil
        case returnLine(ArraySlice<UInt8>)
        case needsMore
        case noop
    }

    mutating func next() -> NextAction {
        switch state {
        case .waitingForEndOfLine(var buffer):
            switch buffer.matchOfOneOf(first: ASCII.lf, second: ASCII.cr) {
            case .noMatch:
                return .needsMore
            case .first(let index):
                // Just a LF, so consume the line and move onto the next line.
                state = .mutating
                let line = buffer[..<index]
                buffer.removeSubrange(...index)
                state = .waitingForEndOfLine(buffer)
                return .returnLine(line)
            case .second(let index):
                // Got a CR, which can either be the only delimiter, or can be followed by a LF.
                // Consume the line, but move to a state that ensures a LF as the first next
                // character is discarded.
                state = .mutating
                let line = buffer[..<index]
                buffer.removeSubrange(...index)
                state = .consumedCR(buffer)
                return .returnLine(line)
            }
        case .consumedCR(var buffer):
            guard !buffer.isEmpty else {
                return .needsMore
            }
            state = .mutating
            if buffer.first! == ASCII.lf {
                buffer.removeFirst()
            }
            state = .waitingForEndOfLine(buffer)
            return .noop
        case .finished:
            return .returnNil
        case .mutating:
            preconditionFailure("Invalid state")
        }
    }

    enum ReceivedValueAction {
        case returnNil
        case returnLine(ArraySlice<UInt8>)
        case noop
    }

    mutating func receivedValue(_ value: ArraySlice<UInt8>?) -> ReceivedValueAction {
        switch state {
        case .waitingForEndOfLine(var buffer):
            if let value {
                state = .mutating
                buffer.append(contentsOf: value)
                state = .waitingForEndOfLine(buffer)
                return .noop
            } else {
                let line = ArraySlice(buffer)
                buffer = []
                state = .finished
                if line.isEmpty {
                    return .returnNil
                } else {
                    return .returnLine(line)
                }
            }
        case .consumedCR(var buffer):
            if let value {
                state = .mutating
                buffer.append(contentsOf: value)
                state = .consumedCR(buffer)
                return .noop
            } else {
                let line = ArraySlice(buffer)
                buffer = []
                state = .finished
                if line.isEmpty {
                    return .returnNil
                } else {
                    return .returnLine(line)
                }
            }
        case .finished, .mutating:
            preconditionFailure("Invalid state")
        }
    }
}
