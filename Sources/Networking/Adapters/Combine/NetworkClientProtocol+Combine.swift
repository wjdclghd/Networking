//
//  NetworkClientProtocol+Combine.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation
import Combine

public extension NetworkClientProtocol {
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
