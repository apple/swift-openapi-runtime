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
/// let body = HTTPBody(bytes)
/// ```
///
/// Create a body from `Foundation.Data`:
/// ```swift
/// let data: Foundation.Data = ...
/// let body = HTTPBody(data)
/// ```
///
/// Create a body from a string:
/// ```swift
/// let body = HTTPBody("Hello, world!")
/// ```
///
/// ## Creating a body from an async sequence
/// The body type also supports initialization from an async sequence.
///
/// ```swift
/// let producingSequence = ... // an AsyncSequence
/// let length: HTTPBody.Length = .known(1024) // or .unknown
/// let body = HTTPBody(
///     producingSequence,
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
///     AsyncStream(ArraySlice<UInt8>.self, { continuation in
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
/// the convenience initializers on the target types that take an `HTTPBody`.
///
/// To get all the bytes, use the initializer on `ArraySlice<UInt8>` or `[UInt8]`:
///
/// ```swift
/// let buffer = try await ArraySlice(collecting: body, upTo: 2 * 1024 * 1024)
/// ```
///
/// The body type provides more variants of the collecting initializer on commonly
/// used buffers, such as:
/// - `Foundation.Data`
/// - `Swift.String`
///
/// > Important: You must provide the maximum number of bytes you can buffer in
/// memory, in the example above we provide 2 MB. If more bytes are available,
/// the method throws the `TooManyBytesError` to stop the process running out
/// of memory. While discouraged, you can provide `upTo: .max` to
/// read all the available bytes, without a limit.
public typealias HTTPBody = OpenAPISequence<ArraySlice<UInt8>>

// MARK: - Creating the HTTPBody

extension HTTPBody {

    /// Creates a new body with the provided byte chunk.
    /// - Parameter bytes: A byte chunk.
    @inlinable public convenience init(_ bytes: ArraySlice<UInt8>) { self.init([bytes], length: .known(bytes.count)) }

    /// Creates a new body with the provided byte sequence.
    /// - Parameters:
    ///   - bytes: A byte chunk.
    ///   - length: The total length of the body.
    ///   - iterationBehavior: The iteration behavior of the sequence, which
    ///     indicates whether it can be iterated multiple times.
    @inlinable public convenience init(
        _ bytes: some Sequence<UInt8> & Sendable,
        length: ByteLength,
        iterationBehavior: IterationBehavior
    ) { self.init([ArraySlice(bytes)], length: length, iterationBehavior: iterationBehavior) }

    /// Creates a new body with the provided byte collection.
    /// - Parameters:
    ///   - bytes: A byte chunk.
    ///   - length: The total length of the body.
    @inlinable public convenience init(_ bytes: some Collection<UInt8> & Sendable, length: ByteLength) {
        self.init(ArraySlice(bytes), length: length, iterationBehavior: .multiple)
    }

    /// Creates a new body with the provided byte collection.
    /// - Parameter bytes: A byte chunk.
    @inlinable public convenience init(_ bytes: some Collection<UInt8> & Sendable) {
        self.init(bytes, length: .known(bytes.count))
    }

    /// Creates a new body with the provided async sequence of byte sequences.
    /// - Parameters:
    ///   - sequence: An async sequence that provides the byte chunks.
    ///   - length: The total length of the body.
    ///   - iterationBehavior: The iteration behavior of the sequence, which
    ///     indicates whether it can be iterated multiple times.
    @inlinable @_disfavoredOverload public convenience init<Bytes: AsyncSequence>(
        _ sequence: Bytes,
        length: ByteLength,
        iterationBehavior: IterationBehavior
    ) where Bytes: Sendable, Bytes.Element: Sequence & Sendable, Bytes.Element.Element == UInt8 {
        self.init(sequence.map { ArraySlice($0) }, length: length, iterationBehavior: iterationBehavior)
    }
}

// MARK: - Consuming the body

extension HTTPBody {

