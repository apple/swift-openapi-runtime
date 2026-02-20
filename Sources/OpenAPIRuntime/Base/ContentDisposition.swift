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

// Full Foundation needed for String.trimmingCharacters
import Foundation

/// A parsed representation of the `content-disposition` header described by RFC 6266 containing only
/// the features relevant to OpenAPI multipart bodies.
struct ContentDisposition: Hashable {

    /// A `disposition-type` parameter value.
    enum DispositionType: Hashable {

        /// A form data value.
        case formData

        /// Any other value.
        case other(String)

        /// Creates a new disposition type value.
        /// - Parameter rawValue: A string representation of the value.
        init(rawValue: String) {
            switch rawValue.lowercased() {
            case "form-data": self = .formData
            default: self = .other(rawValue)
            }
        }

        /// A string representation of the value.
        var rawValue: String {
            switch self {
            case .formData: return "form-data"
            case .other(let string): return string
            }
        }
    }

    /// The disposition type value.
    var dispositionType: DispositionType

    /// A content disposition parameter name.
    enum ParameterName: Hashable {

        /// The name parameter.
        case name

        /// The filename parameter.
        case filename

        /// Any other parameter.
        case other(String)

        /// Creates a new parameter name.
        /// - Parameter rawValue: A string representation of the name.
        init(rawValue: String) {
            switch rawValue.lowercased() {
            case "name": self = .name
            case "filename": self = .filename
            default: self = .other(rawValue)
            }
        }

        /// A string representation of the name.
        var rawValue: String {
            switch self {
            case .name: return "name"
            case .filename: return "filename"
            case .other(let string): return string
            }
        }
    }

    /// The parameters of the content disposition value.
    var parameters: [ParameterName: String] = [:]

    /// The name parameter value.
    var name: String? {
        get { parameters[.name] }
        set { parameters[.name] = newValue }
    }

    /// The filename parameter value.
    var filename: String? {
        get { parameters[.filename] }
        set { parameters[.filename] = newValue }
    }
}

extension ContentDisposition: RawRepresentable {

    /// Creates a new instance with the specified raw value.
    ///
    /// https://datatracker.ietf.org/doc/html/rfc6266#section-4.1
    /// - Parameter rawValue: The raw value to use for the new instance.
    init?(rawValue: String) {
        var components = rawValue.split(separator: ";").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard !components.isEmpty else { return nil }
        self.dispositionType = DispositionType(rawValue: components.removeFirst())
        let parameterTuples: [(ParameterName, String)] = components.compactMap {
            (component: String) -> (ParameterName, String)? in
            let parameterComponents = component.split(separator: "=", maxSplits: 1)
                .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            guard parameterComponents.count == 2 else { return nil }
            let valueWithoutQuotes = parameterComponents[1].trimmingCharacters(in: ["\""])
            return (.init(rawValue: parameterComponents[0]), valueWithoutQuotes)
        }
        self.parameters = Dictionary(parameterTuples, uniquingKeysWith: { a, b in a })
    }

    /// The corresponding value of the raw type.
    var rawValue: String {
        var string = ""
        string.append(dispositionType.rawValue)
        if !parameters.isEmpty {
            for (key, value) in parameters.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                string.append("; \(key.rawValue)=\"\(value)\"")
            }
        }
        return string
    }
}
