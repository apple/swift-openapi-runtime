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

import class Foundation.NSLock
import protocol Foundation.LocalizedError
import struct Foundation.Data  // only for convenience initializers

/// A body of an HTTP request or HTTP response.
///
/// Under the hood, it represents an async sequence of byte chunks.
///
/// ## Creating a body from a buffer
/// There are convenience initializers to create a body from common types, such
/// as `Data`, `[UInt8]`, `ArraySlice<UInt8>`, and `String`.
///
/// Create an empty body:
/// ```swift
/// let body = HTTPBody()
/// ```
///
/// Create a body from a byte chunk:
/// ```swift
/// let bytes: ArraySlice<UInt8> = ...
/// let body = HTTPBody(bytes: bytes)
/// ```
///
/// Create a body from `Foundation.Data`:
/// ```swift
/// let data: Foundation.Data = ...
/// let body = HTTPBody(data: data)
/// ```
///
/// Create a body from a string:
/// ```swift
/// let body = HTTPBody(string: "Hello, world!")
/// ```
///
/// ## Creating a body from an async sequence
/// The body type also supports initialization from an async sequence.
///
/// ```swift
/// let producingSequence = ... // an AsyncSequence
/// let length: HTTPBody.Length = .known(1024) // or .unknown
/// let body = HTTPBody(
///     sequence: producingSequence,
///     length: length,
///     iterationBehavior: .single // or .multiple
/// )
/// ```
///
/// In addition to the async sequence, also provide the total body length,
/// if known (this can be sent in the `content-length` header), and whether
/// the sequence is safe to be iterated multiple times, or can only be iterated
/// once.
///
/// Sequences that can be iterated multiple times work better when an HTTP
/// request needs to be retried, or if a redirect is encountered.
///
/// In addition to providing the async sequence, you can also produce the body
/// using an `AsyncStream` or `AsyncThrowingStream`:
///
/// ```swift
/// let body = HTTPBody(
///     stream: AsyncStream(ArraySlice<UInt8>.self, { continuation in
///         continuation.yield([72, 69])
///         continuation.yield([76, 76, 79])
///         continuation.finish()
///     }),
///     length: .known(5)
/// )
/// ```
///
/// ## Consuming a body as an async sequence
/// The `HTTPBody` type conforms to `AsyncSequence` and uses `ArraySlice<UInt8>`
/// as its element type, so it can be consumed in a streaming fashion, without
/// ever buffering the whole body in your process.
///
/// For example, to get another sequence that contains only the size of each
/// chunk, and print each size, use:
///
/// ```swift
/// let chunkSizes = body.map { chunk in chunk.count }
/// for try await chunkSize in chunkSizes {
///     print("Chunk size: \(chunkSize)")
/// }
/// ```
///
/// ## Consuming a body as a buffer
/// If you need to collect the whole body before processing it, use one of
/// the convenience `collect` methods on `HTTPBody`.
///
/// To get all the bytes, use:
///
/// ```swift
/// let buffer = try await body.collect(upTo: 2 * 1024 * 1024)
/// ```
///
/// Note that you must provide the maximum number of bytes you can buffer in
/// memory, in the example above we provide 2 MB. If more bytes are available,
/// the method throws the `TooManyBytesError` to stop the process running out
/// of memory. While discouraged, you can provide `collect(upTo: .max)` to
/// read all the available bytes, without a limit.
///
/// The body type provides more variants of the `collect` method for commonly
/// used buffers, such as:
/// - `collectAsData` provides the buffered data as `Foundation.Data`
/// - `collectAsString` provides the buffered data as a string decoded as UTF-8
public final class HTTPBody: @unchecked Sendable {

    /// The underlying byte chunk type.
    public typealias ByteChunk = ArraySlice<UInt8>

    /// Describes how many times the provided sequence can be iterated.
    public enum IterationBehavior: Sendable {

        /// The input sequence can only be iterated once.
        ///
        /// If a retry or a redirect is encountered, fail the call with
        /// a descriptive error.
        case single

        /// The input sequence can be iterated multiple times.
        ///
        /// Supports retries and redirects, as a new iterator is created each
        /// time.
        case multiple
    }

    /// The body's iteration behavior, which controls how many times
    /// the input sequence can be iterated.
    public let iterationBehavior: IterationBehavior

    /// Describes the total length of the body, if known.
    public enum Length: Sendable {

