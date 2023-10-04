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

import Foundation

public struct Base64EncodedData: Sendable, Codable, Hashable {
    var data: ArraySlice<UInt8>

    public init(data: ArraySlice<UInt8>) {
        self.data = data
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let base64EncodedString = try container.decode(String.self)

        // permissive decoding
        let options = Data.Base64DecodingOptions.ignoreUnknownCharacters

        guard let data = Data(base64Encoded: base64EncodedString, options: options) else {
            throw RuntimeError.invalidBase64String(base64EncodedString)
        }
        self.init(data: ArraySlice(data))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        // https://datatracker.ietf.org/doc/html/rfc4648#section-3.1
        // "Implementations MUST NOT add line feeds to base-encoded data unless
        // the specification referring to this document explicitly directs base
        // encoders to add line feeds after a specific number of characters."
        let options = Data.Base64EncodingOptions()

        let base64String = Data(data).base64EncodedString(options: options)
        try container.encode(base64String)
    }
}
