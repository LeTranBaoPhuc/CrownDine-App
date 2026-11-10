package com.crowndine.service.chat;

import com.crowndine.dto.response.TableLayoutResponse;
import com.crowndine.exception.AiServiceException;
import com.crowndine.model.ChatMessage;
import com.crowndine.service.layout.RestaurantTableService;
import org.junit.jupiter.api.Test;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ChatBookingSupportTest {
    final RestaurantTableService tables = mock(RestaurantTableService.class);
    final ChatBookingSupport booking = new ChatBookingSupport(tables);
    ChatMessage user(String content) { ChatMessage m = new ChatMessage(); m.setRole("user"); m.setContent(content); return m; }
    TableLayoutResponse table(String name) { var t = new TableLayoutResponse(); t.setName(name); t.setCapacity(4); return t; }
    @Test void incompleteOrInvalidSlotsNeverAdvertiseCurrentStatusAsAvailability() {
        assertTrue(booking.contextFor(List.of(user("4 người ngày mai"))).contains("CHƯA KIỂM TRA"));
        assertTrue(booking.contextFor(List.of(user("2026-02-30 lúc 19:00 cho 4 khách"))).contains("CHƯA KIỂM TRA"));
        assertTrue(booking.contextFor(List.of(user("ngày mai 19:00 cho 4 khách"), user("đổi sang 25:00"))).contains("CHƯA KIỂM TRA"));
        verifyNoInteractions(tables);
    }
    @Test void explicitSlotAndLaterChangesUseTheReservationAvailabilityService() {
        var date = LocalDate.now().plusDays(2);
        when(tables.getTablesForReservation(date, LocalTime.of(19, 30), 4)).thenReturn(List.of(table("Bàn 01")));
        assertTrue(booking.contextFor(List.of(user(date + " lúc 19:30 cho 4 khách"))).contains("Bàn 01"));
        when(tables.getTablesForReservation(date.plusDays(1), LocalTime.of(20, 0), 6)).thenReturn(List.of());
        String result = booking.contextFor(List.of(user(date + " lúc 19:30 cho 4 khách"), user(date.plusDays(1) + " đổi sang 20h00 cho 6 khách")));
        assertTrue(result.contains("Không còn bàn")); assertFalse(result.contains("Bàn 01"));
        verify(tables).getTablesForReservation(date.plusDays(1), LocalTime.of(20, 0), 6);
    }
    @Test void redirectsAreEncodedAndRevalidatedRatherThanSilentlyChoosingAnotherTable() {
        var date = LocalDate.now().plusDays(1);
        when(tables.getTablesForReservation(date, LocalTime.of(19, 0), 4)).thenReturn(List.of(table("Bàn 01")));
        String link = "/reservation?step=4&tableName=Bàn 01&date=" + date + "&startTime=19:00&guests=4";
        String checked = booking.validateLinks("Continue\n" + link);
        assertTrue(checked.contains("B%C3%A0n%2001")); assertTrue(checked.contains("guests=4"));
        assertThrows(AiServiceException.class, () -> booking.validateLinks(link.replace("Bàn 01", "Unknown")));
        when(tables.getTablesForReservation(date, LocalTime.of(19, 0), 4)).thenReturn(List.of());
        assertThrows(AiServiceException.class, () -> booking.validateLinks(link));
        assertThrows(AiServiceException.class, () -> booking.validateLinks(link.replace("step=4", "step=8")));
    }
}
