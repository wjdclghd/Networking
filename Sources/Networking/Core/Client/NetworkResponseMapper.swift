//
//  NetworkResponseMapper.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

public struct NetworkResponseMapper {
    public static func map(statusCode: Int, data: Data?) throws -> Data {
        switch statusCode {
        case 200..<300:
            return data ?? Data()
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        default:
            throw NetworkError.server(statusCode: statusCode, data: data)
        }
    }
}
