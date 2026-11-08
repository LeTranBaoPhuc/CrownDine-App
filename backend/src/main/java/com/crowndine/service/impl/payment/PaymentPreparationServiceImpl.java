package com.crowndine.service.impl.payment;

import com.crowndine.common.enums.*;
import com.crowndine.common.utils.CodeUtils;
import com.crowndine.dto.request.PaymentRequest;
import com.crowndine.exception.InvalidDataException;
import com.crowndine.model.Order;
import com.crowndine.model.OrderDetail;
import com.crowndine.model.Payment;
import com.crowndine.model.Reservation;
import com.crowndine.model.RestaurantTable;
import com.crowndine.model.User;
import com.crowndine.repository.PaymentRepository;
import com.crowndine.repository.ReservationRepository;
import com.crowndine.repository.OrderRepository;
import com.crowndine.security.ResourceAccess;
import com.crowndine.service.CalculationService;
import com.crowndine.service.order.OrderService;
import com.crowndine.service.payment.PaymentPreparationService;
import com.crowndine.service.payment.PreparedPayment;
import com.crowndine.service.reservation.ReservationService;
import com.crowndine.service.user.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j(topic = "PAYMENT-PREPARATION")
public class PaymentPreparationServiceImpl implements PaymentPreparationService {

    private final PaymentRepository paymentRepository;
    private final ReservationService reservationService;
    private final OrderService orderService;
    private final UserService userService;
    private final CalculationService calculationService;
    private final ReservationRepository reservationRepository;
    private final OrderRepository orderRepository;
    private final com.crowndine.service.order.OrderVoucherService orderVoucherService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public PreparedPayment prepare(PaymentRequest request, String username, EPaymentMethod method, EPaymentStatus initialStatus) {
        boolean hasReservation = StringUtils.hasText(request.getReservationCode());

        User user = userService.getUserByUserName(username);

        if (hasReservation) {
            var reservation = reservationRepository.findByCodeForUpdate(request.getReservationCode())
                    .orElseThrow(() -> new InvalidDataException("Không tìm thấy đặt bàn"));
            ResourceAccess.requireOwnerOrStaff(reservation.getUser(), username);
            validateReservationForPayment(reservation);
            if (reservation.getOrder() != null) orderRepository.findByIdForUpdate(reservation.getOrder().getId()).orElseThrow();
            var pending = paymentRepository.findFirstByTargetAndReservationIdAndStatusOrderByIdDesc(
                    EPaymentTarget.RESERVATION, reservation.getId(), EPaymentStatus.PENDING);
            if (pending.isPresent()) return new PreparedPayment(pending.get(), pending.get().getAmount(), "Thanh toán đặt cọc bàn");
        } else {
            if (!ResourceAccess.isStaff()) throw new org.springframework.security.access.AccessDeniedException("Chỉ nhân viên được thu tiền đơn hàng");
            var order = orderRepository.findByCodeForUpdate(request.getOrderCode())
                    .orElseThrow(() -> new InvalidDataException("Không tìm thấy đơn hàng"));
            validateOrderForPayment(order);
            var pending = paymentRepository.findFirstByTargetAndOrderIdAndStatusOrderByIdDesc(
                    EPaymentTarget.ORDER, order.getId(), EPaymentStatus.PENDING);
            if (pending.isPresent()) {
                if (method != pending.get().getMethod()) throw new InvalidDataException("Đơn đang có giao dịch PayOS, hãy kiểm tra giao dịch trước khi thu tiền lần nữa");
                return new PreparedPayment(pending.get(), pending.get().getAmount(), "Thanh toán đơn hàng");
            }
        }

        Payment payment = initPayment(user, method, initialStatus);
        PreparedPayment preparedPayment = hasReservation ? prepareReservationPayment(request, payment) : prepareOrderPayment(request, payment);

        BigDecimal payable = preparedPayment.amount().setScale(0, RoundingMode.HALF_UP);
        if (!(method == EPaymentMethod.CASH && !hasReservation && payable.signum() == 0)) validatePositiveAmount(payable);
        preparedPayment.payment().setAmount(payable);

        Payment savedPayment = paymentRepository.save(preparedPayment.payment());
        log.info("Payment id {} saved with status={}, target={}", savedPayment.getId(), savedPayment.getStatus(), savedPayment.getTarget());

        return new PreparedPayment(savedPayment, payable, preparedPayment.description());
    }

