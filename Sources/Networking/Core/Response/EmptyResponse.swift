//
//  EmptyResponse.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

/// 성공했지만 body가 비어 있는 응답을 표현합니다.
public struct EmptyResponse: Decodable, Sendable {
    /// 빈 응답 값을 생성합니다.
    public init() {}
}
