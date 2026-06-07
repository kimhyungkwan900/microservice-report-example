<img width="240" height="240" alt="야놀자" src="https://github.com/user-attachments/assets/a9a8b84e-21d2-49b7-8e80-1a6ee3d4b4fa" />
<img width="240" height="240" alt="여기어때" src="https://github.com/user-attachments/assets/479e92b5-a638-4b89-b962-1a8418745ff4" />

# Gitpod/Ona Docker Hub 배포

Gitpod/Ona 환경에서 Docker 이미지를 빌드하고 Docker Hub로 바로 푸시할 수 있도록 `.ona/automations.yaml`에 수동 작업을 정의했다.

필요한 secret 또는 환경변수:

```bash
DOCKERHUB_USERNAME=pop2bubble
DOCKERHUB_TOKEN=<docker-hub-access-token>
IMAGE_NAME=accommodation-reservation
TAG=latest
```

실행:

```bash
gitpod automations task start docker-build
gitpod automations task start docker-push
```

직접 실행할 수도 있다.

```bash
PUSH=false ./scripts/docker-publish.sh
DOCKERHUB_USERNAME=pop2bubble DOCKERHUB_TOKEN=<token> ./scripts/docker-publish.sh
```

Docker CLI가 없다면 Dev Container를 다시 빌드한다. `.devcontainer/devcontainer.json`에는 Docker-in-Docker와 Java 21 기능이 포함되어 있다.

# Table of contents

# 서비스 시나리오

예약 및 결제: 고객이 원하는 숙소의 객실을 선택하여 예약하면, 시스템에서 결제 요청으로 넘어간다.
최종 예약 확정: 결제가 성공적으로 완료되면, 해당 숙소로 예약정보가 전달된다. 점주는 이를 확인하고 예약 확정 처리를 한다.
알림: 예약 상태가 바뀔 때마다 고객에게 알림이 발송된다.
예약 취소: 고객이 예약을 취소하면 결제가 취소되고, 숙소의 방 재고가 다시 생긴다.
CQRS: 고객은 본인의 예약 및 결제 현황을 실시간 화면을 통해 조회할 수 있다.

기능적 요구사항
1. 고객이 숙소객실을 선택하여 예약 신청을한다.
2. 예약 신청과 동시에 결제 처리가 진행된다.
3. 결제가 완료되면 이벤트를 발행하고, 숙소 시스템에서 이를 수신하여객실 재고를 차감하고 예약을 접수한다.
4. 점주는 예약을 확인하고 최종 [예약승인] 을 누르면 이벤트가 발생된다.
5. 고객이 예약을 취소할 수 있으며, 취소시 결제 환불과 객실 재고 복구가 연쇄적으로 일어난다.
6. 상태 변경이 발생할 때마다 고객에게 알림 메시지를 발송한다.
7. 고객은 자신의 예약 상태와 결제 이력등이 한눈에 보이는 마이페이지를 볼 수 있다.

비기능적 요구사항
1. 고객은 서버가 다운되더라도, 예약 신청 대기열을 유지하거나 서킷브레이커를 통해 예약시스템을 차단하여 시스템 마비를 방지한다.

# 체크포인트

