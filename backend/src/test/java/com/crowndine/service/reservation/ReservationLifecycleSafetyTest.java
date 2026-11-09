package com.crowndine.service.reservation;

import com.crowndine.common.enums.*;
import com.crowndine.exception.InvalidDataException;
import com.crowndine.model.*;
import com.crowndine.repository.*;
import com.crowndine.service.impl.reservation.ReservationLifecycleServiceImpl;
import com.crowndine.service.layout.RestaurantTableStateService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
class ReservationLifecycleSafetyTest {
    @Mock ReservationRepository reservationRepository;
    @Mock UserRepository userRepository;
    @Mock OrderRepository orderRepository;
    @Mock RestaurantTableRepository tableRepository;
    @Mock RestaurantTableStateService restaurantTableStateService;
    @Mock ApplicationEventPublisher eventPublisher;
    @InjectMocks ReservationLifecycleServiceImpl service;
    @Test void latePaymentDoesNotResurrectCancelledReservation() {
        Reservation r = new Reservation(); r.setId(1L); r.setStatus(EReservationStatus.CANCELLED);
        when(reservationRepository.findByIdForUpdate(1L)).thenReturn(Optional.of(r));
        service.confirmAfterDepositPaid(r);
        assertEquals(EReservationStatus.CANCELLED, r.getStatus());
        verify(reservationRepository, never()).save(any()); verifyNoInteractions(eventPublisher);
    }
    @Test void noFoodVisitCanFinishAndReleaseTable() {
        Reservation r = new Reservation(); r.setId(1L); r.setStatus(EReservationStatus.CHECKED_IN);
        RestaurantTable table = new RestaurantTable(); table.setId(7L); r.setTable(table);
        when(reservationRepository.findByIdForUpdate(1L)).thenReturn(Optional.of(r));
        when(userRepository.findByUsername("staff")).thenReturn(Optional.of(new User()));
        service.completeReservation(1L, "staff");
        assertEquals(EReservationStatus.COMPLETED, r.getStatus()); assertNotNull(r.getCheckedOutAt());
        verify(restaurantTableStateService).changeStatus(7L, ETableStatus.AVAILABLE);
    }
    @Test void checkInCannotReplaceAnotherGuestsActiveOrder() {
        Reservation r = new Reservation(); r.setId(1L); r.setStatus(EReservationStatus.CONFIRMED);
        RestaurantTable table = new RestaurantTable(); table.setId(7L); table.setStatus(ETableStatus.OCCUPIED); r.setTable(table);
        when(reservationRepository.findByIdForUpdate(1L)).thenReturn(Optional.of(r));
        when(userRepository.findByUsername("staff")).thenReturn(Optional.of(new User()));
        when(tableRepository.findByIdForUpdate(7L)).thenReturn(Optional.of(table));
        when(orderRepository.findByRestaurantTableIdAndStatusIn(eq(7L), any())).thenReturn(List.of(new com.crowndine.model.Order()));
        assertThrows(InvalidDataException.class, () -> service.checkInReservation(1L, "staff"));
        assertEquals(EReservationStatus.CONFIRMED, r.getStatus()); verifyNoInteractions(restaurantTableStateService);
    }
}
