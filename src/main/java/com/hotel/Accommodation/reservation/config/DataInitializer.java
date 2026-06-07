package com.hotel.Accommodation.reservation.config;

import com.hotel.Accommodation.reservation.domain.RoomInventory;
import com.hotel.Accommodation.reservation.repository.RoomInventoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@RequiredArgsConstructor
public class DataInitializer {

	private final RoomInventoryRepository roomInventoryRepository;

	@Bean
	CommandLineRunner seedRooms() {
		return args -> {
			if (roomInventoryRepository.count() > 0) {
				return;
			}

			roomInventoryRepository.save(RoomInventory.builder()
					.roomId(101L)
					.roomName("디럭스 더블")
					.stockCount(3)
					.invDate("2026-06-06")
					.build());
			roomInventoryRepository.save(RoomInventory.builder()
					.roomId(102L)
					.roomName("스탠다드 트윈")
					.stockCount(5)
					.invDate("2026-06-06")
					.build());
			roomInventoryRepository.save(RoomInventory.builder()
					.roomId(103L)
					.roomName("패밀리 스위트")
					.stockCount(2)
					.invDate("2026-06-06")
					.build());
		};
	}
}
