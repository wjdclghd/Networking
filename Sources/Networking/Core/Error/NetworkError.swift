//
//  NetworkError.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

public enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidRequest
    case missingAuthorization

    case encoding(Error)
    case decoding(Error)

    case unauthorized
    case forbidden
    case timeout
    case cancelled
    case emptyResponse

    case transport(Error)
    case server(statusCode: Int, data: Data?)
    case unknown

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "유효하지 않은 URL입니다."

        case .invalidRequest:
            return "잘못된 요청입니다."

        case .missingAuthorization:
            return "인증 정보가 없습니다."

        case .encoding(let error):
            return "인코딩 오류가 발생했습니다. \(error.localizedDescription)"

        case .decoding(let error):
            return "디코딩 오류가 발생했습니다. \(error.localizedDescription)"

        case .unauthorized:
            return "인증이 필요합니다."

        case .forbidden:
            return "접근 권한이 없습니다."

        case .timeout:
            return "요청 시간이 초과되었습니다."

        case .cancelled:
            return "요청이 취소되었습니다."

        case .emptyResponse:
            return "응답 데이터가 비어 있습니다."

        case .transport(let error):
            return "네트워크 전송 오류가 발생했습니다. \(error.localizedDescription)"

        case .server(let statusCode, _):
            return "서버 오류가 발생했습니다. statusCode: \(statusCode)"

        case .unknown:
            return "알 수 없는 네트워크 오류입니다."
        }
    }
}