    private Payment initPayment(User user, EPaymentMethod method, EPaymentStatus initialStatus) {
        Payment payment = new Payment();
        payment.setStatus(initialStatus);
        payment.setMethod(method);
        payment.setUser(user);
        payment.setCode(CodeUtils.generatePaymentCode());
        return payment;
    }

    private PreparedPayment prepareReservationPayment(PaymentRequest request, Payment payment) {
        log.info("Preparing reservation payment for reservation code {}", request.getReservationCode());
        Reservation reservation = reservationService.getReservationByCode(request.getReservationCode());
        validateReservationForPayment(reservation);

        payment.setReservation(reservation);
        payment.setTarget(EPaymentTarget.RESERVATION);
        payment.setSource(EPaymentSource.CLIENT_APP);
        payment.setType(EPaymentType.DEPOSIT);

        Order order = reservation.getOrder();
        BigDecimal finalOrderPrice = getReservationOrderFinalPrice(order);
        if (order != null) {
            log.info("Order {} final price used for reservation deposit calculation: {}", order.getId(), finalOrderPrice);
        } else {
            log.info("Reservation {} has no order. Using final order price {} for reservation deposit calculation",
                    reservation.getId(), finalOrderPrice);
        }
        BigDecimal tableDeposit = calculateTableDeposit(reservation);
        payment.setTableDepositAmount(tableDeposit);
        log.info("Reservation {} table {} deposit amount: {}", reservation.getId(), reservation.getTable().getId(), tableDeposit);
        BigDecimal amountToPay = calculationService.calculateDepositPayment(finalOrderPrice, tableDeposit);
        log.info("Reservation {} deposit payment amount calculated from final order price {} and table deposit {}: {}",
                reservation.getId(), finalOrderPrice, tableDeposit, amountToPay);

        return new PreparedPayment(payment, amountToPay, "Thanh toán đặt cọc bàn");
    }

    private PreparedPayment prepareOrderPayment(PaymentRequest request, Payment payment) {
        log.info("Preparing order payment for order code {}", request.getOrderCode());
        Order order = orderService.getOrderByCode(request.getOrderCode());
        validateOrderForPayment(order);

        payment.setOrder(order);
        payment.setTarget(EPaymentTarget.ORDER);
        payment.setSource(EPaymentSource.POS_COUNTER);
        payment.setType(EPaymentType.SETTLEMENT);

        BigDecimal amountToPay = order.getFinalPrice();
        log.info("Order {} final price before settlement adjustment: {}", order.getId(), amountToPay);

        if (order.getReservation() != null) {
            boolean hasSuccessfulReservationDeposit = paymentRepository.existsByTargetAndReservationIdAndStatus(
                    EPaymentTarget.RESERVATION, order.getReservation().getId(), EPaymentStatus.SUCCESS);

            if (hasSuccessfulReservationDeposit) {
                var previousDeposits = paymentRepository.findByTargetAndReservationIdAndStatus(EPaymentTarget.RESERVATION, order.getReservation().getId(), EPaymentStatus.SUCCESS);
                if (previousDeposits.stream().anyMatch(p -> p.getTableDepositAmount() == null)) throw new InvalidDataException("Cọc cũ thiếu số tiền giữ bàn. Cần đối soát dữ liệu trước khi tất toán");
                BigDecimal orderDepositPaid = paymentRepository.findByTargetAndReservationIdAndStatus(
                        EPaymentTarget.RESERVATION, order.getReservation().getId(), EPaymentStatus.SUCCESS).stream()
                        .map(p -> p.getAmount().subtract(p.getTableDepositAmount() == null ? BigDecimal.ZERO : p.getTableDepositAmount()).max(BigDecimal.ZERO))
                        .reduce(BigDecimal.ZERO, BigDecimal::add);
                amountToPay = amountToPay.subtract(orderDepositPaid).max(BigDecimal.ZERO);
                log.info("Order {} settlement subtracts only order deposit {} from final price {}. Table deposit is retained by the restaurant. Remaining amount to collect: {}",
                        order.getId(), orderDepositPaid, order.getFinalPrice(), amountToPay);
            } else {
                log.info("Order {} has reservation {} but no successful reservation deposit payment. Remaining amount stays at final price {}",
                        order.getId(), order.getReservation().getId(), amountToPay);
            }
        }

        return new PreparedPayment(payment, amountToPay, "Thanh toán đơn hàng");
    }