        /// Total length not known yet.
        case unknown

        /// Total length is known.
        case known(Int)
    }

    /// The total length of the body, if known.
    public let length: Length

    /// The underlying type-erased async sequence.
    private let sequence: BodySequence

    /// A lock for shared mutable state.
    private let lock: NSLock = {
        let lock = NSLock()
        lock.name = "com.apple.swift-openapi-generator.runtime.body"
        return lock
    }()

    /// A flag indicating whether an iterator has already been created.
    private var locked_iteratorCreated: Bool = false

    /// Creates a new body.
    /// - Parameters:
    ///   - sequence: The input sequence providing the byte chunks.
    ///   - length: The total length of the body, in other words the accumulated
    ///     length of all the byte chunks.
    ///   - iterationBehavior: The sequence's iteration behavior, which
    ///     indicates whether the sequence can be iterated multiple times.
    @usableFromInline init(
        sequence: BodySequence,
        length: Length,
        iterationBehavior: IterationBehavior
    ) {
        self.sequence = sequence
        self.length = length
        self.iterationBehavior = iterationBehavior
    }
}

extension HTTPBody: Equatable {
    public static func == (
        lhs: HTTPBody,
        rhs: HTTPBody
    ) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

extension HTTPBody: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

// MARK: - Creating the HTTPBody

extension HTTPBody {

    /// Creates a new empty body.
    @inlinable public convenience init() {
        self.init(
            sequence: .init(EmptySequence()),
            length: .known(0),
            iterationBehavior: .multiple
        )
    }

    /// Creates a new body with the provided single byte chunk.
    /// - Parameters:
    ///   - bytes: A byte chunk.
    ///   - length: The total length of the body.
    @inlinable public convenience init(
        bytes: ByteChunk,
        length: Length
    ) {
        self.init(
            byteChunks: [bytes],
            length: length
        )
    }

    /// Creates a new body with the provided single byte chunk.
    /// - Parameter bytes: A byte chunk.
    @inlinable public convenience init(
        bytes: ByteChunk
    ) {
        self.init(
            byteChunks: [bytes],
            length: .known(bytes.count)
        )
    }

    /// Creates a new body with the provided sequence of byte chunks.
    /// - Parameters:
    ///   - byteChunks: A sequence of byte chunks.
    ///   - length: The total length of the body.
    ///   - iterationBehavior: The iteration behavior of the sequence, which
    ///     indicates whether it can be iterated multiple times.
    @inlinable public convenience init<S: Sequence>(
        byteChunks: S,
        length: Length,
        iterationBehavior: IterationBehavior
    ) where S.Element == ByteChunk {
        self.init(
            sequence: .init(WrappedSyncSequence(sequence: byteChunks)),
            length: length,
            iterationBehavior: iterationBehavior
        )
    }

    /// Creates a new body with the provided collection of byte chunks.
    /// - Parameters:
    ///   - byteChunks: A collection of byte chunks.
    ///   - length: The total length of the body.
    @inlinable public convenience init<C: Collection>(
        byteChunks: C,
        length: Length
    ) where C.Element == ByteChunk {
        self.init(
            sequence: .init(WrappedSyncSequence(sequence: byteChunks)),
            length: length,
            iterationBehavior: .multiple
        )
    }

    /// Creates a new body with the provided collection of byte chunks.
    ///   - byteChunks: A collection of byte chunks.
    @inlinable public convenience init<C: Collection>(
        byteChunks: C
    ) where C.Element == ByteChunk {
        self.init(
            sequence: .init(WrappedSyncSequence(sequence: byteChunks)),
            length: .known(byteChunks.map(\.count).reduce(0, +)),
            iterationBehavior: .multiple
        )
    }

    /// Creates a new body with the provided async throwing stream.
    /// - Parameters:
    ///   - stream: An async throwing stream that provides the byte chunks.
    ///   - length: The total length of the body.
    @inlinable public convenience init(
        stream: AsyncThrowingStream<ByteChunk, any Error>,
        length: HTTPBody.Length
    ) {
        self.init(
            sequence: .init(stream),
            length: length,
            iterationBehavior: .single
        )
    }

    /// Creates a new body with the provided async stream.
    /// - Parameters:
    ///   - stream: An async stream that provides the byte chunks.
    ///   - length: The total length of the body.
    @inlinable public convenience init(
        stream: AsyncStream<ByteChunk>,
        length: HTTPBody.Length
    ) {
        self.init(
            sequence: .init(stream),
            length: length,
            iterationBehavior: .single
        )
    }