- 분석 설계
  - 이벤트스토밍: 
    - 스티커 색상별 객체의 의미를 제대로 이해하여 헥사고날 아키텍처와의 연계 설계에 적절히 반영하고 있는가?
    - 각 도메인 이벤트가 의미있는 수준으로 정의되었는가?
    - 어그리게잇: Command와 Event 들을 ACID 트랜잭션 단위의 Aggregate 로 제대로 묶었는가?
    - 기능적 요구사항과 비기능적 요구사항을 누락 없이 반영하였는가?    

  - 서브 도메인, 바운디드 컨텍스트 분리
    - 팀별 KPI 와 관심사, 상이한 배포주기 등에 따른  Sub-domain 이나 Bounded Context 를 적절히 분리하였고 그 분리 기준의 합리성이 충분히 설명되는가?
      - 적어도 3개 이상 서비스 분리
    - 폴리글랏 설계: 각 마이크로 서비스들의 구현 목표와 기능 특성에 따른 각자의 기술 Stack 과 저장소 구조를 다양하게 채택하여 설계하였는가?
    - 서비스 시나리오 중 ACID 트랜잭션이 크리티컬한 Use 케이스에 대하여 무리하게 서비스가 과다하게 조밀히 분리되지 않았는가?
  - 컨텍스트 매핑 / 이벤트 드리븐 아키텍처 
    - 업무 중요성과  도메인간 서열을 구분할 수 있는가? (Core, Supporting, General Domain)
    - Request-Response 방식과 이벤트 드리븐 방식을 구분하여 설계할 수 있는가?
    - 장애격리: 서포팅 서비스를 제거 하여도 기존 서비스에 영향이 없도록 설계하였는가?
    - 신규 서비스를 추가 하였을때 기존 서비스의 데이터베이스에 영향이 없도록 설계(열려있는 아키택처)할 수 있는가?
    - 이벤트와 폴리시를 연결하기 위한 Correlation-key 연결을 제대로 설계하였는가?

  - 헥사고날 아키텍처
    - 설계 결과에 따른 헥사고날 아키텍처 다이어그램을 제대로 그렸는가?
    
- 구현
  - [DDD] 분석단계에서의 스티커별 색상과 헥사고날 아키텍처에 따라 구현체가 매핑되게 개발되었는가?
    - Entity Pattern 과 Repository Pattern 을 적용하여 JPA 를 통하여 데이터 접근 어댑터를 개발하였는가
    - [헥사고날 아키텍처] REST Inbound adaptor 이외에 gRPC 등의 Inbound Adaptor 를 추가함에 있어서 도메인 모델의 손상을 주지 않고 새로운 프로토콜에 기존 구현체를 적응시킬 수 있는가?
    - 분석단계에서의 유비쿼터스 랭귀지 (업무현장에서 쓰는 용어) 를 사용하여 소스코드가 서술되었는가?
  - Request-Response 방식의 서비스 중심 아키텍처 구현
    - 마이크로 서비스간 Request-Response 호출에 있어 대상 서비스를 어떠한 방식으로 찾아서 호출 하였는가? (Service Discovery, REST, FeignClient)
    - 서킷브레이커를 통하여  장애를 격리시킬 수 있는가?
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



# 분석/설계


