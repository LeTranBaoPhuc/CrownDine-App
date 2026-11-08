package com.crowndine.service.payment;

import com.crowndine.common.enums.*;
import com.crowndine.config.PayOSConfig;
import com.crowndine.dto.request.PaymentRequest;
import com.crowndine.exception.InvalidDataException;
import com.crowndine.model.*;
import com.crowndine.repository.*;
import com.crowndine.service.impl.payment.*;
import com.crowndine.service.impl.CalculationServiceImpl;
import com.crowndine.service.order.*;
import com.crowndine.service.reservation.*;
import com.crowndine.service.user.UserService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.AfterEach;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.AuthorityUtils;
import org.springframework.security.core.context.SecurityContextHolder;
import vn.payos.PayOS;
import vn.payos.model.webhooks.WebhookData;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class PaymentSafetyTest {
    PaymentRepository payments = mock(PaymentRepository.class);
    ReservationRepository reservations = mock(ReservationRepository.class);
    OrderRepository orders = mock(OrderRepository.class);
    ReservationService reservationService = mock(ReservationService.class);
    OrderService orderService = mock(OrderService.class);
    UserService users = mock(UserService.class);
    PaymentPreparationServiceImpl preparation = new PaymentPreparationServiceImpl(payments, reservationService, orderService, users,
            new CalculationServiceImpl(), reservations, orders, mock(OrderVoucherService.class));
    PaymentRequest request(String json) throws Exception { return new ObjectMapper().readValue(json, PaymentRequest.class); }
    void staff() { SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken("staff", "", AuthorityUtils.createAuthorityList("STAFF"))); }
    @AfterEach void clear() { SecurityContextHolder.clearContext(); }

    @Test void customerCannotConfirmCashOrPayForAnotherPersonsReservation() throws Exception {
        var cash = new CashService(preparation, mock(OrderPaymentService.class));
        var cashRequest = request("{\"orderCode\":\"O1\",\"method\":\"CASH\"}");
        assertThrows(AccessDeniedException.class, () -> cash.createPaymentLink(cashRequest, "bob"));
        User alice = new User(); alice.setUsername("alice");
        Reservation r = new Reservation(); r.setUser(alice);
        when(reservations.findByCodeForUpdate("R1")).thenReturn(Optional.of(r));
        var depositRequest = request("{\"reservationCode\":\"R1\",\"method\":\"PAYOS\"}");
        assertThrows(AccessDeniedException.class, () -> preparation.prepare(depositRequest, "bob", EPaymentMethod.PAYOS, EPaymentStatus.PENDING));
        verify(payments, never()).save(any());
    }

    @Test void settlementSubtractsActualFoodDepositAfterAdditionalDishesAndReusesPendingIntent() throws Exception {
        staff();
        Reservation r = new Reservation(); r.setId(5L);
        Order order = new Order(); order.setId(1L); order.setCode("O1"); order.setStatus(EOrderStatus.SERVED);
        order.setFinalPrice(new BigDecimal("1500000")); order.setReservation(r);
        when(orders.findByCodeForUpdate("O1")).thenReturn(Optional.of(order));
        when(orderService.getOrderByCode("O1")).thenReturn(order);
        when(payments.existsByTargetAndReservationIdAndStatus(EPaymentTarget.RESERVATION, 5L, EPaymentStatus.SUCCESS)).thenReturn(true);
        Payment deposit = new Payment(); deposit.setAmount(new BigDecimal("450000")); deposit.setTableDepositAmount(new BigDecimal("250000"));
        when(payments.findByTargetAndReservationIdAndStatus(EPaymentTarget.RESERVATION, 5L, EPaymentStatus.SUCCESS)).thenReturn(List.of(deposit));
        when(payments.save(any())).thenAnswer(i -> i.getArgument(0));
        var req = request("{\"orderCode\":\"O1\",\"method\":\"PAYOS\"}");
        var first = preparation.prepare(req, "staff", EPaymentMethod.PAYOS, EPaymentStatus.PENDING);
        assertEquals(new BigDecimal("1300000"), first.amount());
        when(payments.findFirstByTargetAndOrderIdAndStatusOrderByIdDesc(EPaymentTarget.ORDER, 1L, EPaymentStatus.PENDING)).thenReturn(Optional.of(first.payment()));
        assertSame(first.payment(), preparation.prepare(req, "staff", EPaymentMethod.PAYOS, EPaymentStatus.PENDING).payment());
        assertThrows(InvalidDataException.class, () -> preparation.prepare(req, "staff", EPaymentMethod.CASH, EPaymentStatus.SUCCESS));
        verify(payments, times(1)).save(any());
    }

    @Test void verifiedWebhookMustMatchSuccessCodeAmountAndMethodAndBeIdempotent() {
        var payOS = mock(PayOS.class, RETURNS_DEEP_STUBS);
        var paidOrders = mock(OrderPaymentService.class);
        var service = new PayOSService(preparation, mock(PayOSConfig.class), payOS, payments, paidOrders, mock(ReservationLifecycleService.class));
        var data = mock(WebhookData.class);
        when(payOS.webhooks().verify(anyMap())).thenReturn(data);
        when(data.getOrderCode()).thenReturn(99L); when(data.getCode()).thenReturn("00"); when(data.getAmount()).thenReturn(100L);
        Payment p = new Payment(); p.setCode(99L); p.setAmount(new BigDecimal("200")); p.setMethod(EPaymentMethod.PAYOS); p.setStatus(EPaymentStatus.PENDING);
        p.setTarget(EPaymentTarget.ORDER); p.setOrder(new Order());
        when(payments.findByCodeForUpdate(99L)).thenReturn(Optional.of(p));
        assertThrows(InvalidDataException.class, () -> service.handleWebHook(Map.of()));
        assertEquals(EPaymentStatus.PENDING, p.getStatus());
        when(data.getAmount()).thenReturn(200L); when(data.getCode()).thenReturn("01");
        assertThrows(InvalidDataException.class, () -> service.handleWebHook(Map.of()));
        when(data.getCode()).thenReturn("00"); p.setMethod(EPaymentMethod.CASH);
        assertThrows(InvalidDataException.class, () -> service.handleWebHook(Map.of()));
        p.setMethod(EPaymentMethod.PAYOS);
        service.handleWebHook(Map.of()); service.handleWebHook(Map.of());
        assertEquals(EPaymentStatus.SUCCESS, p.getStatus());
        verify(paidOrders, times(1)).markOrderAsPaid(p.getOrder());
    }
}
