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
public import HTTPTypes

/// A raw multipart part containing the header fields and the body stream.
public struct MultipartRawPart: Sendable, Hashable {

    /// The header fields contained in this part, such as `content-disposition`.
    public var headerFields: HTTPFields

    /// The body stream of this part.
    public var body: HTTPBody

    /// Creates a new part.
    /// - Parameters:
    ///   - headerFields: The header fields contained in this part, such as `content-disposition`.
    ///   - body: The body stream of this part.
    public init(headerFields: HTTPFields, body: HTTPBody) {
        self.headerFields = headerFields
        self.body = body
    }
}

/// A wrapper of a typed part with a statically known name that adds other
/// dynamic `content-disposition` parameter values, such as `filename`.
public struct MultipartPart<Payload: Sendable & Hashable>: Sendable, Hashable {

    /// The underlying typed part payload, which has a statically known part name.
    public var payload: Payload

    /// A file name parameter provided in the `content-disposition` part header field.
    public var filename: String?

    /// Creates a new wrapper.
    /// - Parameters:
    ///   - payload: The underlying typed part payload, which has a statically known part name.
    ///   - filename: A file name parameter provided in the `content-disposition` part header field.
    public init(payload: Payload, filename: String? = nil) {
        self.payload = payload
        self.filename = filename
    }
}

/// A wrapper of a typed part without a statically known name that adds
/// dynamic `content-disposition` parameter values, such as `name` and `filename`.
public struct MultipartDynamicallyNamedPart<Payload: Sendable & Hashable>: Sendable, Hashable {

    /// The underlying typed part payload, which has a statically known part name.
    public var payload: Payload

    /// A file name parameter provided in the `content-disposition` part header field.
    public var filename: String?

    /// A name parameter provided in the `content-disposition` part header field.
    public var name: String?

    /// Creates a new wrapper.
    /// - Parameters:
    ///   - payload: The underlying typed part payload, which has a statically known part name.
    ///   - filename: A file name parameter provided in the `content-disposition` part header field.
    ///   - name: A name parameter provided in the `content-disposition` part header field.
    public init(payload: Payload, filename: String? = nil, name: String? = nil) {
        self.payload = payload
        self.filename = filename
        self.name = name
    }
}

/// The body of multipart requests and responses.
///
/// `MultipartBody` represents an async sequence of multipart parts of a specific type.
///
/// The `Part` generic type parameter is usually a generated enum representing
/// the different values documented for this multipart body.
///
/// ## Creating a body from buffered parts
///
/// Create a body from an array of values of type `Part`:
///
/// ```swift
/// let body: MultipartBody<MyPartType> = [
///     .myCaseA(...),
///     .myCaseB(...),
/// ]
/// ```
///
/// ## Creating a body from an async sequence of parts
///
/// The body type also supports initialization from an async sequence.
///
/// ```swift
/// let producingSequence = ... // an AsyncSequence of MyPartType
/// let body = MultipartBody(
///     producingSequence,
///     iterationBehavior: .single // or .multiple
/// )
/// ```
///
/// In addition to the async sequence, also specify whether the sequence is safe
/// to be iterated multiple times, or can only be iterated once.
///
/// Sequences that can be iterated multiple times work better when an HTTP
/// request needs to be retried, or if a redirect is encountered.
///
/// In addition to providing the async sequence, you can also produce the body
/// using an `AsyncStream` or `AsyncThrowingStream`:
///
/// ```swift
/// let (stream, continuation) = AsyncStream.makeStream(of: MyPartType.self)
/// // Pass the continuation to another task that produces the parts asynchronously.
/// Task {
///     continuation.yield(.myCaseA(...))
///     // ... later
///     continuation.yield(.myCaseB(...))
///     continuation.finish()
/// }
/// let body = MultipartBody(stream)
/// ```
///
/// ## Consuming a body as an async sequence
///
/// The `MultipartBody` type conforms to `AsyncSequence` and uses a generic element type,
/// so it can be consumed in a streaming fashion, without ever buffering the whole body
/// in your process.
///
/// ```swift
/// let multipartBody: MultipartBody<MyPartType> = ...
/// for try await part in multipartBody {
///    switch part {
///    case .myCaseA(let myCaseAValue):
///        // Handle myCaseAValue.
///    case .myCaseB(let myCaseBValue):
///        // Handle myCaseBValue, which is a raw type with a streaming part body.
///        //
///        // Option 1: Process the part body bytes in chunks.
///        for try await bodyChunk in myCaseBValue.body {
///            // Handle bodyChunk.
///        }
///        // Option 2: Accumulate the body into a byte array.
///        // (For other convenience initializers, check out ``HTTPBody``.
///        let fullPartBody = try await [UInt8](collecting: myCaseBValue.body, upTo: 1024)
///    // ...
///    }
/// }
/// ```
///
/// Multipart parts of different names can arrive in any order, and the order is not significant.
///
/// Consuming the multipart body should be resilient to parts of different names being reordered.
///
/// However, multiple parts of the same name, if allowed by the OpenAPI document by defining it as an array,
/// should be treated as an ordered array of values, and those cannot be reordered without changing
/// the message's meaning.
///
/// > Important: Parts that contain a raw streaming body (of type ``HTTPBody``) must
/// have their bodies fully consumed before the multipart body sequence is asked for
/// the next part. The multipart body sequence does not buffer internally, and since
/// the parts and their bodies arrive in a single stream of bytes, you cannot move on
/// to the next part until the current one is consumed.
public final class MultipartBody<Part: Sendable>: @unchecked Sendable {

