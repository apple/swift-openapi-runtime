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

/// A sequence that serializes multipart frames into bytes.
struct MultipartFramesToBytesSequence<Upstream: AsyncSequence & Sendable>: Sendable
where Upstream.Element == MultipartFrame {

    /// The source of multipart frames.
    var upstream: Upstream

    /// The boundary string used to separate multipart parts.
    var boundary: String
}

extension MultipartFramesToBytesSequence: AsyncSequence {

    /// The type of element produced by this asynchronous sequence.
    typealias Element = ArraySlice<UInt8>

    /// Creates the asynchronous iterator that produces elements of this
    /// asynchronous sequence.
    ///
    /// - Returns: An instance of the `AsyncIterator` type used to produce
    /// elements of the asynchronous sequence.
    func makeAsyncIterator() -> Iterator<Upstream.AsyncIterator> {
        Iterator(upstream: upstream.makeAsyncIterator(), boundary: boundary)
    }

    /// An iterator that pulls frames from the upstream iterator and provides
    /// serialized byte chunks.
    struct Iterator<UpstreamIterator: AsyncIteratorProtocol>: AsyncIteratorProtocol
    where UpstreamIterator.Element == MultipartFrame {

        /// The iterator that provides the multipart frames.
        private var upstream: UpstreamIterator

        /// The multipart frame serializer.
        private var serializer: MultipartSerializer

        /// Creates a new iterator from the provided source of frames and a boundary string.
        /// - Parameters:
        ///   - upstream: The iterator that provides the multipart frames.
        ///   - boundary: The boundary separating the multipart parts.
        init(upstream: UpstreamIterator, boundary: String) {
            self.upstream = upstream
            self.serializer = .init(boundary: boundary)
        }

        /// Asynchronously advances to the next element and returns it, or ends the
        /// sequence if there is no next element.
        ///
        /// - Returns: The next element, if it exists, or `nil` to signal the end of
        ///   the sequence.
        mutating func next() async throws -> ArraySlice<UInt8>? {
            try await serializer.next { try await upstream.next() }
        }
    }
}
