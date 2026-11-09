package com.crowndine.service.chat;

import com.crowndine.dto.request.*;
import com.crowndine.exception.ResourceNotFoundException;
import com.crowndine.model.*;
import com.crowndine.repository.*;
import com.crowndine.service.openai.OpenAIService;
import org.junit.jupiter.api.*;
import org.springframework.transaction.support.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ChatOwnershipTest {
    final ChatConversationRepository conversations = mock(ChatConversationRepository.class);
    final ChatMessageRepository messages = mock(ChatMessageRepository.class);
    final UserRepository users = mock(UserRepository.class);
    final OpenAIService ai = mock(OpenAIService.class);
    final ChatContextService context = mock(ChatContextService.class);
    final TransactionTemplate transactions = mock(TransactionTemplate.class);
    final ChatGuestAccess guests = new ChatGuestAccess();
    final ChatBookingSupport booking = mock(ChatBookingSupport.class);
    final ChatService chat = new ChatService(conversations, messages, users, ai, transactions, context, guests, booking);
    final User alice = new User(), bob = new User();
    final ChatConversation owned = new ChatConversation();
    @BeforeEach void setup() {
        alice.setId(1L); alice.setUsername("alice"); bob.setId(2L); bob.setUsername("bob");
        owned.setId(9L); owned.setUser(alice); owned.setTitle("Private");
        when(users.findByUsername("alice")).thenReturn(Optional.of(alice));
        when(users.findByUsername("bob")).thenReturn(Optional.of(bob));
        when(conversations.findById(9L)).thenReturn(Optional.of(owned));
        when(conversations.findByIdAndUser(9L, alice)).thenReturn(Optional.of(owned));
        when(messages.findByConversationOrderByCreatedAtAsc(any())).thenReturn(List.of());
        when(booking.contextFor(anyList())).thenReturn("Ask for a booking slot");
        when(booking.validateLinks(anyString())).thenAnswer(i -> i.getArgument(0));
    }
    @Test void anonymousAndAnotherUserCannotReadSendOrDeleteOwnedChats() {
        ChatMessageRequest request = new ChatMessageRequest(); request.setConversationId(9L); request.setContent("Hello");
        for (String username : new String[]{null, "bob", "unknown"}) {
            assertThrows(ResourceNotFoundException.class, () -> chat.getConversation(9L, username));
            assertThrows(ResourceNotFoundException.class, () -> chat.sendMessage(username, request));
            assertThrows(ResourceNotFoundException.class, () -> chat.deleteConversation(9L, username));
        }
        verify(messages, never()).save(any()); verify(conversations, never()).delete(any());
        assertThrows(ResourceNotFoundException.class, () -> chat.getConversation(9L, null, guests.issue(9L)));
        assertEquals(9L, chat.getConversation(9L, "alice").getId());
        chat.deleteConversation(9L, "alice"); verify(conversations).delete(owned);
    }
    @Test void anonymousChatsRequireTheirOwnTokenForEveryOperation() {
        ChatConversation guest = new ChatConversation(); guest.setId(10L); guest.setTitle("Guest");
        when(conversations.save(any())).thenReturn(guest);
        when(conversations.findById(10L)).thenReturn(Optional.of(guest));
        var created = chat.createConversation(null, new ChatConversationRequest());
        String token = created.getGuestAccessToken();
        assertNotNull(token); assertTrue(guests.allows(10L, token));
        assertFalse(guests.allows(11L, token)); assertFalse(guests.allows(10L, token + "x"));
        assertFalse(new ChatGuestAccess().allows(10L, token));
        assertThrows(ResourceNotFoundException.class, () -> chat.getConversation(10L, null));
        assertThrows(ResourceNotFoundException.class, () -> chat.deleteConversation(10L, null));
        assertEquals(10L, chat.getConversation(10L, null, token).getId());
        assertNull(chat.getConversation(10L, null, token).getGuestAccessToken());
        ChatMessageRequest request = new ChatMessageRequest(); request.setConversationId(10L); request.setContent("Hello");
        assertThrows(ResourceNotFoundException.class, () -> chat.sendMessage(null, request));
        when(messages.save(any())).thenAnswer(i -> i.getArgument(0));
        TransactionSynchronizationManager.initSynchronization();
        try { assertEquals("Hello", chat.sendMessage(null, request, token).getContent()); }
        finally { TransactionSynchronizationManager.clearSynchronization(); }
        chat.deleteConversation(10L, null, token); verify(conversations).delete(guest);
    }
    @Test void failuresDuringPromptGenerationBecomeVisibleErrorMessages() {
        when(context.getRestaurantContext()).thenThrow(new IllegalStateException("Local failure"));
        when(transactions.execute(any())).thenAnswer(i -> {
            TransactionCallback<?> callback = i.getArgument(0);
            return callback.doInTransaction(mock(org.springframework.transaction.TransactionStatus.class));
        });
        chat.processAIResponse(9L, 1L);
        verify(messages).save(argThat(message -> "error".equals(message.getRole()) && !message.getContent().isBlank()));
    }
    @Test void retryDoesNotSendLocalErrorRolesToTheAiProvider() {
        ChatMessage failure = new ChatMessage(); failure.setRole("error"); failure.setContent("Please retry");
        ChatMessage user = new ChatMessage(); user.setRole("user"); user.setContent("Hello again");
        when(messages.findLastMessagesByConversationId(eq(9L), any())).thenReturn(List.of(user, failure));
        when(context.getRestaurantContext()).thenReturn("Restaurant");
        when(ai.getDefaultModel()).thenReturn("configured-model");
        when(ai.generateContent(anyList(), anyString())).thenReturn("OK");
        // The provider must receive only supported roles even if the previous attempt failed.
        chat.processAIResponse(9L, 1L);
        verify(ai).generateContent(argThat(history -> history.stream().noneMatch(m -> "error".equals(m.get("role")))), eq("configured-model"));
    }
}
