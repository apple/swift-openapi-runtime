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

/// A parsed representation of the `content-disposition` header described by RFC 6266 containing only
/// the features relevant to OpenAPI multipart bodies.
struct ContentDisposition {
    enum DispositionType {
        case formData
        case other(String)
        init(rawValue: String) {
            switch rawValue.lowercased() {
            case "form-data": self = .formData
            default: self = .other(rawValue)
            }
        }
        var rawValue: String {
            switch self {
            case .formData: return "form-data"
            case .other(let string): return string
            }
        }
    }
    var dispositionType: DispositionType
    enum ParameterName: Hashable {
        case name
        case filename
        case other(String)
        init(rawValue: String) {
            switch rawValue.lowercased() {
            case "name": self = .name
            case "filename": self = .filename
            default: self = .other(rawValue)
            }
        }
        var rawValue: String {
            switch self {
            case .name: return "name"
            case .filename: return "filename"
            case .other(let string): return string
            }
        }
    }
    var parameters: [ParameterName: String]
    var name: String? {
        get { parameters[.name] }
        set { parameters[.name] = newValue }
    }
    var filename: String? {
        get { parameters[.filename] }
        set { parameters[.filename] = newValue }
    }
}

extension ContentDisposition: RawRepresentable {
    // https://datatracker.ietf.org/doc/html/rfc6266#section-4.1

    init?(rawValue: String) {
        var components = rawValue.split(separator: ";").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard !components.isEmpty else { return nil }
        self.dispositionType = DispositionType(rawValue: components.removeFirst())
        let parameterTuples: [(ParameterName, String)] = components.compactMap { component in
            let parameterComponents = component.split(separator: "=", maxSplits: 1)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard parameterComponents.count == 2 else { return nil }
            // TODO: Improve quote handling
            let valueWithoutQuotes = parameterComponents[1].replacingOccurrences(of: "\"", with: "")
            return (.init(rawValue: parameterComponents[0]), valueWithoutQuotes)
        }
        self.parameters = Dictionary(parameterTuples, uniquingKeysWith: { a, b in a })
    }
    var rawValue: String {
        var string = ""
        string.append(dispositionType.rawValue)
        if !parameters.isEmpty {
            for (key, value) in parameters.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                // TODO: Improve quote handling
                let valueWithoutQuotes = value.replacingOccurrences(of: "\"", with: "")
                string.append("; \(key.rawValue)=\"\(valueWithoutQuotes)\"")
            }
        }
        return string
    }
}
