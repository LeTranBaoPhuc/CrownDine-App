package com.crowndine.service.chat;

import com.crowndine.dto.response.TableLayoutResponse;
import com.crowndine.exception.AiServiceException;
import com.crowndine.model.ChatMessage;
import com.crowndine.service.layout.RestaurantTableService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.util.UriComponentsBuilder;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.time.format.ResolverStyle;
import java.util.*;
import java.util.regex.*;
import java.util.stream.Collectors;

/** Uses the reservation service as the source of truth, including schedule conflicts. */
@Service
@RequiredArgsConstructor
public class ChatBookingSupport {
    private final RestaurantTableService tables;
    private static final Pattern ISO_DATE = Pattern.compile("\\b(\\d{4}-\\d{2}-\\d{2})\\b");
    private static final Pattern LOCAL_DATE = Pattern.compile("\\b(\\d{1,2}/\\d{1,2}/\\d{4})\\b");
    private static final Pattern TIME = Pattern.compile("(?<!\\d)(\\d{1,2})[:h](\\d{2})?(?!\\d)");
    private static final Pattern GUESTS = Pattern.compile("(?<!\\d)(\\d{1,3})\\s*(người|khách|nguoi|khach)", Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);
    private static final Pattern LINK = Pattern.compile("/reservation\\?[^\\r\\n]+");

    public String contextFor(List<ChatMessage> messages) {
        LocalDate date = null;
        LocalTime time = null;
        Integer guests = null;
        for (ChatMessage message : messages) {
            if (!"user".equals(message.getRole()) || message.getContent() == null) continue;
            String text = message.getContent().toLowerCase(Locale.ROOT);
            Matcher iso = ISO_DATE.matcher(text), local = LOCAL_DATE.matcher(text);
            try {
                if (iso.find()) date = LocalDate.parse(iso.group(1));
                else if (local.find()) date = LocalDate.parse(local.group(1), DateTimeFormatter.ofPattern("d/M/uuuu").withResolverStyle(ResolverStyle.STRICT));
                else if (text.contains("ngày mốt") || text.contains("ngày kia") || text.contains("ngay mot")) date = LocalDate.now().plusDays(2);
                else if (text.contains("ngày mai") || text.contains("ngay mai") || text.contains("tối mai") || text.contains("sáng mai") || text.contains("chiều mai")) date = LocalDate.now().plusDays(1);
                else if (text.contains("hôm nay") || text.contains("hom nay") || text.contains("tối nay")) date = LocalDate.now();
            } catch (DateTimeException invalid) { date = null; }
            Matcher hours = TIME.matcher(text);
            if (hours.find()) {
                try { time = LocalTime.of(Integer.parseInt(hours.group(1)), hours.group(2) == null ? 0 : Integer.parseInt(hours.group(2))); }
                catch (DateTimeException invalid) { time = null; }
            }
            Matcher people = GUESTS.matcher(text);
            if (people.find()) guests = Integer.parseInt(people.group(1));
        }
        if (date == null || time == null || guests == null || guests < 1) {
            return "CHƯA KIỂM TRA BÀN TRỐNG: thiếu ngày YYYY-MM-DD, giờ HH:mm hoặc số khách. Hỏi rõ thông tin còn thiếu; không báo bàn trống.";
        }
        try {
            List<TableLayoutResponse> available = tables.getTablesForReservation(date, time, guests);
            return "KẾT QUẢ KIỂM TRA MỚI NHẤT: " + date + " lúc " + time + ", " + guests + " khách. "
                    + (available.isEmpty() ? "Không còn bàn phù hợp. Hỏi khách chọn khung giờ khác."
                    : available.stream().map(t -> t.getName() + " (" + t.getCapacity() + " chỗ, " + t.getFloorName() + ", " + t.getAreaName() + ")").collect(Collectors.joining("; ")));
        } catch (RuntimeException error) {
            return "KHÔNG THỂ XÁC NHẬN KHUNG GIỜ: " + date + " " + time + ". Yêu cầu ngày/giờ hợp lệ từ 10:00 đến trước 22:00 và thử lại. Không báo còn bàn.";
        }
    }

    public String validateLinks(String response) {
        Matcher links = LINK.matcher(response);
        StringBuffer result = new StringBuffer();
        while (links.find()) {
            String query = links.group().substring("/reservation?".length()).replaceAll("[\\\"'<>).,]+$", "").trim();
            try {
                Map<String, String> params = new HashMap<>();
                for (String pair : query.split("&")) {
                    String[] parts = pair.split("=", 2);
                    if (parts.length != 2 || params.put(parts[0], URLDecoder.decode(parts[1], StandardCharsets.UTF_8)) != null) throw new IllegalArgumentException();
                }
                int step = Integer.parseInt(params.get("step")), guests = Integer.parseInt(params.get("guests"));
                if ((step != 3 && step != 4) || guests < 1 || guests > 999
                        || !params.getOrDefault("startTime", "").matches("\\d{2}:\\d{2}")) throw new IllegalArgumentException();
                LocalDate date = LocalDate.parse(params.get("date"));
                LocalTime time = LocalTime.parse(params.get("startTime"));
                String name = normalName(params.get("tableName"));
                var matches = tables.getTablesForReservation(date, time, guests).stream()
                        .filter(t -> normalName(t.getName()).equals(name)).toList();
                if (name.isBlank() || matches.size() != 1) throw new IllegalArgumentException();
                String canonical = UriComponentsBuilder.fromPath("/reservation").queryParam("step", step)
                        .queryParam("tableName", matches.getFirst().getName()).queryParam("date", date)
                        .queryParam("startTime", time).queryParam("guests", guests).build().encode().toUriString();
                links.appendReplacement(result, Matcher.quoteReplacement(canonical));
            } catch (RuntimeException invalid) {
                throw new AiServiceException("Không xác nhận được bàn tại khung giờ yêu cầu. Vui lòng chọn lại bàn.");
            }
        }
        links.appendTail(result);
        return result.toString();
    }

    private String normalName(String name) {
        return name == null ? "" : name.trim().toLowerCase(Locale.ROOT).replaceFirst("^b[aà]n\\s+", "");
    }
}
