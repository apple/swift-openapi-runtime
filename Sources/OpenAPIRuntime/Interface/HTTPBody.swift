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

/// The type representing a request or response body.
public final class HTTPBody: @unchecked Sendable {

    /// The underlying data type.
    public typealias DataType = ArraySlice<UInt8>

    /// How many times the provided sequence can be iterated.
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

    /// How many times the provided sequence can be iterated.
    public let iterationBehavior: IterationBehavior

    /// The total length of the body, if known.
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

    /// Whether an iterator has already been created.
    private var locked_iteratorCreated: Bool = false

    private init(
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

    public convenience init(
        data: DataType,
        length: Length
    ) {
        self.init(
            dataChunks: [data],
            length: length
        )
    }

    public convenience init(
        data: DataType
    ) {
        self.init(
            dataChunks: [data],
            length: .known(data.count)
        )
    }

    public convenience init<S: Sequence>(
        dataChunks: S,
        length: Length,
        iterationBehavior: IterationBehavior
    ) where S.Element == DataType {
        self.init(
            sequence: .init(WrappedSyncSequence(sequence: dataChunks)),
            length: length,
            iterationBehavior: iterationBehavior
        )
    }

    public convenience init<C: Collection>(
        dataChunks: C,
        length: Length
    ) where C.Element == DataType {
        self.init(
            sequence: .init(WrappedSyncSequence(sequence: dataChunks)),
            length: length,
            iterationBehavior: .multiple
        )
    }

    public convenience init<C: Collection>(
        dataChunks: C
    ) where C.Element == DataType {
        self.init(
            sequence: .init(WrappedSyncSequence(sequence: dataChunks)),
            length: .known(dataChunks.map(\.count).reduce(0, +)),
            iterationBehavior: .multiple
        )
    }

    public convenience init(
        stream: AsyncThrowingStream<DataType, any Error>,
        length: HTTPBody.Length
    ) {
        self.init(
            sequence: .init(stream),
            length: length,
            iterationBehavior: .single
        )
    }

    public convenience init(
        stream: AsyncStream<DataType>,
        length: HTTPBody.Length
    ) {
        self.init(
            sequence: .init(stream),
            length: length,
            iterationBehavior: .single
        )
    }

    public convenience init<S: AsyncSequence>(
        sequence: S,
        length: HTTPBody.Length,
        iterationBehavior: IterationBehavior
    ) where S.Element == DataType {
        self.init(
            sequence: .init(sequence),
            length: length,
            iterationBehavior: iterationBehavior
        )
    }
}

// MARK: - Consuming the body

extension HTTPBody: AsyncSequence {
    public typealias Element = DataType
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

// MARK: - Transforming the body

extension HTTPBody {

    /// Creates a body where each chunk is transformed by the provided closure.
    /// - Parameter transform: A mapping closure.
    /// - Throws: If a known length was provided to this body at
    /// creation time, the transform closure must not change the length of
    /// each chunk.
    public func mapChunks(
        _ transform: @escaping @Sendable (Element) async -> Element
    ) -> HTTPBody {
        let validatedTransform: @Sendable (Element) async -> Element
        switch length {
        case .known:
            validatedTransform = { element in
                let transformedElement = await transform(element)
                guard transformedElement.count == element.count else {
                    fatalError(
                        "OpenAPIRuntime.HTTPBody.mapChunks transform closure attempted to change the length of a chunk in a body which has a total length specified, this is not allowed."
                    )
                }
                return transformedElement
            }
        case .unknown:
            validatedTransform = transform
        }
        return HTTPBody(
            sequence: map(validatedTransform),
            length: length,
            iterationBehavior: iterationBehavior
        )
    }
}

// MARK: - Consumption utils

extension HTTPBody {

