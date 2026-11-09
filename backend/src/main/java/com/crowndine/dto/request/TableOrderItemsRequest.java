package com.crowndine.dto.request;

import jakarta.validation.constraints.Min;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class TableOrderItemsRequest extends OrderItemBatchRequest {
    // Null means the client saw no active order. Reject a changed table session.
    @Min(1)
    private Long expectedOrderId;
}
