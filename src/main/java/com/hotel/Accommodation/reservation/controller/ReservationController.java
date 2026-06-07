package com.hotel.Accommodation.reservation.controller;

import com.hotel.Accommodation.reservation.domain.PaymentHistory;
import com.hotel.Accommodation.reservation.domain.Reservation;
import com.hotel.Accommodation.reservation.domain.RoomInventory;
import com.hotel.Accommodation.reservation.dto.ReserveRequest;
import com.hotel.Accommodation.reservation.service.ReservationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@CrossOrigin
public class ReservationController {

	private final ReservationService reservationService;

	@GetMapping("/rooms")
	public List<RoomInventory> getRooms() {
		return reservationService.findAllRooms();
	}

	@GetMapping("/reservations")
	public List<Reservation> getReservations() {
		return reservationService.findAllReservations();
	}

	@GetMapping("/payments")
	public List<PaymentHistory> getPayments() {
		return reservationService.findAllPayments();
	}

	@PostMapping("/reservations")
	@ResponseStatus(HttpStatus.CREATED)
	public Reservation reserve(@Valid @RequestBody ReserveRequest request) {
		return handle(() -> reservationService.reserve(request));
	}

	@PostMapping("/reservations/{id}/pay")
	public Reservation pay(@PathVariable Long id) {
		return handle(() -> reservationService.pay(id));
	}

	@PostMapping("/reservations/{id}/approve")
	public Reservation approve(@PathVariable Long id) {
		return handle(() -> reservationService.approve(id));
	}

	@PostMapping("/reservations/{id}/cancel")
	public Reservation cancel(@PathVariable Long id) {
		return handle(() -> reservationService.cancel(id));
	}

	@PostMapping("/reservations/{id}/refund")
	public Reservation refund(@PathVariable Long id) {
		return handle(() -> reservationService.refund(id));
	}

	private Reservation handle(java.util.function.Supplier<Reservation> action) {
		try {
			return action.get();
		} catch (IllegalArgumentException ex) {
			throw new ResponseStatusException(HttpStatus.NOT_FOUND, ex.getMessage());
		} catch (IllegalStateException ex) {
			throw new ResponseStatusException(HttpStatus.BAD_REQUEST, ex.getMessage());
		}
	}
}
