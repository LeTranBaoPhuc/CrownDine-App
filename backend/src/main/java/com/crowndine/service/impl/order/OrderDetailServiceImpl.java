package com.crowndine.service.impl.order;

import com.crowndine.common.enums.EOrderDetailStatus;
import com.crowndine.common.enums.EOrderStatus;
import com.crowndine.common.enums.EItemStatus;
import com.crowndine.common.enums.EComboStatus;
import com.crowndine.dto.request.OrderItemRequest;
import com.crowndine.dto.request.UpdateOrderDetailRequest;
import com.crowndine.dto.response.UpdateStatusOrderDetailResponse;
import com.crowndine.exception.InvalidDataException;
import com.crowndine.exception.ResourceNotFoundException;
import com.crowndine.model.Order;
import com.crowndine.model.OrderDetail;
import com.crowndine.repository.ComboRepository;
import com.crowndine.repository.ItemRepository;
import com.crowndine.repository.OrderDetailRepository;
import com.crowndine.service.CalculationService;
import com.crowndine.service.order.OrderDetailService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j(topic = "ORDER-DETAIL-SERVICE")
public class OrderDetailServiceImpl implements OrderDetailService {

    private final OrderDetailRepository orderDetailRepository;
    private final ItemRepository itemRepository;
    private final ComboRepository comboRepository;

    private final CalculationService calculationService;
    private final com.crowndine.repository.OrderRepository orderRepository;
    private final com.crowndine.repository.PaymentRepository paymentRepository;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void createPendingOrderDetails(Order order, List<OrderItemRequest> request) {
        log.info("Processing {} items for order {}", request.size(), order.getId());

        List<OrderDetail> newOrderDetails = new ArrayList<>();

        request.forEach(item -> {
            if ((item.getItemId() == null) == (item.getComboId() == null)
                    || item.getQuantity() == null || item.getQuantity() < 1) {
                throw new InvalidDataException("Mỗi dòng phải có một món/combo và số lượng hợp lệ");
            }
            OrderDetail orderDetailItem = new OrderDetail();
            if (item.getItemId() != null) {
                orderDetailItem.setItem(itemRepository.findById(item.getItemId()).orElseThrow(() -> new ResourceNotFoundException("Item Not Found")));
            }
            if (item.getComboId() != null) {
                orderDetailItem.setCombo(comboRepository.findById(item.getComboId()).orElseThrow(() -> new ResourceNotFoundException("Combo Not Found")));
            }
            if ((orderDetailItem.getItem() != null && orderDetailItem.getItem().getStatus() != EItemStatus.AVAILABLE)
                    || (orderDetailItem.getCombo() != null && orderDetailItem.getCombo().getStatus() != EComboStatus.AVAILABLE)) {
                throw new InvalidDataException("Món ăn hoặc combo đã ngưng phục vụ. Vui lòng tải lại thực đơn");
            }

            orderDetailItem.setQuantity(item.getQuantity());
            orderDetailItem.setNote(item.getNote());
            orderDetailItem.setStatus(EOrderDetailStatus.PENDING);
            orderDetailItem.calculateAndSetTotalPrice();
            order.addOrderDetail(orderDetailItem);
            newOrderDetails.add(orderDetailItem);
            log.info("Added order detail for order {}", order.getId());
        });

        orderDetailRepository.saveAll(newOrderDetails);

        log.info("Added successfully order detail for order {}", order.getId());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateOrderDetail(Long id, UpdateOrderDetailRequest request) {
        OrderDetail detail = findById(id);
        Order order = lockEditableOrder(detail);
        boolean changesPrice = request.getQuantity() != null || request.getStatus() == EOrderDetailStatus.CANCELLED;
        if (changesPrice) ensurePriceEditable(order);
        if (request.getQuantity() != null) {
            if (request.getQuantity() < 1 || detail.getStatus() != EOrderDetailStatus.PENDING) {
                throw new InvalidDataException("Chỉ chỉnh số lượng hợp lệ khi món chưa chế biến");
            }
            BigDecimal unitPrice = detail.getTotalPrice().divide(BigDecimal.valueOf(detail.getQuantity()), 10, java.math.RoundingMode.HALF_UP);
            detail.setQuantity(request.getQuantity());
            detail.setTotalPrice(unitPrice.multiply(BigDecimal.valueOf(request.getQuantity())).setScale(2, java.math.RoundingMode.HALF_UP));
        }
        if (request.getStatus() != null) transitionDetail(detail, request.getStatus());
        if (request.getNote() != null) detail.setNote(request.getNote());
        if (changesPrice) reprice(order);
        orderDetailRepository.save(detail);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteOrderDetail(Long id) {
        OrderDetail detail = findById(id);
        Order order = lockEditableOrder(detail);
        ensurePriceEditable(order);
        if (detail.getStatus() != EOrderDetailStatus.PENDING) throw new InvalidDataException("Chỉ xóa món chưa chế biến");
        order.getOrderDetails().remove(detail);
        orderDetailRepository.delete(detail);
        reprice(order);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public UpdateStatusOrderDetailResponse changeStatus(Long id, EOrderDetailStatus status) {
        OrderDetail detail = findById(id);
        Order order = lockEditableOrder(detail);
        if (status == EOrderDetailStatus.CANCELLED) ensurePriceEditable(order);
        transitionDetail(detail, status);
        if (status == EOrderDetailStatus.CANCELLED) reprice(order);
        orderDetailRepository.save(detail);
        return UpdateStatusOrderDetailResponse.builder().id(id).status(status).build();
    }

    private Order lockEditableOrder(OrderDetail detail) {
        Order order = orderRepository.findByIdForUpdate(detail.getOrder().getId()).orElseThrow(() -> new ResourceNotFoundException("Order not found"));
        if (order.getStatus().isFinal() || order.getStatus() == EOrderStatus.PRE_ORDER) throw new InvalidDataException("Đơn chưa nhận bàn hoặc đã kết thúc");
        return order;
    }

    private void ensurePriceEditable(Order order) {
        if (paymentRepository.existsByTargetAndOrderIdAndStatus(com.crowndine.common.enums.EPaymentTarget.ORDER, order.getId(), com.crowndine.common.enums.EPaymentStatus.PENDING)
                || (order.getReservation() != null && order.getReservation().getStatus() != com.crowndine.common.enums.EReservationStatus.PENDING)) {
            throw new InvalidDataException("Không thể sửa/xóa giá món khi đã thu cọc hoặc đang thanh toán");
        }
    }

    private void transitionDetail(OrderDetail detail, EOrderDetailStatus target) {
        EOrderDetailStatus current = detail.getStatus();
        if (current == target) return;
        boolean valid = (current == EOrderDetailStatus.PENDING && (target == EOrderDetailStatus.COOKING || target == EOrderDetailStatus.CANCELLED))
                || (current == EOrderDetailStatus.COOKING && target == EOrderDetailStatus.READY)
                || (current == EOrderDetailStatus.READY && target == EOrderDetailStatus.SERVED);
        if (!valid) throw new InvalidDataException("Trạng thái món không đúng trình tự chế biến/phục vụ");
        detail.setStatus(target);
    }

    private void reprice(Order order) {
        var pricing = calculationService.calculateOrderPricing(order);
        order.setTotalPrice(pricing.totalPrice());
        order.setDiscountPrice(pricing.discountPrice());
        order.setFinalPrice(pricing.finalPrice());
    }

    private OrderDetail findById(Long id) {
        return orderDetailRepository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy món ăn trong đơn hàng"));
    }
}
