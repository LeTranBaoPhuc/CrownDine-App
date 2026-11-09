package com.crowndine.service.order;

import com.crowndine.common.enums.*;
import com.crowndine.dto.request.OrderItemRequest;
import com.crowndine.exception.InvalidDataException;
import com.crowndine.model.*;
import com.crowndine.repository.*;
import com.crowndine.service.CalculationService;
import com.crowndine.service.impl.order.OrderDetailServiceImpl;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class OrderDetailAvailabilityTest {
    @Mock OrderDetailRepository orderDetailRepository;
    @Mock ItemRepository itemRepository;
    @Mock ComboRepository comboRepository;
    @Mock CalculationService calculationService;
    @InjectMocks OrderDetailServiceImpl service;
    OrderItemRequest line(String json) throws Exception { return new ObjectMapper().readValue(json, OrderItemRequest.class); }

    @Test void unavailableItemIsRejectedByServerEvenIfClientMenuIsStale() throws Exception {
        Item item = new Item(); item.setStatus(EItemStatus.UNAVAILABLE);
        when(itemRepository.findById(1L)).thenReturn(Optional.of(item));
        assertThrows(InvalidDataException.class, () -> service.createPendingOrderDetails(new Order(),
                List.of(line("{\"itemId\":1,\"quantity\":2}"))));
        verifyNoInteractions(orderDetailRepository);
    }
    @Test void unavailableComboAndAmbiguousProductAreRejected() throws Exception {
        Combo combo = new Combo(); combo.setStatus(EComboStatus.UNAVAILABLE);
        when(comboRepository.findById(1L)).thenReturn(Optional.of(combo));
        assertThrows(InvalidDataException.class, () -> service.createPendingOrderDetails(new Order(),
                List.of(line("{\"comboId\":1,\"quantity\":2}"))));
        assertThrows(InvalidDataException.class, () -> service.createPendingOrderDetails(new Order(),
                List.of(line("{\"itemId\":1,\"comboId\":1,\"quantity\":2}"))));
        verifyNoInteractions(orderDetailRepository);
    }
    @Test void additionalDishCreatesNewPendingTicketWithoutChangingCookingTicket() throws Exception {
        Item item = new Item(); item.setId(1L); item.setStatus(EItemStatus.AVAILABLE); item.setPrice(new BigDecimal("50000"));
        when(itemRepository.findById(1L)).thenReturn(Optional.of(item));
        Order order = new Order();
        OrderDetail cooking = new OrderDetail(); cooking.setItem(item); cooking.setQuantity(1); cooking.setStatus(EOrderDetailStatus.COOKING);
        order.addOrderDetail(cooking);
        service.createPendingOrderDetails(order, List.of(line("{\"itemId\":1,\"quantity\":2,\"note\":\"Less salt\"}")));
        assertEquals(2, order.getOrderDetails().size());
        assertEquals(1, cooking.getQuantity()); assertEquals(EOrderDetailStatus.COOKING, cooking.getStatus());
        OrderDetail added = order.getOrderDetails().getLast();
        assertEquals(EOrderDetailStatus.PENDING, added.getStatus()); assertEquals("Less salt", added.getNote());
        assertEquals(new BigDecimal("100000"), added.getTotalPrice());
    }
}
