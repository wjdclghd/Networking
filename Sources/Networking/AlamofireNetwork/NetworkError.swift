//
//  NetworkError.swift
//  CoreNetwork
//
//  Created by jch on 6/29/25.
//

import Foundation
import Combine

public enum NetworkError: Error {
    case invalidError
    case decodingError
    case basic(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidError:
            return "잘못된 요청입니다."
        case .decodingError:
            return "decoding 오류"
        case .basic(let error):
            return "Alamofire Netword 오류: \(error.localizedDescription)"
        }
    }
}
