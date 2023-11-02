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

@frozen public enum MultipartBodyChunk: Sendable, Hashable {
    case headerFields(HTTPFields)
    case bodyChunk(ArraySlice<UInt8>)
}

public final class MultipartBody: @unchecked Sendable {

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
    public enum Length: Sendable, Equatable {

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

    /// A flag indicating whether an iterator has already been created, only
    /// used for testing.
    internal var testing_iteratorCreated: Bool {
        lock.lock()
        defer { lock.unlock() }
        return locked_iteratorCreated
    }

    /// Verifying that creating another iterator is allowed based on
    /// the values of `iterationBehavior` and `locked_iteratorCreated`.
    /// - Throws: If another iterator is not allowed to be created.
    private func checkIfCanCreateIterator() throws {
        lock.lock()
        defer { lock.unlock() }
        guard iterationBehavior == .single else { return }
        if locked_iteratorCreated { throw TooManyIterationsError() }
    }

    /// Tries to mark an iterator as created, verifying that it is allowed
    /// based on the values of `iterationBehavior` and `locked_iteratorCreated`.
    /// - Throws: If another iterator is not allowed to be created.
    private func tryToMarkIteratorCreated() throws {
        lock.lock()
        defer {
            locked_iteratorCreated = true
            lock.unlock()
        }
        guard iterationBehavior == .single else { return }
        if locked_iteratorCreated { throw TooManyIterationsError() }
    }

    /// Creates a new body.
    /// - Parameters:
    ///   - sequence: The input sequence providing the byte chunks.
    ///   - length: The total length of the body, in other words the accumulated
    ///     length of all the byte chunks.
    ///   - iterationBehavior: The sequence's iteration behavior, which
    ///     indicates whether the sequence can be iterated multiple times.
    @usableFromInline init(_ sequence: BodySequence, length: Length, iterationBehavior: IterationBehavior) {
        self.sequence = sequence
        self.length = length
        self.iterationBehavior = iterationBehavior
    }
    @inlinable public convenience init<Parts: AsyncSequence>(
        _ sequence: Parts,
        length: MultipartBody.Length,
        iterationBehavior: IterationBehavior
    ) where Parts: Sendable, Parts.Element == MultipartBodyChunk {
        self.init(.init(sequence), length: length, iterationBehavior: iterationBehavior)
    }
}

extension MultipartBody: Equatable {
    /// Compares two HTTPBody instances for equality by comparing their object identifiers.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side HTTPBody.
    ///   - rhs: The right-hand side HTTPBody.
    ///
    /// - Returns: `true` if the object identifiers of the two HTTPBody instances are equal,
    /// indicating that they are the same object in memory; otherwise, returns `false`.
    public static func == (lhs: MultipartBody, rhs: MultipartBody) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

extension MultipartBody: Hashable {
    /// Hashes the HTTPBody instance by combining its object identifier into the provided hasher.
    ///
    /// - Parameter hasher: The hasher used to combine the hash value.
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

// MARK: - Creating the MultipartBody

extension MultipartBody {

    @inlinable public convenience init() {
        self.init(.init(EmptySequence()), length: .known(0), iterationBehavior: .multiple)
    }

    @inlinable public convenience init(
        _ parts: some Sequence<MultipartBodyChunk> & Sendable,
        length: Length,
        iterationBehavior: IterationBehavior
    ) { self.init(.init(WrappedSyncSequence(sequence: parts)), length: length, iterationBehavior: iterationBehavior) }
    @inlinable public convenience init(_ parts: some Collection<MultipartBodyChunk> & Sendable, length: Length) {
        self.init(.init(WrappedSyncSequence(sequence: parts)), length: length, iterationBehavior: .multiple)
    }

