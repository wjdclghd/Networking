//
//  StubEncodingFailure.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

enum EncodingFailureError: Error {
    case forcedFailure
}

/// 테스트에서 JSON 인코딩 실패를 강제로 발생시키는 Stub입니다.
struct StubEncodingFailure: Encodable, Sendable {
    func encode(to encoder: Encoder) throws {
        throw EncodingFailureError.forcedFailure
    }
}
