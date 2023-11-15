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
import HTTPTypes

/// A parser of mutlipart frames from bytes.
struct MultipartParser {

    /// The underlying state machine.
    private var stateMachine: StateMachine

    /// Creates a new parser.
    /// - Parameter boundary: The boundary that separates parts.
    init(boundary: String) { self.stateMachine = .init(boundary: boundary) }

    /// Parses the next frame.
    /// - Parameter fetchChunk: A closure that is called when the parser
    ///   needs more bytes to parse the next frame.
    /// - Returns: A parsed frame, or nil at the end of the message.
    /// - Throws: When a parsing error is encountered.
    mutating func next(_ fetchChunk: () async throws -> ArraySlice<UInt8>?) async throws -> MultipartFrame? {
        while true {
            switch stateMachine.readNextPart() {
            case .none: continue
            case .emitError(let actionError): throw ParserError(error: actionError)
            case .returnNil: return nil
            case .emitHeaderFields(let httpFields): return .headerFields(httpFields)
            case .emitBodyChunk(let bodyChunk): return .bodyChunk(bodyChunk)
            case .needsMore:
                let chunk = try await fetchChunk()
                switch stateMachine.receivedChunk(chunk) {
                case .none: continue
                case .returnNil: return nil
                case .emitError(let actionError): throw ParserError(error: actionError)
                }
            }
        }
    }
}
extension MultipartParser {

    /// An error thrown by the parser.
    struct ParserError: Swift.Error, CustomStringConvertible, LocalizedError {

        /// The underlying error emitted by the state machine.
        let error: MultipartParser.StateMachine.ActionError

        var description: String {
            switch error {
            case .invalidInitialBoundary: return "Invalid initial boundary."
            case .invalidCRLFAtStartOfHeaderField: return "Invalid CRLF at the start of a header field."
            case .missingColonAfterHeaderName: return "Missing colon after header field name."
            case .invalidCharactersInHeaderFieldName: return "Invalid characters in a header field name."
            case .incompleteMultipartMessage: return "Incomplete multipart message."
            case .receivedChunkWhenFinished: return "Received a chunk after being finished."
            }
        }

        var errorDescription: String? { description }
    }
}

extension MultipartParser {

    /// A state machine representing the byte to multipart frame parser.
    struct StateMachine {

        /// The possible states of the state machine.
        enum State: Hashable {

            /// Has not yet fully parsed the initial boundary.
            case parsingInitialBoundary([UInt8])

            /// A substate when parsing a part.
            enum PartState: Hashable {

                /// Accumulating part headers.
                case parsingHeaderFields(HTTPFields)

                /// Forwarding body chunks.
                case parsingBody
            }

            /// Is parsing a part.
            case parsingPart([UInt8], PartState)

            /// Finished, the terminal state.
            case finished

            /// Helper state to avoid copy-on-write copies.
            case mutating
        }

        /// The current state of the state machine.
        private(set) var state: State

        /// The bytes of the boundary.
        private let boundary: ArraySlice<UInt8>

        /// The bytes of the boundary with the double dash prepended.
        private let dashDashBoundary: ArraySlice<UInt8>

        /// The bytes of the boundary prepended by CRLF + double dash.
        private let crlfDashDashBoundary: ArraySlice<UInt8>

        /// Creates a new state machine.
        /// - Parameter boundary: The boundary used to separate parts.
        init(boundary: String) {
            self.state = .parsingInitialBoundary([])
            self.boundary = ArraySlice(boundary.utf8)
            self.dashDashBoundary = ASCII.dashes + self.boundary
            self.crlfDashDashBoundary = ASCII.crlf + dashDashBoundary
        }

        /// An error returned by the state machine.
        enum ActionError: Hashable {

            /// The initial boundary is malformed.
            case invalidInitialBoundary

            /// The expected CRLF at the start of a header is missing.
            case invalidCRLFAtStartOfHeaderField

            /// A header field name contains an invalid character.
            case invalidCharactersInHeaderFieldName

            /// The header field name is not followed by a colon.
            case missingColonAfterHeaderName

            /// More bytes were received after completion.
            case receivedChunkWhenFinished

            /// Ran out of bytes without the message being complete.
            case incompleteMultipartMessage
        }

