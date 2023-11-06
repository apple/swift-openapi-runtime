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

// TODO: Document
public final class OpenAPISequence<Element: Sendable>: @unchecked Sendable {
    
    /// The iteration behavior, which controls how many times
    /// the input sequence can be iterated.
    public let iterationBehavior: IterationBehavior

    /// The total length of the sequence's contents in bytes, if known.
    public let length: ByteLength

    /// The underlying type-erased async sequence.
    private let sequence: InnerSequence

    /// A lock for shared mutable state.
    private let lock: NSLock = {
        let lock = NSLock()
        lock.name = "com.apple.swift-openapi-generator.runtime.openapi-sequence"
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

    /// An error thrown by the collecting initializer when another iteration of
    /// the body is not allowed.
    private struct TooManyIterationsError: Error, CustomStringConvertible, LocalizedError {

        var description: String {
            "OpenAPIRuntime.HTTPBody attempted to create a second iterator, but the underlying sequence is only safe to be iterated once."
        }

        var errorDescription: String? { description }
    }

    /// Verifying that creating another iterator is allowed based on
    /// the values of `iterationBehavior` and `locked_iteratorCreated`.
    /// - Throws: If another iterator is not allowed to be created.
    internal func checkIfCanCreateIterator() throws {
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

    /// Creates a new sequence.
    /// - Parameters:
    ///   - sequence: The input sequence providing the byte chunks.
    ///   - length: The total length of the sequence's contents in bytes.
    ///   - iterationBehavior: The sequence's iteration behavior, which
    ///     indicates whether the sequence can be iterated multiple times.
    @usableFromInline init(_ sequence: InnerSequence, length: ByteLength, iterationBehavior: IterationBehavior) {
        self.sequence = sequence
        self.length = length
        self.iterationBehavior = iterationBehavior
    }
}

extension OpenAPISequence: Equatable {
    /// Compares two OpenAPISequence instances for equality by comparing their object identifiers.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side OpenAPISequence.
    ///   - rhs: The right-hand side OpenAPISequence.
    ///
    /// - Returns: `true` if the object identifiers of the two OpenAPISequence instances are equal,
    /// indicating that they are the same object in memory; otherwise, returns `false`.
    public static func == (lhs: OpenAPISequence, rhs: OpenAPISequence) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

extension OpenAPISequence: Hashable {
    /// Hashes the OpenAPISequence instance by combining its object identifier into the provided hasher.
    ///
    /// - Parameter hasher: The hasher used to combine the hash value.
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

// MARK: - Creating the OpenAPISequence.

extension OpenAPISequence {

    /// Creates a new empty sequence.
    @inlinable public convenience init() {
        self.init(.init(EmptySequence()), length: .known(0), iterationBehavior: .multiple)
    }
    /// Creates a new sequence with the provided async sequence.
    /// - Parameters:
    ///   - sequence: An async sequence that provides the elements.
    ///   - length: The total length of the sequence's contents in bytes.
    ///   - iterationBehavior: The iteration behavior of the sequence, which
    ///     indicates whether it can be iterated multiple times.
    @inlinable public convenience init<Input: AsyncSequence>(
        _ sequence: Input,
        length: ByteLength,
        iterationBehavior: IterationBehavior
    ) where Input.Element == Element {
        self.init(.init(sequence), length: length, iterationBehavior: iterationBehavior)
    }

    /// Creates a new sequence with the provided elements.
    /// - Parameters:
    ///   - elements: A sequence of elements.
    ///   - length: The total length of the sequence's contents in bytes.
    ///   - iterationBehavior: The iteration behavior of the sequence, which
    ///     indicates whether it can be iterated multiple times.
    @usableFromInline convenience init(
        _ elements: some Sequence<Element> & Sendable,
        length: ByteLength,
        iterationBehavior: IterationBehavior
    ) {
        self.init(.init(WrappedSyncSequence(sequence: elements)), length: length, iterationBehavior: iterationBehavior)
    }

    /// Creates a new sequence with the provided byte collection.
    /// - Parameters:
    ///   - elements: A collection of elements.
    ///   - length: The total length of the sequence's contents in bytes.
    @inlinable public convenience init(_ elements: some Collection<Element> & Sendable, length: ByteLength) {
        self.init(elements, length: length, iterationBehavior: .multiple)
    }

    /// Creates a new sequence with the provided async throwing stream.
    /// - Parameters:
    ///   - stream: An async throwing stream that provides the elements.
    ///   - length: The total length of the sequence's contents in bytes.
    @inlinable public convenience init(_ stream: AsyncThrowingStream<Element, any Error>, length: ByteLength) {
        self.init(.init(stream), length: length, iterationBehavior: .single)
    }

    /// Creates a new sequence with the provided async stream.
    /// - Parameters:
    ///   - stream: An async stream that provides the elements.
    ///   - length: The total length of the sequence's contents in bytes.
    @inlinable public convenience init(_ stream: AsyncStream<Element>, length: ByteLength) {
        self.init(.init(stream), length: length, iterationBehavior: .single)
    }
}

// MARK: - Consuming the sequence

extension OpenAPISequence: AsyncSequence {
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

// MARK: - Underlying async sequences

extension OpenAPISequence {

    /// An async iterator of both input async sequences and of the sequence itself.
    public struct Iterator: AsyncIteratorProtocol {

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

extension OpenAPISequence {

    /// A type-erased async sequence that wraps input sequences.
    @usableFromInline struct InnerSequence: AsyncSequence, Sendable {

        /// The type of the type-erased iterator.
        @usableFromInline typealias AsyncIterator = OpenAPISequence.Iterator

        /// A closure that produces a new iterator.
        @usableFromInline let produceIterator: @Sendable () -> AsyncIterator

        @usableFromInline init(produceIterator: @Sendable @escaping () -> AsyncIterator) {
            self.produceIterator = produceIterator
        }
        /// Creates a new sequence.
        /// - Parameter sequence: The input sequence to type-erase.
        @inlinable init<Input: AsyncSequence>(_ sequence: Input) where Input.Element == Element, Input: Sendable {
            self.init(produceIterator: { .init(sequence.makeAsyncIterator()) })
        }

        @usableFromInline func makeAsyncIterator() -> AsyncIterator { produceIterator() }
    }

    /// An async sequence wrapper for a sync sequence.
    @usableFromInline struct WrappedSyncSequence<Input: Sequence>: AsyncSequence, Sendable
    where Input.Element == Element, Input.Iterator.Element == Element, Input: Sendable {

        /// The type of the iterator.
        @usableFromInline typealias AsyncIterator = Iterator<Element>
        /// The type of the element.
        @usableFromInline typealias Element = Input.Element

        /// An iterator type that wraps a sync sequence iterator.
        @usableFromInline struct Iterator<IteratorElement>: AsyncIteratorProtocol {

            /// The underlying sync sequence iterator.
            var iterator: any IteratorProtocol<IteratorElement>

            @usableFromInline mutating func next() async throws -> IteratorElement? { iterator.next() }
        }

        /// The underlying sync sequence.
        @usableFromInline let sequence: Input

        /// Creates a new async sequence with the provided sync sequence.
        /// - Parameter sequence: The sync sequence to wrap.
        @usableFromInline init(sequence: Input) { self.sequence = sequence }

        @usableFromInline func makeAsyncIterator() -> AsyncIterator { Iterator(iterator: sequence.makeIterator()) }
    }

    /// An empty async sequence.
    @usableFromInline struct EmptySequence: AsyncSequence, Sendable {

        /// The type of the empty iterator.
        @usableFromInline typealias AsyncIterator = EmptyIterator

        /// An async iterator of an empty sequence.
        @usableFromInline struct EmptyIterator: AsyncIteratorProtocol {

            @usableFromInline mutating func next() async throws -> Element? { nil }
        }

        /// Creates a new empty async sequence.
        @usableFromInline init() {}

        @usableFromInline func makeAsyncIterator() -> EmptyIterator { EmptyIterator() }
    }
}
