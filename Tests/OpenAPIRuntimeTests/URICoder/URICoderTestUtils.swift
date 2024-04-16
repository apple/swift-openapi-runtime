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

@testable import OpenAPIRuntime

extension URICoderConfiguration {

    private static let defaultDateTranscoder: any DateTranscoder = .iso8601

    static let formExplode: Self = .init(
        style: .form,
        explode: true,
        spaceEscapingCharacter: .percentEncoded,
        dateTranscoder: defaultDateTranscoder
    )

    static let formUnexplode: Self = .init(
        style: .form,
        explode: false,
        spaceEscapingCharacter: .percentEncoded,
        dateTranscoder: defaultDateTranscoder
    )

    static let simpleExplode: Self = .init(
        style: .simple,
        explode: true,
        spaceEscapingCharacter: .percentEncoded,
        dateTranscoder: defaultDateTranscoder
    )

    static let simpleUnexplode: Self = .init(
        style: .simple,
        explode: false,
        spaceEscapingCharacter: .percentEncoded,
        dateTranscoder: defaultDateTranscoder
    )

    static let formDataExplode: Self = .init(
        style: .form,
        explode: true,
        spaceEscapingCharacter: .plus,
        dateTranscoder: defaultDateTranscoder
    )

    static let formDataUnexplode: Self = .init(
        style: .form,
        explode: false,
        spaceEscapingCharacter: .plus,
        dateTranscoder: defaultDateTranscoder
    )
    static let deepObjectExplode: Self = .init(
        style: .deepObject,
        explode: true,
        spaceEscapingCharacter: .percentEncoded,
        dateTranscoder: defaultDateTranscoder
    )
}
