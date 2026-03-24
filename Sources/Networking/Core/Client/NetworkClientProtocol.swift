//
//  NetworkClientProtocol.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

public protocol NetworkClientProtocol: Sendable {
    func request<T: Decodable & Sendable>(
        _ endpoint: Endpoint,
        as type: T.Type
    ) async throws -> T

    func request(_ endpoint: Endpoint) async throws -> Data
}