    private BigDecimal getReservationOrderFinalPrice(Order order) {
        if (order == null) {
            log.info("Reservation has no order. Using 0 as final order price for deposit calculation");
            return BigDecimal.ZERO;
        }

        if (order.getFinalPrice() != null) {
            log.info("Using persisted final price {} for order {}", order.getFinalPrice(), order.getId());
            return order.getFinalPrice();
        }

        List<OrderDetail> orderDetails = order.getOrderDetails();
        if (orderDetails == null) {
            log.info("Order {} has no order details. Using 0 as final order price for deposit calculation", order.getId());
            return BigDecimal.ZERO;
        }

        BigDecimal recalculatedFinalPrice = calculationService.calculateTotalOrder(orderDetails);
        log.warn("Order {} finalPrice is null. Falling back to recalculated amount from order details: {}",
                order.getId(), recalculatedFinalPrice);
        return recalculatedFinalPrice;
    }

    private BigDecimal calculateTableDeposit(Reservation reservation) {
        RestaurantTable table = reservation.getTable();
        return calculationService.calculateTableDeposit(table != null ? table.getBaseDeposit() : null);
    }

    private void validatePositiveAmount(BigDecimal amountToPay) {
        if (amountToPay == null || amountToPay.compareTo(BigDecimal.ZERO) <= 0) {
            throw new InvalidDataException("Số tiền thanh toán phải lớn hơn 0");
        }
    }

    private void validateReservationForPayment(Reservation reservation) {
        if (reservation.getExpiratedAt() == null || !reservation.getExpiratedAt().isAfter(java.time.LocalDateTime.now())) {
            throw new InvalidDataException("Đặt bàn đã hết thời gian giữ chỗ");
        }
        if (reservation.getStatus().isFinal() || reservation.getStatus() == EReservationStatus.CHECKED_IN || reservation.getStatus() == EReservationStatus.CONFIRMED) {
            throw new InvalidDataException("Trạng thái đặt bàn hiện tại không thể tạo thanh toán");
        }

        boolean alreadyPaidDeposit = paymentRepository.existsByTargetAndReservationIdAndStatus(EPaymentTarget.RESERVATION, reservation.getId(), EPaymentStatus.SUCCESS);

        if (alreadyPaidDeposit) {
            throw new InvalidDataException("Đặt bàn này đã thanh toán cọc");
        }
    }

    private void validateOrderForPayment(Order order) {
        if (order.getOrderDetails().stream().anyMatch(d -> d.getStatus() != EOrderDetailStatus.SERVED && d.getStatus() != EOrderDetailStatus.CANCELLED)) {
            throw new InvalidDataException("Hãy phục vụ xong các món trước khi tất toán đơn");
        }
        if (order.getVoucher() != null && order.getReservation() == null) {
            orderVoucherService.validateVoucherForOrder(order.getId(), order.getVoucher().getCode(), order.getUser() == null ? null : order.getUser().getUsername());
        }
        if (order.getStatus() == EOrderStatus.PRE_ORDER) throw new InvalidDataException("Đơn chưa nhận bàn, không thể tất toán");
        if (order.getStatus().isFinal()) {
            throw new InvalidDataException("Trạng thái đơn hàng hiện tại không thể tạo thanh toán");
        }

        boolean alreadyPaidOrder = paymentRepository.existsByTargetAndOrderIdAndStatus(EPaymentTarget.ORDER, order.getId(), EPaymentStatus.SUCCESS);

        if (alreadyPaidOrder) {
            throw new InvalidDataException("Đơn hàng này đã được thanh toán");
        }

        if (order.getFinalPrice() == null || order.getFinalPrice().compareTo(BigDecimal.ZERO) < 0) {
            throw new InvalidDataException("Đơn hàng không có số tiền hợp lệ để thanh toán");
        }
    }
}