## AS-IS 조직 (Horizontally-Aligned)
  ![image](https://user-images.githubusercontent.com/487999/79684144-2a893200-826a-11ea-9a01-79927d3a0107.png)

## TO-BE 조직 (Vertically-Aligned)
  ![image](https://user-images.githubusercontent.com/487999/79684159-3543c700-826a-11ea-8d5f-a3fc0c4cad87.png)


## Event Storming 결과


<img width="1280" height="720" alt="image" src="https://github.com/user-attachments/assets/e7b9341a-35b3-4ad8-9d02-b9aa96ed2fd3" />


### 1차 완성본에 대한 기능적/비기능적 요구사항을 커버하는지 검증


<img width="1280" height="720" alt="image" src="https://github.com/user-attachments/assets/e7b9341a-35b3-4ad8-9d02-b9aa96ed2fd3" />

- 고객이 숙소 객실을 선택하여 예약 신청을 한다. (ok)
- 예약 신청과 동시에 결제 처리가 진행된다. (ok)
- 결제가 완료되면 숙소 시스템에서 이를 수신하여 객실 재고를 차감하고 예약을 접수 상태로 변경한다. (ok)
- 점주(Host)가 예약을 확인하고 최종 [예약승인] 처리를 한다. (ok)

<img width="1280" height="720" alt="image" src="https://github.com/user-attachments/assets/e7b9341a-35b3-4ad8-9d02-b9aa96ed2fd3" />

- 고객이 예약을 취소할 수 있다. (ok)
- 예약을 취소하면 결제 환불과 객실 재고 복구가 연쇄적으로 일어난다. (ok - Saga 패턴/보상 트랜잭션 적용)
- 고객은 자신의 예약 상태와 결제 이력 등을 마이페이지를 통해 한눈에 조회할 수 있다. (View-green sticker 추가로 CQRS 적용 ok)
- 상태 변경이 발생할 때마다 고객에게 알림 메시지를 발송한다. (각 상태 변경 Event들을 수신하는 `알림 발송 Policy` 추가를 전제로 ok)

### 비기능적 요구사항 검증
    
- 서버가 다운되더라도 예약 신청 대기열을 유지하거나 서킷브레이커를 통해 시스템 마비를 방지한다. (Req/Res 동기 호출 외에 Pub/Sub 비동기 통신 및 Gateway 서킷브레이커 설정을 통해 장애 격리 ok

# 구현:

분석/설계 단계에서 도출된 헥사고날 아키텍처에 따라, 각 BC(Bounded Context)별로 대변되는 마이크로 서비스들을 Spring Boot(Java 21)와 Gradle을 이용하여 구현하였습니다. 구현한 각 서비스를 로컬에서 실행하는 방법은 아래와 같습니다. (각 서비스의 포트 넘버는 8081 ~ 8084를 사용합니다.)

```

# 예약(Reservation) 서비스
cd reservation
./gradlew bootRun

# 결제(Payment) 서비스
cd payment
./gradlew bootRun

# 숙소(Accommodation) 서비스
cd accommodation
./gradlew bootRun

# 마이페이지(Mypage - CQRS) 서비스
cd mypage
./gradlew bootRun

```

## DDD 의 적용

- 각 서비스 내에 도출된 핵심 Aggregate Root 객체를 Entity로 선언하였습니다. (예시: Payment 마이크로서비스).
- 식별자나 필드명에 한글을 사용할 경우 발생하는 빌드 오류 및 Kafka Topic 인코딩 문제를 원천 차단하기 위해, 현업의 유비쿼터스 랭귀지를 영문으로 매핑하여 적용했습니다. 또한 Lombok을 활용하여 보일러플레이트 코드(Getter/Setter)를 최소화했습니다.

```

package com.hotel.payment.domain;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name="payment_table")
@Data
public class Payment {

    @Id
    @GeneratedValue(strategy=GenerationType.AUTO)
    private Long id;
    private Long reservationId;
    private Double amount;
    private String status;

}

```

- Entity Pattern과 Repository Pattern을 적용하여 JPA를 통해 다양한 데이터소스 유형(RDB or NoSQL)에 대한 별도의 쿼리 작성 없이 데이터 접근 어댑터를 자동 생성하도록 Spring Data REST의 PagingAndSortingRepository를 적용하였습니다.

```

package com.hotel.payment.repository;

import com.hotel.payment.domain.Payment;
import org.springframework.data.repository.PagingAndSortingRepository;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;

@RepositoryRestResource(collectionResourceRel="payments", path="payments")
public interface PaymentRepository extends PagingAndSortingRepository<Payment, Long> {
}

```

- 적용 후 REST API 의 테스트
- 로컬 환경에서 Kafka를 띄운 상태로 각 서비스의 동작과 비동기 호출을 테스트한 결과입니다.

```

# 1. reservation 서비스의 객실 예약 요청 (101호, 50000원)
http POST localhost:8081/reservations roomId=101 price=50000

# 2. payment 서비스에서 결제 내역 생성 확인 (Kafka 비동기 수신)
http GET localhost:8082/payments

# 3. mypage 서비스에서 전체 예약/결제 상태 통합 확인 (CQRS)
http GET localhost:8084/mypages

```


## 비동기식 호출 / 시간적 디커플링 / 장애격리 / 최종 (Eventual) 일관성 테스트


- 본 시스템은 마이크로서비스 간의 결합도를 낮추고 시스템의 확장성을 확보하기 위해 Apache Kafka를 활용한 이벤트 기반 아키텍처(Event-Driven Architecture)를 적용하였습니다.
- REST API(동기 통신)의 한계인 '단일 서비스 장애 시 전체 시스템 마비(Cascading Failure)' 문제를 해결하기 위해 핵심 트랜잭션을 비동기(Pub/Sub)로 처리합니다.

### 이벤트 발행 (Publish): 예약 서비스 (Reservation)
- 고객이 숙소를 예약하면, Reservation 서비스는 데이터베이스에 예약 정보를 저장함과 동시에 ReservationCreated 이벤트를 Kafka 토픽으로 발행(Publish)합니다.
- JPA의 Entity Lifecycle Annotation(@PostPersist)을 활용하여 DB 저장과 이벤트 발행의 생명주기를 일치시켰습니다.
 
```

package com.hotel.reservation.domain;

import jakarta.persistence.*;
import org.springframework.beans.BeanUtils;
import lombok.Data;

@Entity
@Table(name="reservation_table")
@Data
public class Reservation {

    @Id
    @GeneratedValue(strategy=GenerationType.AUTO)
    private Long id;
    private String roomId;
    private Double price;
    private String status;

    @PostPersist
    public void onPostPersist(){
        // 예약이 DB에 성공적으로 저장된 직후, Kafka로 이벤트 발행
        ReservationCreated reservationCreated = new ReservationCreated();
        BeanUtils.copyProperties(this, reservationCreated);
        
        // (MSAEZ 제공 AbstractEvent의 publish 메서드 활용 또는 KafkaTemplate 사용)
        reservationCreated.publishAfterCommit(); 
    }
}

```

### 이벤트 구독 (Subscribe): 결제 및 숙소 서비스 (Policy Handler)

- 발행된 이벤트는 결제(Payment) 서비스와 숙소(Accommodation) 서비스가 각자의 관심사에 맞게 구독(Subscribe)합니다.
- spring-boot-starter-kafka 라이브러리의 @KafkaListener를 사용하여 이벤트를 수신하며, 예약 서비스가 일시적으로 다운되더라도 큐에 저장된 이벤트를 통해 데이터의 최종 일관성(Eventual Consistency)을 보장합니다.

```
package com.hotel.payment.infra;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;
import com.hotel.payment.domain.*;

@Service
public class PolicyHandler {

    @Autowired
    PaymentRepository paymentRepository;

    // 카프카의 'hotel-booking-topic'을 구독하여 예약 생성 이벤트 수신
    @KafkaListener(topics = "hotel-booking-topic", groupId = "payment-group")
    public void wheneverReservationCreated_ProcessPayment(@Payload String eventString) {
        
        // 이벤트 페이로드 파싱 및 결제 승인 로직 실행
        if(eventString.contains("ReservationCreated")) {
            ReservationCreated event = parseEvent(eventString, ReservationCreated.class);
            
            Payment payment = new Payment();
            payment.setReservationId(event.getId());
            payment.setAmount(event.getPrice());
            payment.setStatus("결제승인완료"); // Payment 상태 업데이트
            
            paymentRepository.save(payment);
        }
    }
}

```

### CQRS 패턴을 이용한 통합 조회 (Mypage)

- 사용자가 자신의 예약 및 결제 상태를 한 번에 조회할 때, 여러 마이크로서비스를 넘나들며 데이터를 조인(Join)하는 것은 성능 저하를 유발합니다.
- 이를 해결하기 위해 CQRS(Command and Query Responsibility Segregation) 패턴을 적용한 Mypage 서비스를 별도로 구축했습니다.
- Mypage 서비스는 Kafka를 통해 ReservationCreated, PaymentApproved 등의 이벤트를 모두 구독하여 읽기 전용(Read-Model) DB에 최신 상태로 캐싱해 둡니다.
  
```
  # 사용자가 마이페이지를 조회할 때, 복잡한 조인 없이 CQRS DB에서 즉시 응답
http GET localhost:8084/mypages/1

```

# 운영

## 오토스케일 아웃
앞서 CB 는 시스템을 안정되게 운영할 수 있게 해줬지만 사용자의 요청을 100% 받아들여주지 못했기 때문에 이에 대한 보완책으로 자동화된 확장 기능을 적용하고자 한다. 


- 결제서비스에 대한 replica 를 동적으로 늘려주도록 HPA 를 설정한다. 설정은 CPU 사용량이 15프로를 넘어서면 replica 를 10개까지 늘려준다:
```
kubectl autoscale deploy pay --min=1 --max=10 --cpu-percent=15
```
- CB 에서 했던 방식대로 워크로드를 2분 동안 걸어준다.
```
siege -c100 -t120S -r10 --content-type "application/json" 'http://localhost:8081/orders POST {"item": "chicken"}'
```
- 오토스케일이 어떻게 되고 있는지 모니터링을 걸어둔다:
```
kubectl get deploy pay -w
```
- 어느정도 시간이 흐른 후 (약 30초) 스케일 아웃이 벌어지는 것을 확인할 수 있다:
```
NAME    DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
pay     1         1         1            1           17s
pay     1         2         1            1           45s
pay     1         4         1            1           1m
:
```
- siege 의 로그를 보아도 전체적인 성공률이 높아진 것을 확인 할 수 있다. 
```
Transactions:		        5078 hits
Availability:		       92.45 %
Elapsed time:		       120 secs
Data transferred:	        0.34 MB
Response time:		        5.60 secs
Transaction rate:	       17.15 trans/sec
Throughput:		        0.01 MB/sec
Concurrency:		       96.02
```


## 무정지 재배포

* 먼저 무정지 재배포가 100% 되는 것인지 확인하기 위해서 Autoscaler 이나 CB 설정을 제거함

- seige 로 배포작업 직전에 워크로드를 모니터링 함.
```
siege -c100 -t120S -r10 --content-type "application/json" 'http://localhost:8081/orders POST {"item": "chicken"}'

** SIEGE 4.0.5
** Preparing 100 concurrent users for battle.
The server is now under siege...

HTTP/1.1 201     0.68 secs:     207 bytes ==> POST http://localhost:8081/orders
HTTP/1.1 201     0.68 secs:     207 bytes ==> POST http://localhost:8081/orders
HTTP/1.1 201     0.70 secs:     207 bytes ==> POST http://localhost:8081/orders
HTTP/1.1 201     0.70 secs:     207 bytes ==> POST http://localhost:8081/orders
:

```

- 새버전으로의 배포 시작
```
kubectl set image ...
```

- seige 의 화면으로 넘어가서 Availability 가 100% 미만으로 떨어졌는지 확인
```
Transactions:		        3078 hits
Availability:		       70.45 %
Elapsed time:		       120 secs
Data transferred:	        0.34 MB
Response time:		        5.60 secs
Transaction rate:	       17.15 trans/sec
Throughput:		        0.01 MB/sec
Concurrency:		       96.02

```
배포기간중 Availability 가 평소 100%에서 70% 대로 떨어지는 것을 확인. 원인은 쿠버네티스가 성급하게 새로 올려진 서비스를 READY 상태로 인식하여 서비스 유입을 진행한 것이기 때문. 이를 막기위해 Readiness Probe 를 설정함:

```
# deployment.yaml 의 readiness probe 의 설정:


kubectl apply -f kubernetes/deployment.yaml
```

- 동일한 시나리오로 재배포 한 후 Availability 확인:
```
Transactions:		        3078 hits
Availability:		       100 %
Elapsed time:		       120 secs
Data transferred:	        0.34 MB
Response time:		        5.60 secs
Transaction rate:	       17.15 trans/sec
Throughput:		        0.01 MB/sec
Concurrency:		       96.02

```

배포기간 동안 Availability 가 변화없기 때문에 무정지 재배포가 성공한 것으로 확인됨.
