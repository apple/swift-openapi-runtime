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

/// An event sent by the server.
///
/// https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation
struct ServerSentEventWithJSONData<JSONDataType: Sendable & Hashable>: Sendable, Hashable {

    /// A type of the event, helps inform how to interpret the data.
    var event: String?

    /// The payload of the event.
    var data: JSONDataType?

    /// A unique identifier of the event, can be used to resume an interrupted stream by
    /// making a new request with the `Last-Event-ID` header field set to this value.
    ///
    /// https://html.spec.whatwg.org/multipage/server-sent-events.html#the-last-event-id-header
    var id: String?

    /// The amount of time, in milliseconds, the client should wait before reconnecting in case
    /// of an interruption.
    ///
    /// https://html.spec.whatwg.org/multipage/server-sent-events.html#the-eventsource-interface
    var retry: Int64?
}

/// An event sent by the server.
///
/// https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation
struct ServerSentEvent: Sendable, Hashable {

    /// A unique identifier of the event, can be used to resume an interrupted stream by
    /// making a new request with the `Last-Event-ID` header field set to this value.
    ///
    /// https://html.spec.whatwg.org/multipage/server-sent-events.html#the-last-event-id-header
    var id: String?

    /// A type of the event, helps inform how to interpret the data.
    var event: String?

    /// The payload of the event.
    var data: String?

    /// The amount of time, in milliseconds, the client should wait before reconnecting in case
    /// of an interruption.
    ///
    /// https://html.spec.whatwg.org/multipage/server-sent-events.html#the-eventsource-interface
    var retry: Int64?
}
