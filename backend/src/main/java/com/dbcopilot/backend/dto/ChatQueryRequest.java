package com.dbcopilot.backend.dto;

import lombok.Data;
import java.util.List;

@Data
public class ChatQueryRequest {
    private String message;
    private List<ConversationTurn> conversationHistory;
}
