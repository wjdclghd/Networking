//
//  AnyEncodable.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

/// 구체 타입을 숨긴 채 Encodable 값을 전달합니다.
public struct AnyEncodable: Encodable, Sendable {
    private let encodeClosure: @Sendable (Encoder) throws -> Void

    /// Encodable 값을 type-erased wrapper로 감쌉니다.
    ///
    /// - Parameter value: 인코딩할 값입니다.
    public init<T: Encodable & Sendable>(_ value: T) {
        self.encodeClosure = { encoder in
            try value.encode(to: encoder)
        }
    }

    /// 저장된 값을 전달받은 encoder에 인코딩합니다.
    ///
    /// - Parameter encoder: 값을 기록할 encoder입니다.
    /// - Throws: 원본 값 인코딩 실패 시 해당 오류를 던집니다.
    public func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
