#if JavaScriptFetch
@_spi(BridgeJS) public import JavaScriptKit

@JSClass(from: .global) public struct Headers {
    @JSFunction public init() throws(JSException)
    @JSFunction public func append(_ name: String, _ value: String) throws(JSException) -> Void
    @JSFunction public func delete(_ name: String) throws(JSException) -> Void
    @JSFunction public func get(_ name: String) throws(JSException) -> Optional<String>
    @JSFunction public func has(_ name: String) throws(JSException) -> Bool
    @JSFunction public func set(_ name: String, _ value: String) throws(JSException) -> Void
}

@JSClass(from: .global) public struct Response {
    @JSGetter public var headers: Headers
    @JSGetter public var ok: Bool
    @JSGetter public var status: Double
    @JSGetter public var statusText: String
    @JSGetter public var url: String
    @JSFunction public func json() async throws(JSException) -> JSValue
    @JSFunction public func text() async throws(JSException) -> String
}

@JSFunction(from: .global) public func fetch(_ input: String, _ options: RequestInit) async throws(JSException) -> Response

@JSClass public struct RequestInit {
    @JSFunction public init(_ method: HTTPMethod, _ headers: Headers, _ body: JSObject?) throws(JSException)
}

@JSClass(from: .global) public struct URL {
    @JSFunction public init(_ path: String, _ base: String) throws(JSException)
    @JSGetter public var href: String
    @JSGetter public var searchParams: URLSearchParams
}

@JSClass(from: .global) public struct URLSearchParams {
    @JSFunction public func set(_ name: String, _ value: String) throws(JSException) -> Void
    @JSFunction public func append(_ name: String, _ value: String) throws(JSException) -> Void
    @JSFunction public func delete(_ name: String) throws(JSException) -> Void
}

@JSFunction(from: .global) public func encodeURIComponent(_ string: String) throws(JSException) -> String
#endif
