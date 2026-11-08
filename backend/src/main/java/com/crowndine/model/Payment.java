package com.crowndine.model;

import com.crowndine.common.enums.*;
import com.crowndine.model.converter.PaymentEnumConverters;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "payments")
public class Payment extends AbstractEntity<Long> {

    @Column(name = "code", unique = true, nullable = false)
    private Long code;

    @Column(name = "amount")
    private BigDecimal amount;

    @Column(name = "transaction_code")
    private String transactionCode;

    @Column(name = "raw_api_data", columnDefinition = "TEXT")
    private String rawApiData; //webhook callback

    @Enumerated(EnumType.STRING)
    @Column(name = "method")
    private EPaymentMethod method;

    @Convert(converter = PaymentEnumConverters.Status.class)
    @org.hibernate.annotations.JdbcTypeCode(java.sql.Types.CHAR)
    @Column(name = "status")
    private EPaymentStatus status;

    @Convert(converter = PaymentEnumConverters.Type.class)
    @org.hibernate.annotations.JdbcTypeCode(java.sql.Types.CHAR)
    @Column(name = "type")
    private EPaymentType type;

    @Convert(converter = PaymentEnumConverters.Target.class)
    @org.hibernate.annotations.JdbcTypeCode(java.sql.Types.CHAR)
    @Column(name = "target")
    private EPaymentTarget target;

    @Convert(converter = PaymentEnumConverters.Source.class)
    @org.hibernate.annotations.JdbcTypeCode(java.sql.Types.CHAR)
    @Column(name = "source")
    private EPaymentSource source;

    @ManyToOne
    @JoinColumn(name = "reservation_id")
    private Reservation reservation;

    @ManyToOne
    @JoinColumn(name = "order_id")
    private Order order;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // Payment metadata shares the existing raw_api_data TEXT column. No schema change.
    private static final ObjectMapper JSON = new ObjectMapper()
            .enable(com.fasterxml.jackson.databind.DeserializationFeature.USE_BIG_DECIMAL_FOR_FLOATS);
    private static final String METADATA = "crowndinePayment";

    @Transient
    public BigDecimal getTableDepositAmount() {
        JsonNode value = document().path(METADATA).path("tableDepositAmount");
        return value.isNumber() ? value.decimalValue() : null;
    }

    public void setTableDepositAmount(BigDecimal amount) {
        ObjectNode document = document();
        metadata(document).put("tableDepositAmount", amount);
        rawApiData = document.toString();
    }

    @Transient
    public String getCheckoutUrl() {
        JsonNode value = document().path(METADATA).path("checkoutUrl");
        return value.isTextual() ? value.textValue() : null;
    }

    public void setCheckoutUrl(String url) {
        ObjectNode document = document();
        metadata(document).put("checkoutUrl", url);
        rawApiData = document.toString();
    }

    public void setRawApiData(String gatewayData) {
        ObjectNode existing = document();
        if (existing.path(METADATA).isObject()) {
            existing.put("gateway", gatewayData);
            rawApiData = existing.toString();
        } else {
            rawApiData = gatewayData;
        }
    }

    // The existing SQL type PAYMENT is distinguished by its reservation/order target.
    public EPaymentType getType() {
        if (type == null || type == EPaymentType.REFUND) return type;
        return target == EPaymentTarget.ORDER ? EPaymentType.SETTLEMENT : EPaymentType.DEPOSIT;
    }

    private ObjectNode document() {
        if (rawApiData != null) {
            try {
                JsonNode parsed = JSON.readTree(rawApiData);
                if (parsed != null && parsed.isObject()) return (ObjectNode) parsed;
            } catch (Exception ignored) { /* Historical webhook text is preserved below. */ }
        }
        ObjectNode result = JSON.createObjectNode();
        if (rawApiData != null) result.put("gateway", rawApiData);
        return result;
    }

    private ObjectNode metadata(ObjectNode document) {
        if (document.path(METADATA).isObject()) return (ObjectNode) document.get(METADATA);
        return document.putObject(METADATA);
    }
}
