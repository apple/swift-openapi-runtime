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

/// A type that wraps a value and enforces copy-on-write semantics.
///
/// It also enables recursive types by introducing a "box" into the cycle, which
/// allows the owning type to have a finite size.
@_spi(Generated) public struct CopyOnWriteBox<Wrapped> {

    /// The reference type storage for the box.
    @usableFromInline internal final class Storage {

        /// The stored value.
        @usableFromInline var value: Wrapped

        /// Creates a new storage with the provided initial value.
        /// - Parameter value: The initial value to store in the box.
        @usableFromInline init(value: Wrapped) { self.value = value }
    }

    /// The internal storage of the box.
    @usableFromInline internal var storage: Storage

    /// Creates a new box.
    /// - Parameter value: The value to store in the box.
    public init(value: Wrapped) { self.storage = .init(value: value) }

    /// The stored value whose accessors enforce copy-on-write semantics.
    @inlinable public var value: Wrapped {
        get { storage.value }
        _modify {
            if !isKnownUniquelyReferenced(&storage) { storage = Storage(value: storage.value) }
            yield &storage.value
        }
    }
}

@available(*, unavailable)
extension CopyOnWriteBox.Storage: Sendable {}

extension CopyOnWriteBox: Encodable where Wrapped: Encodable {

    /// Encodes this value into the given encoder.
    ///
    /// If the value fails to encode anything, `encoder` will encode an empty
    /// keyed container in its place.
    ///
    /// This function throws an error if any values are invalid for the given
    /// encoder's format.
    ///
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: On an encoding error.
    @inlinable public func encode(to encoder: any Encoder) throws { try value.encode(to: encoder) }
}

extension CopyOnWriteBox: Decodable where Wrapped: Decodable {

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// This initializer throws an error if reading from the decoder fails, or
    /// if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: On a decoding error.
    @inlinable public init(from decoder: any Decoder) throws {
        let value = try Wrapped(from: decoder)
        self.init(value: value)
    }
}

extension CopyOnWriteBox: Equatable where Wrapped: Equatable {

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    /// - Returns: A Boolean value indicating whether the values are equal.
    @inlinable public static func == (lhs: CopyOnWriteBox<Wrapped>, rhs: CopyOnWriteBox<Wrapped>) -> Bool {
        lhs.value == rhs.value
    }
}

extension CopyOnWriteBox: Hashable where Wrapped: Hashable {

    /// Hashes the essential components of this value by feeding them into the
    /// given hasher.
    ///
    /// Implement this method to conform to the `Hashable` protocol. The
    /// components used for hashing must be the same as the components compared
    /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
    /// with each of these components.
    ///
    /// - Important: In your implementation of `hash(into:)`,
    ///   don't call `finalize()` on the `hasher` instance provided,
    ///   or replace it with a different instance.
    ///   Doing so may become a compile-time error in the future.
    ///
    /// - Parameter hasher: The hasher to use when combining the components
    ///   of this instance.
    @inlinable public func hash(into hasher: inout Hasher) { hasher.combine(value) }
}

extension CopyOnWriteBox: CustomStringConvertible where Wrapped: CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    @inlinable public var description: String { value.description }
}

extension CopyOnWriteBox: CustomDebugStringConvertible where Wrapped: CustomDebugStringConvertible {

    /// A textual representation of this instance, suitable for debugging.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(reflecting:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `debugDescription` property for types that conform to
    /// `CustomDebugStringConvertible`:
    ///
    ///     struct Point: CustomDebugStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var debugDescription: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(reflecting: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `debugDescription` property.
    @inlinable public var debugDescription: String { value.debugDescription }
}

extension CopyOnWriteBox: @unchecked Sendable where Wrapped: Sendable {}
