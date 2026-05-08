#if JavaScriptFetch
@_spi(BridgeJS) public import JavaScriptKit

public enum ClientError: Error {
    case transportFailure(JSException)
    case unexpectedStatus(statusCode: Int, operationID: String)
    case deserializationFailure(String)

    public func toJSException() -> JSException {
        switch self {
        case .transportFailure(let exception):
            return exception
        case .unexpectedStatus(statusCode: let code, operationID: let op):
            return JSException(message: "Unexpected status \(code) for \(op)")
        case .deserializationFailure(let detail):
            return JSException(message: "Deserialization failure: \(detail)")
        }
    }
}
#endif
