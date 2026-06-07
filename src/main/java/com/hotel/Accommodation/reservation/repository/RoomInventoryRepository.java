package com.hotel.Accommodation.reservation.repository;

import com.hotel.Accommodation.reservation.domain.RoomInventory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface RoomInventoryRepository extends JpaRepository<RoomInventory, Long> {

	Optional<RoomInventory> findByRoomId(Long roomId);
}
