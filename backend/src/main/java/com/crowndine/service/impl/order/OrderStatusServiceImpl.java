package com.crowndine.service.impl.order;

import com.crowndine.common.enums.EOrderStatus;
import com.crowndine.common.enums.ETableStatus;
import com.crowndine.dto.response.UpdateStatusOrderResponse;
import com.crowndine.exception.ResourceNotFoundException;
import com.crowndine.exception.InvalidDataException;
import com.crowndine.model.Order;
import com.crowndine.repository.OrderRepository;
import com.crowndine.service.layout.RestaurantTableStateService;
import com.crowndine.service.order.OrderStatusService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j(topic = "ORDER-STATUS-SERVICE")
public class OrderStatusServiceImpl implements OrderStatusService {

    private static final String ORDER_NOT_FOUND_MESSAGE = "Order not found";

    private final OrderRepository orderRepository;
    private final com.crowndine.repository.PaymentRepository paymentRepository;
    private final com.crowndine.repository.ReservationRepository reservationRepository;
    private final RestaurantTableStateService restaurantTableStateService;
    private final SimpMessagingTemplate messagingTemplate;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public UpdateStatusOrderResponse updateOrderStatus(Long orderId, EOrderStatus status) {
        return updateOrderStatus(orderId, status, null);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public UpdateStatusOrderResponse updateOrderStatus(Long orderId, EOrderStatus status, String cancelReason) {
        Order order = orderRepository.findByIdForUpdate(orderId).orElseThrow(() -> new ResourceNotFoundException(ORDER_NOT_FOUND_MESSAGE));
        if (status == EOrderStatus.COMPLETED) {
            throw new InvalidDataException("Hãy xác nhận thu tiền qua chức năng thanh toán để hoàn tất đơn");
        }
        if (order.getStatus().isFinal()) {
            throw new InvalidDataException("Không thể thay đổi đơn đã kết thúc");
        }
        if (status == EOrderStatus.PRE_ORDER || status == EOrderStatus.CONFIRMED) {
            throw new InvalidDataException("Không thể đưa đơn về trạng thái trước đó");
        }
        if (status == EOrderStatus.CANCELLED && (order.getReservation() != null
                || paymentRepository.existsByTargetAndOrderIdAndStatus(com.crowndine.common.enums.EPaymentTarget.ORDER, orderId, com.crowndine.common.enums.EPaymentStatus.PENDING))) {
            throw new InvalidDataException("Đơn gắn đặt chỗ hoặc đang thanh toán không thể hủy tại đây");
        }
        if ((status == EOrderStatus.IN_PROGRESS && order.getStatus() != EOrderStatus.CONFIRMED)
                || (status == EOrderStatus.SERVED && order.getStatus() != EOrderStatus.IN_PROGRESS)) {
            throw new InvalidDataException("Trạng thái đơn không đúng trình tự phục vụ");
        }
        Order updatedOrder = transitionOrderStatus(order, status, cancelReason);
        return buildStatusResponse(updatedOrder);
    }

    @Override
    public Order transitionOrderStatus(Order order, EOrderStatus status) {
        return transitionOrderStatus(order, status, null);
    }

    @Override
    public Order transitionOrderStatus(Order order, EOrderStatus status, String cancelReason) {
        order.setStatus(status);
        if (status == EOrderStatus.CANCELLED && cancelReason != null) {
            order.setCancelReason(cancelReason);
        }
        Order updatedOrder = orderRepository.save(order);
        handleOrderStatusSideEffects(updatedOrder);
        publishOrderStatus(updatedOrder);
        return updatedOrder;
    }

    private void handleOrderStatusSideEffects(Order order) {
        if (order.getRestaurantTable() == null) {
            return;
        }

        Long tableId = order.getRestaurantTable().getId();
        switch (order.getStatus()) {
            case CONFIRMED, IN_PROGRESS -> restaurantTableStateService.changeStatus(tableId, ETableStatus.OCCUPIED);
            case COMPLETED, CANCELLED -> {
                boolean anotherOrder = orderRepository.findByRestaurantTableIdAndStatusIn(tableId, java.util.List.of(EOrderStatus.CONFIRMED, EOrderStatus.IN_PROGRESS, EOrderStatus.SERVED)).stream()
                        .anyMatch(active -> !active.getId().equals(order.getId()));
                boolean guestPresent = reservationRepository.findByTableIdAndStatusAndCheckedOutAtIsNull(tableId, com.crowndine.common.enums.EReservationStatus.CHECKED_IN).stream()
                        .anyMatch(r -> statusIsCancellation(order) || order.getReservation() == null || !r.getId().equals(order.getReservation().getId()));
                if (!anotherOrder && !guestPresent) restaurantTableStateService.changeStatus(tableId, ETableStatus.AVAILABLE);
            }
            case PRE_ORDER, SERVED -> {
                // PRE_ORDER reserve is handled by reservation scheduler; SERVED keeps current table state.
            }
        }
    }

    private boolean statusIsCancellation(Order order) { return order.getStatus() == EOrderStatus.CANCELLED; }

    private void publishOrderStatus(Order order) {
        messagingTemplate.convertAndSend("/topic/orders", buildStatusResponse(order));
    }

    private UpdateStatusOrderResponse buildStatusResponse(Order order) {
        UpdateStatusOrderResponse response = new UpdateStatusOrderResponse();
        response.setId(order.getId());
        response.setStatus(order.getStatus());
        return response;
    }
}
