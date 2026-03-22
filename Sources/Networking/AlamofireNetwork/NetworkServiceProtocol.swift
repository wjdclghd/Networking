//
//  NetworkServiceProtocol.swift
//  CoreNetwork
//
//  Created by jch on 6/29/25.
//

import Foundation
import Combine

public protocol NetworkServiceProtocol {
    func request<T: Decodable & Sendable>(_ endpoint: APIEndpoint, type: T.Type) -> AnyPublisher<T, NetworkError>
}
