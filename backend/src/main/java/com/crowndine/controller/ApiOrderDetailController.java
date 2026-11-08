package com.crowndine.controller;

import com.crowndine.common.enums.EOrderDetailStatus;
import com.crowndine.dto.request.UpdateOrderDetailRequest;
import com.crowndine.dto.response.ApiResponse;
import com.crowndine.exception.InvalidDataException;
import com.crowndine.service.order.OrderDetailService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequiredArgsConstructor
@Validated
@RequestMapping("/api/order-details")
@Slf4j(topic = "API-ORDER-DETAIL-CONTROLLER")
public class ApiOrderDetailController {

    private final OrderDetailService orderDetailService;

    @PreAuthorize("hasAnyAuthority('STAFF', 'ADMIN')")
    @PatchMapping("/{id}/upd")
    public ApiResponse updateOrderDetail(@Min(1) @PathVariable Long id, @Valid @RequestBody UpdateOrderDetailRequest request) {
        orderDetailService.updateOrderDetail(id, request);
        return ApiResponse.builder()
                .status(HttpStatus.ACCEPTED.value())
                .message("Order Details updated successfully")
                .build();
    }

    @PreAuthorize("hasAnyAuthority('STAFF', 'ADMIN')")
    @PatchMapping("/{id}/status")
    public ApiResponse updateOrderDetailStatus(
            @Min(1) @PathVariable Long id,
            @RequestParam(required = false) EOrderDetailStatus status,
            @RequestBody(required = false) Map<String, Object> body) {
        if (status == null && body != null && body.containsKey("status")) {
            String raw = String.valueOf(body.get("status"));
            status = EOrderDetailStatus.valueOf(raw.trim().toUpperCase());
        }
        if (status == null) {
            throw new InvalidDataException("Trạng thái món không được để trống");
        }
        return ApiResponse.builder()
                .status(HttpStatus.ACCEPTED.value())
                .message("Cập nhật trạng thái món thành công")
                .data(orderDetailService.changeStatus(id, status))
                .build();
    }

    @PreAuthorize("hasAnyAuthority('STAFF', 'ADMIN')")
    @DeleteMapping("/{id}/del")
    public ApiResponse deleteOrderDetail(@Min(1) @PathVariable Long id) {
        orderDetailService.deleteOrderDetail(id);
        return ApiResponse.builder()
                .status(HttpStatus.ACCEPTED.value())
                .message("deleted")
                .build();
    }
}
