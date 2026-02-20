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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
public import HTTPTypes

// MARK: - Extensions

extension MultipartRawPart {

    /// Creates a new raw part by injecting the provided name and filename into
    /// the `content-disposition` header field.
    /// - Parameters:
    ///   - name: The name of the part.
    ///   - filename: The file name of the part.
    ///   - headerFields: The header fields of the part.
    ///   - body: The body stream of the part.
    public init(name: String?, filename: String? = nil, headerFields: HTTPFields, body: HTTPBody) {
        var parameters: [ContentDisposition.ParameterName: String] = [:]
        if let name { parameters[.name] = name }
        if let filename { parameters[.filename] = filename }
        let contentDisposition = ContentDisposition(dispositionType: .formData, parameters: parameters)
        var headerFields = headerFields
        headerFields[.contentDisposition] = contentDisposition.rawValue
        self.init(headerFields: headerFields, body: body)
    }

    /// Returns the parameter value for the provided name.
    /// - Parameter name: The parameter name.
    /// - Returns: The parameter value. Nil if not found in the content disposition header field.
    private func getParameter(_ name: ContentDisposition.ParameterName) -> String? {
        guard let contentDispositionString = headerFields[.contentDisposition],
            let contentDisposition = ContentDisposition(rawValue: contentDispositionString)
        else { return nil }
        return contentDisposition.parameters[name]
    }

    /// Sets the parameter name to the provided value.
    /// - Parameters:
    ///   - name: The parameter name.
    ///   - value: The value of the parameter.
    private mutating func setParameter(_ name: ContentDisposition.ParameterName, _ value: String?) {
        guard let contentDispositionString = headerFields[.contentDisposition],
            var contentDisposition = ContentDisposition(rawValue: contentDispositionString)
        else {
            if let value {
                headerFields[.contentDisposition] =
                    ContentDisposition(dispositionType: .formData, parameters: [name: value]).rawValue
            }
            return
        }
        contentDisposition.parameters[name] = value
        headerFields[.contentDisposition] = contentDisposition.rawValue
    }

    /// The name of the part stored in the `content-disposition` header field.
    public var name: String? {
        get { getParameter(.name) }
        set { setParameter(.name, newValue) }
    }

    /// The file name of the part stored in the `content-disposition` header field.
    public var filename: String? {
        get { getParameter(.filename) }
        set { setParameter(.filename, newValue) }
    }
}
