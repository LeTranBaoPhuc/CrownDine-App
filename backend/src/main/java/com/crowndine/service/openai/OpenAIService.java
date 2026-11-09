package com.crowndine.service.openai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
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

    public OpenAIService(RestTemplate restTemplate, ObjectMapper objectMapper) {
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
            log.error("OpenAI API key is not configured");
            return "Xin lỗi, hệ thống AI chưa được cấu hình API key. Vui lòng liên hệ quản trị viên.";
        }

        String targetModel = (model != null && !model.isBlank()) ? model : getDefaultModel();

        try {
            return executeChatCompletion(messages, targetModel, keyToUse.trim());
        } catch (Exception e) {
            log.warn("Failed calling OpenAI with model '{}': {}. Attempting fallback to gpt-4o...", targetModel, e.getMessage());
            if (!"gpt-4o".equalsIgnoreCase(targetModel)) {
                try {
                    return executeChatCompletion(messages, "gpt-4o", keyToUse.trim());
                } catch (Exception ex) {
                    log.error("Fallback to gpt-4o also failed: {}", ex.getMessage());
                }
            }
            return "Xin lỗi, tôi không thể trả lời ngay lúc này. Vui lòng thử lại sau.";
        }
    }

    private String executeChatCompletion(List<Map<String, String>> messages, String model, String apiKey) throws Exception {
        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("model", model);
        requestBody.put("messages", messages);
        requestBody.put("temperature", 0.7);

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
            String content = choices.get(0).path("message").path("content").asText();
            log.info("OpenAI [{}] response generated successfully", model);
            return content;
        }

        throw new IllegalStateException("OpenAI returned response with no choices");
    }
}
