package com.crowndine.service.payment;

import com.crowndine.common.enums.*;
import com.crowndine.model.Payment;
import com.crowndine.model.converter.PaymentEnumConverters;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import static org.junit.jupiter.api.Assertions.*;

class PaymentSchemaCompatibilityTest {
    @Test void snapshotAndCheckoutLinkSurviveReloadAndWebhookWithoutNewColumns() {
        Payment payment = new Payment();
        payment.setRawApiData("legacy gateway data");
        BigDecimal deposit = new BigDecimal("9007199254740993.01");
        payment.setTableDepositAmount(deposit);
        payment.setCheckoutUrl("https://pay.payos.vn/web/pending");
        Payment reloaded = new Payment();
        reloaded.setRawApiData(payment.getRawApiData());
        assertEquals(0, deposit.compareTo(reloaded.getTableDepositAmount()));
        assertTrue(reloaded.getRawApiData().contains("legacy gateway data"));
        reloaded.setRawApiData("verified webhook payload");
        Payment afterWebhook = new Payment();
        afterWebhook.setRawApiData(reloaded.getRawApiData());
        assertEquals(0, deposit.compareTo(afterWebhook.getTableDepositAmount()));
        assertEquals(payment.getCheckoutUrl(), afterWebhook.getCheckoutUrl());
        assertTrue(afterWebhook.getRawApiData().contains("verified webhook payload"));
    }

    @Test void oldWebhookTextDoesNotInventHistoricalDepositSnapshots() {
        Payment payment = new Payment();
        payment.setRawApiData("WebhookData(reference=old)");
        assertNull(payment.getTableDepositAmount());
        assertNull(payment.getCheckoutUrl());
        payment.setCheckoutUrl("https://pay.payos.vn/web/recovered");
        assertNull(payment.getTableDepositAmount());
        assertTrue(payment.getRawApiData().contains("WebhookData(reference=old)"));
    }

    @Test void existingSqlEnumValuesRetainTheirMeaningAndApiNames() {
        var status = new PaymentEnumConverters.Status();
        assertEquals("PAID", status.convertToDatabaseColumn(EPaymentStatus.SUCCESS));
        assertEquals(EPaymentStatus.SUCCESS, status.convertToEntityAttribute("PAID"));
        for (String value : new String[]{"PENDING", "FAILED", "CANCELLED", "EXPIRED", "REFUNDED"}) {
            assertEquals(value, status.convertToDatabaseColumn(status.convertToEntityAttribute(value)));
        }
        var target = new PaymentEnumConverters.Target();
        assertEquals("RESERVATION_DEPOSIT", target.convertToDatabaseColumn(EPaymentTarget.RESERVATION));
        assertEquals("BILL_SETTLEMENT", target.convertToDatabaseColumn(EPaymentTarget.ORDER));
        var source = new PaymentEnumConverters.Source();
        for (String value : new String[]{"CUSTOMER_ONLINE", "CASHIER", "STAFF_MOBILE"}) {
            assertEquals(value, source.convertToDatabaseColumn(source.convertToEntityAttribute(value)));
        }
        var type = new PaymentEnumConverters.Type();
        Payment payment = new Payment();
        payment.setType(type.convertToEntityAttribute("PAYMENT"));
        payment.setTarget(EPaymentTarget.RESERVATION);
        assertEquals(EPaymentType.DEPOSIT, payment.getType());
        payment.setTarget(EPaymentTarget.ORDER);
        assertEquals(EPaymentType.SETTLEMENT, payment.getType());
        assertEquals("PAYMENT", type.convertToDatabaseColumn(payment.getType()));
        payment.setType(EPaymentType.REFUND);
        assertEquals("REFUND", type.convertToDatabaseColumn(payment.getType()));
    }
}
