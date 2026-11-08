package com.crowndine.security;

import com.crowndine.exception.TooManyAttemptsException;
import org.springframework.stereotype.Component;
import java.time.Clock;
import java.util.*;

/** Single-process limiter; deployments with multiple replicas must share this state. */
@Component
public class VerificationAttemptLimiter {
    private record Window(long end, int count) {}
    private final Map<String, Window> windows = new HashMap<>();
    private final Clock clock;
    public VerificationAttemptLimiter() { this(Clock.systemUTC()); }
    VerificationAttemptLimiter(Clock clock) { this.clock = clock; }
    public synchronized void check(String operation, String identity, int limit) {
        long now = clock.millis();
        windows.entrySet().removeIf(e -> e.getValue().end() <= now);
        String key = operation + ":" + identity.trim().toLowerCase(Locale.ROOT);
        Window window = windows.getOrDefault(key, new Window(now + 300_000, 0));
        if (window.count() >= limit || windows.size() >= 10_000 && !windows.containsKey(key)) throw new TooManyAttemptsException();
        windows.put(key, new Window(window.end(), window.count() + 1));
    }
}
