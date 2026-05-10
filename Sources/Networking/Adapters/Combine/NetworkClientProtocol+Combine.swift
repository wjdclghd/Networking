//
//  NetworkClientProtocol+Combine.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation
import Combine

public extension NetworkClientProtocol {
    /// 요청 결과를 Combine publisher로 반환합니다.
    ///
    /// - Parameters:
    ///   - endpoint: 실행할 요청 정보입니다.
    ///   - type: 디코딩할 응답 타입입니다.
    /// - Returns: 디코딩된 응답 값을 방출하는 publisher입니다.
    func publisher<T: Decodable & Sendable>(
        _ endpoint: Endpoint,
        as type: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        Future<T, NetworkError> { promise in
            Task {
                do {
                    let result = try await self.request(endpoint, as: type)
                    promise(.success(result))
                } catch let error as NetworkError {
                    promise(.failure(error))
                } catch {
                    promise(.failure(.transport(error)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// 원본 Data 요청 결과를 Combine publisher로 반환합니다.
    ///
    /// - Parameter endpoint: 실행할 요청 정보입니다.
    /// - Returns: 응답 body Data를 방출하는 publisher입니다.
    func publisher(_ endpoint: Endpoint) -> AnyPublisher<Data, NetworkError> {
        Future<Data, NetworkError> { promise in
            Task {
                do {
                    let result = try await self.request(endpoint)
                    promise(.success(result))
                } catch let error as NetworkError {
                    promise(.failure(error))
                } catch {
                    promise(.failure(.transport(error)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
