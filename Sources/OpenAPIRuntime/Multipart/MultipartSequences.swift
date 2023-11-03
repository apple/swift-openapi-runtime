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

// MARK: - Raw parts

@frozen public enum MultipartBodyChunk: Sendable, Hashable {
    case headerFields(HTTPFields)
    case bodyChunk(ArraySlice<UInt8>)
}

public typealias MultipartBody = OpenAPISequence<MultipartBodyChunk>

// MARK: - Typed parts

public protocol MultipartTypedPart: Sendable { var name: String { get } }

public typealias MultipartTypedBody<Part: MultipartTypedPart> = OpenAPISequence<Part>
