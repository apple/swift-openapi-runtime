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
#if canImport(Darwin)
import Foundation
#else
@preconcurrency import Foundation
#endif

/// A protected-by-locks storage for ``redactedHeaderFields``.
private class RedactedHeadersStorage: @unchecked Sendable {
    /// The underlying storage of ``redactedHeaderFields``,
    /// protected by a lock.
    private var _locked_redactedHeaderFields: Set<String> = HeaderField.defaultRedactedHeaderFields

    /// The header fields to be redacted.
    var redactedHeaderFields: Set<String> {
        get {
            lock.lock()
            defer {
                lock.unlock()
            }
            return _locked_redactedHeaderFields
        }
        set {
            lock.lock()
            defer {
                lock.unlock()
            }
            _locked_redactedHeaderFields = newValue
        }
    }

    /// The lock used for protecting access to `_locked_redactedHeaderFields`.
    private let lock: NSLock = {
        let lock = NSLock()
        lock.name = "com.apple.swift-openapi-runtime.lock.redactedHeaderFields"
        return lock
    }()
}

extension HeaderField {
    /// Names of the header fields whose values should be redacted.
    ///
    /// All header field names are lowercased when added to the set.
    ///
    /// The values of header fields with the provided names will are replaced
    /// with "<redacted>" when using `HeaderField.description`.
    ///
    /// Use this to avoid leaking sensitive tokens into application logs.
    @available(*, deprecated, message: "This feature is deprecated and will be removed in a future version.")
    public static var redactedHeaderFields: Set<String> {
        set {
            internalRedactedHeaderFields = newValue
        }
        get {
            internalRedactedHeaderFields
        }
    }

    /// Names of the header fields whose values should be redacted.
    ///
    /// Should be called by code in the runtime library to avoid emitting a deprecation warning.
    internal static var internalRedactedHeaderFields: Set<String> {
        set {
            // Save lowercased versions of the header field names to make
            // membership checking O(1).
            redactedHeadersStorage.redactedHeaderFields = Set(newValue.map { $0.lowercased() })
        }
        get {
            return redactedHeadersStorage.redactedHeaderFields
        }
    }

    /// The default header field names whose values are redacted.
    public static let defaultRedactedHeaderFields: Set<String> = [
        "authorization",
        "cookie",
        "set-cookie",
    ]

    private static let redactedHeadersStorage = RedactedHeadersStorage()
}
