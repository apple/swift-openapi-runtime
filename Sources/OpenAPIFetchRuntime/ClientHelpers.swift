#if JavaScriptFetch
@_spi(BridgeJS) public import JavaScriptKit

public func makeHeaders(contentType: String? = nil) throws(ClientError) -> Headers {
    do {
        let h = try Headers()
        if let contentType { try h.set("Content-Type", contentType) }
        return h
    } catch {
        throw .transportFailure(error)
    }
}

public func checkOk(_ response: Response, operationID: String) throws(ClientError) {
    let ok: Bool
    let status: Double
    do {
        ok = try response.ok
        status = try response.status
    } catch {
        throw .transportFailure(error)
    }
    if !ok {
        throw .unexpectedStatus(statusCode: Int(status), operationID: operationID)
    }
}

public func deserialize<T: _JSBridgedClass>(_ response: Response) async throws(ClientError) -> T {
    let jsValue: JSValue
    do {
        jsValue = try await response.json()
    } catch {
        throw .transportFailure(error)
    }
    guard let object = jsValue.object else {
        throw .deserializationFailure("Expected JS object for deserialization")
    }
    return T(unsafelyWrapping: object)
}

public func deserializeArray<T: _JSBridgedClass>(_ response: Response) async throws(ClientError) -> [T] {
    let jsValue: JSValue
    do {
        jsValue = try await response.json()
    } catch {
        throw .transportFailure(error)
    }
    guard let object = jsValue.object else {
        throw .deserializationFailure("Expected JS object for array deserialization")
    }
    guard let jsArray = JSArray(object) else {
        throw .deserializationFailure("Expected JS Array, got non-array object")
    }
    var result: [T] = []
    for element in jsArray {
        guard let object = element.object else {
            throw .deserializationFailure("Expected JS object in array element")
        }
        result.append(T(unsafelyWrapping: object))
    }
    return result
}

public func deserializeOneOf(
    _ response: Response,
    discriminatorProperty: String
) async throws(ClientError) -> (String, JSObject) {
    let jsValue: JSValue
    do {
        jsValue = try await response.json()
    } catch {
        throw .transportFailure(error)
    }
    guard let object = jsValue.object else {
        throw .deserializationFailure("Expected JS object for oneOf response")
    }
    let discriminatorJSValue = object[discriminatorProperty]
    guard let stringValue = discriminatorJSValue.string else {
        throw .deserializationFailure("Discriminator property is not a string")
    }
    return (stringValue, object)
}

public func appendQueryParam(_ url: String, name: String, value: String) throws(ClientError) -> String {
    let encodedName: String
    let encodedValue: String
    do {
        encodedName = try encodeURIComponent(name)
        encodedValue = try encodeURIComponent(value)
    } catch {
        throw .transportFailure(error)
    }
    let separator = url.contains("?") ? "&" : "?"
    return url + separator + encodedName + "=" + encodedValue
}
#endif
