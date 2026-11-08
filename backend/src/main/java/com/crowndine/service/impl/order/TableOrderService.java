package com.crowndine.service.impl.order;

import com.crowndine.common.enums.*;
import com.crowndine.common.utils.CodeUtils;
import com.crowndine.dto.request.TableOrderItemsRequest;
import com.crowndine.dto.response.OrderResponse;
import com.crowndine.exception.InvalidDataException;
import com.crowndine.exception.ResourceNotFoundException;
import com.crowndine.model.*;
import com.crowndine.repository.*;
import com.crowndine.service.order.OrderService;
import com.crowndine.service.order.OrderStatusService;
import com.crowndine.service.reservation.ReservationAvailabilityService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;

/** Resolves a serving session by table ID, never by display name or kitchen list. */
@Service
@RequiredArgsConstructor
public class TableOrderService {
    public static final List<EOrderStatus> SERVING = List.of(
            EOrderStatus.CONFIRMED, EOrderStatus.IN_PROGRESS, EOrderStatus.SERVED);
    private final RestaurantTableRepository tables;
    private final OrderRepository orders;
    private final ReservationRepository reservations;
    private final UserRepository users;
    private final OrderService orderService;
    private final OrderStatusService orderStatusService;
    private final ReservationAvailabilityService availability;

    @Transactional(readOnly = true)
    public OrderResponse activeOrder(Long tableId) {
        tables.findById(tableId).orElseThrow(() -> new ResourceNotFoundException("Table not found"));
        Order order = findActive(tableId);
        return order == null ? null : orderService.getOrderResponse(order.getId());
    }

    @Transactional(rollbackFor = Exception.class)
    public OrderResponse addItems(Long tableId, TableOrderItemsRequest request, String username) {
        RestaurantTable table = tables.findByIdForUpdate(tableId)
                .orElseThrow(() -> new ResourceNotFoundException("Table not found"));
        if (table.getStatus() == ETableStatus.UNAVAILABLE) {
            throw new InvalidDataException("Bàn đang ngưng phục vụ");
        }
        Order order = findActive(tableId);
        if (!Objects.equals(request.getExpectedOrderId(), order == null ? null : order.getId())) {
            throw new InvalidDataException("Đơn của bàn đã thay đổi. Vui lòng tải lại trước khi gọi món");
        }
        if (order != null && order.getReservation() != null
                && order.getReservation().getStatus() != EReservationStatus.CHECKED_IN) {
            throw new InvalidDataException("Cần check-in đặt chỗ trước khi gọi món tại bàn");
        }
        if (order == null) {
            List<Reservation> checkedIn = reservations.findByTableIdAndStatusAndCheckedOutAtIsNull(
                    tableId, EReservationStatus.CHECKED_IN);
            if (checkedIn.size() > 1) {
                throw new InvalidDataException("Bàn có nhiều lượt nhận bàn. Vui lòng kiểm tra đặt chỗ");
            }
            if (!checkedIn.isEmpty()) {
                Reservation reservation = checkedIn.getFirst();
                if (reservation.getOrder() != null) {
                    throw new InvalidDataException("Đơn đặt bàn đã kết thúc hoặc chưa sẵn sàng phục vụ");
                }
                order = orderService.createOrderForReservation(reservation, reservation.getUser(), EOrderStatus.CONFIRMED);
                reservation.setOrder(order);
                reservations.save(reservation);
            } else {
                if (table.getStatus() != ETableStatus.AVAILABLE) {
                    throw new InvalidDataException("Bàn chưa có đơn phục vụ. Hãy kiểm tra/check-in đặt chỗ trước");
                }
                LocalDateTime now = LocalDateTime.now();
                availability.ensureTableAvailable(now.toLocalDate(), now.toLocalTime(), tableId);
                order = new Order();
                order.setRestaurantTable(table);
                order.setCode(CodeUtils.generateOrderCode());
                order.setStatus(EOrderStatus.CONFIRMED);
                order = orders.save(order);
            }
            order.setStaff(users.findByUsername(username)
                    .orElseThrow(() -> new ResourceNotFoundException("Staff not found")));
        }
        // A new PENDING ticket is created even when the same dish is already cooking.
        orderService.appendItemsToOrder(order.getId(), request, username);
        orderStatusService.transitionOrderStatus(order, EOrderStatus.IN_PROGRESS);
        return orderService.getOrderResponse(order.getId());
    }

    private Order findActive(Long tableId) {
        List<Order> active = orders.findByRestaurantTableIdAndStatusIn(tableId, SERVING);
        if (active.size() > 1) {
            throw new InvalidDataException("Bàn có nhiều đơn đang phục vụ. Vui lòng kiểm tra trước khi gọi món");
        }
        return active.isEmpty() ? null : active.getFirst();
    }
}
