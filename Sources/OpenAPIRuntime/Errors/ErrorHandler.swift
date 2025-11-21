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

// MARK: - Client Error Handler

/// A protocol for observing and logging errors that occur during client operations.
///
/// Implement this protocol to add logging, monitoring, or analytics for client-side errors.
/// This handler is called after the error has been wrapped in a ``ClientError``, providing
/// full context about the operation and the error.
///
/// - Note: This handler should not throw or modify the error. Its purpose is observation only.
public protocol ClientErrorHandler: Sendable {
    /// Called when a client error occurs, after it has been wrapped in a ``ClientError``.
    ///
    /// Use this method to log, monitor, or send analytics about the error. The error
    /// will be thrown to the caller after this method returns.
    ///
    /// - Parameter error: The ``ClientError`` that will be thrown to the caller.
    func handleClientError(_ error: ClientError)
}


// MARK: - Server Error Handler

/// A protocol for observing and logging errors that occur during server operations.
///
/// Implement this protocol to add logging, monitoring, or analytics for server-side errors.
/// This handler is called after the error has been wrapped in a ``ServerError``, providing
/// full context about the operation and the HTTP response that will be sent.
///
/// - Note: This handler should not throw or modify the error. Its purpose is observation only.
public protocol ServerErrorHandler: Sendable {
    /// Called when a server error occurs, after it has been wrapped in a ``ServerError``.
    ///
    /// Use this method to log, monitor, or send analytics about the error. The error
    /// will be thrown to the error handling middleware after this method returns.
    ///
    /// - Parameter error: The ``ServerError`` that will be thrown to the middleware.
    func handleServerError(_ error: ServerError)
}
