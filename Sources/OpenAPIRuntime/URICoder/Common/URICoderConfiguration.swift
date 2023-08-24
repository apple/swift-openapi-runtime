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

/// A bag of configuration values used by the URI parser and serializer.
struct URICoderConfiguration {

    enum Style {
        case simple
        case form
    }

    enum SpaceEscapingCharacter: String {
        case percentEncoded = "%20"
        case plus = "+"
    }

    var style: Style
    var explode: Bool
    var spaceEscapingCharacter: SpaceEscapingCharacter

    private init(style: Style, explode: Bool, spaceEscapingCharacter: SpaceEscapingCharacter) {
        self.style = style
        self.explode = explode
        self.spaceEscapingCharacter = spaceEscapingCharacter
    }

    static let formExplode: Self = .init(
        style: .form,
        explode: true,
        spaceEscapingCharacter: .percentEncoded
    )

    static let formUnexplode: Self = .init(
        style: .form,
        explode: false,
        spaceEscapingCharacter: .percentEncoded
    )

    static let simpleExplode: Self = .init(
        style: .simple,
        explode: true,
        spaceEscapingCharacter: .percentEncoded
    )

    static let simpleUnexplode: Self = .init(
        style: .simple,
        explode: false,
        spaceEscapingCharacter: .percentEncoded
    )

    static let formDataExplode: Self = .init(
        style: .form,
        explode: true,
        spaceEscapingCharacter: .plus
    )

    static let formDataUnexplode: Self = .init(
        style: .form,
        explode: false,
        spaceEscapingCharacter: .plus
    )
}
