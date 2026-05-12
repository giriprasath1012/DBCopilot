package com.dbcopilot.backend.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ConversationTurn {
    private String userQuery;
    private String generatedSql;
    private String resultSummary;
}
