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

private enum ASCII {
    static let dashes: [UInt8] = [0x2d, 0x2d]
    static let crlf: [UInt8] = [0x0d, 0x0a]
    static let colon: UInt8 = 0x3a
    static let optionalWhitespace: Set<UInt8> = [0x20, 0x09]
    static func isValidHeaderFieldNameByte(_ byte: UInt8) -> Bool {
        // Copied from swift-http-types, because we create HTTPField.Name from these anyway later.
        switch byte {
        case 0x21, 0x23, 0x24, 0x25, 0x26, 0x27, 0x2A, 0x2B, 0x2D, 0x2E, 0x5E, 0x5F, 0x60, 0x7C, 0x7E: return true
        case 0x30...0x39, 0x41...0x5A, 0x61...0x7A:  // DIGHT, ALPHA
            return true
        default: return false
        }
    }
}

extension MultipartBody {
    convenience init(parsing body: HTTPBody, boundary: String) {
        // TODO: Make HTTPBody.Length and MultipartBody.Length the same? Or not?
        let length: MultipartBody.Length
        switch body.length {
        case .known(let count): length = .known(count)
        case .unknown: length = .unknown
        }
        let iterationBehavior: MultipartBody.IterationBehavior
        switch body.iterationBehavior {
        case .single: iterationBehavior = .single
        case .multiple: iterationBehavior = .multiple
        }
        self.init(
            MultipartParsingSequence(upstream: body, boundary: boundary),
            length: length,
            iterationBehavior: iterationBehavior
        )
    }
    private final class MultipartParsingSequence: AsyncSequence {
        typealias Element = MultipartBodyChunk
        typealias AsyncIterator = Iterator
        let upstream: HTTPBody
        let boundary: String
        init(upstream: HTTPBody, boundary: String) {
            self.upstream = upstream
            self.boundary = boundary
        }
        func makeAsyncIterator() -> Iterator { Iterator(upstream: upstream.makeAsyncIterator(), boundary: boundary) }
        struct Iterator: AsyncIteratorProtocol {
            typealias Element = MultipartBodyChunk
            private var upstream: HTTPBody.Iterator
            private var buffer: [UInt8]
            private var parser: MultipartParser
            init(upstream: HTTPBody.Iterator, boundary: String) {
                self.upstream = upstream
                self.buffer = []
                self.parser = .init(boundary: boundary)
            }
            mutating func next() async throws -> Element? {
                struct MultipartParserError: Swift.Error, CustomStringConvertible, LocalizedError {
                    let error: MultipartParser.StateMachine.Action.ActionError
                    var description: String {
                        switch error {
                        case .invalidInitialBoundary: return "Invalid initial boundary."
                        case .invalidCRLFAtStartOfHeaderField: return "Invalid CRLF at the start of a header field."
                        case .missingColonAfterHeaderName: return "Missing colon after header field name."
                        case .invalidCharactersInHeaderFieldName: return "Invalid characters in a header field name."
                        case .incompleteMultipartMessage: return "Incomplete multipart message."
                        }
                    }
                    var errorDescription: String? { description }
                }
                print("MultipartParsingSequence - next")
                var lastChunkWasNil: Bool = false
                while true {
                    switch try parser.parseNextPartChunk(&buffer, lastChunkWasNil: lastChunkWasNil) {
                    case .chunk(let chunk):
                        print("MultipartParsingSequence - returning \(chunk)")
                        return chunk
                    case .returnNil:
                        print("MultipartParsingSequence - returning nil")
                        return nil
                    case .needsMore:
                        print("MultipartParsingSequence - fetching more")
                        precondition(!lastChunkWasNil, "Preventing an infinite loop. This is a parser bug.")
                        if let chunk = try await upstream.next() {
                            buffer.append(contentsOf: chunk)
                            print("MultipartParsingSequence - fetched a chunk of size \(chunk.count)")
                        } else {
                            lastChunkWasNil = true
                            print("MultipartParsingSequence - fetched a nil chunk")
                        }
                    case .emitError(let error): throw MultipartParserError(error: error)
                    }
                }
            }
        }
    }
}

