package com.crowndine.dto.request;

import com.crowndine.common.utils.FlexibleLocalDateDeserializer;
import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.List;

@Getter
public class WorkScheduleCreateRequest {

    @NotNull(message = "Ca làm vệc không được để trống")
    private Long shiftId;

    @NotNull(message = "Thời gian làm việc không được để trống")
    @JsonDeserialize(using = FlexibleLocalDateDeserializer.class)
    @JsonFormat(pattern = "yyyy-MM-dd")
    @FutureOrPresent(message = "Thời gian làm việc phải là hôm nay hoặc mai")
    private LocalDate workDate;

    @NotNull
    private List<Long> staffIds;

    private Boolean repeatWeekly;
    private List<Integer> daysOfWeek;

    @JsonDeserialize(using = FlexibleLocalDateDeserializer.class)
    @JsonFormat(pattern = "yyyy-MM-dd")
    @FutureOrPresent(message = "Ngày kết thúc phải là hôm nay hoặc tương lai")
    private LocalDate endDate;
}
