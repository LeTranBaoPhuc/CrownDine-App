package com.crowndine.model.converter;

import com.crowndine.common.enums.*;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

/** Preserve the existing payment SQL enum values while keeping API vocabulary stable. */
public final class PaymentEnumConverters {
    private PaymentEnumConverters() {}

    @Converter
    public static class Status implements AttributeConverter<EPaymentStatus, String> {
        public String convertToDatabaseColumn(EPaymentStatus value) {
            return value == null ? null : value == EPaymentStatus.SUCCESS ? "PAID" : value.name();
        }
        public EPaymentStatus convertToEntityAttribute(String value) {
            return value == null ? null : "PAID".equals(value) ? EPaymentStatus.SUCCESS : EPaymentStatus.valueOf(value);
        }
    }

    @Converter
    public static class Target implements AttributeConverter<EPaymentTarget, String> {
        public String convertToDatabaseColumn(EPaymentTarget value) {
            return value == null ? null : value == EPaymentTarget.RESERVATION ? "RESERVATION_DEPOSIT" : "BILL_SETTLEMENT";
        }
        public EPaymentTarget convertToEntityAttribute(String value) {
            if (value == null) return null;
            return switch (value) {
                case "RESERVATION_DEPOSIT", "RESERVATION" -> EPaymentTarget.RESERVATION;
                case "BILL_SETTLEMENT", "ORDER" -> EPaymentTarget.ORDER;
                default -> throw new IllegalArgumentException("Unknown payment target: " + value);
            };
        }
    }

    @Converter
    public static class Type implements AttributeConverter<EPaymentType, String> {
        public String convertToDatabaseColumn(EPaymentType value) {
            return value == null ? null : value == EPaymentType.REFUND ? "REFUND" : "PAYMENT";
        }
        public EPaymentType convertToEntityAttribute(String value) {
            return value == null ? null : "PAYMENT".equals(value) ? EPaymentType.DEPOSIT : EPaymentType.valueOf(value);
        }
    }

    @Converter
    public static class Source implements AttributeConverter<EPaymentSource, String> {
        public String convertToDatabaseColumn(EPaymentSource value) {
            if (value == null) return null;
            return switch (value) {
                case CLIENT_APP -> "CUSTOMER_ONLINE";
                case POS_COUNTER -> "CASHIER";
                case STAFF_MOBILE -> "STAFF_MOBILE";
            };
        }
        public EPaymentSource convertToEntityAttribute(String value) {
            if (value == null) return null;
            return switch (value) {
                case "CUSTOMER_ONLINE", "CLIENT_APP" -> EPaymentSource.CLIENT_APP;
                case "CASHIER", "POS_COUNTER" -> EPaymentSource.POS_COUNTER;
                case "STAFF_MOBILE" -> EPaymentSource.STAFF_MOBILE;
                default -> throw new IllegalArgumentException("Unknown payment source: " + value);
            };
        }
    }
}
