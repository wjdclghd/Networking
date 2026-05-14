# Networking Module

Clean Architecture + MVVM 환경에서 App 타겟이 SPM 모듈로 의존하는 형태를 전제로 만든 Networking 모듈입니다.
이 모듈은 **HTTP 네트워크 클라이언트(HTTP Networking Client)** 역할에 집중하며, URLSession / Alamofire 기반 구현 세부를 외부에 직접 노출하지 않고 **공개 계약 + 공개 모델 + 내부 구현체**로 역할을 분리합니다.

모듈 내부는 Endpoint 기반 요청 조립, 응답 매핑, HTTP 에러 변환, 인증 토큰 주입, 이벤트 로깅, 재시도 정책, Combine 어댑터 기능을 포함하며,
상위 계층은 `NetworkClientProtocol`을 통해 `URLSessionNetworkClient` 또는 `AlamofireNetworkClient`를 즉시 사용할 수 있습니다.

**요약**
- 공개 계약: `NetworkClientProtocol`
- 요청 조립: `NetworkRequestBuilder`
- 응답 매핑: `NetworkResponseMapper`
- 설정 객체: `NetworkConfiguration`
- HTTP 에러 모델: `NetworkError.http(NetworkHTTPError)` 통합
- 서버 에러 body 보존: `NetworkErrorPayload`
- 인증 전략: `AuthorizationProvider` (동기) / `AuthorizationProviderAsync` (비동기)
- 이벤트 로깅: `NetworkEventLogger` + `NetworkEvent`
- 재시도 정책: `NetworkRetryPolicy`
- Combine 어댑터: `NetworkClientProtocol+Combine`
- 빈 성공 응답: `EmptyResponse`
- 구현체: `URLSessionNetworkClient`, `AlamofireNetworkClient`

---

**모듈 구조**
```text
Networking/
├─ Package.swift
├─ Sources/
│  └─ Networking/
│     ├─ Adapters/
│     │  └─ Combine/
│     │     └─ NetworkClientProtocol+Combine.swift
│     ├─ Core/
│     │  ├─ Auth/
│     │  │  ├─ AuthorizationProvider.swift
│     │  │  ├─ AuthorizationProviderAsync.swift
│     │  │  └─ StaticBearerTokenProvider.swift
│     │  ├─ Client/
│     │  │  ├─ NetworkClientProtocol.swift
│     │  │  ├─ NetworkRequestBuilder.swift
│     │  │  └─ NetworkResponseMapper.swift
│     │  ├─ Config/
│     │  │  └─ NetworkConfiguration.swift
│     │  ├─ Endpoint/
│     │  │  ├─ AnyEncodable.swift
│     │  │  ├─ Endpoint.swift
│     │  │  ├─ FormURLEncodedSerializer.swift
│     │  │  ├─ HTTPMethod.swift
│     │  │  └─ HTTPTask.swift
│     │  ├─ Error/
│     │  │  ├─ NetworkError.swift
│     │  │  ├─ NetworkHTTPError.swift
│     │  │  └─ NetworkErrorPayload.swift
│     │  ├─ Response/
│     │  │  └─ EmptyResponse.swift
│     │  ├─ NetworkEvent.swift
│     │  ├─ NetworkEventLogger.swift
│     │  └─ NetworkRetryPolicy.swift
│     └─ Implementations/
│        ├─ AlamofireClient/
│        │  └─ AlamofireNetworkClient.swift
│        └─ URLSessionClient/
│           └─ URLSessionNetworkClient.swift
└─ Tests/
   └─ NetworkingTests/
      ├─ Adapters/
      │  └─ NetworkClientProtocolCombineTests.swift
      ├─ Core/
      │  ├─ EndpointTests.swift
      │  ├─ NetworkErrorTests.swift
      │  ├─ NetworkRequestBuilderTests.swift
      │  └─ NetworkResponseMapperTests.swift
      ├─ Implementations/
      │  ├─ AlamofireClient/
      │  │  └─ AlamofireNetworkClientTests.swift
      │  └─ URLSessionClient/
      │     └─ URLSessionNetworkClientTests.swift
      ├─ TestDoubles/
      │  ├─ Stubs/
      │  │  ├─ StubNetworkClient.swift
      │  │  ├─ StubURLProtocol.swift
      │  │  └─ StubEncodingFailure.swift
      │  └─ Fixtures/
      │     ├─ RequestBodyFixture.swift
      │     ├─ UserResponseFixture.swift
      │     └─ SampleResponseData.swift
      └─ Utility/
         ├─ TestUtility.swift
         └─ XCTestCase+URL.swift
```

