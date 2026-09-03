#if JavaScriptFetch
@_spi(BridgeJS) public import JavaScriptKit

public struct FetchTransport: ClientTransport, Sendable {
    public init() {}

    public func send(
        method: HTTPMethod,
        url: String,
        headers: consuming Headers,
        body: JSObject?
    ) async throws(ClientError) -> Response {
        do {
            let requestInit = try RequestInit(method, headers, body)
            return try await fetch(url, requestInit)
        } catch {
            throw .transportFailure(error)
        }
    }
}
#endif
