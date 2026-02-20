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

/// A sequence that parses arbitrary byte chunks into lines using the JSON Sequence format.
public struct JSONSequenceDeserializationSequence<Upstream: AsyncSequence & Sendable>: Sendable
where Upstream.Element == ArraySlice<UInt8> {

    /// The upstream sequence.
    private let upstream: Upstream

    /// Creates a new sequence.
    /// - Parameter upstream: The upstream sequence of arbitrary byte chunks.
    public init(upstream: Upstream) { self.upstream = upstream }
}

extension JSONSequenceDeserializationSequence: AsyncSequence {

    /// The type of element produced by this asynchronous sequence.
    public typealias Element = ArraySlice<UInt8>

    /// An error thrown by the deserializer.
    struct DeserializerError<UpstreamIterator: AsyncIteratorProtocol>: Swift.Error, CustomStringConvertible,
        LocalizedError
    where UpstreamIterator.Element == Element {

        /// The underlying error emitted by the state machine.
        let error: Iterator<UpstreamIterator>.StateMachine.ActionError

        var description: String {
            switch error {
            case .missingInitialRS: return "Missing an initial <RS> character, the bytes might not be a JSON Sequence."
            }
        }

        var errorDescription: String? { description }
    }

    /// The iterator of `JSONSequenceDeserializationSequence`.
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
                case .emitError(let error): throw DeserializerError(error: error)
                case .noop: continue
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

@available(*, unavailable) extension JSONSequenceDeserializationSequence.Iterator: Sendable {}

extension AsyncSequence where Element == ArraySlice<UInt8> {

    /// Returns another sequence that decodes each JSON Sequence event as the provided type using the provided decoder.
    /// - Parameters:
    ///   - eventType: The type to decode the JSON event into.
    ///   - decoder: The JSON decoder to use.
    /// - Returns: A sequence that provides the decoded JSON events.
    @preconcurrency public func asDecodedJSONSequence<Event: Decodable & _OpenAPIRuntimeSendableMetatype>(
        of eventType: Event.Type = Event.self,
        decoder: JSONDecoder = .init()
    ) -> AsyncThrowingMapSequence<JSONSequenceDeserializationSequence<Self>, Event> {
        JSONSequenceDeserializationSequence(upstream: self)
            .map { line in try decoder.decode(Event.self, from: Data(line)) }
    }
}

extension JSONSequenceDeserializationSequence.Iterator {

    /// A state machine representing the JSON Lines deserializer.
    struct StateMachine {

        /// The possible states of the state machine.
        enum State: Hashable {

            /// Has not yet fully parsed the initial boundary.
            case initial(buffer: [UInt8])

            /// Is parsing a line, waiting for the end newline.
            case parsingLine(buffer: [UInt8])

            /// Finished, the terminal state.
            case finished

            /// Helper state to avoid copy-on-write copies.
            case mutating
        }

        /// The current state of the state machine.
        private(set) var state: State

        /// Creates a new state machine.
        init() { self.state = .initial(buffer: []) }

        /// An error returned by the state machine.
        enum ActionError {

            /// The initial boundary `<RS>` was not found.
            case missingInitialRS
        }

        /// An action returned by the `next` method.
        enum NextAction {

            /// Return nil to the caller, no more bytes.
            case returnNil

            /// Emit a full line.
            case emitLine(ArraySlice<UInt8>)

            /// Emit an error.
            case emitError(ActionError)

            /// The line is not complete yet, needs more bytes.
            case needsMore

            /// Rerun the parsing loop.
            case noop
        }

        /// Read the next line parsed from upstream bytes.
        /// - Returns: An action to perform.
        mutating func next() -> NextAction {
            switch state {
            case .initial(var buffer):
                guard !buffer.isEmpty else { return .needsMore }
                guard buffer.first! == ASCII.rs else { return .emitError(.missingInitialRS) }
                state = .mutating
                buffer.removeFirst()
                state = .parsingLine(buffer: buffer)
                return .noop
            case .parsingLine(var buffer):
                state = .mutating
                guard let indexOfRecordSeparator = buffer.firstIndex(of: ASCII.rs) else {
                    state = .parsingLine(buffer: buffer)
                    return .needsMore
                }
                let line = buffer[..<indexOfRecordSeparator]
                buffer.removeSubrange(...indexOfRecordSeparator)
                state = .parsingLine(buffer: buffer)
                if line.isEmpty { return .noop } else { return .emitLine(line) }
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
            case .initial(var buffer):
                if let value {
                    state = .mutating
                    buffer.append(contentsOf: value)
                    state = .initial(buffer: buffer)
                    return .noop
                } else {
                    let line = ArraySlice(buffer)
                    buffer = []
                    state = .finished
                    if line.isEmpty { return .returnNil } else { return .emitLine(line) }
                }
            case .parsingLine(var buffer):
                if let value {
                    state = .mutating
                    buffer.append(contentsOf: value)
                    state = .parsingLine(buffer: buffer)
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