    /// Creates a new body with the provided async sequence.
    /// - Parameters:
    ///   - sequence: An async sequence that provides the byte chunks.
    ///   - length: The total lenght of the body.
    ///   - iterationBehavior: The iteration behavior of the sequence, which
    ///     indicates whether it can be iterated multiple times.
    @inlinable public convenience init<S: AsyncSequence>(
        sequence: S,
        length: HTTPBody.Length,
        iterationBehavior: IterationBehavior
    ) where S.Element == ByteChunk {
        self.init(
            sequence: .init(sequence),
            length: length,
            iterationBehavior: iterationBehavior
        )
    }
}

// MARK: - Consuming the body

extension HTTPBody: AsyncSequence {
    public typealias Element = ByteChunk
    public typealias AsyncIterator = Iterator
    public func makeAsyncIterator() -> AsyncIterator {
        if iterationBehavior == .single {
            lock.lock()
            defer {
                lock.unlock()
            }
            guard !locked_iteratorCreated else {
                fatalError(
                    "OpenAPIRuntime.HTTPBody attempted to create a second iterator, but the underlying sequence is only safe to be iterated once."
                )
            }
            locked_iteratorCreated = true
        }
        return sequence.makeAsyncIterator()
    }
}

extension HTTPBody {

    /// An error thrown by the `collect` function when the body contains more
    /// than the maximum allowed number of bytes.
    private struct TooManyBytesError: Error, CustomStringConvertible, LocalizedError {

        /// The maximum number of bytes acceptable by the user.
        let maxBytes: Int

        var description: String {
            "OpenAPIRuntime.HTTPBody contains more than the maximum allowed \(maxBytes) bytes."
        }

        var errorDescription: String? {
            description
        }
    }

    /// An error thrown by the `collect` function when another iteration of
    /// the body is not allowed.
    private struct TooManyIterationsError: Error, CustomStringConvertible, LocalizedError {

        var description: String {
            "OpenAPIRuntime.HTTPBody attempted to create a second iterator, but the underlying sequence is only safe to be iterated once."
        }

        var errorDescription: String? {
            description
        }
    }

    /// Accumulates the full body in-memory into a single buffer
    /// up to the provided maximum number of bytes and returns it.
    /// - Parameters:
    ///   - maxBytes: The maximum number of bytes this method is allowed
    ///     to accumulate in memory before it throws an error.
    /// - Throws: `TooManyBytesError` if the the sequence contains more
    ///   than `maxBytes`.
    /// - Returns: A single byte chunk containing all the accumulated bytes.
    public func collect(upTo maxBytes: Int) async throws -> ByteChunk {

        // As a courtesy, check if another iteration is allowed, and throw
        // an error instead of fatalError here if the user is trying to
        // iterate a sequence for the second time, if it's only safe to be
        // iterated once.
        if iterationBehavior == .single {
            try {
                lock.lock()
                defer {
                    lock.unlock()
                }
                guard !locked_iteratorCreated else {
                    throw TooManyIterationsError()
                }
            }()
        }

        var buffer = ByteChunk.init()
        for try await chunk in self {
            guard buffer.count + chunk.count <= maxBytes else {
                throw TooManyBytesError(maxBytes: maxBytes)
            }
            buffer.append(contentsOf: chunk)
        }
        return buffer
    }
}

// MARK: - String-based bodies

extension HTTPBody {

    /// Creates a new body with the provided string encoded as UTF-8 bytes.
    /// - Parameters:
    ///   - string: A string to encode as bytes.
    ///   - length: The total length of the body.
    @inlinable public convenience init(
        string: some StringProtocol,
        length: Length
    ) {
        self.init(
            bytes: string.asBodyChunk,
            length: length
        )
    }

    /// Creates a new body with the provided string encoded as UTF-8 bytes.
    /// - Parameters:
    ///   - string: A string to encode as bytes.
    @inlinable public convenience init(
        string: some StringProtocol
    ) {
        self.init(
            bytes: string.asBodyChunk,
            length: .known(string.count)
        )
    }