---

**빠른 시작**

`URLSessionNetworkClient`는 `NetworkClientProtocol`을 즉시 사용할 수 있는 기본 구현체입니다.

```swift
import Networking

let requestBuilder = NetworkRequestBuilder(
    authorizationProvider: StaticBearerTokenProvider(token: "access-token"),
    configuration: .default
)
let client = URLSessionNetworkClient(requestBuilder: requestBuilder)

// Decodable 응답 디코딩
let dto: SearchAppStoreResponseDTO = try await client.request(endpoint, as: SearchAppStoreResponseDTO.self)

// 원본 Data 반환
let data: Data = try await client.request(endpoint)
```

테스트나 샘플 실행처럼 실제 토큰이 없는 환경에서는 `StaticBearerTokenProvider`를 사용합니다.

```swift
import Networking

let client = URLSessionNetworkClient(
    requestBuilder: NetworkRequestBuilder(
        authorizationProvider: StaticBearerTokenProvider(token: nil),
        configuration: .default
    )
)
```

Keychain 또는 메모리 기반 토큰 저장소처럼 비동기 조회가 필요한 경우에는 `AuthorizationProviderAsync`를 구현합니다.

```swift
import Networking

let requestBuilder = NetworkRequestBuilder(
    authorizationProvider: nil,
    authorizationProviderAsync: KeychainBearerTokenProvider(environment: "production"),
    configuration: NetworkConfiguration(
        timeoutInterval: 30,
        defaultHeaders: ["X-App-Version": "1.0.0"],
        logger: ConsoleNetworkLogger(),
        retryPolicy: ExponentialBackoffRetryPolicy()
    )
)
let client = URLSessionNetworkClient(requestBuilder: requestBuilder)
```

---

**핵심 설계 방향**

- **공개 계약과 내부 HTTP 구현 분리**
  상위 계층은 `NetworkClientProtocol`과 `Core/` 공개 타입에만 의존합니다.
  URLSession, Alamofire, prepared request 세부 구현은 `Implementations/` 내부에 감춥니다.

- **HTTP 에러 통합**
  non-2xx 응답은 모두 `NetworkError.http(NetworkHTTPError)`로 통합합니다.
  `.unauthorized`, `.forbidden`, `.serverError` 같이 HTTP status별 case를 두지 않습니다.
  서버 공통 에러 body(`code`, `message`, `details`)를 `NetworkErrorPayload`로 보존하고, AppData가 도메인 의미를 해석합니다.

- **조립 지점 통일**
  `NetworkRequestBuilder`가 `Endpoint` → `URLRequest` 변환, 인증 토큰 주입, header 병합, body 인코딩을 담당합니다.
  구현체(`URLSessionNetworkClient` / `AlamofireNetworkClient`)는 동일한 `requestBuilder`를 기준으로 조립합니다.

- **기능 책임 분리**
  - 요청 정보 표현: `Endpoint`, `HTTPTask`, `HTTPMethod`
  - 요청 조립: `NetworkRequestBuilder`
  - 응답 매핑: `NetworkResponseMapper`
  - 에러 표현: `NetworkError`, `NetworkHTTPError`, `NetworkErrorPayload`
  - 인증 주입: `AuthorizationProvider`, `AuthorizationProviderAsync`
  - 이벤트 로깅: `NetworkEvent`, `NetworkEventLogger`
  - 재시도 정책: `NetworkRetryPolicy`
  - Combine 연동: `NetworkClientProtocol+Combine`

- **테스트 친화적인 구조**
  `StubURLProtocol`이 URLSession 요청을 가로채 고정 응답을 반환합니다.
  실제 네트워크 호출 없이 URLSession, Alamofire 구현체의 요청 실행, 응답 디코딩, 에러 매핑을 검증합니다.

