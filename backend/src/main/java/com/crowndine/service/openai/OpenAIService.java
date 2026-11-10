package com.crowndine.service.openai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.crowndine.exception.AiServiceException;
import org.springframework.beans.factory.annotation.Qualifier;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@Slf4j
public class OpenAIService {

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Value("${openai.api.key:}")
    private String apiKey;

    @Value("${openai.api.url:https://api.openai.com/v1/chat/completions}")
    private String apiUrl;

    @Value("${openai.model:gpt-6-luna}")
    private String defaultModel;

    public OpenAIService(@Qualifier("chatAiRestTemplate") RestTemplate restTemplate, ObjectMapper objectMapper) {
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
    }

    public String getDefaultModel() {
        return (defaultModel != null && !defaultModel.isBlank()) ? defaultModel : "gpt-6-luna";
    }

    /**
     * Send chat messages to OpenAI Chat Completions API
     *
     * @param messages List of messages with role and content
     * @param model    Model name (or null to use default model)
     * @return AI reply text
     */
    public String generateContent(List<Map<String, String>> messages, String model) {
        String keyToUse = (apiKey != null && !apiKey.isBlank()) ? apiKey : System.getenv("OPENAI_API_KEY");
        if (keyToUse == null || keyToUse.isBlank()) {
            throw new AiServiceException("Hệ thống AI chưa được cấu hình. Vui lòng thử lại sau.");
        }

        String targetModel = (model != null && !model.isBlank()) ? model : getDefaultModel();

        try {
            return executeChatCompletion(messages, targetModel, keyToUse.trim());
        } catch (Exception e) {
            // Provider error bodies can contain credentials; never log them or silently change models.
            log.warn("AI request failed for model {} ({})", targetModel, e.getClass().getSimpleName());
            throw new AiServiceException("AI chưa thể phản hồi. Vui lòng thử lại sau.");
        }
    }

    private String executeChatCompletion(List<Map<String, String>> messages, String model, String apiKey) throws Exception {
        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("model", model);
        requestBody.put("messages", messages);
        requestBody.put("max_completion_tokens", 2048);

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + apiKey);
        headers.set("Content-Type", "application/json");

        HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);

        ResponseEntity<String> response = restTemplate.exchange(
                apiUrl,
                HttpMethod.POST,
                request,
                String.class
        );

        JsonNode root = objectMapper.readTree(response.getBody());
        JsonNode choices = root.path("choices");
        if (choices.isArray() && !choices.isEmpty()) {
            String content = choices.get(0).path("message").path("content").asText("");
            if (content.isBlank()) throw new IllegalStateException("AI returned an empty message");
            log.info("OpenAI [{}] response generated successfully", model);
            return content;
        }

        throw new IllegalStateException("OpenAI returned response with no choices");
    }
}

