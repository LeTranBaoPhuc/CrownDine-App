package com.crowndine.security;

import com.crowndine.exception.TooManyAttemptsException;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class VerificationAttemptLimiterTest {
    @Test void verificationBudgetIsSharedForCanonicalAccountAndIndependentOfSendBudget() {
        var limiter = new VerificationAttemptLimiter();
        for (int i = 0; i < 5; i++) limiter.check("otp", "Alice@Example.com", 5);
        assertThrows(TooManyAttemptsException.class, () -> limiter.check("otp", " alice@example.com ", 5));
        assertDoesNotThrow(() -> limiter.check("send", "alice@example.com", 3));
        assertDoesNotThrow(() -> limiter.check("otp", "bob@example.com", 5));
    }
}
