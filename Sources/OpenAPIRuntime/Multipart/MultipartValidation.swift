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

import HTTPTypes
import Foundation

/// A container for multipart body requirements.
struct MultipartBodyRequirements: Sendable, Hashable {

    /// A Boolean value indicating whether unknown part names are allowed.
    var allowsUnknownParts: Bool

    /// A set of known part names that must appear exactly once.
    var requiredExactlyOncePartNames: Set<String>

    /// A set of known part names that must appear at least once.
    var requiredAtLeastOncePartNames: Set<String>

    /// A set of known part names that can appear at most once.
    var atMostOncePartNames: Set<String>

    /// A set of known part names that can appear any number of times.
    var zeroOrMoreTimesPartNames: Set<String>
}

/// A sequence that validates that the raw parts passing through the sequence match the provided semantics.
struct MultipartValidationSequence<Upstream: AsyncSequence & Sendable>: Sendable
where Upstream.Element == MultipartRawPart {

    /// The source of raw parts.
    var upstream: Upstream

    /// The requirements to enforce.
    var requirements: MultipartBodyRequirements
}

extension MultipartValidationSequence: AsyncSequence {

    /// The type of element produced by this asynchronous sequence.
    typealias Element = MultipartRawPart

    /// Creates the asynchronous iterator that produces elements of this
    /// asynchronous sequence.
    ///
    /// - Returns: An instance of the `AsyncIterator` type used to produce
    /// elements of the asynchronous sequence.
    func makeAsyncIterator() -> Iterator {
        Iterator(upstream: upstream.makeAsyncIterator(), requirements: requirements)
    }

    /// An iterator that pulls raw parts from the upstream iterator and validates their semantics.
    struct Iterator: AsyncIteratorProtocol {

        /// The iterator that provides the raw parts.
        var upstream: Upstream.AsyncIterator

        /// The underlying requirements validator.
        var validator: Validator

        /// Creates a new iterator.
        /// - Parameters:
        ///   - upstream: The iterator that provides the raw parts.
        ///   - requirements: The requirements to enforce.
        init(upstream: Upstream.AsyncIterator, requirements: MultipartBodyRequirements) {
            self.upstream = upstream
            self.validator = .init(requirements: requirements)
        }

        /// Asynchronously advances to the next element and returns it, or ends the
        /// sequence if there is no next element.
        ///
        /// - Returns: The next element, if it exists, or `nil` to signal the end of
        ///   the sequence.
        mutating func next() async throws -> Element? { try await validator.next(upstream.next()) }
    }
}

extension MultipartValidationSequence {

    /// A state machine representing the validator.
    struct StateMachine {

        /// The state of the state machine.
        struct State: Hashable {

            /// A Boolean value indicating whether unknown part names are allowed.
            let allowsUnknownParts: Bool

            /// A set of known part names that must appear exactly once.
            let exactlyOncePartNames: Set<String>

            /// A set of known part names that must appear at least once.
            let atLeastOncePartNames: Set<String>

            /// A set of known part names that can appear at most once.
            let atMostOncePartNames: Set<String>

            /// A set of known part names that can appear any number of times.
            let zeroOrMoreTimesPartNames: Set<String>

            /// The remaining part names that must appear exactly once.
            var remainingExactlyOncePartNames: Set<String>

            /// The remaining part names that must appear at least once.
            var remainingAtLeastOncePartNames: Set<String>

            /// The remaining part names that can appear at most once.
            var remainingAtMostOncePartNames: Set<String>
        }

        /// The current state of the state machine.
        private(set) var state: State

        /// Creates a new state machine.
        /// - Parameters:
        ///   - allowsUnknownParts: A Boolean value indicating whether unknown part names are allowed.
        ///   - requiredExactlyOncePartNames: A set of known part names that must appear exactly once.
        ///   - requiredAtLeastOncePartNames: A set of known part names that must appear at least once.
        ///   - atMostOncePartNames: A set of known part names that can appear at most once.
        ///   - zeroOrMoreTimesPartNames: A set of known part names that can appear any number of times.
        init(
            allowsUnknownParts: Bool,
            requiredExactlyOncePartNames: Set<String>,
            requiredAtLeastOncePartNames: Set<String>,
            atMostOncePartNames: Set<String>,
            zeroOrMoreTimesPartNames: Set<String>
        ) {
            self.state = .init(
                allowsUnknownParts: allowsUnknownParts,
                exactlyOncePartNames: requiredExactlyOncePartNames,
                atLeastOncePartNames: requiredAtLeastOncePartNames,
                atMostOncePartNames: atMostOncePartNames,
                zeroOrMoreTimesPartNames: zeroOrMoreTimesPartNames,
                remainingExactlyOncePartNames: requiredExactlyOncePartNames,
                remainingAtLeastOncePartNames: requiredAtLeastOncePartNames,
                remainingAtMostOncePartNames: atMostOncePartNames
            )
        }

