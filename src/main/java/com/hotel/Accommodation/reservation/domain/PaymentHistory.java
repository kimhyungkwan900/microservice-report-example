package com.hotel.Accommodation.reservation.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "payment_histories")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaymentHistory {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	private Long reservationId;
	private Long price;

	@Enumerated(EnumType.STRING)
	private PaymentType type;

	public enum PaymentType {
		PAYMENT,
		REFUND
	}
}