    //    @inlinable public convenience init(
    //        _ parts: some Sequence<BufferedMultipartPart> & Sendable,
    //        length: Length,
    //        iterationBehavior: IterationBehavior
    //    ) {
    //        self.init(
    //            parts.map { MultipartPart(headerFields: $0.headerFields, body: .init($0.body)) },
    //            length: length,
    //            iterationBehavior: iterationBehavior
    //        )
    //    }
    //
    //    @inlinable public convenience init(_ parts: some Collection<BufferedMultipartPart> & Sendable, length: Length) {
    //        self.init(parts, length: length, iterationBehavior: .multiple)
    //    }
    //
    //    /// Creates a new body with the provided byte collection.
    //    /// - Parameter bytes: A byte chunk.
    //    @inlinable public convenience init(_ bytes: some Collection<UInt8> & Sendable) {
    //        self.init(bytes, length: .known(bytes.count))
    //    }
    //
    //    /// Creates a new body with the provided async throwing stream.
    //    /// - Parameters:
    //    ///   - stream: An async throwing stream that provides the byte chunks.
    //    ///   - length: The total length of the body.
    //    @inlinable public convenience init(_ stream: AsyncThrowingStream<ByteChunk, any Error>, length: HTTPBody.Length) {
    //        self.init(.init(stream), length: length, iterationBehavior: .single)
    //    }
    //
    //    /// Creates a new body with the provided async stream.
    //    /// - Parameters:
    //    ///   - stream: An async stream that provides the byte chunks.
    //    ///   - length: The total length of the body.
    //    @inlinable public convenience init(_ stream: AsyncStream<ByteChunk>, length: HTTPBody.Length) {
    //        self.init(.init(stream), length: length, iterationBehavior: .single)
    //    }
    //
    //    /// Creates a new body with the provided async sequence.
    //    /// - Parameters:
    //    ///   - sequence: An async sequence that provides the byte chunks.
    //    ///   - length: The total length of the body.
    //    ///   - iterationBehavior: The iteration behavior of the sequence, which
    //    ///     indicates whether it can be iterated multiple times.
    //    @inlinable public convenience init<Bytes: AsyncSequence>(
    //        _ sequence: Bytes,
    //        length: HTTPBody.Length,
    //        iterationBehavior: IterationBehavior
    //    ) where Bytes.Element == ByteChunk, Bytes: Sendable {
    //        self.init(.init(sequence), length: length, iterationBehavior: iterationBehavior)
    //    }
}

// MARK: - Consuming the body

extension MultipartBody: AsyncSequence {
    /// Represents a single element within an asynchronous sequence
    public typealias Element = MultipartBodyChunk
    /// Represents an asynchronous iterator over a sequence of elements.
    public typealias AsyncIterator = Iterator
    /// Creates and returns an asynchronous iterator
    ///
    /// - Returns: An asynchronous iterator for byte chunks.
    public func makeAsyncIterator() -> AsyncIterator {
        // The crash on error is intentional here.
        try! tryToMarkIteratorCreated()
        return sequence.makeAsyncIterator()
    }
}

extension MultipartBody {

    /// An error thrown by the collecting initializer when the body contains more
    /// than the maximum allowed number of bytes.
    private struct TooManyBytesError: Error, CustomStringConvertible, LocalizedError {

        /// The maximum number of bytes acceptable by the user.
        let maxBytes: Int

        var description: String { "OpenAPIRuntime.HTTPBody contains more than the maximum allowed \(maxBytes) bytes." }

        var errorDescription: String? { description }
    }

    /// An error thrown by the collecting initializer when another iteration of
    /// the body is not allowed.
    private struct TooManyIterationsError: Error, CustomStringConvertible, LocalizedError {

        var description: String {
            "OpenAPIRuntime.HTTPBody attempted to create a second iterator, but the underlying sequence is only safe to be iterated once."
        }

        var errorDescription: String? { description }
    }

