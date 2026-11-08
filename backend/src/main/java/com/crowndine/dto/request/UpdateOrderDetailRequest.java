package com.crowndine.dto.request;

import com.crowndine.common.enums.EOrderDetailStatus;
import jakarta.validation.constraints.Min;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateOrderDetailRequest {

    @Min(1)
    private Integer quantity;

    private String note;

    private EOrderDetailStatus status;
}
