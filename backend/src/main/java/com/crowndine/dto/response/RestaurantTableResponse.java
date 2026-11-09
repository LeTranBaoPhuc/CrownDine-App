package com.crowndine.dto.response;

import com.crowndine.common.enums.ETableShape;
import com.crowndine.common.enums.ETableStatus;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;

@Getter
@Setter
public class RestaurantTableResponse {

    private Long id;

    private String name;

    private ETableStatus status;

    private Integer capacity;

    private ETableShape shape;

    private String imageUrl;

    private String description;

    private Long areaId;
    private String areaName;
    private Long floorId;
    private String floorName;
    private BigDecimal deposit;
    private Integer x;
    private Integer y;
    private Integer width;
    private Integer height;
    private Integer rotation;
}