---

**NetworkClientProtocol**

`NetworkClientProtocol`은 상위 계층이 의존하는 공개 네트워크 클라이언트 계약입니다.

```swift
public protocol NetworkClientProtocol: Sendable {
    func request<T: Decodable & Sendable>(
        _ endpoint: Endpoint,
        as type: T.Type
    ) async throws -> T

    func request(_ endpoint: Endpoint) async throws -> Data
}
```

---

**NetworkRequestBuilder**

`NetworkRequestBuilder`는 `Endpoint`를 `URLRequest`로 변환하는 **요청 조립 진입점**입니다.

담당:
- `defaultHeaders`와 `Endpoint.headers` 병합 (Endpoint 우선)
- `requiresAuthorization` 기준 Authorization header 주입
- `HTTPTask` 기준 body 인코딩 및 Content-Type 설정
- `queryItems` URL 조립
- timeout, cachePolicy 적용

```swift
let requestBuilder = NetworkRequestBuilder(
    authorizationProvider: tokenProvider,
    configuration: NetworkConfiguration(
        timeoutInterval: 30,
        defaultHeaders: ["Accept": "application/json"]
    )
)
```

동기 provider와 비동기 provider를 모두 주입하면 동기 provider를 먼저 시도합니다.
`requiresAuthorization = false`인 공개 API에는 Authorization header를 보내지 않습니다.

---

**NetworkConfiguration**

`NetworkConfiguration`은 요청 생성과 실행에 사용하는 공통 설정입니다.

주요 설정 항목:
- `timeoutInterval`: 요청 제한 시간
- `cachePolicy`: URLRequest 캐시 정책
- `defaultHeaders`: 모든 요청에 기본으로 적용할 header
- `logger`: 요청 이벤트를 기록할 logger
- `retryPolicy`: 실패한 요청의 재시도 정책

생성 방법:
- `NetworkConfiguration(...)`: 항목별 직접 설정
- `NetworkConfiguration.default`: 기본값 (timeout 30초, 캐시/로거/재시도 미설정)

```swift
// 기본 설정
let configuration = NetworkConfiguration.default

// 커스텀 설정
let configuration = NetworkConfiguration(
    timeoutInterval: 30,
    cachePolicy: .reloadIgnoringLocalCacheData,
    defaultHeaders: [
        "Accept": "application/json",
        "X-App-Version": "1.0.0"
    ],
    logger: ConsoleNetworkLogger(),
    retryPolicy: ExponentialBackoffRetryPolicy()
)
```

---

**현재 구현 기능**

### 1. Endpoint 기반 요청 조립

요청 정보를 `Endpoint` 한 타입으로 표현하고 `NetworkRequestBuilder`가 `URLRequest`로 변환합니다.

- `baseURL` + `path` 조합
- `queryItems` URL 인코딩
- `method` 적용
- `defaultHeaders` + `Endpoint.headers` 병합 (Endpoint 우선)
- `HTTPTask` 기준 body 인코딩 및 Content-Type 자동 설정

```swift
let endpoint = Endpoint(
    baseURL: URL(string: "https://itunes.apple.com")!,
    path: "/search",
    method: .get,
    queryItems: [
        URLQueryItem(name: "term", value: "kakaotalk"),
        URLQueryItem(name: "country", value: "kr")
    ],
    requiresAuthorization: false
)
```

관련 타입: `Endpoint`, `HTTPTask`, `HTTPMethod`, `NetworkRequestBuilder`, `FormURLEncodedSerializer`

### 2. HTTP 에러 통합 매핑

모든 non-2xx HTTP 응답을 `NetworkError.http(NetworkHTTPError)`로 통합합니다.

- `200..<300` → 성공 Data 반환
- non-2xx → `NetworkError.http(NetworkHTTPError)` throw
  - 서버 공통 에러 body 디코딩 성공 → `NetworkHTTPError.payload`에 보존
  - 디코딩 실패 → `statusCode` + `data`만 보존