        /// An action returned by the `readNextPart` method.
        enum ReadNextPartAction: Hashable {

            /// No action, call `readNextPart` again.
            case none

            /// Throw the provided error.
            case emitError(ActionError)

            /// Return nil to the caller, no more frames.
            case returnNil

            /// Emit a frame with the provided header fields.
            case emitHeaderFields(HTTPFields)

            /// Emit a frame with the provided part body chunk.
            case emitBodyChunk(ArraySlice<UInt8>)

            /// Needs more bytes to parse the next frame.
            case needsMore
        }

        /// Read the next part from the accumulated bytes.
        /// - Returns: An action to perform.
        mutating func readNextPart() -> ReadNextPartAction {
            switch state {
            case .mutating: preconditionFailure("Invalid state: \(state)")
            case .finished: return .returnNil
            case .parsingInitialBoundary(var buffer):
                state = .mutating
                // These first bytes must be the boundary already, otherwise this is a malformed multipart body.
                switch buffer.firstIndexAfterPrefix(dashDashBoundary) {
                case .index(let index):
                    buffer.removeSubrange(buffer.startIndex..<index)
                    state = .parsingPart(buffer, .parsingHeaderFields(.init()))
                    return .none
                case .reachedEndOfSelf:
                    state = .parsingInitialBoundary(buffer)
                    return .needsMore
                case .unexpectedPrefix:
                    state = .finished
                    return .emitError(.invalidInitialBoundary)
                }
            case .parsingPart(var buffer, let partState):
                state = .mutating
                switch partState {
                case .parsingHeaderFields(var headerFields):
                    // Either we find `--` in which case there are no more parts and we're finished, or something else
                    // and we start parsing headers.
                    switch buffer.firstIndexAfterPrefix(ASCII.dashes) {
                    case .index(let index):
                        state = .finished
                        buffer.removeSubrange(..<index)
                        return .returnNil
                    case .reachedEndOfSelf:
                        state = .parsingPart(buffer, .parsingHeaderFields(headerFields))
                        return .needsMore
                    case .unexpectedPrefix: break
                    }
                    // Consume CRLF
                    let indexAfterFirstCRLF: Array<UInt8>.Index
                    switch buffer.firstIndexAfterPrefix(ASCII.crlf) {
                    case .index(let index): indexAfterFirstCRLF = index
                    case .reachedEndOfSelf:
                        state = .parsingPart(buffer, .parsingHeaderFields(headerFields))
                        return .needsMore
                    case .unexpectedPrefix:
                        state = .finished
                        return .emitError(.invalidCRLFAtStartOfHeaderField)
                    }
                    // If CRLF is here, this is the end of header fields section.
                    switch buffer[indexAfterFirstCRLF...].firstIndexAfterPrefix(ASCII.crlf) {
                    case .index(let index):
                        buffer.removeSubrange(buffer.startIndex..<index)
                        state = .parsingPart(buffer, .parsingBody)
                        return .emitHeaderFields(headerFields)
                    case .reachedEndOfSelf:
                        state = .parsingPart(buffer, .parsingHeaderFields(headerFields))
                        return .needsMore
                    case .unexpectedPrefix: break
                    }
                    let startHeaderNameIndex = indexAfterFirstCRLF
                    guard
                        let endHeaderNameIndex = buffer[startHeaderNameIndex...]
                            .firstIndex(where: { !ASCII.isValidHeaderFieldNameByte($0) })
                    else {
                        // No index matched yet, we need more data.
                        state = .parsingPart(buffer, .parsingHeaderFields(headerFields))
                        return .needsMore
                    }
                    let startHeaderValueWithWhitespaceIndex: Array<UInt8>.Index
                    // Check that what follows is a colon, otherwise this is a malformed header field line.
                    // Source: RFC 7230, section 3.2.4.
                    switch buffer[endHeaderNameIndex...].firstIndexAfterPrefix([ASCII.colon]) {
                    case .index(let index): startHeaderValueWithWhitespaceIndex = index
                    case .reachedEndOfSelf:
                        state = .parsingPart(buffer, .parsingHeaderFields(headerFields))
                        return .needsMore
                    case .unexpectedPrefix:
                        state = .finished
                        return .emitError(.missingColonAfterHeaderName)
                    }
                    guard
                        let startHeaderValueIndex = buffer[startHeaderValueWithWhitespaceIndex...]
                            .firstIndex(where: { !ASCII.optionalWhitespace.contains($0) })
                    else {
                        state = .parsingPart(buffer, .parsingHeaderFields(headerFields))
                        return .needsMore
                    }

                    // Find the CRLF first, then remove any trailing whitespace.
                    guard
                        let endHeaderValueWithWhitespaceRange = buffer[startHeaderValueIndex...]
                            .firstRange(of: ASCII.crlf)
                    else {
                        state = .parsingPart(buffer, .parsingHeaderFields(headerFields))
                        return .needsMore
                    }
                    let headerFieldValueBytes = buffer[
                        startHeaderValueIndex..<endHeaderValueWithWhitespaceRange.lowerBound
                    ]
                    .reversed().drop(while: { ASCII.optionalWhitespace.contains($0) }).reversed()
                    guard
                        let headerFieldName = HTTPField.Name(
                            String(decoding: buffer[startHeaderNameIndex..<endHeaderNameIndex], as: UTF8.self)
                        )
                    else {
                        state = .finished
                        return .emitError(.invalidCharactersInHeaderFieldName)
                    }
                    let headerFieldValue = String(decoding: headerFieldValueBytes, as: UTF8.self)
                    let headerField = HTTPField(name: headerFieldName, value: headerFieldValue)
                    headerFields.append(headerField)
                    buffer.removeSubrange(buffer.startIndex..<endHeaderValueWithWhitespaceRange.lowerBound)

                    state = .parsingPart(buffer, .parsingHeaderFields(headerFields))
                    return .none
                case .parsingBody:
                    switch buffer.longestMatch(crlfDashDashBoundary) {
                    case .noMatch:
                        let bodyChunk = buffer[...]
                        buffer.removeAll(keepingCapacity: true)
                        state = .parsingPart(buffer, .parsingBody)
                        if bodyChunk.isEmpty { return .needsMore } else { return .emitBodyChunk(bodyChunk) }
                    case .prefixMatch(fromIndex: let fromIndex):
                        let bodyChunk = buffer[..<fromIndex]
                        buffer.removeSubrange(..<fromIndex)
                        state = .parsingPart(buffer, .parsingBody)
                        if bodyChunk.isEmpty { return .needsMore } else { return .emitBodyChunk(bodyChunk) }
                    case .fullMatch(let range):
                        let bodyChunkBeforeBoundary = buffer[..<range.lowerBound]
                        buffer.removeSubrange(..<range.upperBound)
                        state = .parsingPart(buffer, .parsingHeaderFields(.init()))
                        if bodyChunkBeforeBoundary.isEmpty {
                            return .none
                        } else {
                            return .emitBodyChunk(bodyChunkBeforeBoundary)
                        }
                    }
                }
            }
        }

