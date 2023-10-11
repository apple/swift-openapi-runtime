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

/// A wrapper reference type for a value that should be copied only when
/// referenced by multiple owners and is being modified.
///
/// It also enables recursive types by introducing a "box" into the cycle, which
/// allows the owning type to have a finite size.
@_spi(Generated)
public final class CopyOnWriteBox<Wrapped> {

    /// The stored value.
    private var value: Wrapped

    /// Creates a new box.
    /// - Parameter value: The value to store in the box.
    public init(value: Wrapped) {
        self.value = value
    }

    /// Returns a copy of the stored value.
    public func read() -> Wrapped {
        value
    }

    /// Provides read-write access to the stored value and enforces
    /// copy-on-write semantics.
    /// - Parameters:
    ///   - box: A reference to the existing box, into which a new reference
    ///     might get written if a copy had to be made.
    ///   - modify: The closure that modifies the value.
    public static func write(
        to box: inout CopyOnWriteBox<Wrapped>,
        using modify: (inout Wrapped) -> Void
    ) {
        let resolvedBox: CopyOnWriteBox<Wrapped>
        if isKnownUniquelyReferenced(&box) {
            resolvedBox = box
        } else {
            resolvedBox = Self(value: box.value)
            box = resolvedBox
        }
        modify(&resolvedBox.value)
    }
}

extension CopyOnWriteBox: Encodable where Wrapped: Encodable {
    public func encode(to encoder: any Encoder) throws {
        try value.encode(to: encoder)
    }
}

extension CopyOnWriteBox: Decodable where Wrapped: Decodable {
    public convenience init(from decoder: any Decoder) throws {
        let value = try Wrapped(from: decoder)
        self.init(value: value)
    }
}

extension CopyOnWriteBox: Equatable where Wrapped: Equatable {
    public static func == (
        lhs: CopyOnWriteBox<Wrapped>,
        rhs: CopyOnWriteBox<Wrapped>
    ) -> Bool {
        lhs.value == rhs.value
    }
}

extension CopyOnWriteBox: Hashable where Wrapped: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

extension CopyOnWriteBox: CustomStringConvertible where Wrapped: CustomStringConvertible {
    public var description: String {
        value.description
    }
}

extension CopyOnWriteBox: CustomDebugStringConvertible where Wrapped: CustomDebugStringConvertible {
    public var debugDescription: String {
        value.debugDescription
    }
}

extension CopyOnWriteBox: @unchecked Sendable where Wrapped: Sendable {}
