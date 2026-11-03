# Response content type not acceptable

An error indicating that the content type of the response isn't acceptable according to the request's `Accept` header field.

## Overview

When this error occurs, the server responds with an HTTP `406 Not Acceptable` status and includes problem details in its body structured according to [RFC 9457](https://www.rfc-editor.org/rfc/rfc9457.html).

The server's handler returned a response with a content type that the request's `Accept` header field doesn't list as acceptable. To resolve it, either add the response content type to the request's `Accept` header field, or update the handler to return a response with one of the acceptable content types.

It includes extension fields to help clients diagnose and correct the mismatch:

- `responseContentType`: A string with the content type of the response that the server tried to send.
- `acceptableContentTypes`: An array of strings with the media ranges, such as `application/json` or `text/*`, listed in the request's `Accept` header field, without parameters such as quality values.

For example:

```http
HTTP/1.1 406 Not Acceptable
Content-Type: application/problem+json

{
  "acceptableContentTypes": ["text/plain"],
  "detail": "Response content type not acceptable, content type: application/json, accepted: text/plain",
  "responseContentType": "application/json",
  "status": 406,
  "title": "Response content type not acceptable",
  "type": "https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime/response-content-type-not-acceptable"
}
```
