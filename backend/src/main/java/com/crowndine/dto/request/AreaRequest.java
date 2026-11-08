package com.crowndine.dto.request;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class AreaRequest {

    @jakarta.validation.constraints.NotBlank
    private String name;
    private String description;
}