    /// Creates a new body with the provided strings encoded as UTF-8 bytes.
    /// - Parameters:
    ///   - stringChunks: A sequence of string chunks.
    ///   - length: The total length of the body.
    ///   - iterationBehavior: The iteration behavior of the sequence, which
    ///     indicates whether it can be iterated multiple times.
    @inlinable public convenience init<S: Sequence>(
        stringChunks: S,
        length: Length,
        iterationBehavior: IterationBehavior
    ) where S.Element: StringProtocol {
        self.init(
            byteChunks: stringChunks.map(\.asBodyChunk),
            length: length,
            iterationBehavior: iterationBehavior
        )
    }

    /// Creates a new body with the provided strings encoded as UTF-8 bytes.
    /// - Parameters:
    ///   - stringChunks: A collection of string chunks.
    ///   - length: The total length of the body.
    @inlinable public convenience init<C: Collection>(
        stringChunks: C,
        length: Length
    ) where C.Element: StringProtocol {
        self.init(
            byteChunks: stringChunks.map(\.asBodyChunk),
            length: length
        )
    }

    /// Creates a new body with the provided strings encoded as UTF-8 bytes.
    /// - Parameters:
    ///   - stringChunks: A collection of string chunks.
    @inlinable public convenience init<C: Collection>(
        stringChunks: C
    ) where C.Element: StringProtocol {
        self.init(
            byteChunks: stringChunks.map(\.asBodyChunk)
        )
    }

    /// Creates a new body with the provided async throwing stream of strings.
    /// - Parameters:
    ///   - stream: An async throwing stream that provides the string chunks.
    ///   - length: The total length of the body.
    @inlinable public convenience init(
        stream: AsyncThrowingStream<some StringProtocol, any Error>,
        length: HTTPBody.Length
    ) {
        self.init(
            sequence: .init(stream.map(\.asBodyChunk)),
            length: length,
            iterationBehavior: .single
        )
    }

    /// Creates a new body with the provided async stream of strings.
    /// - Parameters:
    ///   - stream: An async stream that provides the string chunks.
    ///   - length: The total length of the body.
    @inlinable public convenience init(
        stream: AsyncStream<some StringProtocol>,
        length: HTTPBody.Length
    ) {
        self.init(
            sequence: .init(stream.map(\.asBodyChunk)),
            length: length,
            iterationBehavior: .single
        )
    }

    /// Creates a new body with the provided async sequence of string chunks.
    /// - Parameters:
    ///   - sequence: An async sequence that provides the string chunks.
    ///   - length: The total lenght of the body.
    ///   - iterationBehavior: The iteration behavior of the sequence, which
    ///     indicates whether it can be iterated multiple times.
    @inlinable public convenience init<S: AsyncSequence>(
        sequence: S,
        length: HTTPBody.Length,
        iterationBehavior: IterationBehavior
    ) where S.Element: StringProtocol {
        self.init(
            sequence: .init(sequence.map(\.asBodyChunk)),
            length: length,
            iterationBehavior: iterationBehavior
        )
    }
}

extension StringProtocol {

    /// Returns the string as a byte chunk compatible with the `HTTPBody` type.
    @inlinable var asBodyChunk: HTTPBody.ByteChunk {
        Array(utf8)[...]
    }
}

extension HTTPBody {

    /// Accumulates the full body in-memory into a single buffer up to
    /// the provided maximum number of bytes, converts it to string from
    /// the UTF-8 bytes, and returns it.
    /// - Parameters:
    ///   - maxBytes: The maximum number of bytes this method is allowed
    ///     to accumulate in memory before it throws an error.
    /// - Throws: `TooManyBytesError` if the the body contains more
    ///   than `maxBytes`.
    /// - Returns: The string decoded from the UTF-8 bytes.
    public func collectAsString(upTo maxBytes: Int) async throws -> String {
        let bytes: ByteChunk = try await collect(upTo: maxBytes)
        return String(decoding: bytes, as: UTF8.self)
    }
}

// MARK: - HTTPBody conversions

extension HTTPBody: ExpressibleByStringLiteral {
    public convenience init(stringLiteral value: String) {
        self.init(string: value)
    }
}

extension HTTPBody {

    /// Creates a new body from the provided array of bytes.
    /// - Parameter bytes: An array of bytes.
    @inlinable public convenience init(bytes: [UInt8]) {
        self.init(bytes: bytes[...])
    }
}

extension HTTPBody: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = UInt8
    public convenience init(arrayLiteral elements: UInt8...) {
        self.init(bytes: elements)
    }
}

extension HTTPBody {