struct MultipartParser {
    struct StateMachine {
        enum State {
            case parsingInitialBoundary
            enum PartState {
                case parsingHeaderFields(HTTPFields)
                case parsingBody
            }
            case parsingPart(PartState)
            case finished
            case mutating
        }
        enum Action {
            case none
            enum ActionError {
                case invalidInitialBoundary
                case invalidCRLFAtStartOfHeaderField
                case invalidCharactersInHeaderFieldName
                case missingColonAfterHeaderName
                case incompleteMultipartMessage
            }
            case emitError(ActionError)
            case returnNil
            case emitHeaderFields(HTTPFields)
            case emitBodyChunk(ArraySlice<UInt8>)
            case needsMore
        }
        private var state: State
        private let boundary: ArraySlice<UInt8>
        private let dashDashBoundary: ArraySlice<UInt8>
        private let crlfDashDashBoundary: ArraySlice<UInt8>

        init(boundary: String) {
            self.state = .parsingInitialBoundary
            self.boundary = ArraySlice(boundary.utf8)
            self.dashDashBoundary = ASCII.dashes + self.boundary
            self.crlfDashDashBoundary = ASCII.crlf + dashDashBoundary
        }
        mutating func readNextPart(_ buffer: inout [UInt8]) -> Action {
            switch state {
            case .mutating: preconditionFailure("Invalid state: \(state)")
            case .finished: return .returnNil
            case .parsingInitialBoundary:
                // These first bytes must be the boundary already, otherwise this is a malformed multipart body.
                switch buffer.firstIndexAfterElements(dashDashBoundary) {
                case .index(let index):
                    buffer.removeSubrange(buffer.startIndex..<index)
                    state = .parsingPart(.parsingHeaderFields(.init()))
                    return .none
                case .reachedEndOfSelf: return .needsMore
                case .mismatchedCharacter:
                    state = .finished
                    return .emitError(.invalidInitialBoundary)
                }
            case .parsingPart(let partState):
                state = .mutating
                switch partState {
                case .parsingHeaderFields(var headerFields):
                    // Either we find `--` in which case there are no more parts and we're finished, or something else
                    // and we start parsing headers.
                    switch buffer.firstIndexAfterElements(ASCII.dashes) {
                    case .index(let index):
                        state = .finished
                        buffer.removeSubrange(..<index)
                        return .returnNil
                    case .reachedEndOfSelf:
                        state = .parsingPart(.parsingHeaderFields(headerFields))
                        return .needsMore
                    case .mismatchedCharacter: break
                    }
                    // Consume CRLF
                    let indexAfterFirstCRLF: [UInt8].Index
                    switch buffer.firstIndexAfterElements(ASCII.crlf) {
                    case .index(let index): indexAfterFirstCRLF = index
                    case .reachedEndOfSelf:
                        state = .parsingPart(.parsingHeaderFields(headerFields))
                        return .needsMore
                    case .mismatchedCharacter:
                        state = .finished
                        return .emitError(.invalidCRLFAtStartOfHeaderField)
                    }
                    // If CRLF is here, this is the end of header fields section.
                    switch buffer[indexAfterFirstCRLF...].firstIndexAfterElements(ASCII.crlf) {
                    case .index(let index):
                        buffer.removeSubrange(buffer.startIndex..<index)
                        state = .parsingPart(.parsingBody)
                        return .emitHeaderFields(headerFields)
                    case .reachedEndOfSelf:
                        state = .parsingPart(.parsingHeaderFields(headerFields))
                        return .needsMore
                    case .mismatchedCharacter: break
                    }
                    let startHeaderNameIndex = indexAfterFirstCRLF
                    guard
                        let endHeaderNameIndex = buffer[startHeaderNameIndex...]
                            .firstIndex(where: { !ASCII.isValidHeaderFieldNameByte($0) })
                    else {
                        // No index matched yet, we need more data.
                        state = .parsingPart(.parsingHeaderFields(headerFields))
                        return .needsMore
                    }
                    let startHeaderValueWithWhitespaceIndex: [UInt8].Index
                    // Check that what follows is a colon, otherwise this is a malformed header field line.
                    // Source: RFC 7230, section 3.2.4.
                    switch buffer[endHeaderNameIndex...].firstIndexAfterElements([ASCII.colon]) {
                    case .index(let index): startHeaderValueWithWhitespaceIndex = index
                    case .reachedEndOfSelf:
                        state = .parsingPart(.parsingHeaderFields(headerFields))
                        return .needsMore
                    case .mismatchedCharacter:
                        state = .finished
                        return .emitError(.missingColonAfterHeaderName)
                    }
                    guard
                        let startHeaderValueIndex = buffer[startHeaderValueWithWhitespaceIndex...]
                            .firstIndex(where: { !ASCII.optionalWhitespace.contains($0) })
                    else {
                        state = .parsingPart(.parsingHeaderFields(headerFields))
                        return .needsMore
                    }

                    // Find the CRLF first, then remove any trailing whitespace.
                    guard
                        let endHeaderValueWithWhitespaceRange = buffer[startHeaderValueIndex...]
                            .firstRange(of: ASCII.crlf)
                    else {
                        state = .parsingPart(.parsingHeaderFields(headerFields))
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

                    state = .parsingPart(.parsingHeaderFields(headerFields))
                    return .none
                case .parsingBody:
                    switch buffer.longestMatch(crlfDashDashBoundary) {
                    case .noMatch:
                        let bodyChunk = buffer[...]
                        buffer.removeAll(keepingCapacity: true)
                        state = .parsingPart(.parsingBody)
                        return .emitBodyChunk(bodyChunk)
                    case .prefixMatch(fromIndex: let fromIndex):
                        let bodyChunk = buffer[..<fromIndex]
                        buffer.removeSubrange(..<fromIndex)
                        state = .parsingPart(.parsingBody)
                        if bodyChunk.isEmpty { return .needsMore } else { return .emitBodyChunk(bodyChunk) }
                    case .fullMatch(let range):
                        let bodyChunkBeforeBoundary = buffer[..<range.lowerBound]
                        buffer.removeSubrange(..<range.upperBound)
                        state = .parsingPart(.parsingHeaderFields(.init()))
                        return .emitBodyChunk(bodyChunkBeforeBoundary)
                    }
                }
            }
        }
    }
    private var stateMachine: StateMachine
    init(boundary: String) { self.stateMachine = .init(boundary: boundary) }
    enum ParserResult {
        case chunk(MultipartBodyChunk)
        case returnNil
        case emitError(MultipartParser.StateMachine.Action.ActionError)
        case needsMore
    }
    mutating func parseNextPartChunk(_ buffer: inout [UInt8], lastChunkWasNil: Bool) throws -> ParserResult {
        while true {
            switch stateMachine.readNextPart(&buffer) {
            case .returnNil: return .returnNil
            case .emitHeaderFields(let headerFields): return .chunk(.headerFields(headerFields))
            case .emitBodyChunk(let bodyChunk): return .chunk(.bodyChunk(bodyChunk))
            case .none: continue
            case .emitError(let error): return .emitError(error)
            case .needsMore:
                if lastChunkWasNil { return .emitError(.incompleteMultipartMessage) } else { return .needsMore }
            }
        }
    }
}

enum FirstIndexAfterElementsResult<C: RandomAccessCollection> {
    /// The index after the end of the first match.
    case index(C.Index)
    /// Matched all characters so far, but reached the end of self before matching all.
    /// When more data is fetched, it's possible this will fully match.
    case reachedEndOfSelf
    /// The character at the provided index does not match the expected character.
    case mismatchedCharacter(C.Index)
}

fileprivate extension RandomAccessCollection where Element: Equatable {
    /// Verifies that the elements match the provided sequence and returns the first index past the match.
    /// - Parameter expectedElements: The elements to match against.
    /// - Returns: First index past the match; nil if elements don't match or if ran out of elements on self.
    func firstIndexAfterElements(_ expectedElements: some Sequence<Element>) -> FirstIndexAfterElementsResult<Self> {
        var index = startIndex
        for expectedElement in expectedElements {
            guard index < endIndex else { return .reachedEndOfSelf }
            guard self[index] == expectedElement else { return .mismatchedCharacter(index) }
            formIndex(after: &index)
        }
        return .index(index)
    }
}

enum LongestMatchResult<C: RandomAccessCollection> {
    /// No match found at any position in self.
    case noMatch
    /// Found a prefix match but reached the end of self.
    /// Provides the index of the first matching character.
    /// When more data is fetched, this might become a full match.
    case prefixMatch(fromIndex: C.Index)
    /// Found a full match within self at the provided range.
    case fullMatch(Range<C.Index>)
}

fileprivate extension RandomAccessCollection where Element: Equatable {
    /// Returns the longest match found within the sequence.
    func longestMatch(_ expectedElements: some Sequence<Element>) -> LongestMatchResult<Self> {
        var index = startIndex
        while index < endIndex {
            switch self[index...].firstIndexAfterElements(expectedElements) {
            case .index(let end): return .fullMatch(index..<end)
            case .reachedEndOfSelf: return .prefixMatch(fromIndex: index)
            case .mismatchedCharacter: formIndex(after: &index)
            }
        }
        return .noMatch
    }
}
