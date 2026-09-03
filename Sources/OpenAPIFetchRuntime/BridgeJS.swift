#if JavaScriptFetch
// bridge-js: skip
// NOTICE: This is auto-generated code by BridgeJS from JavaScriptKit,
// DO NOT EDIT.
//
// To update this file, just rebuild your project or run
// `swift package bridge-js`.

@_spi(BridgeJS) public import JavaScriptKit

#if arch(wasm32)
@_extern(wasm, module: "bjs", name: "invoke_js_callback_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes7JSValueV_y")
fileprivate func invoke_js_callback_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes7JSValueV_y_extern(_ callback: Int32, _ param0Kind: Int32, _ param0Payload1: Int32, _ param0Payload2: Float64) -> Void
#else
fileprivate func invoke_js_callback_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes7JSValueV_y_extern(_ callback: Int32, _ param0Kind: Int32, _ param0Payload1: Int32, _ param0Payload2: Float64) -> Void {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func invoke_js_callback_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes7JSValueV_y(_ callback: Int32, _ param0Kind: Int32, _ param0Payload1: Int32, _ param0Payload2: Float64) -> Void {
    return invoke_js_callback_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes7JSValueV_y_extern(callback, param0Kind, param0Payload1, param0Payload2)
}

#if arch(wasm32)
@_extern(wasm, module: "bjs", name: "make_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes7JSValueV_y")
fileprivate func make_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes7JSValueV_y_extern(_ boxPtr: UnsafeMutableRawPointer, _ file: UnsafePointer<UInt8>, _ line: UInt32) -> Int32
#else
fileprivate func make_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes7JSValueV_y_extern(_ boxPtr: UnsafeMutableRawPointer, _ file: UnsafePointer<UInt8>, _ line: UInt32) -> Int32 {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func make_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes7JSValueV_y(_ boxPtr: UnsafeMutableRawPointer, _ file: UnsafePointer<UInt8>, _ line: UInt32) -> Int32 {
    return make_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes7JSValueV_y_extern(boxPtr, file, line)
}

private enum _BJS_Closure_19OpenAPIFetchRuntimes7JSValueV_y {
    static func bridgeJSLift(_ callbackId: Int32) -> (sending JSValue) -> Void {
        let callback = JSObject.bridgeJSLiftParameter(callbackId)
        return { [callback] param0 in
            #if arch(wasm32)
            let callbackValue = callback.bridgeJSLowerParameter()
            let (param0Kind, param0Payload1, param0Payload2) = param0.bridgeJSLowerParameter()
            invoke_js_callback_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes7JSValueV_y(callbackValue, param0Kind, param0Payload1, param0Payload2)
            #else
            fatalError("Only available on WebAssembly")
            #endif
        }
    }
}

extension JSTypedClosure where Signature == (sending JSValue) -> Void {
    init(fileID: StaticString = #fileID, line: UInt32 = #line, _ body: @escaping (sending JSValue) -> Void) {
        self.init(
            makeClosure: make_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes7JSValueV_y,
            body: body,
            fileID: fileID,
            line: line
        )
    }
}

@_expose(wasm, "invoke_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes7JSValueV_y")
@_cdecl("invoke_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes7JSValueV_y")
public func _invoke_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes7JSValueV_y(_ boxPtr: UnsafeMutableRawPointer, _ param0Kind: Int32, _ param0Payload1: Int32, _ param0Payload2: Float64) -> Void {
    #if arch(wasm32)
    let closure = Unmanaged<_BridgeJSTypedClosureBox<(sending JSValue) -> Void>>.fromOpaque(boxPtr).takeUnretainedValue().closure
    closure(JSValue.bridgeJSLiftParameter(param0Kind, param0Payload1, param0Payload2))
    #else
    fatalError("Only available on WebAssembly")
    #endif
}

#if arch(wasm32)
@_extern(wasm, module: "bjs", name: "invoke_js_callback_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes8ResponseC_y")
fileprivate func invoke_js_callback_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes8ResponseC_y_extern(_ callback: Int32, _ param0: Int32) -> Void
#else
fileprivate func invoke_js_callback_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes8ResponseC_y_extern(_ callback: Int32, _ param0: Int32) -> Void {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func invoke_js_callback_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes8ResponseC_y(_ callback: Int32, _ param0: Int32) -> Void {
    return invoke_js_callback_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes8ResponseC_y_extern(callback, param0)
}

#if arch(wasm32)
@_extern(wasm, module: "bjs", name: "make_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes8ResponseC_y")
fileprivate func make_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes8ResponseC_y_extern(_ boxPtr: UnsafeMutableRawPointer, _ file: UnsafePointer<UInt8>, _ line: UInt32) -> Int32
#else
fileprivate func make_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes8ResponseC_y_extern(_ boxPtr: UnsafeMutableRawPointer, _ file: UnsafePointer<UInt8>, _ line: UInt32) -> Int32 {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func make_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes8ResponseC_y(_ boxPtr: UnsafeMutableRawPointer, _ file: UnsafePointer<UInt8>, _ line: UInt32) -> Int32 {
    return make_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes8ResponseC_y_extern(boxPtr, file, line)
}

private enum _BJS_Closure_19OpenAPIFetchRuntimes8ResponseC_y {
    static func bridgeJSLift(_ callbackId: Int32) -> (sending Response) -> Void {
        let callback = JSObject.bridgeJSLiftParameter(callbackId)
        return { [callback] param0 in
            #if arch(wasm32)
            let callbackValue = callback.bridgeJSLowerParameter()
            let param0Value = param0.bridgeJSLowerParameter()
            invoke_js_callback_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes8ResponseC_y(callbackValue, param0Value)
            #else
            fatalError("Only available on WebAssembly")
            #endif
        }
    }
}

extension JSTypedClosure where Signature == (sending Response) -> Void {
    init(fileID: StaticString = #fileID, line: UInt32 = #line, _ body: @escaping (sending Response) -> Void) {
        self.init(
            makeClosure: make_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes8ResponseC_y,
            body: body,
            fileID: fileID,
            line: line
        )
    }
}

@_expose(wasm, "invoke_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes8ResponseC_y")
@_cdecl("invoke_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes8ResponseC_y")
public func _invoke_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimes8ResponseC_y(_ boxPtr: UnsafeMutableRawPointer, _ param0: Int32) -> Void {
    #if arch(wasm32)
    let closure = Unmanaged<_BridgeJSTypedClosureBox<(sending Response) -> Void>>.fromOpaque(boxPtr).takeUnretainedValue().closure
    closure(Response.bridgeJSLiftParameter(param0))
    #else
    fatalError("Only available on WebAssembly")
    #endif
}

#if arch(wasm32)
@_extern(wasm, module: "bjs", name: "invoke_js_callback_OpenAPIFetchRuntime_19OpenAPIFetchRuntimesSS_y")
fileprivate func invoke_js_callback_OpenAPIFetchRuntime_19OpenAPIFetchRuntimesSS_y_extern(_ callback: Int32, _ param0Bytes: Int32, _ param0Length: Int32) -> Void
#else
fileprivate func invoke_js_callback_OpenAPIFetchRuntime_19OpenAPIFetchRuntimesSS_y_extern(_ callback: Int32, _ param0Bytes: Int32, _ param0Length: Int32) -> Void {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func invoke_js_callback_OpenAPIFetchRuntime_19OpenAPIFetchRuntimesSS_y(_ callback: Int32, _ param0Bytes: Int32, _ param0Length: Int32) -> Void {
    return invoke_js_callback_OpenAPIFetchRuntime_19OpenAPIFetchRuntimesSS_y_extern(callback, param0Bytes, param0Length)
}

#if arch(wasm32)
@_extern(wasm, module: "bjs", name: "make_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimesSS_y")
fileprivate func make_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimesSS_y_extern(_ boxPtr: UnsafeMutableRawPointer, _ file: UnsafePointer<UInt8>, _ line: UInt32) -> Int32
#else
fileprivate func make_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimesSS_y_extern(_ boxPtr: UnsafeMutableRawPointer, _ file: UnsafePointer<UInt8>, _ line: UInt32) -> Int32 {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func make_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimesSS_y(_ boxPtr: UnsafeMutableRawPointer, _ file: UnsafePointer<UInt8>, _ line: UInt32) -> Int32 {
    return make_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimesSS_y_extern(boxPtr, file, line)
}

private enum _BJS_Closure_19OpenAPIFetchRuntimesSS_y {
    static func bridgeJSLift(_ callbackId: Int32) -> (sending String) -> Void {
        let callback = JSObject.bridgeJSLiftParameter(callbackId)
        return { [callback] param0 in
            #if arch(wasm32)
            let callbackValue = callback.bridgeJSLowerParameter()
            param0.bridgeJSWithLoweredParameter { (param0Bytes, param0Length) in
                invoke_js_callback_OpenAPIFetchRuntime_19OpenAPIFetchRuntimesSS_y(callbackValue, param0Bytes, param0Length)
            }
            #else
            fatalError("Only available on WebAssembly")
            #endif
        }
    }
}

extension JSTypedClosure where Signature == (sending String) -> Void {
    init(fileID: StaticString = #fileID, line: UInt32 = #line, _ body: @escaping (sending String) -> Void) {
        self.init(
            makeClosure: make_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimesSS_y,
            body: body,
            fileID: fileID,
            line: line
        )
    }
}

@_expose(wasm, "invoke_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimesSS_y")
@_cdecl("invoke_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimesSS_y")
public func _invoke_swift_closure_OpenAPIFetchRuntime_19OpenAPIFetchRuntimesSS_y(_ boxPtr: UnsafeMutableRawPointer, _ param0Bytes: Int32, _ param0Length: Int32) -> Void {
    #if arch(wasm32)
    let closure = Unmanaged<_BridgeJSTypedClosureBox<(sending String) -> Void>>.fromOpaque(boxPtr).takeUnretainedValue().closure
    closure(String.bridgeJSLiftParameter(param0Bytes, param0Length))
    #else
    fatalError("Only available on WebAssembly")
    #endif
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_fetch")
fileprivate func bjs_fetch_extern(_ resolveRef: Int32, _ rejectRef: Int32, _ inputBytes: Int32, _ inputLength: Int32, _ options: Int32) -> Void
#else
fileprivate func bjs_fetch_extern(_ resolveRef: Int32, _ rejectRef: Int32, _ inputBytes: Int32, _ inputLength: Int32, _ options: Int32) -> Void {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_fetch(_ resolveRef: Int32, _ rejectRef: Int32, _ inputBytes: Int32, _ inputLength: Int32, _ options: Int32) -> Void {
    return bjs_fetch_extern(resolveRef, rejectRef, inputBytes, inputLength, options)
}

func _$fetch(_ input: String, _ options: RequestInit) async throws(JSException) -> Response {
    let resolved = try await _bjs_awaitPromise(makeResolveClosure: {
            JSTypedClosure<(sending Response) -> Void>($0)
        }, makeRejectClosure: {
            JSTypedClosure<(sending JSValue) -> Void>($0)
        }) { resolveRef, rejectRef in
        input.bridgeJSWithLoweredParameter { (inputBytes, inputLength) in
            let optionsValue = options.bridgeJSLowerParameter()
            bjs_fetch(resolveRef, rejectRef, inputBytes, inputLength, optionsValue)
        }
    }
    return resolved
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_encodeURIComponent")
fileprivate func bjs_encodeURIComponent_extern(_ stringBytes: Int32, _ stringLength: Int32) -> Int32
#else
fileprivate func bjs_encodeURIComponent_extern(_ stringBytes: Int32, _ stringLength: Int32) -> Int32 {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_encodeURIComponent(_ stringBytes: Int32, _ stringLength: Int32) -> Int32 {
    return bjs_encodeURIComponent_extern(stringBytes, stringLength)
}

func _$encodeURIComponent(_ string: String) throws(JSException) -> String {
    let ret0 = string.bridgeJSWithLoweredParameter { (stringBytes, stringLength) in
        let ret = bjs_encodeURIComponent(stringBytes, stringLength)
        return ret
    }
    let ret = ret0
    if let error = _swift_js_take_exception() {
        throw error
    }
    return String.bridgeJSLiftReturn(ret)
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_Headers_init")
fileprivate func bjs_Headers_init_extern() -> Int32
#else
fileprivate func bjs_Headers_init_extern() -> Int32 {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_Headers_init() -> Int32 {
    return bjs_Headers_init_extern()
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_Headers_append")
fileprivate func bjs_Headers_append_extern(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32, _ valueBytes: Int32, _ valueLength: Int32) -> Void
#else
fileprivate func bjs_Headers_append_extern(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32, _ valueBytes: Int32, _ valueLength: Int32) -> Void {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_Headers_append(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32, _ valueBytes: Int32, _ valueLength: Int32) -> Void {
    return bjs_Headers_append_extern(self, nameBytes, nameLength, valueBytes, valueLength)
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_Headers_delete")
fileprivate func bjs_Headers_delete_extern(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32) -> Void
#else
fileprivate func bjs_Headers_delete_extern(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32) -> Void {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_Headers_delete(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32) -> Void {
    return bjs_Headers_delete_extern(self, nameBytes, nameLength)
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_Headers_get")
fileprivate func bjs_Headers_get_extern(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32) -> Void
#else
fileprivate func bjs_Headers_get_extern(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32) -> Void {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_Headers_get(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32) -> Void {
    return bjs_Headers_get_extern(self, nameBytes, nameLength)
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_Headers_has")
fileprivate func bjs_Headers_has_extern(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32) -> Int32
#else
fileprivate func bjs_Headers_has_extern(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32) -> Int32 {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_Headers_has(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32) -> Int32 {
    return bjs_Headers_has_extern(self, nameBytes, nameLength)
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_Headers_set")
fileprivate func bjs_Headers_set_extern(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32, _ valueBytes: Int32, _ valueLength: Int32) -> Void
#else
fileprivate func bjs_Headers_set_extern(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32, _ valueBytes: Int32, _ valueLength: Int32) -> Void {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_Headers_set(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32, _ valueBytes: Int32, _ valueLength: Int32) -> Void {
    return bjs_Headers_set_extern(self, nameBytes, nameLength, valueBytes, valueLength)
}

func _$Headers_init() throws(JSException) -> JSObject {
    let ret = bjs_Headers_init()
    if let error = _swift_js_take_exception() {
        throw error
    }
    return JSObject.bridgeJSLiftReturn(ret)
}

func _$Headers_append(_ self: JSObject, _ name: String, _ value: String) throws(JSException) -> Void {
    let selfValue = self.bridgeJSLowerParameter()
    name.bridgeJSWithLoweredParameter { (nameBytes, nameLength) in
        value.bridgeJSWithLoweredParameter { (valueBytes, valueLength) in
            bjs_Headers_append(selfValue, nameBytes, nameLength, valueBytes, valueLength)
        }
    }
    if let error = _swift_js_take_exception() {
        throw error
    }
}

func _$Headers_delete(_ self: JSObject, _ name: String) throws(JSException) -> Void {
    let selfValue = self.bridgeJSLowerParameter()
    name.bridgeJSWithLoweredParameter { (nameBytes, nameLength) in
        bjs_Headers_delete(selfValue, nameBytes, nameLength)
    }
    if let error = _swift_js_take_exception() {
        throw error
    }
}

func _$Headers_get(_ self: JSObject, _ name: String) throws(JSException) -> Optional<String> {
    let selfValue = self.bridgeJSLowerParameter()
    name.bridgeJSWithLoweredParameter { (nameBytes, nameLength) in
        bjs_Headers_get(selfValue, nameBytes, nameLength)
    }
    if let error = _swift_js_take_exception() {
        throw error
    }
    return Optional<String>.bridgeJSLiftReturnFromSideChannel()
}

func _$Headers_has(_ self: JSObject, _ name: String) throws(JSException) -> Bool {
    let selfValue = self.bridgeJSLowerParameter()
    let ret0 = name.bridgeJSWithLoweredParameter { (nameBytes, nameLength) in
        let ret = bjs_Headers_has(selfValue, nameBytes, nameLength)
        return ret
    }
    let ret = ret0
    if let error = _swift_js_take_exception() {
        throw error
    }
    return Bool.bridgeJSLiftReturn(ret)
}

func _$Headers_set(_ self: JSObject, _ name: String, _ value: String) throws(JSException) -> Void {
    let selfValue = self.bridgeJSLowerParameter()
    name.bridgeJSWithLoweredParameter { (nameBytes, nameLength) in
        value.bridgeJSWithLoweredParameter { (valueBytes, valueLength) in
            bjs_Headers_set(selfValue, nameBytes, nameLength, valueBytes, valueLength)
        }
    }
    if let error = _swift_js_take_exception() {
        throw error
    }
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_Response_headers_get")
fileprivate func bjs_Response_headers_get_extern(_ self: Int32) -> Int32
#else
fileprivate func bjs_Response_headers_get_extern(_ self: Int32) -> Int32 {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_Response_headers_get(_ self: Int32) -> Int32 {
    return bjs_Response_headers_get_extern(self)
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_Response_ok_get")
fileprivate func bjs_Response_ok_get_extern(_ self: Int32) -> Int32
#else
fileprivate func bjs_Response_ok_get_extern(_ self: Int32) -> Int32 {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_Response_ok_get(_ self: Int32) -> Int32 {
    return bjs_Response_ok_get_extern(self)
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_Response_status_get")
fileprivate func bjs_Response_status_get_extern(_ self: Int32) -> Float64
#else
fileprivate func bjs_Response_status_get_extern(_ self: Int32) -> Float64 {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_Response_status_get(_ self: Int32) -> Float64 {
    return bjs_Response_status_get_extern(self)
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_Response_statusText_get")
fileprivate func bjs_Response_statusText_get_extern(_ self: Int32) -> Int32
#else
fileprivate func bjs_Response_statusText_get_extern(_ self: Int32) -> Int32 {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_Response_statusText_get(_ self: Int32) -> Int32 {
    return bjs_Response_statusText_get_extern(self)
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_Response_url_get")
fileprivate func bjs_Response_url_get_extern(_ self: Int32) -> Int32
#else
fileprivate func bjs_Response_url_get_extern(_ self: Int32) -> Int32 {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_Response_url_get(_ self: Int32) -> Int32 {
    return bjs_Response_url_get_extern(self)
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_Response_json")
fileprivate func bjs_Response_json_extern(_ resolveRef: Int32, _ rejectRef: Int32, _ self: Int32) -> Void
#else
fileprivate func bjs_Response_json_extern(_ resolveRef: Int32, _ rejectRef: Int32, _ self: Int32) -> Void {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_Response_json(_ resolveRef: Int32, _ rejectRef: Int32, _ self: Int32) -> Void {
    return bjs_Response_json_extern(resolveRef, rejectRef, self)
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_Response_text")
fileprivate func bjs_Response_text_extern(_ resolveRef: Int32, _ rejectRef: Int32, _ self: Int32) -> Void
#else
fileprivate func bjs_Response_text_extern(_ resolveRef: Int32, _ rejectRef: Int32, _ self: Int32) -> Void {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_Response_text(_ resolveRef: Int32, _ rejectRef: Int32, _ self: Int32) -> Void {
    return bjs_Response_text_extern(resolveRef, rejectRef, self)
}

func _$Response_headers_get(_ self: JSObject) throws(JSException) -> Headers {
    let selfValue = self.bridgeJSLowerParameter()
    let ret = bjs_Response_headers_get(selfValue)
    if let error = _swift_js_take_exception() {
        throw error
    }
    return Headers.bridgeJSLiftReturn(ret)
}

func _$Response_ok_get(_ self: JSObject) throws(JSException) -> Bool {
    let selfValue = self.bridgeJSLowerParameter()
    let ret = bjs_Response_ok_get(selfValue)
    if let error = _swift_js_take_exception() {
        throw error
    }
    return Bool.bridgeJSLiftReturn(ret)
}

func _$Response_status_get(_ self: JSObject) throws(JSException) -> Double {
    let selfValue = self.bridgeJSLowerParameter()
    let ret = bjs_Response_status_get(selfValue)
    if let error = _swift_js_take_exception() {
        throw error
    }
    return Double.bridgeJSLiftReturn(ret)
}

func _$Response_statusText_get(_ self: JSObject) throws(JSException) -> String {
    let selfValue = self.bridgeJSLowerParameter()
    let ret = bjs_Response_statusText_get(selfValue)
    if let error = _swift_js_take_exception() {
        throw error
    }
    return String.bridgeJSLiftReturn(ret)
}

func _$Response_url_get(_ self: JSObject) throws(JSException) -> String {
    let selfValue = self.bridgeJSLowerParameter()
    let ret = bjs_Response_url_get(selfValue)
    if let error = _swift_js_take_exception() {
        throw error
    }
    return String.bridgeJSLiftReturn(ret)
}

func _$Response_json(_ self: JSObject) async throws(JSException) -> JSValue {
    let resolved = try await _bjs_awaitPromise(makeResolveClosure: {
            JSTypedClosure<(sending JSValue) -> Void>($0)
        }, makeRejectClosure: {
            JSTypedClosure<(sending JSValue) -> Void>($0)
        }) { resolveRef, rejectRef in
        let selfValue = self.bridgeJSLowerParameter()
        bjs_Response_json(resolveRef, rejectRef, selfValue)
    }
    return resolved
}

func _$Response_text(_ self: JSObject) async throws(JSException) -> String {
    let resolved = try await _bjs_awaitPromise(makeResolveClosure: {
            JSTypedClosure<(sending String) -> Void>($0)
        }, makeRejectClosure: {
            JSTypedClosure<(sending JSValue) -> Void>($0)
        }) { resolveRef, rejectRef in
        let selfValue = self.bridgeJSLowerParameter()
        bjs_Response_text(resolveRef, rejectRef, selfValue)
    }
    return resolved
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_RequestInit_init")
fileprivate func bjs_RequestInit_init_extern(_ methodBytes: Int32, _ methodLength: Int32, _ headers: Int32, _ bodyIsSome: Int32, _ bodyValue: Int32) -> Int32
#else
fileprivate func bjs_RequestInit_init_extern(_ methodBytes: Int32, _ methodLength: Int32, _ headers: Int32, _ bodyIsSome: Int32, _ bodyValue: Int32) -> Int32 {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_RequestInit_init(_ methodBytes: Int32, _ methodLength: Int32, _ headers: Int32, _ bodyIsSome: Int32, _ bodyValue: Int32) -> Int32 {
    return bjs_RequestInit_init_extern(methodBytes, methodLength, headers, bodyIsSome, bodyValue)
}

func _$RequestInit_init(_ method: HTTPMethod, _ headers: Headers, _ body: Optional<JSObject>) throws(JSException) -> JSObject {
    let ret0 = method.bridgeJSWithLoweredParameter { (methodBytes, methodLength) in
        let headersValue = headers.bridgeJSLowerParameter()
        let (bodyIsSome, bodyValue) = body.bridgeJSLowerParameter()
        let ret = bjs_RequestInit_init(methodBytes, methodLength, headersValue, bodyIsSome, bodyValue)
        return ret
    }
    let ret = ret0
    if let error = _swift_js_take_exception() {
        throw error
    }
    return JSObject.bridgeJSLiftReturn(ret)
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_URL_init")
fileprivate func bjs_URL_init_extern(_ pathBytes: Int32, _ pathLength: Int32, _ baseBytes: Int32, _ baseLength: Int32) -> Int32
#else
fileprivate func bjs_URL_init_extern(_ pathBytes: Int32, _ pathLength: Int32, _ baseBytes: Int32, _ baseLength: Int32) -> Int32 {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_URL_init(_ pathBytes: Int32, _ pathLength: Int32, _ baseBytes: Int32, _ baseLength: Int32) -> Int32 {
    return bjs_URL_init_extern(pathBytes, pathLength, baseBytes, baseLength)
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_URL_href_get")
fileprivate func bjs_URL_href_get_extern(_ self: Int32) -> Int32
#else
fileprivate func bjs_URL_href_get_extern(_ self: Int32) -> Int32 {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_URL_href_get(_ self: Int32) -> Int32 {
    return bjs_URL_href_get_extern(self)
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_URL_searchParams_get")
fileprivate func bjs_URL_searchParams_get_extern(_ self: Int32) -> Int32
#else
fileprivate func bjs_URL_searchParams_get_extern(_ self: Int32) -> Int32 {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_URL_searchParams_get(_ self: Int32) -> Int32 {
    return bjs_URL_searchParams_get_extern(self)
}

func _$URL_init(_ path: String, _ base: String) throws(JSException) -> JSObject {
    let ret0 = path.bridgeJSWithLoweredParameter { (pathBytes, pathLength) in
        let ret1 = base.bridgeJSWithLoweredParameter { (baseBytes, baseLength) in
            let ret = bjs_URL_init(pathBytes, pathLength, baseBytes, baseLength)
            return ret
        }
        return ret1
    }
    let ret = ret0
    if let error = _swift_js_take_exception() {
        throw error
    }
    return JSObject.bridgeJSLiftReturn(ret)
}

func _$URL_href_get(_ self: JSObject) throws(JSException) -> String {
    let selfValue = self.bridgeJSLowerParameter()
    let ret = bjs_URL_href_get(selfValue)
    if let error = _swift_js_take_exception() {
        throw error
    }
    return String.bridgeJSLiftReturn(ret)
}

func _$URL_searchParams_get(_ self: JSObject) throws(JSException) -> URLSearchParams {
    let selfValue = self.bridgeJSLowerParameter()
    let ret = bjs_URL_searchParams_get(selfValue)
    if let error = _swift_js_take_exception() {
        throw error
    }
    return URLSearchParams.bridgeJSLiftReturn(ret)
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_URLSearchParams_set")
fileprivate func bjs_URLSearchParams_set_extern(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32, _ valueBytes: Int32, _ valueLength: Int32) -> Void
#else
fileprivate func bjs_URLSearchParams_set_extern(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32, _ valueBytes: Int32, _ valueLength: Int32) -> Void {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_URLSearchParams_set(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32, _ valueBytes: Int32, _ valueLength: Int32) -> Void {
    return bjs_URLSearchParams_set_extern(self, nameBytes, nameLength, valueBytes, valueLength)
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_URLSearchParams_append")
fileprivate func bjs_URLSearchParams_append_extern(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32, _ valueBytes: Int32, _ valueLength: Int32) -> Void
#else
fileprivate func bjs_URLSearchParams_append_extern(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32, _ valueBytes: Int32, _ valueLength: Int32) -> Void {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_URLSearchParams_append(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32, _ valueBytes: Int32, _ valueLength: Int32) -> Void {
    return bjs_URLSearchParams_append_extern(self, nameBytes, nameLength, valueBytes, valueLength)
}

#if arch(wasm32)
@_extern(wasm, module: "OpenAPIFetchRuntime", name: "bjs_URLSearchParams_delete")
fileprivate func bjs_URLSearchParams_delete_extern(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32) -> Void
#else
fileprivate func bjs_URLSearchParams_delete_extern(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32) -> Void {
    fatalError("Only available on WebAssembly")
}
#endif
@inline(never) fileprivate func bjs_URLSearchParams_delete(_ self: Int32, _ nameBytes: Int32, _ nameLength: Int32) -> Void {
    return bjs_URLSearchParams_delete_extern(self, nameBytes, nameLength)
}

func _$URLSearchParams_set(_ self: JSObject, _ name: String, _ value: String) throws(JSException) -> Void {
    let selfValue = self.bridgeJSLowerParameter()
    name.bridgeJSWithLoweredParameter { (nameBytes, nameLength) in
        value.bridgeJSWithLoweredParameter { (valueBytes, valueLength) in
            bjs_URLSearchParams_set(selfValue, nameBytes, nameLength, valueBytes, valueLength)
        }
    }
    if let error = _swift_js_take_exception() {
        throw error
    }
}

func _$URLSearchParams_append(_ self: JSObject, _ name: String, _ value: String) throws(JSException) -> Void {
    let selfValue = self.bridgeJSLowerParameter()
    name.bridgeJSWithLoweredParameter { (nameBytes, nameLength) in
        value.bridgeJSWithLoweredParameter { (valueBytes, valueLength) in
            bjs_URLSearchParams_append(selfValue, nameBytes, nameLength, valueBytes, valueLength)
        }
    }
    if let error = _swift_js_take_exception() {
        throw error
    }
}

func _$URLSearchParams_delete(_ self: JSObject, _ name: String) throws(JSException) -> Void {
    let selfValue = self.bridgeJSLowerParameter()
    name.bridgeJSWithLoweredParameter { (nameBytes, nameLength) in
        bjs_URLSearchParams_delete(selfValue, nameBytes, nameLength)
    }
    if let error = _swift_js_take_exception() {
        throw error
    }
}
#endif
