package com.crowndine.config;
import com.crowndine.ai.controller.ApiAIChatBotController;
import com.crowndine.ai.service.AIAdminChatService;
import com.crowndine.security.*;
import com.crowndine.repository.TokenRepository;
import com.crowndine.service.auth.JwtService;
import com.crowndine.common.i18n.MessageService;
import jakarta.persistence.EntityManagerFactory;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.*;
import org.springframework.test.context.junit.jupiter.web.SpringJUnitWebConfig;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;
import org.springframework.test.web.servlet.*;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import reactor.core.publisher.Flux;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
@SpringJUnitWebConfig({AppConfig.class,PreFilter.class,CustomAuthenticationEntryPoint.class,CustomAccessDeniedHandler.class,AIEndpointAuthorizationTest.Config.class})
class AIEndpointAuthorizationTest {
 @Configuration @EnableWebMvc static class Config {
  @Bean CustomUserDetailsService users(){return mock(CustomUserDetailsService.class);}
  @Bean JwtService jwt(){return mock(JwtService.class);}
  @Bean TokenRepository tokens(){return mock(TokenRepository.class);}
  @Bean MessageService messages(){return mock(MessageService.class);}
  @Bean EntityManagerFactory emf(){return mock(EntityManagerFactory.class);}
  @Bean AIAdminChatService ai(){var ai=mock(AIAdminChatService.class);when(ai.chatStream(anyString(),anyString())).thenReturn(Flux.just("OK"));return ai;}
  @Bean ApiAIChatBotController endpoint(AIAdminChatService ai){return new ApiAIChatBotController(ai);}
 }
 @Autowired WebApplicationContext context;MockMvc mvc;
 @BeforeEach void setup(){mvc=MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();}
 @Test void anonymousIsRejectedByTheRealAdminChatController() throws Exception {
  mvc.perform(post("/api/ai/chat").contentType("application/json").content("{\"message\":\"Hello\"}")).andExpect(status().isUnauthorized());
 }
 @Test void customerIsRejectedByTheRealAdminChatController() throws Exception {
  mvc.perform(post("/api/ai/chat").with(user("customer").authorities(()->"USER")).contentType("application/json").content("{\"message\":\"Hello\"}")).andExpect(status().isForbidden());
 }
 @Test void adminCanCallTheRealAdminChatController() throws Exception {
  mvc.perform(post("/api/ai/chat").with(user("admin").authorities(()->"ADMIN")).contentType("application/json").content("{\"message\":\"Hello\"}")).andExpect(status().isOk());
 }
}