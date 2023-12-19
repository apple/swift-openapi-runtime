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

public struct ServerSentEventsSerializationSequence<Upstream: AsyncSequence & Sendable>: Sendable where Upstream.Element == ServerSentEvent {
    var upstream: Upstream
    public init(upstream: Upstream) {
        self.upstream = upstream
    }
}

extension ServerSentEventsSerializationSequence: AsyncSequence {
    public typealias Element = ArraySlice<UInt8>
    
    public struct Iterator<UpstreamIterator: AsyncIteratorProtocol>: AsyncIteratorProtocol where UpstreamIterator.Element == ServerSentEvent {
        var upstream: UpstreamIterator
        var stateMachine: ServerSentEventsSerializerStateMachine = .init()
        public mutating func next() async throws -> ArraySlice<UInt8>? {
            while true {
                switch stateMachine.next() {
                case .returnNil:
                    return nil
                case .needsMore:
                    let value = try await upstream.next()
                    switch stateMachine.receivedValue(value) {
                    case .returnNil:
                        return nil
                    case .returnBytes(let bytes):
                        return bytes
                    }
                }
            }
        }
    }
    
    public func makeAsyncIterator() -> Iterator<Upstream.AsyncIterator> {
        Iterator(upstream: upstream.makeAsyncIterator())
    }
}

extension AsyncSequence where Element == ServerSentEvent {

    public func asEncodedServerSentEvents() -> ServerSentEventsSerializationSequence<Self> {
        .init(upstream: self)
    }
}

extension AsyncSequence {
    public func asEncodedServerSentEventsWithJSONData<JSONDataType: Encodable>(
        encoder: JSONEncoder = {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            return encoder
        }()
    ) -> ServerSentEventsSerializationSequence<AsyncThrowingMapSequence<Self, ServerSentEvent>> where Element == ServerSentEventWithJSONData<JSONDataType>
    {
        map { event in
            ServerSentEvent(
                id: event.id,
                event: event.event,
                data: try event.data.flatMap { try String(decoding: encoder.encode($0), as: UTF8.self) },
                retry: event.retry
            )
        }
        .asEncodedServerSentEvents()
    }
}

struct ServerSentEventsSerializerStateMachine {
    
    enum State {
        case running
        case finished
    }
    private(set) var state: State = .running
    
    enum NextAction {
        case returnNil
        case needsMore
    }
    
    mutating func next() -> NextAction {
        switch state {
        case .running:
            return .needsMore
        case .finished:
            return .returnNil
        }
    }
    
    enum ReceivedValueAction {
        case returnNil
        case returnBytes(ArraySlice<UInt8>)
    }
    
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
                if let id = value.id {
                    encodeField(name: "id", value: id)
                }
                if let event = value.event {
                    encodeField(name: "event", value: event)
                }
                if let retry = value.retry {
                    encodeField(name: "retry", value: String(retry))
                }
                if let data = value.data {
                    // Normalize the data section by replacing CRLF and CR with just LF.
                    // Then split the section into individual field/value pairs.
                    let lines = data
                        .replacingOccurrences(of: "\r\n", with: "\n")
                        .replacingOccurrences(of: "\r", with: "\n")
                        .split(separator: "\n", omittingEmptySubsequences: false)
                    for line in lines {
                        encodeField(name: "data", value: line)
                    }
                }
                // End the event.
                buffer.append(ASCII.lf)
                return .returnBytes(ArraySlice(buffer))
            } else {
                state = .finished
                return .returnNil
            }
        case .finished:
            preconditionFailure("Invalid state")
        }
    }
}
