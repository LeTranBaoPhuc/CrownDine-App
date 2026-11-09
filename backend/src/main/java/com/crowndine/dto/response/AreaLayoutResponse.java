package com.crowndine.dto.response;

import lombok.Getter;
import lombok.Setter;
import java.util.List;

@Getter
@Setter
public class AreaLayoutResponse {

    private Long areaId;
    private String areaName;
    private String description;
    private Double x;
    private Double y;
    private Double width;
    private Double height;
    private List<TableLayoutResponse> tables;
}
