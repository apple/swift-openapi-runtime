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

struct LinesSerializationSequence<Upstream: AsyncSequence & Sendable>: Sendable where Upstream.Element == ArraySlice<UInt8> {
    var upstream: Upstream
    init(upstream: Upstream) {
        self.upstream = upstream
    }
}

extension LinesSerializationSequence: AsyncSequence {
    typealias Element = ArraySlice<UInt8>
    
    struct Iterator<UpstreamIterator: AsyncIteratorProtocol>: AsyncIteratorProtocol where UpstreamIterator.Element == Element {
        var upstream: UpstreamIterator
        var stateMachine: LinesSerializerStateMachine = .init()
        mutating func next() async throws -> ArraySlice<UInt8>? {
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
    
    func makeAsyncIterator() -> Iterator<Upstream.AsyncIterator> {
        Iterator(upstream: upstream.makeAsyncIterator())
    }
}

extension AsyncSequence where Element == ArraySlice<UInt8> {

    func asSerializedLines() -> LinesSerializationSequence<Self> {
        .init(upstream: self)
    }
}

struct LinesSerializerStateMachine {
    
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
                var buffer = value
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