    /// An error thrown by the collecting initializer when the body contains more
    /// than the maximum allowed number of bytes.
    private struct TooManyBytesError: Error, CustomStringConvertible, LocalizedError {

        /// The maximum number of bytes acceptable by the user.
        let maxBytes: Int

        var description: String { "OpenAPIRuntime.HTTPBody contains more than the maximum allowed \(maxBytes) bytes." }

        var errorDescription: String? { description }
    }

    /// Accumulates the full body in-memory into a single buffer
    /// up to the provided maximum number of bytes and returns it.
    /// - Parameter maxBytes: The maximum number of bytes this method is allowed
    ///     to accumulate in memory before it throws an error.
    /// - Throws: `TooManyBytesError` if the body contains more
    ///   than `maxBytes`.
    /// - Returns: A byte chunk containing all the accumulated bytes.
    fileprivate func collect(upTo maxBytes: Int) async throws -> ArraySlice<UInt8> {

        // Check that we're allowed to iterate again.
        try checkIfCanCreateIterator()

        // If the length is known, verify it's within the limit.
        if case .known(let knownBytes) = length {
            guard knownBytes <= maxBytes else { throw TooManyBytesError(maxBytes: maxBytes) }
        }

        // Accumulate the byte chunks.
        var buffer: ArraySlice<UInt8> = []
        for try await chunk in self {
            guard buffer.count + chunk.count <= maxBytes else { throw TooManyBytesError(maxBytes: maxBytes) }
            buffer.append(contentsOf: chunk)
        }
        return buffer
    }
}

extension ArraySlice<UInt8> {
    /// Creates a byte chunk by accumulating the full body in-memory into a single buffer
    /// up to the provided maximum number of bytes and returning it.
    /// - Parameters:
    ///   - body: The HTTP body to collect.
    ///   - maxBytes: The maximum number of bytes this method is allowed
    ///     to accumulate in memory before it throws an error.
    /// - Throws: `TooManyBytesError` if the body contains more
    ///   than `maxBytes`.
    public init(collecting body: HTTPBody, upTo maxBytes: Int) async throws {
        self = try await body.collect(upTo: maxBytes)
    }
}

extension [UInt8] {
    /// Creates a byte array by accumulating the full body in-memory into a single buffer
    /// up to the provided maximum number of bytes and returning it.
    /// - Parameters:
    ///   - body: The HTTP body to collect.
    ///   - maxBytes: The maximum number of bytes this method is allowed
    ///     to accumulate in memory before it throws an error.
    /// - Throws: `TooManyBytesError` if the body contains more
    ///   than `maxBytes`.
    public init(collecting body: HTTPBody, upTo maxBytes: Int) async throws {
        self = try await Array(body.collect(upTo: maxBytes))
    }
}

// MARK: - String-based bodies

extension HTTPBody {

    /// Creates a new body with the provided string encoded as UTF-8 bytes.
    /// - Parameters:
    ///   - string: A string to encode as bytes.
    ///   - length: The total length of the body.
    @inlinable public convenience init(_ string: some StringProtocol & Sendable, length: ByteLength) {
        self.init(ArraySlice<UInt8>(string.utf8), length: length)
    }

    /// Creates a new body with the provided string encoded as UTF-8 bytes.
    /// - Parameter string: A string to encode as bytes.
    @inlinable public convenience init(_ string: some StringProtocol & Sendable) {
        self.init(ArraySlice<UInt8>(string.utf8))
    }

    /// Creates a new body with the provided async throwing stream of strings.
    /// - Parameters:
    ///   - stream: An async throwing stream that provides the string chunks.
    ///   - length: The total length of the body.
    @inlinable public convenience init(
        _ stream: AsyncThrowingStream<some StringProtocol & Sendable, any Error & Sendable>,
        length: ByteLength
    ) { self.init(.init(stream.map { ArraySlice<UInt8>($0.utf8) }), length: length, iterationBehavior: .single) }

