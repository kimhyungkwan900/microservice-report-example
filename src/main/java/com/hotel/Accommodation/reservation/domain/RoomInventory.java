package com.hotel.Accommodation.reservation.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "room_inventories")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RoomInventory {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	private Long roomId;
	private Integer stockCount;
	private String roomName;
	private String invDate;
}
