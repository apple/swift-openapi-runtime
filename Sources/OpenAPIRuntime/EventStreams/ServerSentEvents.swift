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

/// An event sent by the server that has a JSON payload in the data field.
///
/// https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation
public struct ServerSentEventWithJSONData<JSONDataType: Sendable & Hashable>: Sendable, Hashable {

    /// A type of the event, helps inform how to interpret the data.
    public var event: String?

    /// The payload of the event.
    public var data: JSONDataType?

    /// A unique identifier of the event, can be used to resume an interrupted stream by
    /// making a new request with the `Last-Event-ID` header field set to this value.
    ///
    /// https://html.spec.whatwg.org/multipage/server-sent-events.html#the-last-event-id-header
    public var id: String?

    /// The amount of time, in milliseconds, the client should wait before reconnecting in case
    /// of an interruption.
    ///
    /// https://html.spec.whatwg.org/multipage/server-sent-events.html#the-eventsource-interface
    public var retry: Int64?

    /// Creates a new event.
    /// - Parameters:
    ///   - event: A type of the event, helps inform how to interpret the data.
    ///   - data: The payload of the event.
    ///   - id: A unique identifier of the event.
    ///   - retry: The amount of time, in milliseconds, to wait before retrying.
    public init(event: String? = nil, data: JSONDataType? = nil, id: String? = nil, retry: Int64? = nil) {
        self.event = event
        self.data = data
        self.id = id
        self.retry = retry
    }
}

/// An event sent by the server.
///
/// https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation
public struct ServerSentEvent: Sendable, Hashable {

    /// A unique identifier of the event, can be used to resume an interrupted stream by
    /// making a new request with the `Last-Event-ID` header field set to this value.
    ///
    /// https://html.spec.whatwg.org/multipage/server-sent-events.html#the-last-event-id-header
    public var id: String?

    /// A type of the event, helps inform how to interpret the data.
    public var event: String?

    /// The payload of the event.
    public var data: String?

    /// The amount of time, in milliseconds, the client should wait before reconnecting in case
    /// of an interruption.
    ///
    /// https://html.spec.whatwg.org/multipage/server-sent-events.html#the-eventsource-interface
    public var retry: Int64?

    /// Creates a new event.
    /// - Parameters:
    ///   - id: A unique identifier of the event.
    ///   - event: A type of the event, helps inform how to interpret the data.
    ///   - data: The payload of the event.
    ///   - retry: The amount of time, in milliseconds, to wait before retrying.
    public init(id: String? = nil, event: String? = nil, data: String? = nil, retry: Int64? = nil) {
        self.id = id
        self.event = event
        self.data = data
        self.retry = retry
    }
}
