<img width="240" height="240" alt="야놀자" src="https://github.com/user-attachments/assets/a9a8b84e-21d2-49b7-8e80-1a6ee3d4b4fa" />
<img width="240" height="240" alt="여기어때" src="https://github.com/user-attachments/assets/479e92b5-a638-4b89-b962-1a8418745ff4" />

# Accommodation Reservation

숙소 예약 도메인(Event Storming)을 기반으로 한 **Spring Boot + Kafka EDA** 데모 프로젝트입니다.  
단일 애플리케이션으로 예약·결제·재고 흐름을 구현하고, **Docker Compose** 로 로컬에서 API Gateway·Kafka·무정지 재배포·스케일 아웃을 체험할 수 있습니다.

| 항목 | 내용 |
|------|------|
| Docker Hub | `pop2bubble/accommodation-reservation:latest` |
| 로컬 진입점 | `http://localhost:8080` (nginx API Gateway) |
| API Prefix | `/api` |
| Java | 21 |
| DB | H2 (인메모리) |
| 메시지 브로커 | Apache Kafka |

---

# 목차

- [빠른 시작 (Docker)](#빠른-시작-docker)
- [프로젝트 구조](#프로젝트-구조)
- [Docker Hub 배포](#docker-hub-배포)
- [API 게이트웨이 및 라우팅](#api-게이트웨이-및-라우팅)
- [서비스 시나리오](#서비스-시나리오)
- [체크포인트](#체크포인트)
- [분석/설계](#분석설계)
- [구현](#구현)
- [운영 (로컬 Docker)](#운영-로컬-docker)
- [운영 (Kubernetes, 참고)](#운영-kubernetes-참고)

---

# 빠른 시작 (Docker)

## 사전 요구사항

- Docker Desktop (또는 Docker Engine + Compose v2)
- PowerShell 5.1 이상 (Windows)

## 1. 전체 스택 기동

```powershell
cd Accommodation-reservation
.\scripts\docker-local-up.ps1
```

기동 구성: **Kafka** + **Spring Boot 앱** + **nginx Gateway**  
약 1분 후 `http://localhost:8080` 접속.

## 2. API 테스트

```powershell
.\scripts\docker-api-test.ps1
```

## 3. 종료

```powershell
docker compose down
```

## 로컬 개발 (Gradle)

```powershell
.\gradlew.bat bootRun
```

Kafka 없이 실행하려면 `src/test/resources/application.properties` 와 같이 `app.kafka.enabled=false` 를 설정합니다.

---

# 프로젝트 구조

```
Accommodation-reservation/
├── src/main/java/com/hotel/Accommodation/reservation/
│   ├── AccommodationReservationApplication.java   # 메인
│   ├── controller/ReservationController.java      # REST Inbound Adapter (/api)
│   ├── service/ReservationService.java            # 도메인 서비스 (Command 처리)
│   ├── domain/                                    # Aggregate
│   │   ├── Reservation.java
│   │   ├── PaymentHistory.java
│   │   ├── RoomInventory.java
│   │   └── ReservationStatus.java
│   ├── repository/                                # JPA Repository
│   ├── dto/ReserveRequest.java
│   ├── dto/event/ReservationCreated.java          # Kafka 이벤트 DTO
│   ├── event/ReservationEventPublisher.java       # Publish (After Commit)
│   ├── infra/ReservationCreatedPolicyHandler.java # Subscribe (@KafkaListener)
│   └── config/                                    # Security, Kafka, Seed Data
├── src/main/resources/
│   ├── application.properties
│   └── static/                                    # 웹 UI (index.html)
├── nginx/default.conf                             # API Gateway (리버스 프록시)
├── docker-compose.yml                             # kafka + app + gateway
├── docker-compose.no-healthcheck.yml              # 무정지 재배포 대조군용
├── Dockerfile
├── k8s/                                           # Kubernetes 매니페스트 (참고)
└── scripts/
    ├── docker-local-up.ps1                        # Compose 기동
    ├── docker-api-test.ps1                        # API 라우팅 테스트
    ├── docker-load-test.ps1                       # 부하 테스트
    ├── docker-scale-test.ps1                      # 스케일 아웃 체험
    ├── docker-rolling-update.ps1                  # 무정지 재배포 체험
    ├── docker-publish.ps1                         # build & push
    ├── _api.ps1 / _encoding.ps1                   # UTF-8 API 헬퍼
    └── docker-publish.sh / podman-push.sh
```

---

# Docker Hub 배포

```powershell
# 빌드 + push
.\scripts\docker-publish.ps1 -Tag latest

# v2 태그 (무정지 재배포 테스트용)
.\scripts\docker-publish.ps1 -Tag v2
```

환경 변수:

```bash
DOCKERHUB_USERNAME=pop2bubble
IMAGE_NAME=accommodation-reservation
TAG=latest
```

Linux / Git Bash:

```bash
PUSH=false ./scripts/docker-publish.sh          # 빌드만
DOCKERHUB_USERNAME=pop2bubble ./scripts/docker-publish.sh
```

Gitpod/Ona 자동화는 `.ona/automations.yaml` 에 정의되어 있으며, 무료 이용량 제한 시 **로컬 Docker** 방식을 사용합니다.

---

# API 게이트웨이 및 라우팅

클라이언트는 복잡한 내부 포트를 알 필요 없이 **단일 진입점(`localhost:8080`)** 으로 요청합니다.  
`nginx` 가 `accommodation-reservation:8080` 으로 프록시합니다.

| 기능 | Method | URL |
|------|--------|-----|
| 객실 목록 | GET | `/api/rooms` |
| 예약 생성 | POST | `/api/reservations` |
| 결제 | POST | `/api/reservations/{id}/pay` |
| 예약 승인 (Host) | POST | /api/reservations/{id}/approve` |
| 예약 취소 | POST | `/api/reservations/{id}/cancel` |
| 환불 | POST | `/api/reservations/{id}/refund` |
| 결제 이력 조회 | GET | `/api/payments` |

`ReservationController` 에 `@RequestMapping("/api")`, `@CrossOrigin` 이 선언되어 CORS 및 공통 API 경로가 통일되어 있습니다.

### 예약 요청 예시

```json
POST /api/reservations
Content-Type: application/json

{
  "roomId": 101,
  "userId": "customer01",
  "price": 120000,
  "status": "REQUESTED",
  "checkInDate": "2026-06-10",
  "checkOutDate": "2026-06-12"
}
```

---

# 서비스 시나리오

- **예약 및 결제:** 고객이 원하는 숙소의 객실을 선택하여 예약하면, 시스템에서 결제 요청으로 넘어간다. 
- **최종 예약 확정:** 결제가 성공적으로 완료되면, 해당 숙소로 예약정보가 전달된다. 점주는 이를 확인하고 예약 확정 처리를 한다. 
- **알림:** 예약 상태가 바뀔 때마다 고객에게 알림이 발송된다.
- **예약 취소:** 고객이 예약을 취소하면 결제가 취소되고, 숙소의 방 재고가 다시 생긴다.  
- **CQRS:** 고객은 본인의 예약 및 결제 현황을 실시간 화면을 통해 조회할 수 있다.

**기능적 요구사항**

1. 고객이 숙소객실을 선택하여 예약 신청을한다.
2. 예약 신청과 동시에 결제 처리가 진행된다.
3. 결제가 완료되면 이벤트를 발행하고, 숙소 시스템에서 이를 수신하여객실 재고를 차감하고 예약을 접수한다.
4. 점주는 예약을 확인하고 최종 [예약승인] 을 누르면 이벤트가 발생된다.
5. 고객이 예약을 취소할 수 있으며, 취소시 결제 환불과 객실 재고 복구가 연쇄적으로 일어난다.
6. 상태 변경이 발생할 때마다 고객에게 알림 메시지를 발송한다.
7. 고객은 자신의 예약 상태와 결제 이력등이 한눈에 보이는 마이페이지를 볼 수 있다.

**비기능적 요구사항**

1. 고객은 서버가 다운되더라도, 예약 신청 대기열을 유지하거나 서킷브레이커를 통해 예약시스템을 차단하여 시스템 마비를 방지한다.

---

# 체크포인트

- [x] 분석 설계
  - [x] 이벤트스토밍: 
    - [x] 스티커 색상별 객체의 의미를 제대로 이해하여 헥사고날 아키텍처와의 연계 설계에 적절히 반영하고 있는가?
    - [x] 각 도메인 이벤트가 의미있는 수준으로 정의되었는가?
    - [x] 어그리게잇: Command와 Event 들을 ACID 트랜잭션 단위의 Aggregate 로 제대로 묶었는가?
    - [x] 기능적 요구사항과 비기능적 요구사항을 누락 없이 반영하였는가?    

  - [x] 서브 도메인, 바운디드 컨텍스트 분리
    - [x] 팀별 KPI 와 관심사, 상이한 배포주기 등에 따른  Sub-domain 이나 Bounded Context 를 적절히 분리하였고 그 분리 기준의 합리성이 충분히 설명되는가?
      - [x] 적어도 3개 이상 서비스 분리
    - [x] 폴리글랏 설계: 각 마이크로 서비스들의 구현 목표와 기능 특성에 따른 각자의 기술 Stack 과 저장소 구조를 다양하게 채택하여 설계하였는가?
    - [x] 서비스 시나리오 중 ACID 트랜잭션이 크리티컬한 Use 케이스에 대하여 무리하게 서비스가 과다하게 조밀히 분리되지 않았는가?
  - [x] 컨텍스트 매핑 / 이벤트 드리븐 아키텍처 
    - [x] 업무 중요성과  도메인간 서열을 구분할 수 있는가? (Core, Supporting, General Domain)
    - [x] Request-Response 방식과 이벤트 드리븐 방식을 구분하여 설계할 수 있는가?
    - [x] 장애격리: 서포팅 서비스를 제거 하여도 기존 서비스에 영향이 없도록 설계하였는가?
    - [x] 신규 서비스를 추가 하였을때 기존 서비스의 데이터베이스에 영향이 없도록 설계(열려있는 아키택처)할 수 있는가?
    - [x] 이벤트와 폴리시를 연결하기 위한 Correlation-key 연결을 제대로 설계하였는가?

  - [x] 헥사고날 아키텍처
    - [x] 설계 결과에 따른 헥사고날 아키텍처 다이어그램을 제대로 그렸는가?
    
- 구현
  - [DDD] 분석단계에서의 스티커별 색상과 헥사고날 아키텍처에 따라 구현체가 매핑되게 개발되었는가?
    - Entity Pattern 과 Repository Pattern 을 적용하여 JPA 를 통하여 데이터 접근 어댑터를 개발하였는가
    - [헥사고날 아키텍처] REST Inbound adaptor 이외에 gRPC 등의 Inbound Adaptor 를 추가함에 있어서 도메인 모델의 손상을 주지 않고 새로운 프로토콜에 기존 구현체를 적응시킬 수 있는가?
    - 분석단계에서의 유비쿼터스 랭귀지 (업무현장에서 쓰는 용어) 를 사용하여 소스코드가 서술되었는가?
  - Request-Response 방식의 서비스 중심 아키텍처 구현
    - 마이크로 서비스간 Request-Response 호출에 있어 대상 서비스를 어떠한 방식으로 찾아서 호출 하였는가? (Service Discovery, REST, FeignClient)
    - 서킷브레이커를 통하여  장애를 격리시킬 수 있는가?
  - 이벤트 드리븐 아키텍처의 구현
    - 카프카를 이용하여 PubSub 으로 하나 이상의 서비스가 연동되었는가?
    - Correlation-key:  각 이벤트 건 (메시지)가 어떠한 폴리시를 처리할때 어떤 건에 연결된 처리건인지를 구별하기 위한 Correlation-key 연결을 제대로 구현 하였는가?
    - Message Consumer 마이크로서비스가 장애상황에서 수신받지 못했던 기존 이벤트들을 다시 수신받아 처리하는가?
    - Scaling-out: Message Consumer 마이크로서비스의 Replica 를 추가했을때 중복없이 이벤트를 수신할 수 있는가
    - CQRS: Materialized View 를 구현하여, 타 마이크로서비스의 데이터 원본에 접근없이(Composite 서비스나 조인SQL 등 없이) 도 내 서비스의 화면 구성과 잦은 조회가 가능한가?

- 운영
  - SLA 준수
    - 셀프힐링: Liveness Probe 를 통하여 어떠한 서비스의 health 상태가 지속적으로 저하됨에 따라 어떠한 임계치에서 pod 가 재생되는 것을 증명할 수 있는가?
    - 서킷브레이커, 레이트리밋 등을 통한 장애격리와 성능효율을 높힐 수 있는가?
    - 오토스케일러 (HPA) 를 설정하여 확장적 운영이 가능한가?
    - 모니터링, 앨럿팅: 
  - 무정지 운영 CI/CD (10)
    - Readiness Probe 의 설정과 Rolling update을 통하여 신규 버전이 완전히 서비스를 받을 수 있는 상태일때 신규버전의 서비스로 전환됨을 siege 등으로 증명 

---

# 분석/설계

<img width="1280" height="720" alt="image" src="https://github.com/user-attachments/assets/e389dd64-7af9-49df-9a4b-a18e53354bed" />

## Event Storming 결과

<img width="1280" height="720" alt="image" src="https://github.com/user-attachments/assets/e7b9341a-35b3-4ad8-9d02-b9aa96ed2fd3" />

### 도메인 모델 요약 (Event Storming → 코드 매핑)

| 유형 | 이름 | 구현 |
|------|------|------|
| Actor | Customer, Host | 웹 UI / REST API 호출자 |
| Aggregate | 예약 | `Reservation` |
| Aggregate | 결제이력 | `PaymentHistory` |
| Aggregate | 방 상태정보 | `RoomInventory` |
| Command | 숙소예약 | `POST /api/reservations` |
| Command | 금액지불 | `POST /api/reservations/{id}/pay` |
| Command | 예약승인 | `POST /api/reservations/{id}/approve` |
| Command | 예약취소 | `POST /api/reservations/{id}/cancel` |
| Command | 금액환불 | `POST /api/reservations/{id}/refund` |
| Event | 예약신청됨 | `ReservationCreated` → Kafka Publish |
| Policy | 결제 승인시 재고차감 | `pay()` 시 `stockCount--` |
| Policy | 환불/취소시 재고 복구 | `refund()` / `cancel()` 시 `stockCount++` |

### 1차 완성본에 대한 기능적/비기능적 요구사항을 커버하는지 검증

- 고객이 숙소 객실을 선택하여 예약 신청을 한다. (ok)
- 예약 신청과 동시에 결제 처리가 진행된다. (ok — API 단계 분리, 동기 호출)
- 결제가 완료되면 숙소 시스템에서 이를 수신하여 객실 재고를 차감하고 예약을 접수 상태로 변경한다. (ok)
- 점주(Host)가 예약을 확인하고 최종 [예약승인] 처리를 한다. (ok)
- 고객이 예약을 취소할 수 있다. (ok)
- 예약을 취소하면 결제 환불과 객실 재고 복구가 연쇄적으로 일어난다. (ok)
- 고객은 자신의 예약 상태와 결제 이력 등을 마이페이지를 통해 한눈에 조회할 수 있다. (웹 UI + `/api/reservations`, `/api/payments` 로 조회)
- 상태 변경이 발생할 때마다 고객에게 알림 메시지를 발송한다. (설계 반영, 알림 서비스는 확장 포인트)

### 비기능적 요구사항 검증
    
- 서버가 다운되더라도 예약 신청 대기열을 유지하거나 서킷브레이커를 통해 시스템 마비를 방지한다. (Kafka Pub/Sub + Gateway + Healthcheck 로 장애 격리·복구 기반 마련)

---

# 구현

본 프로젝트는 Event Storming 결과를 **단일 Spring Boot 애플리케이션**으로 구현한 뒤, Docker Compose로 배포합니다.  
향후 Payment·Mypage 등은 별도 마이크로서비스로 분리할 수 있도록 **Kafka 이벤트 경계**를 두었습니다.

## 기술 스택

- Java 21, Spring Boot 4.0.6, Gradle
- Spring Data JPA, H2
- Spring Kafka, Apache Kafka 3.8
- Spring Security (개발용 전체 permit)
- nginx (API Gateway)
- Docker / Docker Compose

## DDD 적용

- **Aggregate Root**: `Reservation`, `PaymentHistory`, `RoomInventory`
- **Repository Pattern**: `ReservationRepository`, `PaymentHistoryRepository`, `RoomInventoryRepository`
- **도메인 상태**: `ReservationStatus` (REQUESTED → PAID → CONFIRMED / CANCELLED / REFUNDED)
- 한글 필드명 대신 영문 매핑 (`roomId`, `userId`, `price`, `status` 등)으로 Kafka·JSON 인코딩 이슈 방지

## 예약 상태 흐름

```
REQUESTED (예약신청됨)
    → pay()      → PAID (결제됨, 재고 차감)
    → approve()  → CONFIRMED (예약확정됨)
    → cancel()   → CANCELLED / REFUNDED
    → refund()   → REFUNDED (재고 복구)
```

## 이벤트 드리븐 아키텍처 (Kafka)

### Publish — 예약 생성 시

`ReservationService.reserve()` 에서 DB 저장 후 `ReservationCreated` 이벤트를 발행합니다.  
`@TransactionalEventListener(AFTER_COMMIT)` 으로 **트랜잭션 커밋 성공 후** Kafka에 전송합니다.

- 토픽: `hotel-booking-topic`
- 발행 클래스: `event/ReservationEventPublisher.java`
- 이벤트 DTO: `dto/event/ReservationCreated.java`

### Subscribe — Policy Handler

`infra/ReservationCreatedPolicyHandler.java` 가 동일 토픽을 구독합니다.  
현재는 수신 로그 및 후속 정책 확장 포인트이며, 분리 시 Payment·Notification 서비스로 이전할 수 있습니다.

```java
@KafkaListener(topics = "hotel-booking-topic", groupId = "accommodation-reservation-group")
public void wheneverReservationCreated(@Payload ReservationCreated event) { ... }
```

### REST API 테스트 (Docker 기동 후)

```powershell
.\scripts\docker-api-test.ps1
```

또는 curl:

```bash
curl http://localhost:8080/api/rooms
curl -X POST http://localhost:8080/api/reservations \
  -H "Content-Type: application/json" \
  -d '{"roomId":101,"userId":"customer01","price":120000,"checkInDate":"2026-06-10","checkOutDate":"2026-06-12"}'
```

Kafka 이벤트 발행 여부는 앱 로그에서 확인합니다.

```
ReservationCreated 이벤트 발행 완료: reservationId=...
[Subscribe] ReservationCreated 수신 - reservationId=...
```

---

# 운영 (로컬 Docker)

Kubernetes Pod 체험 대신 **로컬 Docker Compose** 로 동일 개념을 검증합니다.

| Kubernetes 개념 | 로컬 Docker 대체 |
|-----------------|------------------|
| Ingress / API Gateway | `nginx` (`localhost:8080`) |
| HPA (오토스케일) | `docker compose --scale accommodation-reservation=N` |
| Readiness Probe | Docker `healthcheck` (`/api/rooms`) |
| Rolling Update | `docker compose up -d --force-recreate` |
| siege 부하 테스트 | `scripts/docker-load-test.ps1` |

## 오토스케일 아웃 (HPA 대체)

```powershell
# replica 3개로 기동
.\scripts\docker-local-up.ps1 -Replicas 3

# CPU/메모리 모니터링
.\scripts\docker-scale-test.ps1 -Replicas 3
```

다른 터미널에서 부하:

```powershell
.\scripts\docker-load-test.ps1 -Concurrency 50 -DurationSeconds 120
```

`docker compose ps` 로 앱 컨테이너가 여러 개 뜨는지 확인합니다.

## 무정지 재배포 (Zero-Downtime)

Healthcheck **없음(대조군)** vs **있음(실험군)** Availability 를 비교합니다.

```powershell
# 대조군: Healthcheck 비활성
.\scripts\docker-rolling-update.ps1 -Replicas 2 -NoHealthCheck -Tag v2

# 실험군: Healthcheck 활성 (기본)
.\scripts\docker-rolling-update.ps1 -Replicas 2 -Tag v2
```

스크립트가 자동으로:

1. replica N개 기동  
2. 120초 부하 테스트 시작  
3. 20초 후 `v2` 이미지로 재배포  
4. **Availability %** 출력  

Healthcheck 적용 시 gateway가 healthy 컨테이너에만 트래픽을내므로 성공률이 더 높게 나옵니다.

## 상태 확인

```powershell
docker compose ps
docker compose logs -f accommodation-reservation
docker stats
```

## 주의사항

- H2 인메모리 DB 사용 → 컨테이너 재시작 시 예약/결제 데이터 초기화
- 객실 재고 소진 시 예약 API가 400 반환 → `docker compose restart accommodation-reservation` 으로 초기화
- PowerShell 한글 깨짐 → `scripts/_api.ps1` 의 UTF-8 API 헬퍼 사용 (`docker-api-test.ps1` 적용됨)

---

# 운영 (Kubernetes, 참고)

로컬 Docker 환경이 주 운영·테스트 경로입니다. Kubernetes 매니페스트는 `k8s/` 에 보관되어 있습니다.

```powershell
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service-nodeport.yaml
kubectl apply -f k8s/hpa.yaml
```

이미지: `pop2bubble/accommodation-reservation:latest`

```powershell
kubectl set image deployment/accommodation-reservation accommodation-reservation=pop2bubble/accommodation-reservation:v2
```

자세한 K8s 절차는 과제 환경(Pod 사용 가능 시)에서 `k8s/deployment.yaml` 의 readinessProbe 설정을 참고합니다.
