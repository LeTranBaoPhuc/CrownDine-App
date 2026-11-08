package com.crowndine.common.utils;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;

import java.io.IOException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;

public class FlexibleLocalDateTimeDeserializer extends JsonDeserializer<LocalDateTime> {

    private static final DateTimeFormatter[] FORMATTERS = new DateTimeFormatter[]{
            DateTimeFormatter.ISO_LOCAL_DATE_TIME,            // 2026-11-08T15:30:00
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"),
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"),
            DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss"),
            DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"),
            DateTimeFormatter.ofPattern("dd-MM-yyyy HH:mm:ss"),
            DateTimeFormatter.ofPattern("dd-MM-yyyy HH:mm")
    };

    private static final DateTimeFormatter[] TIME_FORMATTERS = new DateTimeFormatter[]{
            DateTimeFormatter.ofPattern("HH:mm:ss"),
            DateTimeFormatter.ofPattern("HH:mm")
    };

    @Override
    public LocalDateTime deserialize(JsonParser p, DeserializationContext ctxt) throws IOException {
        String text = p.getText();
        if (text == null || text.trim().isEmpty()) {
            return null;
        }
        text = text.trim();

        // 1. Try full date-time patterns
        for (DateTimeFormatter formatter : FORMATTERS) {
            try {
                return LocalDateTime.parse(text, formatter);
            } catch (DateTimeParseException ignored) {
            }
        }

        // 2. If only time provided (e.g. "08:00" or "08:00:00"), combine with today's date
        for (DateTimeFormatter timeFormatter : TIME_FORMATTERS) {
            try {
                LocalTime time = LocalTime.parse(text, timeFormatter);
                return LocalDateTime.of(LocalDate.now(), time);
            } catch (DateTimeParseException ignored) {
            }
        }

        return (LocalDateTime) ctxt.handleWeirdStringValue(LocalDateTime.class, text, "Không thể chuyển đổi chuỗi sang LocalDateTime: " + text);
    }
}
