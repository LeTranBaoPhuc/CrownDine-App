package com.crowndine.dto.request;

import com.crowndine.common.enums.EAttendanceType;
import com.crowndine.common.utils.FlexibleLocalDateDeserializer;
import com.crowndine.common.utils.FlexibleLocalDateTimeDeserializer;
import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@Setter
public class AttendanceRecordRequest {

    @NotNull(message = "Nhân viên không được để trống")
    private Long userId;

    @NotNull(message = "Ngày không được để trống")
    @JsonDeserialize(using = FlexibleLocalDateDeserializer.class)
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate workDate;

    @NotNull(message = "Ca làm việc không được để trống")
    private Long shiftId;

    private String note;

    @NotNull(message = "Hình thức không được để trống")
    private EAttendanceType attendanceType;

    private Boolean hasPunchIn = false;

    private Boolean hasPunchOut = false;

    @JsonDeserialize(using = FlexibleLocalDateTimeDeserializer.class)
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime checkInAt;

    @JsonDeserialize(using = FlexibleLocalDateTimeDeserializer.class)
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime checkOutAt;
}
