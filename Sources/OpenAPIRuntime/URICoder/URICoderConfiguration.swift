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
struct URISerializationConfiguration {
    
    // TODO: Wrap in a struct, as this will grow.
    // https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.3.md#style-values
    enum Style {
        case simple
        case form
    }
    
    var style: Style
    var explode: Bool
    var spaceEscapingCharacter: String
    
    private init(style: Style, explode: Bool, spaceEscapingCharacter: String) {
        self.style = style
        self.explode = explode
        self.spaceEscapingCharacter = spaceEscapingCharacter
    }
    
    static let formExplode: Self = .init(
        style: .form,
        explode: true,
        spaceEscapingCharacter: "%20"
    )
    
    static let formUnexplode: Self = .init(
        style: .form,
        explode: false,
        spaceEscapingCharacter: "%20"
    )
    
    static let simpleExplode: Self = .init(
        style: .simple,
        explode: true,
        spaceEscapingCharacter: "%20"
    )
    
    static let simpleUnexplode: Self = .init(
        style: .simple,
        explode: false,
        spaceEscapingCharacter: "%20"
    )
    
    static let formDataExplode: Self = .init(
        style: .form,
        explode: true,
        spaceEscapingCharacter: "+"
    )
    
    static let formDataUnexplode: Self = .init(
        style: .form,
        explode: false,
        spaceEscapingCharacter: "+"
    )
}
