//
//  HTTPTask.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

/// HTTP 요청 body 구성 방식을 표현합니다.
public enum HTTPTask: Sendable {
    /// body 없이 요청합니다.
    case plain
    /// Encodable 값을 JSON body로 인코딩합니다.
    case jsonEncodable(AnyEncodable)
    /// 파라미터를 form-urlencoded body로 인코딩합니다.
    case formURLEncoded([String: String])
}
