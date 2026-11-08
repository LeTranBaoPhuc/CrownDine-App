package com.crowndine.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.AssertTrue;
import lombok.Getter;

@Getter
public class OrderItemRequest {
    @Min(1)
    private Long itemId;
    @Min(1)
    private Long comboId;

    @NotNull(message = "Số lượng không được để trống")
    @Min(1)
    private Integer quantity;

    private String note;

    @AssertTrue(message = "Chọn đúng một món ăn hoặc combo")
    public boolean isExactlyOneProduct() {
        return (itemId == null) != (comboId == null);
    }
}
