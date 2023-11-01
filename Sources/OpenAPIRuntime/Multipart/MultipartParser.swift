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
import HTTPTypes

private enum ASCII {
    static let dashes: [UInt8] = [0x2d, 0x2d]
    static let crlf: [UInt8] = [0xd, 0xa]
    static let colonSpace: [UInt8] = [0x3a, 0x20]
}

extension MultipartBody {
    convenience init(parsing body: HTTPBody) {
        // TODO: Make HTTPBody.Length and MultipartBody.Length the same? Or not?
        let length: MultipartBody.Length
        switch body.length {
        case .known(let count): length = .known(count)
        case .unknown: length = .unknown
        }
        let iterationBehavior: MultipartBody.IterationBehavior
        switch body.iterationBehavior {
        case .single: iterationBehavior = .single
        case .multiple: iterationBehavior = .multiple
        }
        self.init(MultipartParsingSequence(upstream: body), length: length, iterationBehavior: iterationBehavior)
    }
    private final class MultipartParsingSequence: AsyncSequence {
        typealias Element = MultipartPart
        typealias AsyncIterator = Iterator
        let upstream: HTTPBody
        init(upstream: HTTPBody) { self.upstream = upstream }
        func makeAsyncIterator() -> Iterator { Iterator(upstream: upstream.makeAsyncIterator()) }
        struct Iterator: AsyncIteratorProtocol {
            typealias Element = MultipartPart
            var upstream: HTTPBody.Iterator
            init(upstream: HTTPBody.Iterator) { self.upstream = upstream }
            mutating func next() async throws -> MultipartPart? {
                let chunk = try await upstream.next()
                return nil
            }
        }
    }
}
