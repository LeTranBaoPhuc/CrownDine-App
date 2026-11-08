package com.crowndine.config;

import org.springframework.messaging.*;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.messaging.simp.stomp.*;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;

/** Enforce the same serving permissions for STOMP as for HTTP. */
public class WebSocketAuthorizationInterceptor implements ChannelInterceptor {
    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor headers = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (headers == null || headers.getCommand() == null) return message;
        StompCommand command = headers.getCommand();
        if (command == StompCommand.DISCONNECT || command == StompCommand.UNSUBSCRIBE) return message;
        if (!(headers.getUser() instanceof Authentication auth) || !auth.isAuthenticated()) throw new AccessDeniedException("WebSocket authentication required");
        boolean staff = auth.getAuthorities().stream().anyMatch(a -> java.util.Set.of("STAFF", "ADMIN", "ROLE_STAFF", "ROLE_ADMIN").contains(a.getAuthority()));
        String destination = headers.getDestination();
        if (command == StompCommand.SEND && (!staff || destination == null || !destination.startsWith("/app/"))) throw new AccessDeniedException("Serving updates require staff permissions");
        if (command == StompCommand.SUBSCRIBE) {
            boolean ownNotifications = "/user/queue/notifications".equals(destination);
            boolean tableUpdates = "/topic/tables".equals(destination);
            boolean serving = staff && java.util.Set.of("/topic/orders", "/topic/order-details").contains(destination == null ? "" : destination);
            if (!ownNotifications && !tableUpdates && !serving) throw new AccessDeniedException("Subscription is not permitted");
        }
        return message;
    }
}
