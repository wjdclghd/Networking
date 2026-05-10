//
//  URLSessionNetworkClient.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

/// URLSession을 사용해 Endpoint 요청을 실행합니다.
///
/// URLSession 같은 reference 기반 협력 객체를 보관하므로 `@unchecked Sendable`을 사용합니다.
public final class URLSessionNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    private let session: URLSession
    private let requestBuilder: NetworkRequestBuilder
    private let decoderFactory: @Sendable () -> JSONDecoder

    /// URLSession 기반 네트워크 client를 생성합니다.
    ///
    /// - Parameters:
    ///   - session: 요청 실행에 사용할 URLSession입니다.
    ///   - requestBuilder: Endpoint를 URLRequest로 변환할 builder입니다.
    ///   - decoderFactory: 응답 디코딩에 사용할 decoder 생성 클로저입니다.
    public init(
        session: URLSession = .shared,
        requestBuilder: NetworkRequestBuilder,
        decoderFactory: @escaping @Sendable () -> JSONDecoder = { JSONDecoder() }
    ) {
        self.session = session
        self.requestBuilder = requestBuilder
        self.decoderFactory = decoderFactory
    }

    /// 요청을 실행하고 응답 body를 지정한 타입으로 디코딩합니다.
    ///
    /// - Parameters:
    ///   - endpoint: 실행할 요청 정보입니다.
    ///   - type: 디코딩할 응답 타입입니다.
    /// - Returns: 디코딩된 응답 값입니다.
    /// - Throws: 요청 생성, 전송, 응답 매핑, 디코딩 실패 시 `NetworkError`를 던집니다.
    public func request<T: Decodable & Sendable>(
        _ endpoint: Endpoint,
        as type: T.Type
    ) async throws -> T {
        let data = try await request(endpoint)

        guard !data.isEmpty else {
            if endpoint.allowsEmptyResponse, let emptyValue = EmptyResponse() as? T {
                return emptyValue
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

    /// 요청을 실행하고 응답 body를 원본 Data로 반환합니다.
    ///
    /// - Parameter endpoint: 실행할 요청 정보입니다.
    /// - Returns: 응답 body Data입니다.
    /// - Throws: 요청 생성, 전송, 응답 매핑 실패 시 `NetworkError`를 던집니다.
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