    /// An error thrown by the `collect` function when the body contains more
    /// than the maximum allowed number of bytes.
    private struct TooManyBytesError: Error, CustomStringConvertible, LocalizedError {
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
    /// up to `maxBytes` and returns it.
    /// - Parameters:
    ///   - maxBytes: The maximum number of bytes this method is allowed
    ///     to accumulate in memory before it throws an error.
    /// - Throws: `TooManyBytesError` if the the sequence contains more
    ///   than `maxBytes`.
    public func collect(upTo maxBytes: Int) async throws -> DataType {

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

        var buffer = DataType.init()
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

extension StringProtocol {
    fileprivate var asBodyChunk: HTTPBody.DataType {
        Array(utf8)[...]
    }
}

extension HTTPBody {

    public convenience init(
        data: some StringProtocol,
        length: Length
    ) {
        self.init(
            dataChunks: [data.asBodyChunk],
            length: length
        )
    }

    public convenience init(
        data: some StringProtocol
    ) {
        self.init(
            dataChunks: [data.asBodyChunk],
            length: .known(data.count)
        )
    }

    public convenience init<S: Sequence>(
        dataChunks: S,
        length: Length,
        iterationBehavior: IterationBehavior
    ) where S.Element: StringProtocol {
        self.init(
            dataChunks: dataChunks.map(\.asBodyChunk),
            length: length,
            iterationBehavior: iterationBehavior
        )
    }

    public convenience init<C: Collection>(
        dataChunks: C,
        length: Length
    ) where C.Element: StringProtocol {
        self.init(
            dataChunks: dataChunks.map(\.asBodyChunk),
            length: length
        )
    }

    public convenience init<C: Collection>(
        dataChunks: C
    ) where C.Element: StringProtocol {
        self.init(
            dataChunks: dataChunks.map(\.asBodyChunk)
        )
    }

    public convenience init(
        stream: AsyncThrowingStream<some StringProtocol, any Error>,
        length: HTTPBody.Length
    ) {
        self.init(
            sequence: .init(stream.map(\.asBodyChunk)),
            length: length,
            iterationBehavior: .single
        )
    }

    public convenience init(
        stream: AsyncStream<some StringProtocol>,
        length: HTTPBody.Length
    ) {
        self.init(
            sequence: .init(stream.map(\.asBodyChunk)),
            length: length,
            iterationBehavior: .single
        )
    }

    public convenience init<S: AsyncSequence>(
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

extension HTTPBody {

    /// Accumulates the full body in-memory into a single buffer
    /// up to `maxBytes`, converts it to String, and returns it.
    /// - Parameters:
    ///   - maxBytes: The maximum number of bytes this method is allowed
    ///     to accumulate in memory before it throws an error.
    /// - Throws: `TooManyBytesError` if the the body contains more
    ///   than `maxBytes`.
    public func collectAsString(upTo maxBytes: Int) async throws -> String {
        let bytes: DataType = try await collect(upTo: maxBytes)
        return String(decoding: bytes, as: UTF8.self)
    }
}

// MARK: - HTTPBody conversions

extension HTTPBody: ExpressibleByStringLiteral {

    public convenience init(stringLiteral value: String) {
        self.init(data: value)
    }
}

extension HTTPBody {

    public convenience init(data: [UInt8]) {
        self.init(data: data[...])
    }
}

extension HTTPBody: ExpressibleByArrayLiteral {

    public typealias ArrayLiteralElement = UInt8

    public convenience init(arrayLiteral elements: UInt8...) {
        self.init(data: elements)
    }
}

extension HTTPBody {

    public convenience init(data: Data) {
        self.init(data: ArraySlice(data))
    }

    /// Accumulates the full body in-memory into a single buffer
    /// up to `maxBytes`, converts it to Foundation.Data, and returns it.
    /// - Parameters:
    ///   - maxBytes: The maximum number of bytes this method is allowed
    ///     to accumulate in memory before it throws an error.
    /// - Throws: `TooManyBytesError` if the the body contains more
    ///   than `maxBytes`.
    public func collectAsData(upTo maxBytes: Int) async throws -> Data {
        let bytes: DataType = try await collect(upTo: maxBytes)
        return Data(bytes)
    }
}

// MARK: - Underlying async sequences

extension HTTPBody {

    /// Async iterator of both input async sequences and of the body itself.
    public struct Iterator: AsyncIteratorProtocol {

        public typealias Element = HTTPBody.DataType

        private let produceNext: () async throws -> Element?

        init<Iterator: AsyncIteratorProtocol>(
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
    private struct BodySequence: AsyncSequence {

        typealias AsyncIterator = HTTPBody.Iterator
        typealias Element = DataType

        private let produceIterator: () -> AsyncIterator

        init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
            self.produceIterator = {
                .init(sequence.makeAsyncIterator())
            }
        }

        func makeAsyncIterator() -> AsyncIterator {
            produceIterator()
        }
    }

    /// A wrapper for a sync sequence.
    private struct WrappedSyncSequence<S: Sequence>: AsyncSequence
    where S.Element == DataType, S.Iterator.Element == DataType {

        typealias AsyncIterator = Iterator
        typealias Element = DataType

        struct Iterator: AsyncIteratorProtocol {

            typealias Element = DataType

            var iterator: any IteratorProtocol<Element>

            mutating func next() async throws -> HTTPBody.DataType? {
                iterator.next()
            }
        }

        let sequence: S

        func makeAsyncIterator() -> Iterator {
            Iterator(iterator: sequence.makeIterator())
        }
    }
}
