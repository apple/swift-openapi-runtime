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

public struct JSONSequenceSerializationSequence<Upstream: AsyncSequence & Sendable>: Sendable where Upstream.Element == ArraySlice<UInt8> {
    var upstream: Upstream
    public init(upstream: Upstream) {
        self.upstream = upstream
    }
}

extension JSONSequenceSerializationSequence: AsyncSequence {
    public typealias Element = ArraySlice<UInt8>
    
    public struct Iterator<UpstreamIterator: AsyncIteratorProtocol>: AsyncIteratorProtocol where UpstreamIterator.Element == Element {
        var upstream: UpstreamIterator
        var stateMachine: JSONSequenceSerializerStateMachine = .init()
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

extension AsyncSequence where Element == ArraySlice<UInt8> {

    func asSerializedJSONSequence() -> JSONSequenceSerializationSequence<Self> {
        .init(upstream: self)
    }
}

extension AsyncSequence where Element: Encodable {
    public func asEncodedJSONSequence(
        encoder: JSONEncoder = {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            return encoder
        }()
    ) -> JSONSequenceSerializationSequence<AsyncThrowingMapSequence<Self, ArraySlice<UInt8>>> {
        map { event in
            try ArraySlice(encoder.encode(event))
        }
        .asSerializedJSONSequence()
    }
}

struct JSONSequenceSerializerStateMachine {
    
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
    
    mutating func receivedValue(_ value: ArraySlice<UInt8>?) -> ReceivedValueAction {
        switch state {
        case .running:
            if let value {
                var buffer: [UInt8] = []
                buffer.reserveCapacity(value.count + 2)
                buffer.append(ASCII.rs)
                buffer.append(contentsOf: value)
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
