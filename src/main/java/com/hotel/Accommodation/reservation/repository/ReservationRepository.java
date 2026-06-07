package com.hotel.Accommodation.reservation.repository;

import com.hotel.Accommodation.reservation.domain.Reservation;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReservationRepository extends JpaRepository<Reservation, Long> {
}
