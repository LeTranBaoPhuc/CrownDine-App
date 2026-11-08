package com.crowndine.dto.request;

import com.crowndine.common.enums.ETableShape;
import com.crowndine.common.enums.ETableStatus;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
public class TableRequest {

    @jakarta.validation.constraints.NotBlank
    private String name;
    @jakarta.validation.constraints.NotNull
    @jakarta.validation.constraints.Min(1)
    private Integer capacity;
    private ETableShape shape;
    private ETableStatus status; // optional

    @jakarta.validation.constraints.DecimalMin("0.0")
    private BigDecimal deposit;
    private Integer width;
    private Integer height;
    private Integer x;
    private Integer y;
    private Integer rotation;

    private String imageUrl;
    private String description;
}
