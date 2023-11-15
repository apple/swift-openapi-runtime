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

import HTTPTypes

/// A frame of a multipart message, either the whole header fields
/// section or a chunk of the body bytes.
enum MultipartFrame: Sendable, Hashable {

    /// The header fields section.
    case headerFields(HTTPFields)

    /// One byte chunk of the part's body.
    case bodyChunk(ArraySlice<UInt8>)
}
