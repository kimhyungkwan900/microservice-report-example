package com.hotel.Accommodation.reservation.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.config.TopicBuilder;

@Configuration
@EnableKafka
@ConditionalOnProperty(name = "app.kafka.enabled", havingValue = "true", matchIfMissing = true)
public class KafkaConfig {

	public static final String HOTEL_BOOKING_TOPIC = "hotel-booking-topic";

	@Bean
	NewTopic hotelBookingTopic() {
		return TopicBuilder.name(HOTEL_BOOKING_TOPIC)
				.partitions(1)
				.replicas(1)
				.build();
	}
}
