package com.crowndine.config;

import com.crowndine.security.*;
import com.crowndine.service.auth.JwtService;
import com.crowndine.repository.TokenRepository;
import com.crowndine.common.i18n.MessageService;
import jakarta.persistence.EntityManagerFactory;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.*;
import org.springframework.test.context.junit.jupiter.web.SpringJUnitWebConfig;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;
import org.springframework.test.web.servlet.*;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringJUnitWebConfig({AppConfig.class, PreFilter.class, CustomAuthenticationEntryPoint.class, CustomAccessDeniedHandler.class, HttpAuthorizationTest.Config.class})
class HttpAuthorizationTest {
    @Configuration @EnableWebMvc static class Config {
        @Bean CustomUserDetailsService users() { return mock(CustomUserDetailsService.class); }
        @Bean JwtService jwt() { return mock(JwtService.class); }
        @Bean TokenRepository tokens() { return mock(TokenRepository.class); }
        @Bean MessageService messages() { return mock(MessageService.class); }
        @Bean EntityManagerFactory emf() { return mock(EntityManagerFactory.class); }
        @Bean Endpoints endpoints() { return new Endpoints(); }
    }
    @RestController static class Endpoints {
        @RequestMapping({"/api/orders", "/api/orders/1/status", "/api/reservations/all", "/api/ai/admin-chat", "/api/vouchers/validate", "/api/vouchers/1/exchange", "/api/user-vouchers/my", "/api/shifts", "/actuator/env"})
        public String endpoint() { return "ok"; }
    }
    @Autowired WebApplicationContext context;
    MockMvc mvc;
    @BeforeEach void setup() { mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build(); }
    @Test void anonymousCannotUsePrivateEndpoints() throws Exception {
        mvc.perform(get("/api/orders")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/ai/admin-chat")).andExpect(status().isUnauthorized());
    }
    @Test void customerCannotReadGlobalOrdersOrReservationsOrChangeServingAndShifts() throws Exception {
        for (String path : new String[]{"/api/orders", "/api/reservations/all", "/actuator/env"}) mvc.perform(get(path).with(user("alice").authorities(() -> "USER"))).andExpect(status().isForbidden());
        mvc.perform(patch("/api/orders/1/status").with(user("alice").authorities(() -> "USER"))).andExpect(status().isForbidden());
        mvc.perform(post("/api/shifts").with(user("staff").authorities(() -> "STAFF"))).andExpect(status().isForbidden());
        mvc.perform(post("/api/ai/admin-chat").with(user("alice").authorities(() -> "USER"))).andExpect(status().isForbidden());
    }
    @Test void customersCanUseTheirVoucherWalletAndCheckoutValidation() throws Exception {
        mvc.perform(get("/api/user-vouchers/my").with(user("alice").authorities(() -> "USER"))).andExpect(status().isOk());
        mvc.perform(post("/api/vouchers/validate").with(user("alice").authorities(() -> "USER"))).andExpect(status().isOk());
        mvc.perform(post("/api/vouchers/1/exchange").with(user("alice").authorities(() -> "USER"))).andExpect(status().isOk());
        mvc.perform(get("/api/orders").with(user("staff").authorities(() -> "STAFF"))).andExpect(status().isOk());
    }
}
