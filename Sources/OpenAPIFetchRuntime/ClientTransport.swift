#if JavaScriptFetch
@_spi(BridgeJS) public import JavaScriptKit

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
    case options = "OPTIONS"
}
extension HTTPMethod: _BridgedSwiftEnumNoPayload, _BridgedSwiftRawValueEnum {}

public protocol ClientTransport: Sendable {
    func send(
        method: HTTPMethod,
        url: String,
        headers: consuming Headers,
        body: JSObject?
    ) async throws(ClientError) -> Response
}
#endif
