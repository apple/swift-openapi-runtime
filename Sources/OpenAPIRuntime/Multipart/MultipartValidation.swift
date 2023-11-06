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

struct MultipartValidation: Sendable, Hashable {
    var allowsUnknownParts: Bool
    var requiredExactlyOncePartNames: Set<String>
    var requiredAtLeastOncePartNames: Set<String>
    var atMostOncePartNames: Set<String>
    var zeroOrMoreTimesPartNames: Set<String>
}

struct MultipartValidationSequence<Upstream: AsyncSequence & Sendable>: Sendable
where Upstream.Element == MultipartRawPart {
    var validation: MultipartValidation
    var upstream: Upstream
}

extension MultipartValidationSequence: AsyncSequence {
    typealias Element = MultipartRawPart
    func makeAsyncIterator() -> Iterator {
        Iterator(
            upstream: upstream.makeAsyncIterator(),
            allowsUnknownParts: validation.allowsUnknownParts,
            requiredExactlyOncePartNames: validation.requiredExactlyOncePartNames,
            requiredAtLeastOncePartNames: validation.requiredAtLeastOncePartNames,
            atMostOncePartNames: validation.atMostOncePartNames,
            zeroOrMoreTimesPartNames: validation.zeroOrMoreTimesPartNames
        )
    }
    enum ValidationError: Swift.Error, LocalizedError, CustomStringConvertible {
        case missingRequiredParts(expectedExactlyOnce: Set<String>, expectedAtLeastOnce: Set<String>)
        case receivedUnnamedPart
        case receivedUnknownPart(String)
        case receivedMultipleValuesForSingleValuePart(String)
        var description: String {
            switch self {
            case .missingRequiredParts(let expectedExactlyOnce, let expectedAtLeastOnce):
                let allSorted = expectedExactlyOnce.union(expectedAtLeastOnce).sorted()
                return "Missing required parts: \(allSorted.joined(separator: ", "))."
            case .receivedUnnamedPart:
                return
                    "Received an unnamed part, which is disallowed in the OpenAPI document using \"additionalProperties: false\"."
            case .receivedUnknownPart(let name):
                return
                    "Received an unknown part '\(name)', which is disallowed in the OpenAPI document using \"additionalProperties: false\"."
            case .receivedMultipleValuesForSingleValuePart(let name):
                return
                    "Received more than one value of the part '\(name)', but according to the OpenAPI document this part can only appear at most once."
            }
        }
        var errorDescription: String? { description }
    }
    struct Iterator: AsyncIteratorProtocol {
        var upstream: Upstream.AsyncIterator
        let allowsUnknownParts: Bool

        let exactlyOncePartNames: Set<String>
        let atLeastOncePartNames: Set<String>
        let atMostOncePartNames: Set<String>
        let zeroOrMoreTimesPartNames: Set<String>

        var remainingExactlyOncePartNames: Set<String>
        var remainingAtLeastOncePartNames: Set<String>
        var remainingAtMostOncePartNames: Set<String>

        init(
            upstream: Upstream.AsyncIterator,
            allowsUnknownParts: Bool,
            requiredExactlyOncePartNames: Set<String>,
            requiredAtLeastOncePartNames: Set<String>,
            atMostOncePartNames: Set<String>,
            zeroOrMoreTimesPartNames: Set<String>
        ) {
            self.upstream = upstream
            self.allowsUnknownParts = allowsUnknownParts
            self.exactlyOncePartNames = requiredExactlyOncePartNames
            self.atLeastOncePartNames = requiredAtLeastOncePartNames
            self.atMostOncePartNames = atMostOncePartNames
            self.zeroOrMoreTimesPartNames = zeroOrMoreTimesPartNames
            self.remainingExactlyOncePartNames = requiredExactlyOncePartNames
            self.remainingAtLeastOncePartNames = requiredAtLeastOncePartNames
            self.remainingAtMostOncePartNames = atMostOncePartNames
        }

        mutating func next() async throws -> Element? {
            // TODO: Turn this into a synchronous state machines for easier testing.

            guard let part = try await upstream.next() else {
                guard remainingExactlyOncePartNames.isEmpty && remainingAtLeastOncePartNames.isEmpty else {
                    throw ValidationError.missingRequiredParts(
                        expectedExactlyOnce: remainingExactlyOncePartNames,
                        expectedAtLeastOnce: remainingAtLeastOncePartNames
                    )
                }
                return nil
            }
            guard let name = part.name else {
                guard allowsUnknownParts else { throw ValidationError.receivedUnnamedPart }
                return part
            }
            if remainingExactlyOncePartNames.contains(name) {
                remainingExactlyOncePartNames.remove(name)
                return part
            }
            if remainingAtLeastOncePartNames.contains(name) {
                remainingAtLeastOncePartNames.remove(name)
                return part
            }
            if remainingAtMostOncePartNames.contains(name) {
                remainingAtMostOncePartNames.remove(name)
                return part
            }
            if exactlyOncePartNames.contains(name) || atMostOncePartNames.contains(name) {
                throw ValidationError.receivedMultipleValuesForSingleValuePart(name)
            }
            if atLeastOncePartNames.contains(name) { return part }
            if zeroOrMoreTimesPartNames.contains(name) { return part }
            guard allowsUnknownParts else { throw ValidationError.receivedUnknownPart(name) }
            return part
        }
    }
}
