package com.crowndine.service.chat;

import org.springframework.stereotype.Component;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;

/** Anonymous access lasts 24 hours and expires on server restart; no schema/config changes. */
@Component
public class ChatGuestAccess {
    private final byte[] secret = new byte[32];
    public ChatGuestAccess() { new SecureRandom().nextBytes(secret); }
    public String issue(Long id) {
        String expires = Long.toString(Instant.now().plusSeconds(86400).getEpochSecond());
        return expires + "." + sign(id + ":" + expires);
    }
    public boolean allows(Long id, String token) {
        if (token == null || token.length() > 128) return false;
        try {
            String[] parts = token.split("\\.", -1);
            if (parts.length != 2 || Long.parseLong(parts[0]) <= Instant.now().getEpochSecond()) return false;
            return MessageDigest.isEqual(sign(id + ":" + parts[0]).getBytes(StandardCharsets.UTF_8),
                    parts[1].getBytes(StandardCharsets.UTF_8));
        } catch (RuntimeException ignored) { return false; }
    }
    private String sign(String value) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret, "HmacSHA256"));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(mac.doFinal(value.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception error) { throw new IllegalStateException("Cannot sign guest conversation access", error); }
    }
}
