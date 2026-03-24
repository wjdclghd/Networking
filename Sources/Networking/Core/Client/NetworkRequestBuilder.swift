//
//  NetworkRequestBuilder.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

public struct NetworkRequestBuilder {
    private let authorizationProvider: AuthorizationProvider?
    private let authorizationProviderAsync: AuthorizationProviderAsync?
    private let configuration: NetworkConfiguration
    private let encoderFactory: @Sendable () -> JSONEncoder

    public var logger: NetworkEventLogger? {
        configuration.logger
    }

    public var retryPolicy: NetworkRetryPolicy? {
        configuration.retryPolicy
    }

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
