package com.hotel.Accommodation.reservation.infra;

import com.hotel.Accommodation.reservation.config.KafkaConfig;
import com.hotel.Accommodation.reservation.dto.event.ReservationCreated;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@ConditionalOnProperty(name = "app.kafka.enabled", havingValue = "true", matchIfMissing = true)
public class ReservationCreatedPolicyHandler {

	@KafkaListener(
			topics = KafkaConfig.HOTEL_BOOKING_TOPIC,
			groupId = "accommodation-reservation-group"
	)
	public void wheneverReservationCreated(@Payload ReservationCreated event) {
		if (!"ReservationCreated".equals(event.getEventType())) {
			return;
		}

		log.info(
				"[Subscribe] ReservationCreated 수신 - reservationId={}, userId={}, roomId={}, price={}, status={}",
				event.getId(),
				event.getUserId(),
				event.getRoomId(),
				event.getPrice(),
				event.getStatus()
		);
	}
}
