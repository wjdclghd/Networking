//
//  Endpoint.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

/// 네트워크 요청에 필요한 URL, method, header, body 정보를 표현합니다.
public struct Endpoint: Sendable {
    /// 요청의 기준 URL입니다.
    public let baseURL: URL
    /// 기준 URL 뒤에 붙일 path입니다.
    public let path: String
    /// HTTP method입니다.
    public let method: HTTPMethod
    /// 요청 단위로 추가하거나 덮어쓸 header입니다.
    public let headers: [String: String]
    /// URL query item 목록입니다.
    public let queryItems: [URLQueryItem]
    /// 요청 body 구성 방식입니다.
    public let task: HTTPTask
    /// Authorization header가 필요한 요청인지 여부입니다.
    public let requiresAuthorization: Bool
    /// 비어 있는 성공 응답을 허용할지 여부입니다.
    public let allowsEmptyResponse: Bool

    /// Endpoint를 생성합니다.
    ///
    /// - Parameters:
    ///   - baseURL: 요청의 기준 URL입니다.
    ///   - path: 기준 URL 뒤에 붙일 path입니다.
    ///   - method: HTTP method입니다.
    ///   - headers: 요청 단위로 추가하거나 덮어쓸 header입니다.
    ///   - queryItems: URL query item 목록입니다.
    ///   - task: 요청 body 구성 방식입니다.
    ///   - requiresAuthorization: Authorization header가 필요한 요청인지 여부입니다.
    ///   - allowsEmptyResponse: 비어 있는 성공 응답을 허용할지 여부입니다.
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
