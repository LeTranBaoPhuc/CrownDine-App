package com.crowndine.service.order;

import com.crowndine.common.enums.*;
import com.crowndine.dto.request.TableOrderItemsRequest;
import com.crowndine.dto.response.OrderResponse;
import com.crowndine.exception.InvalidDataException;
import com.crowndine.model.*;
import com.crowndine.repository.*;
import com.crowndine.service.impl.order.TableOrderService;
import com.crowndine.service.reservation.ReservationAvailabilityService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import java.util.List;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TableOrderServiceTest {
    @Mock RestaurantTableRepository tables;
    @Mock OrderRepository orders;
    @Mock ReservationRepository reservations;
    @Mock UserRepository users;
    @Mock OrderService orderService;
    @Mock OrderStatusService statusService;
    @Mock ReservationAvailabilityService availability;
    @InjectMocks TableOrderService service;
    RestaurantTable table;
    TableOrderItemsRequest request;
    Order active;

    @BeforeEach void setup() {
        table = new RestaurantTable(); table.setId(7L); table.setStatus(ETableStatus.OCCUPIED);
        active = new Order(); active.setId(11L); active.setRestaurantTable(table); active.setStatus(EOrderStatus.IN_PROGRESS);
        request = new TableOrderItemsRequest(); request.setExpectedOrderId(11L);
    }
    void locked() { when(tables.findByIdForUpdate(7L)).thenReturn(Optional.of(table)); }
    void active() { when(orders.findByRestaurantTableIdAndStatusIn(7L, TableOrderService.SERVING)).thenReturn(List.of(active)); }

    @Test void appendsToExactActiveOrderAndReopensServedSession() {
        locked(); active();
        OrderResponse response = new OrderResponse(); response.setId(11L);
        when(orderService.getOrderResponse(11L)).thenReturn(response);
        assertSame(response, service.addItems(7L, request, "staff"));
        verify(orderService).appendItemsToOrder(11L, request, "staff");
        verify(statusService).transitionOrderStatus(active, EOrderStatus.IN_PROGRESS);
        verify(orders, never()).save(any());
    }
    @Test void rejectsChangedOrNewlyOccupiedSessionBeforeWriting() {
        locked(); active(); request.setExpectedOrderId(null);
        assertThrows(InvalidDataException.class, () -> service.addItems(7L, request, "staff"));
        verifyNoInteractions(orderService, statusService);
    }
    @Test void rejectsStaleClosedOrderInsteadOfCreatingAnother() {
        locked(); request.setExpectedOrderId(99L);
        assertThrows(InvalidDataException.class, () -> service.addItems(7L, request, "staff"));
        verifyNoInteractions(orderService);
    }
    @Test void createsWalkInOrderAndMarksTableOnlyAfterAppendingItems() {
        locked(); table.setStatus(ETableStatus.AVAILABLE); request.setExpectedOrderId(null);
        User staff = new User(); staff.setId(3L);
        when(users.findByUsername("staff")).thenReturn(Optional.of(staff));
        when(orders.save(any())).thenAnswer(inv -> { Order o = inv.getArgument(0); o.setId(20L); return o; });
        service.addItems(7L, request, "staff");
        ArgumentCaptor<Order> captured = ArgumentCaptor.forClass(Order.class);
        verify(orders).save(captured.capture());
        assertSame(table, captured.getValue().getRestaurantTable());
        assertSame(staff, captured.getValue().getStaff());
        verify(availability).ensureTableAvailable(any(), any(), eq(7L));
        InOrder sequence = inOrder(orderService, statusService);
        sequence.verify(orderService).appendItemsToOrder(20L, request, "staff");
        sequence.verify(statusService).transitionOrderStatus(captured.getValue(), EOrderStatus.IN_PROGRESS);
    }
    @Test void usesCheckedInReservationWithoutCreatingWalkIn() {
        locked(); request.setExpectedOrderId(null);
        Reservation reservation = new Reservation(); reservation.setId(9L); reservation.setTable(table);
        reservation.setStatus(EReservationStatus.CHECKED_IN);
        User customer = new User(); reservation.setUser(customer);
        when(reservations.findByTableIdAndStatusAndCheckedOutAtIsNull(7L, EReservationStatus.CHECKED_IN)).thenReturn(List.of(reservation));
        when(users.findByUsername("staff")).thenReturn(Optional.of(new User()));
        when(orderService.createOrderForReservation(reservation, customer, EOrderStatus.CONFIRMED)).thenReturn(active);
        service.addItems(7L, request, "staff");
        assertSame(active, reservation.getOrder());
        verify(reservations).save(reservation);
        verify(orders, never()).save(any());
    }
    @Test void reservedTableRequiresCheckIn() {
        locked(); table.setStatus(ETableStatus.RESERVED); request.setExpectedOrderId(null);
        assertThrows(InvalidDataException.class, () -> service.addItems(7L, request, "staff"));
        verifyNoInteractions(orderService);
    }
    @Test void unavailableTableCannotReceiveItems() {
        locked(); table.setStatus(ETableStatus.UNAVAILABLE);
        assertThrows(InvalidDataException.class, () -> service.addItems(7L, request, "staff"));
        verifyNoInteractions(orders, orderService);
    }
    @Test void conflictingReservationPreventsWalkIn() {
        locked(); table.setStatus(ETableStatus.AVAILABLE); request.setExpectedOrderId(null);
        doThrow(new InvalidDataException("Reserved")).when(availability).ensureTableAvailable(any(), any(), eq(7L));
        assertThrows(InvalidDataException.class, () -> service.addItems(7L, request, "staff"));
        verify(orders, never()).save(any());
    }
    @Test void duplicateActiveOrdersFailClosed() {
        locked(); when(orders.findByRestaurantTableIdAndStatusIn(7L, TableOrderService.SERVING)).thenReturn(List.of(active, active));
        assertThrows(InvalidDataException.class, () -> service.addItems(7L, request, "staff"));
        verifyNoInteractions(orderService);
    }
    @Test void reservationOrderRequiresActualCheckIn() {
        locked(); active();
        Reservation reservation = new Reservation(); reservation.setStatus(EReservationStatus.CONFIRMED);
        active.setReservation(reservation);
        assertThrows(InvalidDataException.class, () -> service.addItems(7L, request, "staff"));
        verifyNoInteractions(orderService);
    }
    @Test void emptyTableReturnsNoActiveOrder() {
        when(tables.findById(7L)).thenReturn(Optional.of(table));
        assertNull(service.activeOrder(7L));
    }
}
