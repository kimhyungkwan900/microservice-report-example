package com.hotel.Accommodation.reservation.event;

import com.hotel.Accommodation.reservation.config.KafkaConfig;
import com.hotel.Accommodation.reservation.dto.event.ReservationCreated;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "app.kafka.enabled", havingValue = "true", matchIfMissing = true)
public class ReservationEventPublisher {

	private final KafkaTemplate<String, ReservationCreated> kafkaTemplate;

	@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
	public void publishReservationCreated(ReservationCreated event) {
		kafkaTemplate.send(KafkaConfig.HOTEL_BOOKING_TOPIC, event.getId().toString(), event)
				.whenComplete((result, ex) -> {
					if (ex != null) {
						log.error("ReservationCreated 이벤트 발행 실패: reservationId={}", event.getId(), ex);
						return;
					}
					log.info("ReservationCreated 이벤트 발행 완료: reservationId={}, topic={}",
							event.getId(), KafkaConfig.HOTEL_BOOKING_TOPIC);
				});
	}
}
