//
//  File.swift
//  
//
//  Created by Honza Dvorsky on 9/4/23.
//

import Foundation

/// A container for request metadata already parsed and validated
/// by the server transport.
public struct ServerRequestMetadata: Hashable, Sendable {

    /// The path parameters parsed from the URL of the HTTP request.
    public var pathParameters: [String: Substring]

    /// Creates a new metadata wrapper with the specified path and query parameters.
    /// - Parameters:
    ///   - pathParameters: Path parameters parsed from the URL of the HTTP
    ///   request.
    public init(
        pathParameters: [String: Substring] = [:]
    ) {
        self.pathParameters = pathParameters
    }
}
