# Unexpected accept header

An error indicating that the request's accept header contained unexpected or unsupported content types.

## Overview

When this error occurs, the server responds with an HTTP `406 Not Acceptable` status and includes problem details in its body structured according to [RFC 9457](https://www.rfc-editor.org/rfc/rfc9457.html).

It includes extension fields to help clients diagnose and correct the mismatch:
    - `expectedContentTypes`: A string indicating the content types expected by the server.
    - `receivedContentTypes`: A string indicating the invalid or unsupported content types actually sent.

For example:

```json
HTTP/1.1 406 Not Acceptable
Content-Type: application/problem+json

{
  "detail": "Unexpected Accept header: text/plain",
  "expectedContentTypes": "application/json",
  "receivedContentTypes": "text/plain",
  "title": "Unexpected Accept header",
  "type": "https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/swift-openapi-runtime/problemdetails/unexpected-accept-header",
  "status": 406
}
```
