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

public struct JSONSequenceDeserializationSequence<Upstream: AsyncSequence & Sendable>: Sendable where Upstream.Element == ArraySlice<UInt8> {
    var upstream: Upstream
    public init(upstream: Upstream) {
        self.upstream = upstream
    }
}

extension JSONSequenceDeserializationSequence: AsyncSequence {
    public typealias Element = ArraySlice<UInt8>
    
    struct DeserializerError: Swift.Error, CustomStringConvertible, LocalizedError {
        
        let error: JSONSequenceDeserializerStateMachine.ActionError
        
        var description: String {
            switch error {
            case .missingInitialRS:
                return "Missing an initial <RS> character, the bytes might not be a JSON Sequence."
            }
        }
        
        var errorDescription: String? { description }
    }

    public struct Iterator<UpstreamIterator: AsyncIteratorProtocol>: AsyncIteratorProtocol where UpstreamIterator.Element == Element {
        var upstream: UpstreamIterator
        var stateMachine: JSONSequenceDeserializerStateMachine = .init()
        public mutating func next() async throws -> ArraySlice<UInt8>? {
            while true {
                switch stateMachine.next() {
                case .returnNil:
                    return nil
                case .returnEvent(let line):
                    return line
                case .needsMore:
                    let value = try await upstream.next()
                    switch stateMachine.receivedValue(value) {
                    case .returnNil:
                        return nil
                    case .returnEvent(let line):
                        return line
                    case .noop:
                        continue
                    }
                case .emitError(let error):
                    throw DeserializerError(error: error)
                case .noop:
                    continue
                }
            }
        }
    }
    
    public func makeAsyncIterator() -> Iterator<Upstream.AsyncIterator> {
        Iterator(upstream: upstream.makeAsyncIterator())
    }
}

extension AsyncSequence where Element == ArraySlice<UInt8> {
    func asParsedJSONSequence() -> JSONSequenceDeserializationSequence<Self> {
        .init(upstream: self)
    }
    
    public func asDecodedJSONSequence<Event: Decodable>(
        of eventType: Event.Type = Event.self,
        using decoder: JSONDecoder = .init()
    ) -> AsyncThrowingMapSequence<JSONSequenceDeserializationSequence<Self>, Event> {
        asParsedJSONSequence().map { line in
            try decoder.decode(Event.self, from: Data(line))
        }
    }
}

struct JSONSequenceDeserializerStateMachine {
    
    enum State {
        case initial([UInt8])
        case parsingEvent([UInt8])
        case finished
        case mutating
    }
    private(set) var state: State = .initial([])
    
    enum ActionError {
        case missingInitialRS
    }
    
    enum NextAction {
        case returnNil
        case returnEvent(ArraySlice<UInt8>)
        case emitError(ActionError)
        case needsMore
        case noop
    }
    
    mutating func next() -> NextAction {
        switch state {
        case .initial(var buffer):
            guard !buffer.isEmpty else {
                return .needsMore
            }
            guard buffer.first! == ASCII.rs else {
                return .emitError(.missingInitialRS)
            }
            state = .mutating
            buffer.removeFirst()
            state = .parsingEvent(buffer)
            return .noop
        case .parsingEvent(var buffer):
            state = .mutating
            guard let indexOfRecordSeparator = buffer.firstIndex(of: ASCII.rs) else {
                state = .parsingEvent(buffer)
                return .needsMore
            }
            let event = buffer[..<indexOfRecordSeparator]
            buffer.removeSubrange(...indexOfRecordSeparator)
            state = .parsingEvent(buffer)
            if event.isEmpty {
                return .noop
            } else {
                return .returnEvent(event)
            }
        case .finished:
            return .returnNil
        case .mutating:
            preconditionFailure("Invalid state")
        }
    }
    
    enum ReceivedValueAction {
        case returnNil
        case returnEvent(ArraySlice<UInt8>)
        case noop
    }
    
    mutating func receivedValue(_ value: ArraySlice<UInt8>?) -> ReceivedValueAction {
        switch state {
        case .initial(var buffer):
            if let value {
                state = .mutating
                buffer.append(contentsOf: value)
                state = .initial(buffer)
                return .noop
            } else {
                let line = ArraySlice(buffer)
                buffer = []
                state = .finished
                if line.isEmpty {
                    return .returnNil
                } else {
                    return .returnEvent(line)
                }
            }
        case .parsingEvent(var buffer):
            if let value {
                state = .mutating
                buffer.append(contentsOf: value)
                state = .parsingEvent(buffer)
                return .noop
            } else {
                let line = ArraySlice(buffer)
                buffer = []
                state = .finished
                if line.isEmpty {
                    return .returnNil
                } else {
                    return .returnEvent(line)
                }
            }
        case .finished, .mutating:
            preconditionFailure("Invalid state")
        }
    }
}
