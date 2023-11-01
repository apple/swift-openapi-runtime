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
    static let crlf: [UInt8] = [0xd, 0xa]
    static let colonSpace: [UInt8] = [0x3a, 0x20]
    
    static func isValidHeaderFieldNameByte(_ byte: UInt8) -> Bool {
        // Copied from swift-http-types, because we create HTTPField.Name from these anyway later.
        switch byte {
        case 0x21, 0x23, 0x24, 0x25, 0x26, 0x27, 0x2A, 0x2B, 0x2D, 0x2E, 0x5E, 0x5F, 0x60, 0x7C, 0x7E:
            return true
        case 0x30 ... 0x39, 0x41 ... 0x5A, 0x61 ... 0x7A: // DIGHT, ALPHA
            return true
        default:
            return false
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
        typealias Element = MultipartPart
        typealias AsyncIterator = Iterator
        let upstream: HTTPBody
        let boundary: String
        init(
            upstream: HTTPBody,
            boundary: String
        ) {
            self.upstream = upstream
            self.boundary = boundary
        }
        func makeAsyncIterator() -> Iterator {
            Iterator(
                upstream: upstream.makeAsyncIterator(),
                boundary: boundary
            )
        }
        struct Iterator: AsyncIteratorProtocol {
            typealias Element = MultipartPart
            private var upstream: HTTPBody.Iterator
            private var buffer: [UInt8]
            private let boundary: String
            init(upstream: HTTPBody.Iterator, boundary: String) {
                self.upstream = upstream
                self.buffer = []
                self.boundary = boundary
            }
            mutating func next() async throws -> MultipartPart? {
                // TODO: Make this actually stream parts, where each part streams its body contents.
                
                // For now, just buffer everything.
                while let chunk = try await upstream.next() {
                    buffer.append(contentsOf: chunk)
                }
                
                // Parse the contents.
                return try MultipartParser.parseNextPart(&buffer, boundary: boundary)
            }
        }
    }
}

struct MultipartParser {
    
    private struct StateMachine {
        
        enum State {
            case parsingInitialBoundary
            case readyForPart
            
            enum PartState {
                case parsingHeaderFields(HTTPFields)
                case parsingBody(AsyncStream<HTTPBody.ByteChunk>.Continuation)
            }
            
            case parsingPart(PartState)
            case finished
            case mutating
        }
        
        enum Action {
            case none
            
            enum ActionError {
                case invalidInitialBoundary
                case invalidCRLFAtStartOfHeader
            }
            
            case emitError(ActionError)
            case returnNil
            case emitPart(MultipartPart)
            case needsMore
        }
        
        private var state: State
        private let boundary: ArraySlice<UInt8>
        private var prefixedBoundary: ArraySlice<UInt8> {
            ASCII.dashes + boundary
        }
        
        init(boundary: String) {
            self.state = .parsingInitialBoundary
            self.boundary = ArraySlice(boundary.utf8)
        }
        
