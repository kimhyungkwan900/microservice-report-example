package com.hotel.Accommodation.reservation.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "reservations")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Reservation {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	private Long roomId;
	private String userId;
	private Long price;

	@Enumerated(EnumType.STRING)
	private ReservationStatus status;

	private String checkInDate;
	private String checkOutDate;
}