    /// Creates a new body with the provided async stream of strings.
    /// - Parameters:
    ///   - stream: An async stream that provides the string chunks.
    ///   - length: The total length of the body.
    @inlinable public convenience init(_ stream: AsyncStream<some StringProtocol & Sendable>, length: ByteLength) {
        self.init(.init(stream.map { ArraySlice<UInt8>($0.utf8) }), length: length, iterationBehavior: .single)
    }

    /// Creates a new body with the provided async sequence of string chunks.
    /// - Parameters:
    ///   - sequence: An async sequence that provides the string chunks.
    ///   - length: The total length of the body.
    ///   - iterationBehavior: The iteration behavior of the sequence, which
    ///     indicates whether it can be iterated multiple times.
    @inlinable public convenience init<Strings: AsyncSequence>(
        _ sequence: Strings,
        length: ByteLength,
        iterationBehavior: IterationBehavior
    ) where Strings.Element: StringProtocol & Sendable, Strings: Sendable {
        self.init(
            .init(sequence.map { ArraySlice<UInt8>($0.utf8) }),
            length: length,
            iterationBehavior: iterationBehavior
        )
    }
}

extension String {
    /// Creates a string by accumulating the full body in-memory into a single buffer up to
    /// the provided maximum number of bytes, converting it to string using UTF-8 encoding.
    /// - Parameters:
    ///   - body: The HTTP body to collect.
    ///   - maxBytes: The maximum number of bytes this method is allowed
    ///     to accumulate in memory before it throws an error.
    /// - Throws: `TooManyBytesError` if the body contains more
    ///   than `maxBytes`.
    public init(collecting body: HTTPBody, upTo maxBytes: Int) async throws {
        self = try await String(decoding: body.collect(upTo: maxBytes), as: UTF8.self)
    }
}

// MARK: - HTTPBody conversions

extension HTTPBody: ExpressibleByUnicodeScalarLiteral {
    convenience public init(unicodeScalarLiteral value: String) { self.init(value) }
}

extension HTTPBody: ExpressibleByExtendedGraphemeClusterLiteral {}

extension HTTPBody: ExpressibleByStringLiteral {
    /// Initializes an `HTTPBody` instance with the provided string value.
    ///
    /// - Parameter value: The string literal to use for initializing the `HTTPBody`.
    public convenience init(stringLiteral value: String) { self.init(value) }
}

extension HTTPBody {

    /// Creates a new body from the provided array of bytes.
    /// - Parameter bytes: An array of bytes.
    @inlinable public convenience init(_ bytes: [UInt8]) { self.init(bytes[...]) }
}

extension HTTPBody: ExpressibleByArrayLiteral {
    /// Element type for array literals.
    public typealias ArrayLiteralElement = UInt8
    /// Initializes an `HTTPBody` instance with a sequence of `UInt8` elements.
    ///
    /// - Parameter elements: A variadic list of `UInt8` elements used to initialize the `HTTPBody`.
    public convenience init(arrayLiteral elements: UInt8...) { self.init(elements) }
}

extension HTTPBody {

    /// Creates a new body from the provided data chunk.
    /// - Parameter data: A single data chunk.
    public convenience init(_ data: Data) { self.init(ArraySlice(data)) }
}

extension Data {
    /// Creates a Data by accumulating the full body in-memory into a single buffer up to
    /// the provided maximum number of bytes and converting it to `Data`.
    /// - Parameters:
    ///   - body: The HTTP body to collect.
    ///   - maxBytes: The maximum number of bytes this method is allowed
    ///     to accumulate in memory before it throws an error.
    /// - Throws: `TooManyBytesError` if the body contains more
    ///   than `maxBytes`.
    public init(collecting body: HTTPBody, upTo maxBytes: Int) async throws {
        self = try await Data(body.collect(upTo: maxBytes))
    }
}
