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
    var data: Foundation.Data // or [UInt8] or ArraySlice<UInt8>

    public init(data: Foundation.Data) {
        self.data = data
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let base64EncodedString = try container.decode(String.self)
        guard let data = Data(base64Encoded: base64EncodedString) else {
            throw RuntimeError.invalidBase64String(base64EncodedString)
        }
        self.init(data: data)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        let base64String = data.base64EncodedString()
        try container.encode(base64String)
    }
}
