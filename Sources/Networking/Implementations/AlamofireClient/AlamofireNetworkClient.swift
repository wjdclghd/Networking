//
//  AlamofireNetworkClient.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation
import Alamofire

// NOTE:
// This type currently uses @unchecked Sendable because it holds
// reference-based collaborators such as URLSession / Alamofire Session.
// Shared mutable state is intentionally minimized.
// Revisit if strict concurrency enforcement is introduced project-wide.
public final class AlamofireNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    private let session: Session
    private let requestBuilder: NetworkRequestBuilder
    private let decoderFactory: @Sendable () -> JSONDecoder

    public init(
        session: Session = .default,
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
        var urlRequest: URLRequest

        do {
            urlRequest = try requestBuilder.build(from: endpoint)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.invalidRequest
        }

        urlRequest = try await requestBuilder.applyAuthorization(
            to: urlRequest,
            requiresAuthorization: endpoint.requiresAuthorization
        )

        let requestId = UUID()
        let logger = requestBuilder.logger
        let retryPolicy = requestBuilder.retryPolicy
        var attempt = 0
        let requestBox = AlamofireRequestBox()

        return try await withTaskCancellationHandler {
            while true {
                let startTime = Date()
                logger?.log(NetworkEvent.requestStarted(id: requestId, request: urlRequest))

                do {
                    let data = try await performRequest(
                        urlRequest: urlRequest,
                        requestId: requestId,
                        startTime: startTime,
                        logger: logger,
                        requestBox: requestBox
                    )
                    return data
                } catch {
                    if let delay = retryPolicy?.retryDelay(for: urlRequest, error: error, attempt: attempt) {
                        attempt += 1
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                    throw error
                }
            }
        } onCancel: {
            Task {
                await requestBox.cancel()
            }
        }
    }

    private func performRequest(
        urlRequest: URLRequest,
        requestId: UUID,
        startTime: Date,
        logger: NetworkEventLogger?,
        requestBox: AlamofireRequestBox
    ) async throws -> Data {
        let request = session.request(urlRequest)
        await requestBox.set(request)

        return try await withCheckedThrowingContinuation { continuation in
            request.responseData(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success(let data):
                    guard let statusCode = response.response?.statusCode else {
                        let mappedError = NetworkError.unknown
                        logger?.log(
                            NetworkEvent.requestFailed(
                                id: requestId,
                                request: urlRequest,
                                error: mappedError,
                                duration: Date().timeIntervalSince(startTime)
                            )
                        )
                        continuation.resume(throwing: mappedError)
                        return
                    }

                    do {
                        let mappedData = try NetworkResponseMapper.map(
                            statusCode: statusCode,
                            data: data
                        )
                        logger?.log(
                            NetworkEvent.requestFinished(
                                id: requestId,
                                request: urlRequest,
                                response: response.response,
                                data: data,
                                duration: Date().timeIntervalSince(startTime)
                            )
                        )
                        continuation.resume(returning: mappedData)
                    } catch {
                        logger?.log(
                            NetworkEvent.requestFailed(
                                id: requestId,
                                request: urlRequest,
                                error: error,
                                duration: Date().timeIntervalSince(startTime)
                            )
                        )
                        continuation.resume(throwing: error)
                    }

                case .failure(let error):
                    // 200 + empty body 를 Alamofire가
                    // responseSerializationFailed(.inputDataNilOrZeroLength)
                    // 로 실패시키는 경우를 empty response 흐름으로 맞춘다.
                    if case let .responseSerializationFailed(reason) = error,
                       case .inputDataNilOrZeroLength = reason,
                       let statusCode = response.response?.statusCode,
                       (200..<300).contains(statusCode) {
                        do {
                            let mappedData = try NetworkResponseMapper.map(
                                statusCode: statusCode,
                                data: Data()
                            )
                            logger?.log(
                                NetworkEvent.requestFinished(
                                    id: requestId,
                                    request: urlRequest,
                                    response: response.response,
                                    data: Data(),
                                    duration: Date().timeIntervalSince(startTime)
                                )
                            )
                            continuation.resume(returning: mappedData)
                        } catch {
                            logger?.log(
                                NetworkEvent.requestFailed(
                                    id: requestId,
                                    request: urlRequest,
                                    error: error,
                                    duration: Date().timeIntervalSince(startTime)
                                )
                            )
                            continuation.resume(throwing: error)
                        }
                        return
                    }

                    if let underlyingError = error.underlyingError as? URLError {
                        let mappedError: NetworkError
                        switch underlyingError.code {
                        case .timedOut:
                            mappedError = .timeout
                        case .cancelled:
                            mappedError = .cancelled
                        default:
                            mappedError = .transport(underlyingError)
                        }
                        logger?.log(
                            NetworkEvent.requestFailed(
                                id: requestId,
                                request: urlRequest,
                                error: mappedError,
                                duration: Date().timeIntervalSince(startTime)
                            )
                        )
                        continuation.resume(throwing: mappedError)
                        return
                    }

                    if error.isExplicitlyCancelledError {
                        let mappedError = NetworkError.cancelled
                        logger?.log(
                            NetworkEvent.requestFailed(
                                id: requestId,
                                request: urlRequest,
                                error: mappedError,
                                duration: Date().timeIntervalSince(startTime)
                            )
                        )
                        continuation.resume(throwing: mappedError)
                        return
                    }

                    if let statusCode = response.response?.statusCode {
                        do {
                            let mappedData = try NetworkResponseMapper.map(
                                statusCode: statusCode,
                                data: response.data
                            )
                            logger?.log(
                                NetworkEvent.requestFinished(
                                    id: requestId,
                                    request: urlRequest,
                                    response: response.response,
                                    data: response.data,
                                    duration: Date().timeIntervalSince(startTime)
                                )
                            )
                            continuation.resume(returning: mappedData)
                        } catch {
                            logger?.log(
                                NetworkEvent.requestFailed(
                                    id: requestId,
                                    request: urlRequest,
                                    error: error,
                                    duration: Date().timeIntervalSince(startTime)
                                )
                            )
                            continuation.resume(throwing: error)
                        }
                    } else {
                        let mappedError = NetworkError.transport(error)
                        logger?.log(
                            NetworkEvent.requestFailed(
                                id: requestId,
                                request: urlRequest,
                                error: mappedError,
                                duration: Date().timeIntervalSince(startTime)
                            )
                        )
                        continuation.resume(
                            throwing: mappedError
                        )
                    }
                }
            }
        }
    }
}
private actor AlamofireRequestBox {
    private var request: DataRequest?

    func set(_ request: DataRequest) {
        self.request = request
    }

    func cancel() {
        request?.cancel()
    }
}

