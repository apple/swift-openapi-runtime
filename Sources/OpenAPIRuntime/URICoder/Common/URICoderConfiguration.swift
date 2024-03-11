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

/// A bag of configuration values used by the URI encoder and decoder.
struct URICoderConfiguration {

    /// A variable expansion style as described by RFC 6570 and OpenAPI 3.0.3.
    enum Style {

        /// A style for simple string variable expansion.
        case simple

        /// A style for form-based URI expansion.
        case form
        
        /// A style for nested variable expansion
        case deepObject
    }

    /// A character used to escape the space character.
    enum SpaceEscapingCharacter: String {

        /// A percent encoded value for the space character.
        case percentEncoded = "%20"

        /// The plus character.
        case plus = "+"
    }

    /// The variable expansion style.
    var style: Style

    /// A Boolean value indicating whether the key should be repeated with
    /// each value, as described by RFC 6570 and OpenAPI 3.0.3.
    var explode: Bool

    /// The character used to escape the space character.
    var spaceEscapingCharacter: SpaceEscapingCharacter

    /// The coder used for serializing the Date type.
    var dateTranscoder: any DateTranscoder
}
