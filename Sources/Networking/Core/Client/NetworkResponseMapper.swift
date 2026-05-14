//
//  NetworkResponseMapper.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

/// HTTP status code와 body를 네트워크 계층 결과로 변환합니다.
public struct NetworkResponseMapper {
    /// HTTP 응답을 성공 Data 또는 `NetworkError`로 변환합니다.
    ///
    /// - Parameters:
    ///   - statusCode: HTTP status code입니다.
    ///   - data: 응답 body Data입니다.
    /// - Returns: 성공 응답의 body Data입니다.
    /// - Throws: 실패 status code는 `NetworkError.http`를 던집니다.
    public static func map(statusCode: Int, data: Data?) throws -> Data {
        switch statusCode {
        case 200..<300:
            return data ?? Data()
        default:
            throw NetworkError.http(
                NetworkHTTPError(
                    statusCode: statusCode,
                    payload: decodePayload(from: data),
                    data: data
                )
            )
        }
    }

    private static func decodePayload(from data: Data?) -> NetworkErrorPayload? {
        guard let data, data.isEmpty == false else {
            return nil
        }

        return try? JSONDecoder().decode(NetworkErrorPayload.self, from: data)
    }
}
