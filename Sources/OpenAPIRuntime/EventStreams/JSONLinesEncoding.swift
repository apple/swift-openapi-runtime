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

extension AsyncSequence where Element: Encodable {
    func asEncodedJSONLines(
        using encoder: JSONEncoder = {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            return encoder
        }()
    ) -> LinesSerializationSequence<AsyncThrowingMapSequence<Self, ArraySlice<UInt8>>> {
        map { event in
            try ArraySlice(encoder.encode(event))
        }
        .asSerializedLines()
    }
}
