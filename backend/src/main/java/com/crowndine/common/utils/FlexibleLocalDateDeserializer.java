package com.crowndine.common.utils;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;

public class FlexibleLocalDateDeserializer extends JsonDeserializer<LocalDate> {

    private static final DateTimeFormatter[] FORMATTERS = new DateTimeFormatter[]{
            DateTimeFormatter.ISO_LOCAL_DATE,          // yyyy-MM-dd
            DateTimeFormatter.ofPattern("dd-MM-yyyy"), // dd-MM-yyyy
            DateTimeFormatter.ofPattern("dd/MM/yyyy"), // dd/MM/yyyy
            DateTimeFormatter.ofPattern("yyyy/MM/dd")  // yyyy/MM/dd
    };

    @Override
    public LocalDate deserialize(JsonParser p, DeserializationContext ctxt) throws IOException {
        String text = p.getText();
        if (text == null || text.trim().isEmpty()) {
            return null;
        }
        text = text.trim();
        for (DateTimeFormatter formatter : FORMATTERS) {
            try {
                return LocalDate.parse(text, formatter);
            } catch (DateTimeParseException ignored) {
            }
        }
        if (text.length() >= 10) {
            String dateSub = text.substring(0, 10);
            for (DateTimeFormatter formatter : FORMATTERS) {
                try {
                    return LocalDate.parse(dateSub, formatter);
                } catch (DateTimeParseException ignored) {
                }
            }
        }
        return (LocalDate) ctxt.handleWeirdStringValue(LocalDate.class, text, "Không thể chuyển đổi chuỗi sang LocalDate: " + text);
    }
}
