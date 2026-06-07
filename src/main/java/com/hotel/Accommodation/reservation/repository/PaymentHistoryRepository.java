package com.hotel.Accommodation.reservation.repository;

import com.hotel.Accommodation.reservation.domain.PaymentHistory;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PaymentHistoryRepository extends JpaRepository<PaymentHistory, Long> {
}
