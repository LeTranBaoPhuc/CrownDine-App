package com.crowndine.service.impl.payment;

import com.crowndine.common.enums.EPaymentMethod;
import com.crowndine.common.enums.EPaymentStatus;
import com.crowndine.common.enums.EPaymentTarget;
import com.crowndine.config.PayOSConfig;
import com.crowndine.exception.InvalidDataException;
import com.crowndine.exception.ResourceNotFoundException;
import com.crowndine.model.Payment;
import com.crowndine.repository.PaymentRepository;
import com.crowndine.service.order.OrderPaymentService;
import com.crowndine.service.payment.AbstractPaymentStrategy;
import com.crowndine.service.payment.PaymentPreparationService;
import com.crowndine.service.payment.PreparedPayment;
import com.crowndine.service.reservation.ReservationLifecycleService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.payos.PayOS;
import vn.payos.model.v2.paymentRequests.CreatePaymentLinkRequest;
import vn.payos.model.v2.paymentRequests.CreatePaymentLinkResponse;
import vn.payos.model.v2.paymentRequests.PaymentLinkItem;
import vn.payos.model.webhooks.WebhookData;

import java.math.BigDecimal;
import java.util.Map;

@Service("payos")
@Slf4j(topic = "PAYOS-SERVICE")
public class PayOSService extends AbstractPaymentStrategy {

    private final PayOSConfig payOSConfig;
    private final PayOS payOS;
    private final PaymentRepository paymentRepository;
    private final OrderPaymentService orderPaymentService;
    private final ReservationLifecycleService reservationLifecycleService;

    public PayOSService(PaymentPreparationService paymentPreparationService,
                        PayOSConfig payOSConfig,
                        PayOS payOS,
                        PaymentRepository paymentRepository,
                        OrderPaymentService orderPaymentService,
                        ReservationLifecycleService reservationLifecycleService) {
        super(paymentPreparationService);
        this.payOSConfig = payOSConfig;
        this.payOS = payOS;
        this.paymentRepository = paymentRepository;
        this.orderPaymentService = orderPaymentService;
        this.reservationLifecycleService = reservationLifecycleService;
    }

    @Override
    protected EPaymentMethod getMethod() {
        return EPaymentMethod.PAYOS;
    }

    @Override
    protected EPaymentStatus getInitialStatus() {
        return EPaymentStatus.PENDING;
    }