서버 공통 에러 body 형식:
```json
{
  "code": "AUTH_INVALID_CREDENTIALS",
  "message": "이메일 또는 비밀번호가 올바르지 않습니다.",
  "details": [],
  "timestamp": "2026-05-10T09:00:00Z"
}
```

관련 타입: `NetworkResponseMapper`, `NetworkHTTPError`, `NetworkErrorPayload`

### 3. 인증 토큰 주입

`requiresAuthorization = true`인 요청에 `Authorization: Bearer {token}` header를 자동으로 추가합니다.

- 동기 provider: `AuthorizationProvider.bearerToken`
- 비동기 provider: `AuthorizationProviderAsync.bearerToken()` (Keychain 등 비동기 조회)
- 동기 provider가 우선, nil이면 비동기 provider 시도
- token이 없으면 `NetworkError.missingAuthorization` throw
- `requiresAuthorization = false` 공개 API는 Authorization header를 보내지 않음

관련 타입: `AuthorizationProvider`, `AuthorizationProviderAsync`, `StaticBearerTokenProvider`

### 4. 이벤트 로깅

`NetworkEventLogger`를 구현하면 요청 생명주기 전체를 기록할 수 있습니다.

```swift
public enum NetworkEvent: Sendable {
    case requestStarted(id: UUID, request: URLRequest)
    case requestFinished(id: UUID, request: URLRequest, response: HTTPURLResponse?, data: Data?, duration: TimeInterval)
    case requestFailed(id: UUID, request: URLRequest, error: Error, duration: TimeInterval)
}
```

관련 타입: `NetworkEvent`, `NetworkEventLogger`, `NetworkConfiguration.logger`

### 5. 재시도 정책

`NetworkRetryPolicy`를 구현하면 실패한 요청의 재시도 동작을 제어할 수 있습니다.

- `retryDelay(for:error:attempt:) → TimeInterval?`
- `nil` 반환 → 재시도 없음
- `TimeInterval` 반환 → 해당 초 대기 후 재시도

```swift
struct ExponentialBackoffRetryPolicy: NetworkRetryPolicy {
    func retryDelay(for request: URLRequest, error: Error, attempt: Int) -> TimeInterval? {
        guard attempt < 3 else { return nil }
        return pow(2.0, Double(attempt))
    }
}
```

관련 타입: `NetworkRetryPolicy`, `NetworkConfiguration.retryPolicy`

### 6. Combine 어댑터

`NetworkClientProtocol`을 준수하는 모든 타입에 Combine publisher 확장을 제공합니다.

```swift
// Decodable 응답
client.publisher(endpoint, as: SearchAppStoreResponseDTO.self)
    .sink(receiveCompletion: { _ in }, receiveValue: { dto in })
    .store(in: &cancellables)

// 원본 Data 응답
client.publisher(endpoint)
    .sink(receiveCompletion: { _ in }, receiveValue: { data in })
    .store(in: &cancellables)
```

관련 타입: `NetworkClientProtocol+Combine`

### 7. 빈 성공 응답 (EmptyResponse)

`204 No Content`처럼 body가 비어 있는 성공 응답에 사용합니다.
`Endpoint.allowsEmptyResponse = true`로 설정해야 빈 응답을 정상 처리합니다.

```swift
let endpoint = Endpoint(
    baseURL: baseURL,
    path: "/v1/auth/logout",
    method: .post,
    requiresAuthorization: true,
    allowsEmptyResponse: true
)
let _: EmptyResponse = try await client.request(endpoint, as: EmptyResponse.self)
```

관련 타입: `EmptyResponse`, `Endpoint.allowsEmptyResponse`

---

**공개 계약과 타입**

### NetworkClientProtocol

| 메서드 | 설명 |
|---|---|
| `request(_:as:) async throws -> T` | Decodable 응답 디코딩 |
| `request(_:) async throws -> Data` | 원본 Data 반환 |

### Endpoint

