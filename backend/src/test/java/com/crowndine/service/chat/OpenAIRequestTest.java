package com.crowndine.service.chat;

import com.crowndine.exception.AiServiceException;
import com.crowndine.service.openai.OpenAIService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.springframework.http.*;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestTemplate;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.*;

class OpenAIRequestTest {
    RestTemplate rest = new RestTemplate();
    MockRestServiceServer server = MockRestServiceServer.bindTo(rest).build();
    OpenAIService ai = new OpenAIService(rest, new ObjectMapper());
    @BeforeEach void setup() {
        ReflectionTestUtils.setField(ai, "apiKey", "test-not-a-real-key");
        ReflectionTestUtils.setField(ai, "apiUrl", "https://example.invalid/chat");
    }
    @Test void usesTheRequestedModelWithoutUnsupportedTemperature() {
        server.expect(requestTo("https://example.invalid/chat")).andExpect(jsonPath("$.model").value("gpt-6-luna"))
                .andExpect(jsonPath("$.temperature").doesNotExist())
                .andRespond(withSuccess("{\"choices\":[{\"message\":{\"content\":\"OK\"}}]}", MediaType.APPLICATION_JSON));
        assertEquals("OK", ai.generateContent(List.of(Map.of("role", "user", "content", "Hello")), "gpt-6-luna"));
        server.verify();
    }
    @Test void doesNotHideModelErrorsBySwitchingModels() {
        server.expect(requestTo("https://example.invalid/chat")).andRespond(withStatus(HttpStatus.NOT_FOUND));
        assertThrows(AiServiceException.class, () -> ai.generateContent(List.of(), "configured-model"));
        server.verify();
    }
    @Test void rejectsEmptyResponses() {
        server.expect(requestTo("https://example.invalid/chat"))
                .andRespond(withSuccess("{\"choices\":[{\"message\":{\"content\":\"\"}}]}", MediaType.APPLICATION_JSON));
        assertThrows(AiServiceException.class, () -> ai.generateContent(List.of(), "configured-model"));
    }
}