        /// An error returned by the state machine.
        enum ActionError: Hashable {

            /// The sequence finished without encountering at least one required part.
            case missingRequiredParts(expectedExactlyOnce: Set<String>, expectedAtLeastOnce: Set<String>)

            /// The validator encountered a part without a name, but `allowsUnknownParts` is set to `false`.
            case receivedUnnamedPart

            /// The validator encountered a part with an unknown name, but `allowsUnknownParts` is set to `false`.
            case receivedUnknownPart(String)

            /// The validator encountered a repeated part of the provided name, even though the part
            /// is only allowed to appear at most once.
            case receivedMultipleValuesForSingleValuePart(String)
        }

        /// An action returned by the `next` method.
        enum NextAction: Hashable {

            /// Return nil to the caller, no more parts.
            case returnNil

            /// Fetch the next part.
            case emitError(ActionError)

            /// Return the part to the caller.
            case emitPart(MultipartRawPart)
        }

        /// Read the next part from the upstream and validate it.
        /// - Returns: An action to perform.
        mutating func next(_ part: MultipartRawPart?) -> NextAction {
            guard let part else {
                guard state.remainingExactlyOncePartNames.isEmpty && state.remainingAtLeastOncePartNames.isEmpty else {
                    return .emitError(
                        .missingRequiredParts(
                            expectedExactlyOnce: state.remainingExactlyOncePartNames,
                            expectedAtLeastOnce: state.remainingAtLeastOncePartNames
                        )
                    )
                }
                return .returnNil
            }
            guard let name = part.name else {
                guard state.allowsUnknownParts else { return .emitError(.receivedUnnamedPart) }
                return .emitPart(part)
            }
            if state.remainingExactlyOncePartNames.contains(name) {
                state.remainingExactlyOncePartNames.remove(name)
                return .emitPart(part)
            }
            if state.remainingAtLeastOncePartNames.contains(name) {
                state.remainingAtLeastOncePartNames.remove(name)
                return .emitPart(part)
            }
            if state.remainingAtMostOncePartNames.contains(name) {
                state.remainingAtMostOncePartNames.remove(name)
                return .emitPart(part)
            }
            if state.exactlyOncePartNames.contains(name) || state.atMostOncePartNames.contains(name) {
                return .emitError(.receivedMultipleValuesForSingleValuePart(name))
            }
            if state.atLeastOncePartNames.contains(name) { return .emitPart(part) }
            if state.zeroOrMoreTimesPartNames.contains(name) { return .emitPart(part) }
            guard state.allowsUnknownParts else { return .emitError(.receivedUnknownPart(name)) }
            return .emitPart(part)
        }
    }
}

extension MultipartValidationSequence {

    /// A validator of multipart raw parts.
    struct Validator {

        /// The underlying state machine.
        private var stateMachine: StateMachine
        /// Creates a new validator.
        /// - Parameter requirements: The requirements to validate.
        init(requirements: MultipartBodyRequirements) {
            self.stateMachine = .init(
                allowsUnknownParts: requirements.allowsUnknownParts,
                requiredExactlyOncePartNames: requirements.requiredExactlyOncePartNames,
                requiredAtLeastOncePartNames: requirements.requiredAtLeastOncePartNames,
                atMostOncePartNames: requirements.atMostOncePartNames,
                zeroOrMoreTimesPartNames: requirements.zeroOrMoreTimesPartNames
            )
        }

        /// Ingests the next part.
        /// - Parameter part: A part provided by the upstream sequence. Nil if the sequence is finished.
        /// - Returns: The validated part. Nil if the incoming part was nil.
        /// - Throws: When a validation error is encountered.
        mutating func next(_ part: MultipartRawPart?) async throws -> MultipartRawPart? {
            switch stateMachine.next(part) {
            case .returnNil: return nil
            case .emitPart(let outPart): return outPart
            case .emitError(let error): throw ValidatorError(error: error)
            }
        }
    }
}

extension MultipartValidationSequence {

    /// An error thrown by the validator.
    struct ValidatorError: Swift.Error, LocalizedError, CustomStringConvertible {

        /// The underlying error emitted by the state machine.
        var error: StateMachine.ActionError

        var description: String {
            switch error {
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
}
