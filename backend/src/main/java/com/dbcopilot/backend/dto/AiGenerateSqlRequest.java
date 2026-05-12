package com.dbcopilot.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class AiGenerateSqlRequest {
    private String query;
    private List<ConversationTurn> conversationHistory;
}