    // TODO: Document
    // TODO: Discuss if it's okay or should again be an initializer on Array<BufferedMultipartPart>? (Hard to discover)
    public func collect(upTo maxBytes: Int) async throws -> [MultipartBodyChunk] {

        // Check that we're allowed to iterate again.
        try checkIfCanCreateIterator()

        // If the length is known, verify it's within the limit.
        if case .known(let knownBytes) = length {
            guard knownBytes <= maxBytes else { throw TooManyBytesError(maxBytes: maxBytes) }
        }

        // Accumulate the parts.
        // TODO: The maxBytes limit here is difficult to enforce due to headers.
        var buffer: [MultipartBodyChunk] = []
        for try await part in self { buffer.append(part) }
        return buffer
    }
}

//extension HTTPBody.ByteChunk {
//    /// Creates a byte chunk by accumulating the full body in-memory into a single buffer
//    /// up to the provided maximum number of bytes and returning it.
//    /// - Parameters:
//    ///   - body: The HTTP body to collect.
//    ///   - maxBytes: The maximum number of bytes this method is allowed
//    ///     to accumulate in memory before it throws an error.
//    /// - Throws: `TooManyBytesError` if the body contains more
//    ///   than `maxBytes`.
//    public init(collecting body: HTTPBody, upTo maxBytes: Int) async throws {
//        self = try await body.collect(upTo: maxBytes)
//    }
//}
//
//extension Array where Element == UInt8 {
//    /// Creates a byte array by accumulating the full body in-memory into a single buffer
//    /// up to the provided maximum number of bytes and returning it.
//    /// - Parameters:
//    ///   - body: The HTTP body to collect.
//    ///   - maxBytes: The maximum number of bytes this method is allowed
//    ///     to accumulate in memory before it throws an error.
//    /// - Throws: `TooManyBytesError` if the body contains more
//    ///   than `maxBytes`.
//    public init(collecting body: HTTPBody, upTo maxBytes: Int) async throws {
//        self = try await Array(body.collect(upTo: maxBytes))
//    }
//}
//
//// MARK: - String-based bodies
//
//extension HTTPBody {
//
//    /// Creates a new body with the provided string encoded as UTF-8 bytes.
//    /// - Parameters:
//    ///   - string: A string to encode as bytes.
//    ///   - length: The total length of the body.
//    @inlinable public convenience init(_ string: some StringProtocol & Sendable, length: Length) {
//        self.init(ByteChunk(string), length: length)
//    }
//
//    /// Creates a new body with the provided string encoded as UTF-8 bytes.
//    /// - Parameter string: A string to encode as bytes.
//    @inlinable public convenience init(_ string: some StringProtocol & Sendable) { self.init(ByteChunk(string)) }
//
//    /// Creates a new body with the provided async throwing stream of strings.
//    /// - Parameters:
//    ///   - stream: An async throwing stream that provides the string chunks.
//    ///   - length: The total length of the body.
//    @inlinable public convenience init(
//        _ stream: AsyncThrowingStream<some StringProtocol & Sendable, any Error & Sendable>,
//        length: HTTPBody.Length
//    ) { self.init(.init(stream.map { ByteChunk.init($0) }), length: length, iterationBehavior: .single) }
//
//    /// Creates a new body with the provided async stream of strings.
//    /// - Parameters:
//    ///   - stream: An async stream that provides the string chunks.
//    ///   - length: The total length of the body.
//    @inlinable public convenience init(_ stream: AsyncStream<some StringProtocol & Sendable>, length: HTTPBody.Length) {
//        self.init(.init(stream.map { ByteChunk.init($0) }), length: length, iterationBehavior: .single)
//    }
//
//    /// Creates a new body with the provided async sequence of string chunks.
//    /// - Parameters:
//    ///   - sequence: An async sequence that provides the string chunks.
//    ///   - length: The total length of the body.
//    ///   - iterationBehavior: The iteration behavior of the sequence, which
//    ///     indicates whether it can be iterated multiple times.
//    @inlinable public convenience init<Strings: AsyncSequence>(
//        _ sequence: Strings,
//        length: HTTPBody.Length,
//        iterationBehavior: IterationBehavior
//    ) where Strings.Element: StringProtocol & Sendable, Strings: Sendable {
//        self.init(.init(sequence.map { ByteChunk.init($0) }), length: length, iterationBehavior: iterationBehavior)
//    }
//}
//
//extension HTTPBody.ByteChunk {
//
//    /// Creates a byte chunk compatible with the `HTTPBody` type from the provided string.
//    /// - Parameter string: The string to encode.
//    @inlinable init(_ string: some StringProtocol & Sendable) { self = Array(string.utf8)[...] }
//}
//
//extension String {
//    /// Creates a string by accumulating the full body in-memory into a single buffer up to
//    /// the provided maximum number of bytes, converting it to string using UTF-8 encoding.
//    /// - Parameters:
//    ///   - body: The HTTP body to collect.
//    ///   - maxBytes: The maximum number of bytes this method is allowed
//    ///     to accumulate in memory before it throws an error.
//    /// - Throws: `TooManyBytesError` if the body contains more
//    ///   than `maxBytes`.
//    public init(collecting body: HTTPBody, upTo maxBytes: Int) async throws {
//        self = try await String(decoding: body.collect(upTo: maxBytes), as: UTF8.self)
//    }
//}
//
//// MARK: - HTTPBody conversions
//
//extension HTTPBody: ExpressibleByStringLiteral {
//    /// Initializes an `HTTPBody` instance with the provided string value.
//    ///
//    /// - Parameter value: The string literal to use for initializing the `HTTPBody`.
//    public convenience init(stringLiteral value: String) { self.init(value) }
//}
//
//extension HTTPBody {
//
//    /// Creates a new body from the provided array of bytes.
//    /// - Parameter bytes: An array of bytes.
//    @inlinable public convenience init(_ bytes: [UInt8]) { self.init(bytes[...]) }
//}
//
//extension HTTPBody: ExpressibleByArrayLiteral {
//    /// Element type for array literals.
//    public typealias ArrayLiteralElement = UInt8
//    /// Initializes an `HTTPBody` instance with a sequence of `UInt8` elements.
//    ///
//    /// - Parameter elements: A variadic list of `UInt8` elements used to initialize the `HTTPBody`.
//    public convenience init(arrayLiteral elements: UInt8...) { self.init(elements) }
//}
//
//extension HTTPBody {
//
//    /// Creates a new body from the provided data chunk.
//    /// - Parameter data: A single data chunk.
//    public convenience init(_ data: Data) { self.init(ArraySlice(data)) }
//}
//
//extension Data {
//    /// Creates a Data by accumulating the full body in-memory into a single buffer up to
//    /// the provided maximum number of bytes and converting it to `Data`.
//    /// - Parameters:
//    ///   - body: The HTTP body to collect.
//    ///   - maxBytes: The maximum number of bytes this method is allowed
//    ///     to accumulate in memory before it throws an error.
//    /// - Throws: `TooManyBytesError` if the body contains more
//    ///   than `maxBytes`.
//    public init(collecting body: HTTPBody, upTo maxBytes: Int) async throws {
//        self = try await Data(body.collect(upTo: maxBytes))
//    }
//}

// MARK: - Underlying async sequences

extension MultipartBody {

