package com.hotel.Accommodation.reservation.service;

import com.hotel.Accommodation.reservation.domain.*;
import com.hotel.Accommodation.reservation.dto.ReserveRequest;
import com.hotel.Accommodation.reservation.dto.event.ReservationCreated;
import com.hotel.Accommodation.reservation.repository.PaymentHistoryRepository;
import com.hotel.Accommodation.reservation.repository.ReservationRepository;
import com.hotel.Accommodation.reservation.repository.RoomInventoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class ReservationService {

	private final ReservationRepository reservationRepository;
	private final PaymentHistoryRepository paymentHistoryRepository;
	private final RoomInventoryRepository roomInventoryRepository;
	private final org.springframework.context.ApplicationEventPublisher applicationEventPublisher;

	@Transactional(readOnly = true)
	public List<Reservation> findAllReservations() {
		return reservationRepository.findAll();
	}

	@Transactional(readOnly = true)
	public List<RoomInventory> findAllRooms() {
		return roomInventoryRepository.findAll();
	}

	@Transactional(readOnly = true)
	public List<PaymentHistory> findAllPayments() {
		return paymentHistoryRepository.findAll();
	}

	public Reservation reserve(ReserveRequest request) {
		RoomInventory room = getRoom(request.getRoomId());
		if (room.getStockCount() <= 0) {
			throw new IllegalStateException("해당 객실의 재고가 없습니다.");
		}

		Reservation reservation = Reservation.builder()
				.roomId(request.getRoomId())
				.userId(request.getUserId())
				.price(request.getPrice())
				.status(ReservationStatus.REQUESTED)
				.checkInDate(request.getCheckInDate())
				.checkOutDate(request.getCheckOutDate())
				.build();

		Reservation saved = reservationRepository.save(reservation);
		applicationEventPublisher.publishEvent(new ReservationCreated(saved));
		return saved;
	}

	public Reservation pay(Long reservationId) {
		Reservation reservation = getReservation(reservationId);
		if (reservation.getStatus() != ReservationStatus.REQUESTED) {
			throw new IllegalStateException("결제 가능한 상태가 아닙니다.");
		}

		RoomInventory room = getRoom(reservation.getRoomId());
		if (room.getStockCount() <= 0) {
			throw new IllegalStateException("재고가 부족하여 결제할 수 없습니다.");
		}

		room.setStockCount(room.getStockCount() - 1);
		reservation.setStatus(ReservationStatus.PAID);

		paymentHistoryRepository.save(PaymentHistory.builder()
				.reservationId(reservationId)
				.price(reservation.getPrice())
				.type(PaymentHistory.PaymentType.PAYMENT)
				.build());

		return reservation;
	}

	public Reservation approve(Long reservationId) {
		Reservation reservation = getReservation(reservationId);
		if (reservation.getStatus() != ReservationStatus.PAID) {
			throw new IllegalStateException("승인 가능한 상태가 아닙니다.");
		}
		reservation.setStatus(ReservationStatus.CONFIRMED);
		return reservation;
	}

	public Reservation cancel(Long reservationId) {
		Reservation reservation = getReservation(reservationId);
		if (reservation.getStatus() == ReservationStatus.CANCELLED
				|| reservation.getStatus() == ReservationStatus.REFUNDED) {
			throw new IllegalStateException("이미 취소된 예약입니다.");
		}

		if (reservation.getStatus() == ReservationStatus.PAID
				|| reservation.getStatus() == ReservationStatus.CONFIRMED) {
			refundInternal(reservation);
		} else {
			reservation.setStatus(ReservationStatus.CANCELLED);
		}

		return reservation;
	}

	public Reservation refund(Long reservationId) {
		Reservation reservation = getReservation(reservationId);
		if (reservation.getStatus() != ReservationStatus.PAID
				&& reservation.getStatus() != ReservationStatus.CONFIRMED) {
			throw new IllegalStateException("환불 가능한 상태가 아닙니다.");
		}
		return refundInternal(reservation);
	}

	private Reservation refundInternal(Reservation reservation) {
		RoomInventory room = getRoom(reservation.getRoomId());
		room.setStockCount(room.getStockCount() + 1);
		reservation.setStatus(ReservationStatus.REFUNDED);

		paymentHistoryRepository.save(PaymentHistory.builder()
				.reservationId(reservation.getId())
				.price(reservation.getPrice())
				.type(PaymentHistory.PaymentType.REFUND)
				.build());

		return reservation;
	}

	private Reservation getReservation(Long reservationId) {
		return reservationRepository.findById(reservationId)
				.orElseThrow(() -> new IllegalArgumentException("예약을 찾을 수 없습니다."));
	}

	private RoomInventory getRoom(Long roomId) {
		return roomInventoryRepository.findByRoomId(roomId)
				.orElseThrow(() -> new IllegalArgumentException("객실을 찾을 수 없습니다."));
	}
}
