package com.crowndine.service.order;

import com.crowndine.common.enums.*;
import com.crowndine.dto.request.UpdateOrderDetailRequest;
import com.crowndine.exception.InvalidDataException;
import com.crowndine.model.Order;
import com.crowndine.model.OrderDetail;
import com.crowndine.repository.*;
import com.crowndine.service.impl.CalculationServiceImpl;
import com.crowndine.service.impl.order.OrderDetailServiceImpl;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

class OrderDetailSafetyTest {
    final OrderRepository orders = mock(OrderRepository.class);
    final OrderDetailRepository details = mock(OrderDetailRepository.class);
    final PaymentRepository payments = mock(PaymentRepository.class);
    final OrderDetailServiceImpl service = new OrderDetailServiceImpl(details, mock(ItemRepository.class), mock(ComboRepository.class), new CalculationServiceImpl(), orders, payments);
    Order order = new Order(); OrderDetail line = new OrderDetail();
    OrderDetailSafetyTest() {
        order.setId(1L); order.setStatus(EOrderStatus.IN_PROGRESS);
        line.setId(7L); line.setQuantity(2); line.setTotalPrice(new BigDecimal("100000")); line.setStatus(EOrderDetailStatus.PENDING);
        order.addOrderDetail(line);
        when(details.findById(7L)).thenReturn(Optional.of(line));
        when(orders.findByIdForUpdate(1L)).thenReturn(Optional.of(order));
    }
    @Test void quantityChangeRecalculatesFullQuoteUsingAcceptedUnitPrice() {
        var update = new UpdateOrderDetailRequest(); update.setQuantity(3);
        service.updateOrderDetail(7L, update);
        assertEquals(new BigDecimal("150000.00"), line.getTotalPrice());
        assertEquals(new BigDecimal("150000.00"), order.getFinalPrice());
    }
    @Test void pendingPaymentFreezesPriceAndFinalOrderCannotBeDeleted() {
        when(payments.existsByTargetAndOrderIdAndStatus(EPaymentTarget.ORDER, 1L, EPaymentStatus.PENDING)).thenReturn(true);
        assertThrows(InvalidDataException.class, () -> service.deleteOrderDetail(7L));
        assertEquals(1, order.getOrderDetails().size());
        order.setStatus(EOrderStatus.COMPLETED);
        assertThrows(InvalidDataException.class, () -> service.changeStatus(7L, EOrderDetailStatus.CANCELLED));
    }
    @Test void servedDishCannotBeReopenedOrCancelled() {
        line.setStatus(EOrderDetailStatus.SERVED);
        assertThrows(InvalidDataException.class, () -> service.changeStatus(7L, EOrderDetailStatus.PENDING));
        assertThrows(InvalidDataException.class, () -> service.changeStatus(7L, EOrderDetailStatus.CANCELLED));
    }
}
