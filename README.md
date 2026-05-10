# Networking Module

Clean Architecture + MVVM 환경에서 App 타겟이 SPM 모듈로 의존하는 형태를 전제로 만든 Networking 모듈입니다. 모듈 내부는 정책을 강제하지 않고, App 레벨에서 로깅/재시도/인증 전략을 주입할 수 있도록 확장 지점을 제공합니다.

**요약**
- 요청 생성: `Endpoint` + `NetworkRequestBuilder`
- 실행 클라이언트: `URLSessionNetworkClient` 또는 `AlamofireNetworkClient`
- 응답 매핑: `NetworkResponseMapper`
- 확장 지점: `NetworkEventLogger`, `NetworkRetryPolicy`, `AuthorizationProviderAsync`

---

**모듈 구조**
- Core
- Endpoint/HTTPTask/HTTPMethod
- RequestBuilder
- ResponseMapper
- Error/NetworkError
- Implementations

---

**빠른 시작**
```swift
let configuration = NetworkConfiguration(
    timeoutInterval: 30,
    defaultHeaders: ["X-App-Version": "1.0.0"]
)

let requestBuilder = NetworkRequestBuilder(
    authorizationProvider: StaticBearerTokenProvider(token: "token"),
    configuration: configuration
)

let client = URLSessionNetworkClient(requestBuilder: requestBuilder)

let endpoint = Endpoint(
    baseURL: URL(string: "https://example.com")!,
    path: "/users/me",
    method: .get,
    requiresAuthorization: true
)

let data = try await client.request(endpoint)
```

---

**Endpoint 설계**
`Endpoint`는 요청의 구조를 정의합니다.
- `baseURL`, `path`, `method`
- `headers`, `queryItems`
- `task`: `.plain`, `.jsonEncodable`, `.formURLEncoded`
- `requiresAuthorization`
- `allowsEmptyResponse`

예시:
```swift
let endpoint = Endpoint(
    baseURL: URL(string: "https://example.com")!,
    path: "/login",
    method: .post,
    task: .formURLEncoded([
        "email": "user@example.com",
        "password": "1234"
    ]),
    requiresAuthorization: false
)
```

---

**RequestBuilder**
`NetworkRequestBuilder`는 `Endpoint`를 `URLRequest`로 변환합니다.
- 기본 헤더와 Endpoint 헤더 병합
- Content-Type 자동 설정
- Authorization 헤더 자동 설정

Content-Type 우선순위:
- `Endpoint.headers["Content-Type"]`가 있으면 유지
- 없으면 `task` 종류에 따라 자동 설정

---

**응답 처리**
`NetworkResponseMapper`는 상태 코드를 매핑합니다.
- 200..<300: data 반환
- 401: `NetworkError.unauthorized`
- 403: `NetworkError.forbidden`
- 그 외: `NetworkError.server(statusCode:data:)`

---

**에러 모델**
`NetworkError`는 네트워크 오류를 일관된 형태로 제공합니다.
- 요청/인코딩/디코딩 오류
- 인증/권한/타임아웃/취소
- 전송/서버/알 수 없는 오류

---

**관측성(Logging/Tracing)**
모듈은 로그 정책을 강제하지 않습니다. `NetworkEventLogger`를 통해 App 레벨에서 로깅/트레이싱을 통일할 수 있습니다.

```swift
final class ConsoleLogger: NetworkEventLogger {
    func log(_ event: NetworkEvent) {
        print(event)
    }
}

let configuration = NetworkConfiguration(
    logger: ConsoleLogger()
)
```

이벤트 종류:
- `requestStarted`
- `requestFinished`
- `requestFailed`

---

**재시도 정책**
`NetworkRetryPolicy`로 재시도 여부와 지연을 결정합니다. 모듈은 정책을 강제하지 않습니다.

```swift
struct SimpleRetryPolicy: NetworkRetryPolicy {
    func retryDelay(
        for request: URLRequest,
        error: Error,
        attempt: Int
    ) -> TimeInterval? {
        guard attempt < 2 else { return nil }
        return 0.5 * Double(attempt + 1)
    }
}

let configuration = NetworkConfiguration(
    retryPolicy: SimpleRetryPolicy()
)
```

---

**인증(토큰 주입/갱신)**
동기/비동기 방식 모두 지원합니다.

동기 방식:
```swift
let requestBuilder = NetworkRequestBuilder(
    authorizationProvider: StaticBearerTokenProvider(token: "token")
)
```

비동기 방식:
```swift
struct AsyncTokenProvider: AuthorizationProviderAsync {
    func bearerToken() async throws -> String? {
        // 토큰 갱신/조회 로직
        return "token"
    }
}

let requestBuilder = NetworkRequestBuilder(
    authorizationProviderAsync: AsyncTokenProvider()
)
```

`requiresAuthorization`이 `true`인 경우에만 Authorization 헤더가 적용됩니다.

---

**클라이언트 선택**
- `URLSessionNetworkClient`: 기본 네이티브 구현
- `AlamofireNetworkClient`: Alamofire 기반 구현

프로젝트 정책에 따라 하나만 선택해 사용해도 됩니다.

---

**테스트**
모듈은 URLProtocol 기반의 단위 테스트를 포함합니다.
- Endpoint/RequestBuilder/Error/Client 테스트 포함
- App 레벨의 정책은 모듈 외부에서 테스트

---

**권장 사용 전략**
- 모듈은 최소 정책만 제공
- 로깅/재시도/인증 전략은 App 또는 상위 모듈에서 주입
- 도메인별 정책 분리를 위해 `NetworkConfiguration`을 계층별로 구성


Created by: JEONG, Chi-hong
Initial version: June 2026
