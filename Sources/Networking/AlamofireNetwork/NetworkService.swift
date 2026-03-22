//
//  NetworkService.swift
//  CoreNetwork
//
//  Created by jch on 6/29/25.
//

import Foundation
import Combine
import Alamofire

public final class NetworkService: NetworkServiceProtocol {
    private let apiKey: String?
    
    public init(apiKey: String? = nil) {
        self.apiKey = apiKey
    }
    
    public func request<T: Decodable & Sendable>(_ endpoint: APIEndpoint, type: T.Type) -> AnyPublisher<T, NetworkError> {
        var request = endpoint.urlRequest
        
        if endpoint.requiresAuth, let key = apiKey {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        
        return AF.request(request)
            .validate()
            .publishDecodable(type: T.self)
            .value()
            .mapError {
                NetworkError.basic($0)
            }
            .eraseToAnyPublisher()
    }
}
