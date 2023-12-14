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

extension AsyncSequence where Element == ArraySlice<UInt8> {
    func asDecodedJSONLines<Event: Decodable>(
        of eventType: Event.Type = Event.self,
        using decoder: JSONDecoder = .init()
    ) -> AsyncThrowingMapSequence<LinesDeserializationSequence<Self>, Event> {
        asParsedLines().map { line in
            try decoder.decode(Event.self, from: Data(line))
        }
    }
}
