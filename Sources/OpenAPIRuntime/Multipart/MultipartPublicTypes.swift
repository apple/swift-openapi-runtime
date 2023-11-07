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

// MARK: - Extensions

extension MultipartRawPart {
    public init(name: String?, filename: String? = nil, headerFields: HTTPFields, body: HTTPBody) {
        var contentDisposition = ContentDisposition(dispositionType: .formData, parameters: [:])
        if let name { contentDisposition.parameters[.name] = name }
        if let filename { contentDisposition.parameters[.filename] = filename }
        var headerFields = headerFields
        headerFields[.contentDisposition] = contentDisposition.rawValue
        self.init(headerFields: headerFields, body: body)
    }
    public var name: String? {
        get {
            guard let contentDispositionString = headerFields[.contentDisposition],
                let contentDisposition = ContentDisposition(rawValue: contentDispositionString),
                let name = contentDisposition.name
            else { return nil }
            return name
        }
        set {
            guard let contentDispositionString = headerFields[.contentDisposition],
                var contentDisposition = ContentDisposition(rawValue: contentDispositionString)
            else {
                if let newValue {
                    headerFields[.contentDisposition] =
                        ContentDisposition(dispositionType: .formData, parameters: [.name: newValue]).rawValue
                }
                return
            }
            contentDisposition.name = newValue
            headerFields[.contentDisposition] = contentDisposition.rawValue
        }
    }
    public var filename: String? {
        get {
            guard let contentDispositionString = headerFields[.contentDisposition],
                let contentDisposition = ContentDisposition(rawValue: contentDispositionString),
                let filename = contentDisposition.filename
            else { return nil }
            return filename
        }
        set {
            guard let contentDispositionString = headerFields[.contentDisposition],
                var contentDisposition = ContentDisposition(rawValue: contentDispositionString)
            else {
                if let newValue {
                    headerFields[.contentDisposition] =
                        ContentDisposition(dispositionType: .formData, parameters: [.filename: newValue]).rawValue
                }
                return
            }
            contentDisposition.filename = newValue
            headerFields[.contentDisposition] = contentDisposition.rawValue
        }
    }
}

// TODO: Document
public final class MultipartBody<Part: Sendable>: @unchecked Sendable {

    /// The iteration behavior, which controls how many times
    /// the input sequence can be iterated.
    public let iterationBehavior: IterationBehavior

    /// The underlying type-erased async sequence.
    private let sequence: AnySequence<Part>

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
    ///   - sequence: The input sequence providing the parts.
    ///   - iterationBehavior: The sequence's iteration behavior, which
    ///     indicates whether the sequence can be iterated multiple times.
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

    /// Creates a new empty sequence.
    @inlinable public convenience init() { self.init(.init(EmptySequence()), iterationBehavior: .multiple) }
    /// Creates a new sequence with the provided async sequence.
    /// - Parameters:
    ///   - sequence: An async sequence that provides the elements.
    ///   - iterationBehavior: The iteration behavior of the sequence, which
    ///     indicates whether it can be iterated multiple times.
    @inlinable public convenience init<Input: AsyncSequence>(_ sequence: Input, iterationBehavior: IterationBehavior)
    where Input.Element == Element { self.init(.init(sequence), iterationBehavior: iterationBehavior) }

    /// Creates a new sequence with the provided elements.
    /// - Parameters:
    ///   - elements: A sequence of elements.
    ///   - iterationBehavior: The iteration behavior of the sequence, which
    ///     indicates whether it can be iterated multiple times.
    @usableFromInline convenience init(
        _ elements: some Sequence<Element> & Sendable,
        iterationBehavior: IterationBehavior
    ) { self.init(.init(WrappedSyncSequence(sequence: elements)), iterationBehavior: iterationBehavior) }

    /// Creates a new sequence with the provided byte collection.
    /// - Parameters:
    ///   - elements: A collection of elements.
    @inlinable public convenience init(_ elements: some Collection<Element> & Sendable) {
        self.init(elements, iterationBehavior: .multiple)
    }

    /// Creates a new sequence with the provided async throwing stream.
    /// - Parameters:
    ///   - stream: An async throwing stream that provides the elements.
    @inlinable public convenience init(_ stream: AsyncThrowingStream<Element, any Error>) {
        self.init(.init(stream), iterationBehavior: .single)
    }

    /// Creates a new sequence with the provided async stream.
    /// - Parameters:
    ///   - stream: An async stream that provides the elements.
    @inlinable public convenience init(_ stream: AsyncStream<Element>) {
        self.init(.init(stream), iterationBehavior: .single)
    }
}

// MARK: - Conversion from literals

extension MultipartBody: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = Element
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
    public func makeAsyncIterator() -> AsyncIterator {
        // The crash on error is intentional here.
        try! tryToMarkIteratorCreated()
        return .init(sequence.makeAsyncIterator())
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

        /// Advances the iterator to the next element and returns it asynchronously.
        ///
        /// - Returns: The next element in the sequence, or `nil` if there are no more elements.
        /// - Throws: An error if there is an issue advancing the iterator or retrieving the next element.
        public mutating func next() async throws -> Element? { try await produceNext() }
    }
}
