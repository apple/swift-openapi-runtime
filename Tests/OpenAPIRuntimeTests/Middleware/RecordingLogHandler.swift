//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2025 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if Logging && OTelSemanticConventions

import Logging
@testable import OpenAPIRuntime

/// A log handler that records every event it is asked to emit, for asserting on the metadata
/// produced by a middleware.
///
/// `Logger` copies its handler on every metadata mutation, so the recorded events are kept in a
/// shared reference-typed sink that outlives those copies.
struct RecordingLogHandler: LogHandler {
    /// A recorded log event.
    struct Event {
        var level: Logger.Level
        var message: String
        var metadata: Logger.Metadata
        var error: (any Error)?
    }

    final class Sink: @unchecked Sendable {
        private let lock = Lock()
        private var storage: [Event] = []

        var events: [Event] { self.lock.withLock { self.storage } }

        func append(_ event: Event) { self.lock.withLock { self.storage.append(event) } }
    }

    let sink: Sink

    var logLevel: Logger.Level = .trace
    var metadata: Logger.Metadata = [:]
    var metadataProvider: Logger.MetadataProvider?

    init(sink: Sink) { self.sink = sink }

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { self.metadata[key] }
        set { self.metadata[key] = newValue }
    }

    func log(event: LogEvent) {
        self.sink.append(
            Event(
                level: event.level,
                message: "\(event.message)",
                metadata: self.metadata.merging(event.metadata ?? [:]) { _, new in new },
                error: event.error
            )
        )
    }
}

extension RecordingLogHandler.Sink {
    /// Runs `operation` with a logger that records into this sink bound as the task-local logger.
    /// - Parameters:
    ///   - logLevel: The level the recording handler is configured with.
    ///   - operation: The work to run with the recording logger bound.
    /// - Returns: The value returned by `operation`.
    /// - Throws: Whatever `operation` throws.
    func record<Result>(logLevel: Logger.Level = .trace, _ operation: nonisolated(nonsending) () async throws -> Result)
        async throws -> Result
    {
        // Only `handler:` is passed: `withLogger(logLevel:handler:)` assigns its `logLevel` to the
        // handler it is about to replace, so the level has to be carried by the handler itself.
        var handler = RecordingLogHandler(sink: self)
        handler.logLevel = logLevel
        return try await withLogger(handler: handler) { _ in try await operation() }
    }
}

#endif
