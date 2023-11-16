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

import HTTPTypes

/// A sequence that parses multipart frames from bytes.
struct MultipartBytesToFramesSequence<Upstream: AsyncSequence & Sendable>: Sendable
where Upstream.Element == ArraySlice<UInt8> {

    /// The source of byte chunks.
    var upstream: Upstream

    /// The boundary string used to separate multipart parts.
    var boundary: String
}

extension MultipartBytesToFramesSequence: AsyncSequence {

    /// The type of element produced by this asynchronous sequence.
    typealias Element = MultipartFrame

    /// Creates the asynchronous iterator that produces elements of this
    /// asynchronous sequence.
    ///
    /// - Returns: An instance of the `AsyncIterator` type used to produce
    /// elements of the asynchronous sequence.
    func makeAsyncIterator() -> Iterator<Upstream.AsyncIterator> {
        Iterator(upstream: upstream.makeAsyncIterator(), boundary: boundary)
    }

    /// An iterator that pulls byte chunks from the upstream iterator and provides
    /// parsed multipart frames.
    struct Iterator<UpstreamIterator: AsyncIteratorProtocol>: AsyncIteratorProtocol
    where UpstreamIterator.Element == ArraySlice<UInt8> {
        /// The iterator that provides the byte chunks.
        private var upstream: UpstreamIterator

        /// The multipart frame parser.
        private var parser: MultipartParser
        /// Creates a new iterator from the provided source of byte chunks and a boundary string.
        /// - Parameters:
        ///   - upstream: The iterator that provides the byte chunks.
        ///   - boundary: The boundary separating the multipart parts.
        init(upstream: UpstreamIterator, boundary: String) {
            self.upstream = upstream
            self.parser = .init(boundary: boundary)
        }

        /// Asynchronously advances to the next element and returns it, or ends the
        /// sequence if there is no next element.
        ///
        /// - Returns: The next element, if it exists, or `nil` to signal the end of
        ///   the sequence.
        mutating func next() async throws -> MultipartFrame? { try await parser.next { try await upstream.next() } }
    }
}
