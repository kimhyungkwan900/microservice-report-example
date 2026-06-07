package com.hotel.Accommodation.reservation.dto.event;

import com.hotel.Accommodation.reservation.domain.Reservation;
import com.hotel.Accommodation.reservation.domain.ReservationStatus;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.ToString;

@Getter
@NoArgsConstructor
@ToString
public class ReservationCreated {

	private String eventType = "ReservationCreated";
	private Long id;
	private Long roomId;
	private String userId;
	private Long price;
	private ReservationStatus status;
	private String checkInDate;
	private String checkOutDate;

	public ReservationCreated(Reservation reservation) {
		this.id = reservation.getId();
		this.roomId = reservation.getRoomId();
		this.userId = reservation.getUserId();
		this.price = reservation.getPrice();
		this.status = reservation.getStatus();
		this.checkInDate = reservation.getCheckInDate();
		this.checkOutDate = reservation.getCheckOutDate();
	}
}
