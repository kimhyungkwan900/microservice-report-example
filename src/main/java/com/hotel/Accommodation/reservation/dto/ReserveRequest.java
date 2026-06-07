package com.hotel.Accommodation.reservation.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ReserveRequest {

	@NotNull
	private Long roomId;

	@NotBlank
	private String userId;

	@NotNull
	private Long price;

	@NotBlank
	private String checkInDate;

	@NotBlank
	private String checkOutDate;
}
