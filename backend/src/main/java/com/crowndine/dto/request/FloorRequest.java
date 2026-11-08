package com.crowndine.dto.request;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class FloorRequest {

    @jakarta.validation.constraints.NotBlank
    private String name;
    private Integer floorNumber;
    private String description;
}