    /// Creates a new body from the provided data chunk.
    /// - Parameter data: A single data chunk.
    public convenience init(data: Data) {
        self.init(bytes: ArraySlice(data))
    }

    /// Accumulates the full body in-memory into a single buffer up to
    /// the provided maximum number of bytes, converts it to `Data`, and
    /// returns it.
    /// - Parameters:
    ///   - maxBytes: The maximum number of bytes this method is allowed
    ///     to accumulate in memory before it throws an error.
    /// - Throws: `TooManyBytesError` if the the body contains more
    ///   than `maxBytes`.
    /// - Returns: The accumulated bytes wrapped in `Data`.
    public func collectAsData(upTo maxBytes: Int) async throws -> Data {
        let bytes: ByteChunk = try await collect(upTo: maxBytes)
        return Data(bytes)
    }
}

// MARK: - Underlying async sequences

extension HTTPBody {

    /// An async iterator of both input async sequences and of the body itself.
    public struct Iterator: AsyncIteratorProtocol {

        /// The element byte chunk type.
        public typealias Element = HTTPBody.ByteChunk

        /// The closure that produces the next element.
        private let produceNext: () async throws -> Element?

        /// Creates a new type-erased iterator from the provided iterator.
        /// - Parameter iterator: The iterator to type-erase.
        @usableFromInline init<Iterator: AsyncIteratorProtocol>(
            _ iterator: Iterator
        ) where Iterator.Element == Element {
            var iterator = iterator
            self.produceNext = {
                try await iterator.next()
            }
        }

        public func next() async throws -> Element? {
            try await produceNext()
        }
    }
}

extension HTTPBody {

    /// A type-erased async sequence that wraps input sequences.
    @usableFromInline struct BodySequence: AsyncSequence {

        /// The type of the type-erased iterator.
        @usableFromInline typealias AsyncIterator = HTTPBody.Iterator

        /// The byte chunk element type.
        @usableFromInline typealias Element = ByteChunk

        /// A closure that produces a new iterator.
        @usableFromInline let produceIterator: () -> AsyncIterator

        /// Creates a new sequence.
        /// - Parameter sequence: The input sequence to type-erase.
        @inlinable init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
            self.produceIterator = {
                .init(sequence.makeAsyncIterator())
            }
        }

        @usableFromInline func makeAsyncIterator() -> AsyncIterator {
            produceIterator()
        }
    }

    /// An async sequence wrapper for a sync sequence.
    @usableFromInline struct WrappedSyncSequence<S: Sequence>: AsyncSequence
    where S.Element == ByteChunk, S.Iterator.Element == ByteChunk {

        /// The type of the iterator.
        @usableFromInline typealias AsyncIterator = Iterator

        /// The byte chunk element type.
        @usableFromInline typealias Element = ByteChunk

        /// An iterator type that wraps a sync sequence iterator.
        @usableFromInline struct Iterator: AsyncIteratorProtocol {

            /// The byte chunk element type.
            @usableFromInline typealias Element = ByteChunk

            /// The underlying sync sequence iterator.
            var iterator: any IteratorProtocol<Element>

            @usableFromInline mutating func next() async throws -> HTTPBody.ByteChunk? {
                iterator.next()
            }
        }

        /// The underlying sync sequence.
        @usableFromInline let sequence: S

        /// Creates a new async sequence with the provided sync sequence.
        /// - Parameter sequence: The sync sequence to wrap.
        @inlinable init(sequence: S) {
            self.sequence = sequence
        }

        @usableFromInline func makeAsyncIterator() -> Iterator {
            Iterator(iterator: sequence.makeIterator())
        }
    }

    /// An empty async sequence.
    @usableFromInline struct EmptySequence: AsyncSequence {

        /// The type of the empty iterator.
        @usableFromInline typealias AsyncIterator = EmptyIterator

        /// The byte chunk element type.
        @usableFromInline typealias Element = ByteChunk

        /// An async iterator of an empty sequence.
        @usableFromInline struct EmptyIterator: AsyncIteratorProtocol {

            /// The byte chunk element type.
            @usableFromInline typealias Element = ByteChunk

            @usableFromInline mutating func next() async throws -> HTTPBody.ByteChunk? {
                nil
            }
        }

        /// Creates a new empty async sequence.
        @inlinable init() {}

        @usableFromInline func makeAsyncIterator() -> EmptyIterator {
            EmptyIterator()
        }
    }
}