    /// An async iterator of both input async sequences and of the body itself.
    public struct Iterator: AsyncIteratorProtocol {

        /// The element byte chunk type.
        public typealias Element = MultipartBodyChunk

        /// The closure that produces the next element.
        private let produceNext: () async throws -> Element?

        /// Creates a new type-erased iterator from the provided iterator.
        /// - Parameter iterator: The iterator to type-erase.
        @usableFromInline init<Iterator: AsyncIteratorProtocol>(_ iterator: Iterator)
        where Iterator.Element == Element {
            var iterator = iterator
            self.produceNext = { try await iterator.next() }
        }

        /// Advances the iterator to the next element and returns it asynchronously.
        ///
        /// - Returns: The next element in the sequence, or `nil` if there are no more elements.
        /// - Throws: An error if there is an issue advancing the iterator or retrieving the next element.
        public mutating func next() async throws -> Element? { try await produceNext() }
    }
}

extension MultipartBody {

    /// A type-erased async sequence that wraps input sequences.
    @usableFromInline struct BodySequence: AsyncSequence, Sendable {

        /// The type of the type-erased iterator.
        @usableFromInline typealias AsyncIterator = MultipartBody.Iterator

        /// The byte chunk element type.
        @usableFromInline typealias Element = MultipartBodyChunk

        /// A closure that produces a new iterator.
        @usableFromInline let produceIterator: @Sendable () -> AsyncIterator

        /// Creates a new sequence.
        /// - Parameter sequence: The input sequence to type-erase.
        @inlinable init<Bytes: AsyncSequence>(_ sequence: Bytes) where Bytes.Element == Element, Bytes: Sendable {
            self.produceIterator = { .init(sequence.makeAsyncIterator()) }
        }

        @usableFromInline func makeAsyncIterator() -> AsyncIterator { produceIterator() }
    }

    /// An async sequence wrapper for a sync sequence.
    @usableFromInline struct WrappedSyncSequence<Bytes: Sequence>: AsyncSequence, Sendable
    where Bytes.Element == MultipartBodyChunk, Bytes.Iterator.Element == MultipartBodyChunk, Bytes: Sendable {

        /// The type of the iterator.
        @usableFromInline typealias AsyncIterator = Iterator

        /// The byte chunk element type.
        @usableFromInline typealias Element = MultipartBodyChunk

        /// An iterator type that wraps a sync sequence iterator.
        @usableFromInline struct Iterator: AsyncIteratorProtocol {

            /// The byte chunk element type.
            @usableFromInline typealias Element = MultipartBodyChunk

            /// The underlying sync sequence iterator.
            var iterator: any IteratorProtocol<Element>

            @usableFromInline mutating func next() async throws -> Element? { iterator.next() }
        }

        /// The underlying sync sequence.
        @usableFromInline let sequence: Bytes

        /// Creates a new async sequence with the provided sync sequence.
        /// - Parameter sequence: The sync sequence to wrap.
        @inlinable init(sequence: Bytes) { self.sequence = sequence }

        @usableFromInline func makeAsyncIterator() -> Iterator { Iterator(iterator: sequence.makeIterator()) }
    }

    /// An empty async sequence.
    @usableFromInline struct EmptySequence: AsyncSequence, Sendable {

        /// The type of the empty iterator.
        @usableFromInline typealias AsyncIterator = EmptyIterator

        /// The byte chunk element type.
        @usableFromInline typealias Element = MultipartBodyChunk

        /// An async iterator of an empty sequence.
        @usableFromInline struct EmptyIterator: AsyncIteratorProtocol {

            /// The byte chunk element type.
            @usableFromInline typealias Element = MultipartBodyChunk

            @usableFromInline mutating func next() async throws -> Element? { nil }
        }

        /// Creates a new empty async sequence.
        @inlinable init() {}

        @usableFromInline func makeAsyncIterator() -> EmptyIterator { EmptyIterator() }
    }
}