| 프로퍼티 | 타입 | 설명 |
|---|---|---|
| `baseURL` | `URL` | 요청의 기준 URL |
| `path` | `String` | 기준 URL 뒤에 붙일 path |
| `method` | `HTTPMethod` | HTTP method |
| `headers` | `[String: String]` | 요청 단위 header |
| `queryItems` | `[URLQueryItem]` | URL query parameter |
| `task` | `HTTPTask` | body 구성 방식 |
| `requiresAuthorization` | `Bool` | Authorization header 필요 여부 |
| `allowsEmptyResponse` | `Bool` | 빈 성공 응답 허용 여부 |

### HTTPTask

| case | Content-Type |
|---|---|
| `.plain` | 설정 안 함 |
| `.jsonEncodable(AnyEncodable)` | `application/json` |
| `.formURLEncoded([String: String])` | `application/x-www-form-urlencoded` |

`Endpoint.headers["Content-Type"]`가 명시되어 있으면 task의 자동 설정보다 우선합니다.

### HTTPMethod

`GET`, `POST`, `PUT`, `PATCH`, `DELETE`

### NetworkError

| case | 설명 |
|---|---|
| `invalidURL` | URL 생성 실패 |
| `invalidRequest` | 요청 생성 실패 |
| `missingAuthorization` | 인증 토큰 없음 |
| `encoding(Error)` | body 인코딩 실패 |
| `decoding(Error)` | 응답 디코딩 실패 |
| `timeout` | 요청 시간 초과 |
| `cancelled` | 요청 취소 |
| `emptyResponse` | 허용하지 않은 빈 응답 |
| `transport(Error)` | 전송 오류 (URLError 등) |
| `http(NetworkHTTPError)` | non-2xx HTTP 응답 |
| `unknown` | 미분류 오류 |

### NetworkHTTPError

```swift
public struct NetworkHTTPError: Equatable, Sendable {
    public let statusCode: Int
    public let payload: NetworkErrorPayload?
    public let data: Data?
}
```

### NetworkErrorPayload

```swift
public struct NetworkErrorPayload: Decodable, Equatable, Sendable {
    public let code: String
    public let message: String
    public let details: [String]
    public let timestamp: String?
}
```

---

**내부 계층 구성**

### Auth
bearer token 공급 계약과 개발·테스트용 고정 구현체를 정의합니다.
- `AuthorizationProvider`: 동기 bearer token 프로토콜
- `AuthorizationProviderAsync`: 비동기 bearer token 프로토콜
- `StaticBearerTokenProvider`: 고정 token 구현체 (개발·테스트용)

### Client
네트워크 요청 계약, 요청 조립, 응답 매핑을 담당합니다.
- `NetworkClientProtocol`: 공개 클라이언트 계약
- `NetworkRequestBuilder`: Endpoint → URLRequest 변환
- `NetworkResponseMapper`: HTTP status → Data / NetworkError 변환

### Config
요청 공통 설정 객체를 정의합니다.
- `NetworkConfiguration`: timeout, header, logger, retryPolicy 통합 설정

### Endpoint
HTTP 요청 정보 타입을 정의합니다.
- `Endpoint`: 요청 정보 모델
- `HTTPTask`: body 구성 방식
- `HTTPMethod`: HTTP method enum
- `AnyEncodable`: type-erased Encodable 래퍼
- `FormURLEncodedSerializer`: form-urlencoded 직렬화

### Error
네트워크 오류 타입을 정의합니다.
- `NetworkError`: 네트워크 계층 오류 enum
- `NetworkHTTPError`: HTTP 실패 상태 (statusCode + payload + data)
- `NetworkErrorPayload`: 서버 공통 에러 body 구조체

### Response
성공 응답 마커 타입을 정의합니다.
- `EmptyResponse`: 빈 성공 응답 마커 타입

### Adapters/Combine
Combine 기반 reactive 연동 확장을 제공합니다.
- `NetworkClientProtocol+Combine`: AnyPublisher 확장 메서드

### Implementations
실제 HTTP 통신 구현체를 담당합니다.
- `URLSessionNetworkClient`: URLSession 기반 구현체 (재시도, 이벤트 로깅, Task 취소 지원)
- `AlamofireNetworkClient`: Alamofire.Session 기반 구현체

---

**HTTP 기반 foundation**

`NetworkRequestBuilder`와 `NetworkResponseMapper`가 HTTP 처리의 핵심 foundation을 담당합니다.

