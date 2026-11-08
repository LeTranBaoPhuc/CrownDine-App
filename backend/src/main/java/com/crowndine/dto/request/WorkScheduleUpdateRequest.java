package com.crowndine.dto.request;

import com.crowndine.common.utils.FlexibleLocalDateDeserializer;
import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import lombok.Getter;

import java.time.LocalDate;

@Getter
public class WorkScheduleUpdateRequest {
    private Long staffId;
    private Long shiftId;

    @JsonDeserialize(using = FlexibleLocalDateDeserializer.class)
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate workDate;
}
