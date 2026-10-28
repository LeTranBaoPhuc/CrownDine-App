package com.crowndine.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@Setter
@Builder
public class FavoriteResponse {
    private Long id;
    private Long itemId;
    private String itemName;
    private String itemImageUrl;
    private BigDecimal itemPrice;
    private Long comboId;
    private String comboName;
    private String comboImageUrl;
    private BigDecimal comboPrice;
    private LocalDateTime createdAt;
}