`NetworkRequestBuilder` 처리 순서:
1. `baseURL` + `path` 조합
2. `queryItems` URL 인코딩
3. `defaultHeaders` 적용 후 `Endpoint.headers` 병합
4. `requiresAuthorization` 기준 token 조회 및 Authorization header 주입
5. `HTTPTask` 기준 body 인코딩 + Content-Type 자동 설정
6. timeout, cachePolicy 적용

`NetworkResponseMapper` 처리 방식:
```text
200..<300  →  성공 Data 반환
non-2xx    →  NetworkError.http(NetworkHTTPError) throw
               payload 디코딩 성공 → NetworkHTTPError.payload에 보존
               payload 디코딩 실패 → statusCode + data만 보존
```

AppData에서의 에러 해석:

Networking은 서버 error code의 도메인 의미를 해석하지 않습니다.
AppData의 Mapper 또는 Repository에서 `NetworkHTTPError.payload?.code`를 기준으로 도메인 에러로 변환합니다.

```swift
// AppData/Auth Mapper 예시
func toLoginDomainError(from httpError: NetworkHTTPError) -> LoginDomainError {
    switch httpError.payload?.code {
    case "AUTH_INVALID_CREDENTIALS": return .invalidCredentials
    case "AUTH_INACTIVE_USER":       return .inactiveUser
    default:                         return .temporarilyUnavailable
    }
}
```

---

**테스트**

모듈은 in-memory stub 환경을 활용한 54개 테스트를 포함합니다.

포함된 테스트 범위:
- Core: `EndpointTests`, `NetworkErrorTests`, `NetworkRequestBuilderTests`, `NetworkResponseMapperTests`
- Implementations: `URLSessionNetworkClientTests`, `AlamofireNetworkClientTests`
- Adapters: `NetworkClientProtocolCombineTests`

테스트 전략:
- 실제 네트워크 호출을 사용하지 않습니다.
- `StubURLProtocol`이 URLSession / Alamofire 요청을 가로채 고정 응답을 반환합니다.
- 성공 응답, non-2xx HTTP 에러(payload 포함/미포함), 전송 오류, 디코딩 실패, 빈 응답 시나리오를 단위 테스트로 고정합니다.

---

**권장 사용 전략**
- 상위 계층(AppData DataSource)은 `NetworkClientProtocol`과 공개 타입을 기준으로 의존성을 설계합니다.
- 구현체(`URLSessionNetworkClient` / `AlamofireNetworkClient`) 직접 의존은 App Target DI 조립부에 제한합니다.
- 서버 error code 해석과 도메인 에러 변환은 AppData의 Mapper 또는 Repository가 담당합니다.
- 운영 환경은 `KeychainBearerTokenProvider` 구현체를 사용하고, 테스트와 개발 환경은 `StaticBearerTokenProvider`를 사용합니다.
- 재시도가 필요한 API는 `NetworkRetryPolicy`로 정책을 분리하고, 재시도 불필요 환경은 `NetworkConfiguration.retryPolicy = nil`을 유지합니다.
- `allowsEmptyResponse = true`는 `204 No Content`처럼 body가 비어 있는 성공 응답이 예상되는 엔드포인트에만 설정합니다.

---

**권장 확장 방식**
1. `Core/Endpoint`에 새 `HTTPTask` case 추가 (multipart/form-data 등)
2. `Core/Auth`에 새 `AuthorizationProvider` 구현체 추가
3. `Core/Config`에 `NetworkConfiguration` 항목 추가
4. `Core/Error`에 `NetworkError` case 추가 (도메인 공통 에러 확장 시)
5. `Core/Response`에 새 response 마커 타입 추가
6. `Implementations`에 새 HTTP 클라이언트 구현체 추가
7. `Adapters`에 새 reactive 또는 callback 어댑터 추가
8. `NetworkEventLogger` 구현체 추가 (OSLog, 원격 logging 등)
9. `NetworkRetryPolicy` 구현체 추가 (circuit breaker, jitter backoff 등)
10. 기능 전용 테스트 추가

---

Created by: JEONG, Chi-hong  
Updated: May 2026