    @Override
    protected String doCreatePayment(PreparedPayment prepared) {
        Payment payment = prepared.payment();
        if (payment.getCheckoutUrl() != null) return payment.getCheckoutUrl();
        BigDecimal amountToPay = prepared.amount();
        String description = prepared.description();

        log.info("Processing create payment link for code {} ", payment.getCode());

        PaymentLinkItem item = PaymentLinkItem.builder()
                .name("CrownDine Restaurant")
                .quantity(1)
                .price(amountToPay.longValue())
                .build();

        CreatePaymentLinkRequest paymentData = CreatePaymentLinkRequest.builder()
                .orderCode(payment.getCode())
                .amount(amountToPay.longValue())
                .description(description)
                .returnUrl(payOSConfig.getReturnPaymentSuccessUrl())
                .cancelUrl(payOSConfig.getReturnPaymentCancelUrl())
                .item(item)
                .build();

        try {
            CreatePaymentLinkResponse data = payOS.paymentRequests().create(paymentData);
            payment.setCheckoutUrl(data.getCheckoutUrl());
            paymentRepository.updateCheckoutUrl(payment.getId(), data.getCheckoutUrl());
            log.info("Created payment link successfully");
            return data.getCheckoutUrl();
        } catch (Exception ex) {
            // Recover the same code after a lost create response; never allocate another intent.
            try {
                var existing = payOS.paymentRequests().get(payment.getCode());
                if (payment.getCode().equals(existing.getOrderCode()) && existing.getId() != null
                        && existing.getId().matches("[A-Za-z0-9_-]+")
                        && existing.getAmount() != null && payment.getAmount().compareTo(BigDecimal.valueOf(existing.getAmount())) == 0) {
                    String recoveredUrl = "https://pay.payos.vn/web/" + existing.getId();
                    payment.setCheckoutUrl(recoveredUrl);
                    paymentRepository.updateCheckoutUrl(payment.getId(), recoveredUrl);
                    return recoveredUrl;
                }
            } catch (Exception lookupError) {
                log.warn("Cannot recover pending PayOS link {} yet", payment.getCode());
            }
            // Keep the committed intent/code: a timeout may have created a real link.
            log.error("Payment link could not be created, message={}", ex.getMessage(), ex);
            throw new InvalidDataException("Cannot create PayOS payment link", ex);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void handleWebHook(Map<String, Object> body) {
        WebhookData data = payOS.webhooks().verify(body);
        Long orderCode = data.getOrderCode();
        log.info("Processing PAYOS webhook for orderCode: {}", orderCode);
        try {
            Payment payment = paymentRepository.findByCodeForUpdate(orderCode).orElseThrow(() -> new ResourceNotFoundException("Payment not found"));
            if (!"00".equals(data.getCode()) || data.getAmount() == null
                    || payment.getAmount().compareTo(BigDecimal.valueOf(data.getAmount())) != 0
                    || payment.getMethod() != EPaymentMethod.PAYOS) {
                throw new InvalidDataException("Webhook không khớp giao dịch thành công/số tiền/phương thức");
            }
            if (payment.getStatus() == EPaymentStatus.SUCCESS || payment.getStatus() == EPaymentStatus.REFUNDED) {
                log.info("Payment code {} already marked as success, skipping duplicate webhook", orderCode);
                return;
            }

            payment.setStatus(EPaymentStatus.SUCCESS);
            payment.setTransactionCode(data.getReference());
            String rawApiData = data.toString().replace("WebhookData(", "").replace(")", "");
            payment.setRawApiData(rawApiData);
            paymentRepository.save(payment);

            handlePaymentSuccess(payment);
            log.info("Payment id {} saved with status={}", payment.getId(), payment.getStatus());
        } catch (Exception e) {
            log.error("Error while handling PayOS webhook: {}", e.getMessage(), e);
            throw e;
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public Payment reconcile(Long code) {
        Payment payment = paymentRepository.findByCodeForUpdate(code).orElseThrow(() -> new ResourceNotFoundException("Payment not found"));
        if (payment.getMethod() != EPaymentMethod.PAYOS || payment.getStatus() != EPaymentStatus.PENDING) return payment;
        vn.payos.model.v2.paymentRequests.PaymentLink link;
        try { link = payOS.paymentRequests().get(code); }
        catch (Exception networkError) { return payment; }
        if (!code.equals(link.getOrderCode()) || link.getAmount() == null
                || payment.getAmount().compareTo(BigDecimal.valueOf(link.getAmount())) != 0) {
            throw new InvalidDataException("PayOS trả về giao dịch không khớp");
        }
        if (link.getStatus() == vn.payos.model.v2.paymentRequests.PaymentLinkStatus.CANCELLED) {
            payment.setStatus(EPaymentStatus.FAILED);
        } else if (link.getStatus() == vn.payos.model.v2.paymentRequests.PaymentLinkStatus.PAID
                && link.getAmountPaid() != null && link.getAmountPaid() >= payment.getAmount().longValueExact()) {
            payment.setStatus(EPaymentStatus.SUCCESS);
            handlePaymentSuccess(payment);
        }
        return paymentRepository.save(payment);
    }

    private void handlePaymentSuccess(Payment payment) {
        if (payment.getTarget() == EPaymentTarget.RESERVATION) {
            handleReservationPaymentSuccess(payment);
            return;
        }

        if (payment.getTarget() == EPaymentTarget.ORDER) {
            handleOrderPaymentSuccess(payment);
            return;
        }

        throw new InvalidDataException("Unsupported payment target for PayOS webhook");
    }

    private void handleReservationPaymentSuccess(Payment payment) {
        if (payment.getReservation() == null) {
            throw new InvalidDataException("Payment reservation not found");
        }
        reservationLifecycleService.confirmAfterDepositPaid(payment.getReservation());
    }

    private void handleOrderPaymentSuccess(Payment payment) {
        if (payment.getOrder() == null) {
            throw new InvalidDataException("Payment order not found");
        }
        orderPaymentService.markOrderAsPaid(payment.getOrder());
    }
}
