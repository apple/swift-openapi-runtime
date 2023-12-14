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

struct ServerSentEventsDeserializationSequence<Upstream: AsyncSequence & Sendable>: Sendable where Upstream.Element == ArraySlice<UInt8> {
    var upstream: Upstream
    init(upstream: Upstream) {
        self.upstream = upstream
    }
}

extension ServerSentEventsDeserializationSequence: AsyncSequence {
    typealias Element = ArraySlice<UInt8>
    
    struct Iterator<UpstreamIterator: AsyncIteratorProtocol>: AsyncIteratorProtocol where UpstreamIterator.Element == Element {
        var upstream: UpstreamIterator
        var stateMachine: ServerSentEventsDeserializerStateMachine = .init()
        mutating func next() async throws -> ArraySlice<UInt8>? {
            while true {
                switch stateMachine.next() {
                case .returnNil:
                    return nil
                case .returnLine(let line):
                    return line
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
    
    func makeAsyncIterator() -> Iterator<Upstream.AsyncIterator> {
        Iterator(upstream: upstream.makeAsyncIterator())
    }
}

extension AsyncSequence where Element == ArraySlice<UInt8> {
    func asParsedServerSentEvents() -> ServerSentEventsDeserializationSequence<Self> {
        .init(upstream: self)
    }
    
    func asDecodedServerSentEvents<Event: Decodable>(
        of eventType: Event.Type = Event.self,
        using decoder: JSONDecoder = .init()
    ) -> AsyncThrowingMapSequence<ServerSentEventsDeserializationSequence<Self>, Event> {
        asParsedServerSentEvents().map { line in
            try decoder.decode(Event.self, from: Data(line))
        }
    }
}

struct ServerSentEventsDeserializerStateMachine {
    
    enum State {
        case waitingForDelimiter([UInt8])
        case finished
        case mutating
    }
    private(set) var state: State = .waitingForDelimiter([])
    
    enum NextAction {
        case returnNil
        case returnLine(ArraySlice<UInt8>)
        case needsMore
    }
    
    mutating func next() -> NextAction {
        switch state {
        case .waitingForDelimiter(var buffer):
            state = .mutating
            guard let indexOfNewline = buffer.firstIndex(of: ASCII.lf) else {
                state = .waitingForDelimiter(buffer)
                return .needsMore
            }
            let line = buffer[..<indexOfNewline]
            buffer.removeSubrange(...indexOfNewline)
            state = .waitingForDelimiter(buffer)
            return .returnLine(line)
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
        case .waitingForDelimiter(var buffer):
            if let value {
                state = .mutating
                buffer.append(contentsOf: value)
                state = .waitingForDelimiter(buffer)
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
