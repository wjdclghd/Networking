//
//  Endpoint.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

public struct Endpoint: Sendable {
    public let baseURL: URL
    public let path: String
    public let method: HTTPMethod
    public let headers: [String: String]
    public let queryItems: [URLQueryItem]
    public let task: HTTPTask
    public let requiresAuthorization: Bool
    public let allowsEmptyResponse: Bool
    
    public init(
        baseURL: URL,
        path: String,
        method: HTTPMethod,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem] = [],
        task: HTTPTask = .plain,
        requiresAuthorization: Bool = false,
        allowsEmptyResponse: Bool = false
    ) {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
        self.task = task
        self.requiresAuthorization = requiresAuthorization
        self.allowsEmptyResponse = allowsEmptyResponse
    }
}
