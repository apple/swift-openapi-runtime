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
@_spi(Generated) extension Optional where Wrapped == OpenAPIMIMEType {

    /// Unwraps the boundary parameter from the parsed MIME type.
    /// - Returns: The boundary value.
    /// - Throws: If self is nil, or if the MIME type isn't a `multipart/form-data`
    ///   with a boundary parameter.
    public func requiredBoundary() throws -> String {
        guard let self else { throw RuntimeError.missingRequiredMultipartFormDataContentType }
        guard case .concrete(type: "multipart", subtype: "form-data") = self.kind else {
            throw RuntimeError.missingRequiredMultipartFormDataContentType
        }
        guard let boundary = self.parameters["boundary"] else {
            throw RuntimeError.missingMultipartBoundaryContentTypeParameter
        }
        return boundary
    }
}