        /// An action returned by the `receivedChunk` method.
        enum ReceivedChunkAction: Hashable {

            /// No action, call `readNextPart` again.
            case none

            /// Return nil to the caller, no more frames.
            case returnNil

            /// Throw the provided error.
            case emitError(ActionError)
        }

        /// Ingest the provided byte chunk.
        /// - Parameter chunk: A new byte chunk. If `nil`, then the source of
        ///   bytes is finished and no more chunks will come.
        /// - Returns: An action to perform.
        mutating func receivedChunk(_ chunk: ArraySlice<UInt8>?) -> ReceivedChunkAction {
            switch state {
            case .parsingInitialBoundary(var buffer):
                guard let chunk else { return .emitError(.incompleteMultipartMessage) }
                state = .mutating
                buffer.append(contentsOf: chunk)
                state = .parsingInitialBoundary(buffer)
                return .none
            case .parsingPart(var buffer, let part):
                guard let chunk else { return .emitError(.incompleteMultipartMessage) }
                state = .mutating
                buffer.append(contentsOf: chunk)
                state = .parsingPart(buffer, part)
                return .none
            case .finished:
                guard chunk == nil else { return .emitError(.receivedChunkWhenFinished) }
                return .returnNil
            case .mutating: preconditionFailure("Invalid state: \(state)")
            }
        }
    }
}
