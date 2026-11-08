package com.crowndine.controller;

import com.crowndine.common.enums.ETableStatus;
import com.crowndine.dto.request.TableOrderItemsRequest;
import com.crowndine.service.impl.order.TableOrderService;
import com.crowndine.service.layout.RestaurantTableService;
import com.crowndine.service.order.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.*;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

@SpringJUnitConfig(TableServingAuthorizationTest.Config.class)
class TableServingAuthorizationTest {
    @Configuration @EnableMethodSecurity static class Config {
        @Bean TableOrderService tableOrders() { return mock(TableOrderService.class); }
        @Bean RestaurantTableService tables() { return mock(RestaurantTableService.class); }
        @Bean ApiOrderController orders(TableOrderService tables) {
            return new ApiOrderController(mock(OrderService.class), mock(OrderStatusService.class),
                    mock(OrderVoucherService.class), tables);
        }
        @Bean ApiRestaurantTableController tableController(RestaurantTableService tables) {
            return new ApiRestaurantTableController(tables);
        }
    }
    @Autowired ApiOrderController orders;
    @Autowired ApiRestaurantTableController tables;

    @Test @WithMockUser(authorities = "CUSTOMER") void customerCannotReadOrWriteStaffTableOrders() {
        assertThrows(AccessDeniedException.class, () -> orders.getActiveTableOrder(7L));
        assertThrows(AccessDeniedException.class, () -> orders.addTableItems(7L, new TableOrderItemsRequest(), () -> "customer"));
        assertThrows(AccessDeniedException.class, () -> tables.updateStatusTable(7L, ETableStatus.AVAILABLE));
    }
    @Test @WithMockUser(authorities = "STAFF") void staffCanUseServingEndpoints() {
        orders.getActiveTableOrder(7L);
        orders.addTableItems(7L, new TableOrderItemsRequest(), () -> "staff");
        tables.updateStatusTable(7L, ETableStatus.RESERVED);
    }
    @Test @WithMockUser(authorities = "ADMIN") void adminCanManageTables() {
        tables.updateStatusTable(7L, ETableStatus.UNAVAILABLE);
    }
}
