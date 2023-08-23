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

final class URIValueFromNodeDecoder {
    
    private var node: URIParsedNode
    
    init(node: URIParsedNode) {
        self.node = node
    }
    
    func decodeRoot<T: Decodable>(_ type: T.Type = T.self) throws -> T {
        fatalError()
    }
}
