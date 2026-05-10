//
//  NetworkRequestBuilder.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

/// Endpoint를 URLRequest로 변환하고 인증 header를 적용합니다.
public struct NetworkRequestBuilder {
    private let authorizationProvider: AuthorizationProvider?
    private let authorizationProviderAsync: AuthorizationProviderAsync?
    private let configuration: NetworkConfiguration
    private let encoderFactory: @Sendable () -> JSONEncoder

    /// 설정에 포함된 network event logger입니다.
    public var logger: NetworkEventLogger? {
        configuration.logger
    }

    /// 설정에 포함된 retry policy입니다.
    public var retryPolicy: NetworkRetryPolicy? {
        configuration.retryPolicy
    }

    /// 요청 builder를 생성합니다.
    ///
    /// - Parameters:
    ///   - authorizationProvider: 동기 bearer token 제공자입니다.
    ///   - authorizationProviderAsync: 비동기 bearer token 제공자입니다.
    ///   - configuration: 요청 생성과 실행에 사용할 네트워크 설정입니다.
    ///   - encoderFactory: JSON body 인코딩에 사용할 encoder 생성 클로저입니다.
    public init(
        authorizationProvider: AuthorizationProvider? = nil,
        authorizationProviderAsync: AuthorizationProviderAsync? = nil,
        configuration: NetworkConfiguration = .default,
        encoderFactory: @escaping @Sendable () -> JSONEncoder = { JSONEncoder() }
    ) {
        self.authorizationProvider = authorizationProvider
        self.authorizationProviderAsync = authorizationProviderAsync
        self.configuration = configuration
        self.encoderFactory = encoderFactory
    }

    /// Endpoint 정보를 URLRequest로 변환합니다.
    ///
    /// - Parameter endpoint: 변환할 Endpoint입니다.
    /// - Returns: Endpoint 값이 반영된 URLRequest입니다.
    /// - Throws: URL 생성, 인증 정보, body 인코딩 실패 시 `NetworkError`를 던집니다.
    public func build(from endpoint: Endpoint) throws -> URLRequest {
        let normalizedPath = endpoint.path.hasPrefix("/")
            ? String(endpoint.path.dropFirst())
            : endpoint.path

        let url = normalizedPath.isEmpty
            ? endpoint.baseURL
            : endpoint.baseURL.appendingPathComponent(normalizedPath)

        guard var components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL
        }

        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }

        guard let finalURL = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(
            url: finalURL,
            cachePolicy: configuration.cachePolicy,
            timeoutInterval: configuration.timeoutInterval
        )

        request.httpMethod = endpoint.method.rawValue

        configuration.defaultHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        if endpoint.requiresAuthorization {
            if let token = authorizationProvider?.bearerToken,
               !token.isEmpty {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else if authorizationProviderAsync == nil {
                throw NetworkError.missingAuthorization
            }
        }

        switch endpoint.task {
        case .plain:
            break

        case .jsonEncodable(let body):
            do {
                let encoder = encoderFactory()
                request.httpBody = try encoder.encode(body)
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
            } catch {
                throw NetworkError.encoding(error)
            }

        case .formURLEncoded(let parameters):
            let bodyString = FormURLEncodedSerializer.encode(parameters)
            request.httpBody = bodyString.data(using: .utf8)
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            }
        }

        return request
    }

    /// 요청에 Authorization header를 적용합니다.
    ///
    /// - Parameters:
    ///   - request: Authorization header를 적용할 URLRequest입니다.
    ///   - requiresAuthorization: Authorization header가 필요한지 여부입니다.
    /// - Returns: Authorization header가 반영된 URLRequest입니다.
    /// - Throws: 인증이 필요하지만 token이 없으면 `NetworkError.missingAuthorization`을 던집니다.
    public func applyAuthorization(
        to request: URLRequest,
        requiresAuthorization: Bool
    ) async throws -> URLRequest {
        guard requiresAuthorization else {
            return request
        }

        if request.value(forHTTPHeaderField: "Authorization") != nil {
            return request
        }

        if let token = authorizationProvider?.bearerToken,
           !token.isEmpty {
            var updatedRequest = request
            updatedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            return updatedRequest
        }

        if let token = try await authorizationProviderAsync?.bearerToken(),
           !token.isEmpty {
            var updatedRequest = request
            updatedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            return updatedRequest
        }

        throw NetworkError.missingAuthorization
    }
}