        mutating func readNextPart(_ buffer: inout [UInt8]) -> Action {
            switch state {
            case .mutating:
                preconditionFailure("Invalid state: \(state)")
            case .finished:
                return .returnNil
            case .parsingInitialBoundary:
                // These first bytes must be the boundary already, otherwise this is a malformed multipart body.
                switch buffer.firstIndexAfterElements(prefixedBoundary) {
                case .index(let index):
                    buffer.removeSubrange(buffer.startIndex..<index)
                    state = .readyForPart
                    return .none
                case .reachedEndOfSelf:
                    return .needsMore
                case .mismatchedCharacter:
                    state = .finished
                    return .emitError(.invalidInitialBoundary)
                }
            case .readyForPart:
                // If two dashes, then this is the end, no more parts.
                switch buffer.firstIndexAfterElements(ASCII.dashes) {
                case .index(let index):
                    buffer.removeSubrange(buffer.startIndex..<index)
                    state = .finished
                    return .returnNil
                case .reachedEndOfSelf:
                    return .needsMore
                case .mismatchedCharacter:
                    // Otherwise, a part is starting.
                    state = .parsingPart(.parsingHeaderFields(.init()))
                    return .none
                }
            case .parsingPart(var partState):
                state = .mutating
                
                switch partState {
                case .parsingHeaderFields(var headerFields):
                    // Consume CRLF
                    switch buffer.firstIndexAfterElements(ASCII.crlf) {
                    case .index(let index):
                        buffer.removeSubrange(buffer.startIndex..<index)
                    case .reachedEndOfSelf:
                        state = .parsingPart(.parsingHeaderFields(headerFields))
                        return .needsMore
                    case .mismatchedCharacter:
                        state = .finished
                        return .emitError(.invalidCRLFAtStartOfHeader)
                    }
                    
                    // If CRLF is here, this is the end of header fields section.
                    switch buffer.firstIndexAfterElements(ASCII.crlf) {
                    case .index(let index):
                        buffer.removeSubrange(buffer.startIndex..<index)
                        
                        let length: HTTPBody.Length
                        if
                            let contentLengthString = headerFields[.contentLength],
                            let contentLength = Int64(contentLengthString)
                        {
                            length = .known(/* TODO: remove this cast */ Int(contentLength))
                        } else {
                            length = .unknown
                        }
                        
                        let (stream, continuation) = AsyncStream.makeStream(of: HTTPBody.ByteChunk.self)
                        state = .parsingPart(.parsingBody(continuation))
                        
                        let body = HTTPBody(
                            stream,
                            length: length,
                            iterationBehavior: .single
                        )
                        return .emitPart(.init(
                            headerFields: headerFields,
                            body: body
                        ))
                    case .reachedEndOfSelf:
                        preconditionFailure("TODO: This needs more work, we already ate the CRLF but didn't change our state.")
                        //                            state = .parsingPart(.parsingHeaderFields(headerFields))
                        //                            return .needsMore
                    case .mismatchedCharacter:
                        break
                    }
                    
                    guard let index = buffer.firstIndex(where: { !ASCII.isValidHeaderFieldNameByte($0) }) else {
                        // No index matched yet, we need more data.
                        state = .parsingPart(.parsingHeaderFields(headerFields))
                        return .needsMore
                    }
                    print()
                    
                    
                case .parsingBody(let continuation):
                    preconditionFailure()
                }
                
                
                // First consume the initial CRLF, then start reading header key/value pairs
                // until we reach an empty line, which will mean the end of headers.
                
                return .none
            }
        }
    }
    
    static func parseNextPart(_ buffer: inout [UInt8], boundary: String) throws -> MultipartPart? {
        struct MultipartParserError: Swift.Error, CustomStringConvertible, LocalizedError {
            let error: MultipartParser.StateMachine.Action.ActionError
            var description: String {
                switch error {
                case .invalidInitialBoundary:
                    return "Invalid initial boundary."
                case .invalidCRLFAtStartOfHeader:
                    return "Invalid CRLF at the start of a header field."
                }
            }
            var errorDescription: String? {
                description
            }
        }
        var stateMachine = StateMachine(boundary: boundary)
        while true {
            switch stateMachine.readNextPart(&buffer) {
            case .returnNil:
                return nil
            case .emitPart(let part):
                return part
            case .none:
                continue
            case .emitError(let error):
                throw MultipartParserError(error: error)
            case .needsMore:
                preconditionFailure("Must not happen while we're still using buffering.")
            }
        }
    }
}

enum FirstIndexAfterElementsResult<C: RandomAccessCollection> {
    case index(C.Index)
    case reachedEndOfSelf
    case mismatchedCharacter(C.Index)
}

fileprivate extension RandomAccessCollection where Element: Equatable {
    
    /// Verifies that the elements match the provided sequence and returns the first index past the match.
    /// - Parameter expectedElements: The elements to match against.
    /// - Returns: First index past the match; nil if elements don't match or if ran out of elements on self.
    func firstIndexAfterElements(
        _ expectedElements: some Sequence<Element>
    ) -> FirstIndexAfterElementsResult<Self> {
        var index = startIndex
        for expectedElement in expectedElements {
            guard index < endIndex else {
                return .reachedEndOfSelf
            }
            guard self[index] == expectedElement else {
                return .mismatchedCharacter(index)
            }
            formIndex(after: &index)
        }
        return .index(index)
    }
}
