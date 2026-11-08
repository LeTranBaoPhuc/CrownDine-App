package com.crowndine.service.layout;

import com.crowndine.common.enums.*;
import com.crowndine.dto.response.RestaurantTableResponse;
import com.crowndine.exception.InvalidDataException;
import com.crowndine.model.*;
import com.crowndine.repository.*;
import com.crowndine.service.impl.layout.RestaurantTableServiceImpl;
import com.crowndine.service.reservation.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RestaurantTableManagementTest {
    @Mock RestaurantTableRepository tableRepository;
    @Mock AreaRepository areaRepository;
    @Mock ReservationTimePolicy reservationTimePolicy;
    @Mock ReservationAvailabilityService reservationAvailabilityService;
    @Mock RestaurantTableStateService restaurantTableStateService;
    @Mock OrderRepository orderRepository;
    @Mock ReservationRepository reservationRepository;
    @InjectMocks RestaurantTableServiceImpl service;
    RestaurantTable table;
    @BeforeEach void setup() {
        table = new RestaurantTable(); table.setId(7L); table.setStatus(ETableStatus.OCCUPIED);
    }
    void locked() { when(tableRepository.findByIdForUpdate(7L)).thenReturn(Optional.of(table)); }
    @Test void responseIncludesRealDepositAndGeometry() {
        table.setBaseDeposit(new BigDecimal("250000")); table.setPositionX(120); table.setPositionY(80);
        table.setWidth(90); table.setHeight(60); table.setRotation(45);
        when(tableRepository.findAll()).thenReturn(List.of(table));
        RestaurantTableResponse dto = service.getAllTables().getFirst();
        assertEquals(new BigDecimal("250000"), dto.getDeposit()); assertEquals(120, dto.getX());
        assertEquals(80, dto.getY()); assertEquals(45, dto.getRotation());
    }
    @Test void activeOrderCannotBeClearedOrDisabled() {
        locked(); when(orderRepository.findByRestaurantTableIdAndStatusIn(eq(7L), anyList())).thenReturn(List.of(new Order()));
        assertThrows(InvalidDataException.class, () -> service.updateTableStatus(7L, ETableStatus.AVAILABLE));
        assertThrows(InvalidDataException.class, () -> service.updateTableStatus(7L, ETableStatus.UNAVAILABLE));
        verifyNoInteractions(restaurantTableStateService);
    }
    @Test void checkedInGuestCannotBeCleared() {
        locked(); when(reservationRepository.findByTableIdAndStatusAndCheckedOutAtIsNull(7L, EReservationStatus.CHECKED_IN)).thenReturn(List.of(new Reservation()));
        assertThrows(InvalidDataException.class, () -> service.updateTableStatus(7L, ETableStatus.AVAILABLE));
        verifyNoInteractions(restaurantTableStateService);
    }
    @Test void emptyTableCanBeReleasedThroughStateService() {
        locked(); service.updateTableStatus(7L, ETableStatus.AVAILABLE);
        verify(reservationAvailabilityService).ensureTableAvailable(any(), any(), eq(7L));
        verify(restaurantTableStateService).changeStatus(7L, ETableStatus.AVAILABLE);
    }
    @Test void manualOccupyCannotBypassOrderOrCheckIn() {
        locked(); table.setStatus(ETableStatus.AVAILABLE);
        assertThrows(InvalidDataException.class, () -> service.updateTableStatus(7L, ETableStatus.OCCUPIED));
        verifyNoInteractions(restaurantTableStateService);
    }
}
