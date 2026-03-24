//
//  URLSessionNetworkClient.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

// NOTE:
// This type currently uses @unchecked Sendable because it holds
// reference-based collaborators such as URLSession / Alamofire Session.
// Shared mutable state is intentionally minimized.
// Revisit if strict concurrency enforcement is introduced project-wide.
public final class URLSessionNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    private let session: URLSession
    private let requestBuilder: NetworkRequestBuilder
    private let decoderFactory: @Sendable () -> JSONDecoder

    public init(
        session: URLSession = .shared,
        requestBuilder: NetworkRequestBuilder,
        decoderFactory: @escaping @Sendable () -> JSONDecoder = { JSONDecoder() }
    ) {
        self.session = session
        self.requestBuilder = requestBuilder
        self.decoderFactory = decoderFactory
    }

    public func request<T: Decodable & Sendable>(
        _ endpoint: Endpoint,
        as type: T.Type
    ) async throws -> T {
        let data = try await request(endpoint)

        guard !data.isEmpty else {
            if endpoint.allowsEmptyResponse, let emptyType = T.self as? EmptyResponse.Type {
                return emptyType.init() as! T
            }
            throw NetworkError.emptyResponse
        }

        do {
            let decoder = decoderFactory()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decoding(error)
        }
    }

    public func request(_ endpoint: Endpoint) async throws -> Data {
        var request: URLRequest

        do {
            request = try requestBuilder.build(from: endpoint)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.invalidRequest
        }

        request = try await requestBuilder.applyAuthorization(
            to: request,
            requiresAuthorization: endpoint.requiresAuthorization
        )

        let requestId = UUID()
        let logger = requestBuilder.logger
        let retryPolicy = requestBuilder.retryPolicy
        var attempt = 0

        while true {
            let startTime = Date()
            logger?.log(NetworkEvent.requestStarted(id: requestId, request: request))

            do {
                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    let mappedError = NetworkError.unknown
                    logger?.log(
                        NetworkEvent.requestFailed(
                            id: requestId,
                            request: request,
                            error: mappedError,
                            duration: Date().timeIntervalSince(startTime)
                        )
                    )
                    throw mappedError
                }

                let mappedData = try NetworkResponseMapper.map(
                    statusCode: httpResponse.statusCode,
                    data: data
                )
                logger?.log(
                    NetworkEvent.requestFinished(
                        id: requestId,
                        request: request,
                        response: httpResponse,
                        data: data,
                        duration: Date().timeIntervalSince(startTime)
                    )
                )
                return mappedData
            } catch let error as NetworkError {
                logger?.log(
                    NetworkEvent.requestFailed(
                        id: requestId,
                        request: request,
                        error: error,
                        duration: Date().timeIntervalSince(startTime)
                    )
                )
                if let delay = retryPolicy?.retryDelay(for: request, error: error, attempt: attempt) {
                    attempt += 1
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                throw error
            } catch let error as URLError {
                let mappedError: NetworkError
                switch error.code {
                case .timedOut:
                    mappedError = .timeout
                case .cancelled:
                    mappedError = .cancelled
                default:
                    mappedError = .transport(error)
                }
                logger?.log(
                    NetworkEvent.requestFailed(
                        id: requestId,
                        request: request,
                        error: mappedError,
                        duration: Date().timeIntervalSince(startTime)
                    )
                )
                if let delay = retryPolicy?.retryDelay(for: request, error: mappedError, attempt: attempt) {
                    attempt += 1
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                throw mappedError
            } catch is CancellationError {
                let mappedError = NetworkError.cancelled
                logger?.log(
                    NetworkEvent.requestFailed(
                        id: requestId,
                        request: request,
                        error: mappedError,
                        duration: Date().timeIntervalSince(startTime)
                    )
                )
                throw mappedError
            } catch {
                let mappedError = NetworkError.transport(error)
                logger?.log(
                    NetworkEvent.requestFailed(
                        id: requestId,
                        request: request,
                        error: mappedError,
                        duration: Date().timeIntervalSince(startTime)
                    )
                )
                if let delay = retryPolicy?.retryDelay(for: request, error: mappedError, attempt: attempt) {
                    attempt += 1
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                throw mappedError
            }
        }
    }
}
