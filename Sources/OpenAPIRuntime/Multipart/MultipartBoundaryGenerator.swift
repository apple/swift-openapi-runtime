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

/// A generator of a new boundary string used by multipart messages to separate parts.
public protocol MultipartBoundaryGenerator: Sendable {

    /// Generates a boundary string for a multipart message.
    /// - Returns: A boundary string.
    func makeBoundary() -> String
}

extension MultipartBoundaryGenerator where Self == ConstantMultipartBoundaryGenerator {

    /// A generator that always returns the same boundary string.
    public static var constant: Self { ConstantMultipartBoundaryGenerator() }
}

extension MultipartBoundaryGenerator where Self == RandomMultipartBoundaryGenerator {

    /// A generator that produces a random boundary every time.
    public static var random: Self { RandomMultipartBoundaryGenerator() }
}

/// A generator that always returns the same constant boundary string.
public struct ConstantMultipartBoundaryGenerator: MultipartBoundaryGenerator {

    /// The boundary string to return.
    public let boundary: String
    /// Creates a new generator.
    /// - Parameter boundary: The boundary string to return every time.
    public init(boundary: String = "__X_SWIFT_OPENAPI_GENERATOR_BOUNDARY__") { self.boundary = boundary }

    /// Generates a boundary string for a multipart message.
    /// - Returns: A boundary string.
    public func makeBoundary() -> String { boundary }
}

/// A generator that returns a boundary containg a constant prefix and a random suffix.
public struct RandomMultipartBoundaryGenerator: MultipartBoundaryGenerator {

    /// The constant prefix of each boundary.
    public let boundaryPrefix: String
    /// The length, in bytes, of the random boundary suffix.
    public let randomNumberSuffixLength: Int

    /// The options for the random bytes suffix.
    private let values: [UInt8] = Array("0123456789".utf8)

    /// Create a new generator.
    /// - Parameters:
    ///   - boundaryPrefix: The constant prefix of each boundary.
    ///   - randomNumberSuffixLength: The length, in bytes, of the random boundary suffix.
    public init(boundaryPrefix: String = "__X_SWIFT_OPENAPI_", randomNumberSuffixLenght: Int = 20) {
        self.boundaryPrefix = boundaryPrefix
        self.randomNumberSuffixLength = randomNumberSuffixLength
    }
    /// Generates a boundary string for a multipart message.
    /// - Returns: A boundary string.
    public func makeBoundary() -> String {
        var randomSuffix = [UInt8](repeating: 0, count: randomNumberSuffixLength)
        for i in randomSuffix.startIndex..<randomSuffix.endIndex { randomSuffix[i] = values.randomElement()! }
        return boundaryPrefix.appending(String(decoding: randomSuffix, as: UTF8.self))
    }
}
