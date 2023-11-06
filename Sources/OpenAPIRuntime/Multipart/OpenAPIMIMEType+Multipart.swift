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

extension OpenAPIMIMEType {
    func _requiredBoundary() throws -> String {
        guard case .concrete(type: "multipart", subtype: "form-data") = kind else {
            throw RuntimeError.missingRequiredMultipartFormDataContentType
        }
        guard let boundary = parameters["boundary"] else {
            throw RuntimeError.missingMultipartBoundaryContentTypeParameter
        }
        return boundary
    }
}

@_spi(Generated) extension Optional where Wrapped == OpenAPIMIMEType {
    public func requiredBoundary() throws -> String {
        guard let self else { throw RuntimeError.missingRequiredMultipartFormDataContentType }
        return try self._requiredBoundary()
    }
}
