package com.dbcopilot.backend.dto;

import lombok.Data;

@Data
public class AiGenerateSqlResponse {
    private String sql;
    private String explanation;
}
