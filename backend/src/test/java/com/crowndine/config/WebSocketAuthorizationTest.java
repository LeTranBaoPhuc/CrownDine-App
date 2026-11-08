package com.crowndine.config;

import org.junit.jupiter.api.Test;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.messaging.simp.stomp.*;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.AuthorityUtils;
import org.springframework.security.access.AccessDeniedException;
import static org.junit.jupiter.api.Assertions.*;

class WebSocketAuthorizationTest {
    private final WebSocketAuthorizationInterceptor guard = new WebSocketAuthorizationInterceptor();
    void send(StompCommand command, String destination, String role) {
        var headers = StompHeaderAccessor.create(command);
        headers.setDestination(destination);
        if (role != null) headers.setUser(new UsernamePasswordAuthenticationToken("tester", "", AuthorityUtils.createAuthorityList(role)));
        guard.preSend(MessageBuilder.createMessage(new byte[0], headers.getMessageHeaders()), null);
    }
    @Test void anonymousAndCustomersCannotMutateServingStateOrReadOtherNotifications() {
        assertThrows(AccessDeniedException.class, () -> send(StompCommand.SEND, "/app/order/1/upd-status", null));
        assertThrows(AccessDeniedException.class, () -> send(StompCommand.SEND, "/app/order/1/upd-status", "USER"));
        assertThrows(AccessDeniedException.class, () -> send(StompCommand.SUBSCRIBE, "/topic/orders", "USER"));
        assertThrows(AccessDeniedException.class, () -> send(StompCommand.SUBSCRIBE, "/queue/notifications-alice", "USER"));
        assertThrows(AccessDeniedException.class, () -> send(StompCommand.SEND, "/topic/tables", "STAFF"));
    }
    @Test void authenticatedUsersCanReadOwnNotificationsAndStaffCanServe() {
        assertDoesNotThrow(() -> send(StompCommand.SUBSCRIBE, "/user/queue/notifications", "USER"));
        assertDoesNotThrow(() -> send(StompCommand.SUBSCRIBE, "/topic/orders", "STAFF"));
        assertDoesNotThrow(() -> send(StompCommand.SEND, "/app/table/1", "ADMIN"));
    }
}