    /// The iteration behavior, which controls how many times the input sequence can be iterated.
    public let iterationBehavior: IterationBehavior

    /// The underlying type-erased async sequence.
    private let sequence: AnySequence<Part>

    /// A lock for shared mutable state.
    private let lock: NSLock = {
        let lock = NSLock()
        lock.name = "com.apple.swift-openapi-generator.runtime.multipart-body"
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

        /// A textual representation of this instance.
        var description: String {
            "OpenAPIRuntime.MultipartBody attempted to create a second iterator, but the underlying sequence is only safe to be iterated once."
        }

        /// A localized message describing what error occurred.
        var errorDescription: String? { description }
    }

    /// Tries to mark an iterator as created, verifying that it is allowed based on the values
    /// of `iterationBehavior` and `locked_iteratorCreated`.
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
    ///   - sequence: The input sequence providing the parts.
    ///   - iterationBehavior: The sequence's iteration behavior, which indicates whether the sequence
    ///     can be iterated multiple times.
    @usableFromInline init(_ sequence: AnySequence<Part>, iterationBehavior: IterationBehavior) {
        self.sequence = sequence
        self.iterationBehavior = iterationBehavior
    }
}

extension MultipartBody: Equatable {

    /// Compares two OpenAPISequence instances for equality by comparing their object identifiers.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side OpenAPISequence.
    ///   - rhs: The right-hand side OpenAPISequence.
    ///
    /// - Returns: `true` if the object identifiers of the two OpenAPISequence instances are equal,
    /// indicating that they are the same object in memory; otherwise, returns `false`.
    public static func == (lhs: MultipartBody, rhs: MultipartBody) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

extension MultipartBody: Hashable {

    /// Hashes the OpenAPISequence instance by combining its object identifier into the provided hasher.
    ///
    /// - Parameter hasher: The hasher used to combine the hash value.
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

// MARK: - Creating the MultipartBody.

extension MultipartBody {

    /// Creates a new sequence with the provided async sequence of parts.
    /// - Parameters:
    ///   - sequence: An async sequence that provides the parts.
    ///   - iterationBehavior: The iteration behavior of the sequence, which indicates whether it
    ///     can be iterated multiple times.
    @inlinable public convenience init<Input: AsyncSequence & Sendable>(
        _ sequence: Input,
        iterationBehavior: IterationBehavior
    ) where Input.Element == Element { self.init(.init(sequence), iterationBehavior: iterationBehavior) }

    /// Creates a new sequence with the provided sequence parts.
    /// - Parameters:
    ///   - elements: A sequence of parts.
    ///   - iterationBehavior: The iteration behavior of the sequence, which indicates whether it
    ///     can be iterated multiple times.
    @usableFromInline convenience init(
        _ elements: some Sequence<Element> & Sendable,
        iterationBehavior: IterationBehavior
    ) { self.init(.init(WrappedSyncSequence(sequence: elements)), iterationBehavior: iterationBehavior) }

    /// Creates a new sequence with the provided collection of parts.
    /// - Parameter elements: A collection of parts.
    @inlinable public convenience init(_ elements: some Collection<Element> & Sendable) {
        self.init(elements, iterationBehavior: .multiple)
    }

    /// Creates a new sequence with the provided async throwing stream.
    /// - Parameter stream: An async throwing stream that provides the parts.
    @inlinable public convenience init(_ stream: AsyncThrowingStream<Element, any Error>) {
        self.init(.init(stream), iterationBehavior: .single)
    }

    /// Creates a new sequence with the provided async stream.
    /// - Parameter stream: An async stream that provides the parts.
    @inlinable public convenience init(_ stream: AsyncStream<Element>) {
        self.init(.init(stream), iterationBehavior: .single)
    }
}

// MARK: - Conversion from literals
extension MultipartBody: ExpressibleByArrayLiteral {

    /// The type of the elements of an array literal.
    public typealias ArrayLiteralElement = Element

    /// Creates an instance initialized with the given elements.
    public convenience init(arrayLiteral elements: Element...) { self.init(elements) }
}

// MARK: - Consuming the sequence
extension MultipartBody: AsyncSequence {

    /// The type of the element.
    public typealias Element = Part

    /// Represents an asynchronous iterator over a sequence of elements.
    public typealias AsyncIterator = Iterator

    /// Creates and returns an asynchronous iterator
    ///
    /// - Returns: An asynchronous iterator for parts.
    /// - Note: The returned sequence throws an error if no further iterations are allowed. See ``IterationBehavior``.
    public func makeAsyncIterator() -> AsyncIterator {
        do {
            try tryToMarkIteratorCreated()
            return .init(sequence.makeAsyncIterator())
        } catch { return .init(throwing: error) }
    }
}

// MARK: - Underlying async sequences
extension MultipartBody {

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

        /// Creates an iterator throwing the given error when iterated.
        /// - Parameter error: The error to throw on iteration.
        fileprivate init(throwing error: any Error) { self.produceNext = { throw error } }

        /// Advances the iterator to the next element and returns it asynchronously.
        ///
        /// - Returns: The next element in the sequence, or `nil` if there are no more elements.
        /// - Throws: An error if there is an issue advancing the iterator or retrieving the next element.
        public mutating func next() async throws -> Element? { try await produceNext() }
    }
}

@available(*, unavailable) extension MultipartBody.Iterator: Sendable {}
