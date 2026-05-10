//
//  StubNetworkClient.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation
@testable import Networking

/// 테스트에서 네트워크 응답을 고정값으로 주입하는 Stub입니다.
final class StubNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    var dataResult: Result<Data, Error> = .failure(NetworkError.unknown)
    var decodedResult: Result<Any, Error> = .failure(NetworkError.unknown)

    func request<T: Decodable & Sendable>(
        _ endpoint: Endpoint,
        as type: T.Type
    ) async throws -> T {
        switch decodedResult {
        case .success(let value):
            guard let typedValue = value as? T else {
                throw NetworkError.invalidRequest
            }
            return typedValue
        case .failure(let error):
            throw error
        }
    }

    func request(_ endpoint: Endpoint) async throws -> Data {
        switch dataResult {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }
}
