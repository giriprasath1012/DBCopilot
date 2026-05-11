package com.dbcopilot.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ChatQueryResponse {
    private String summary;
    private String sql;
    private List<Map<String, Object>> data;
    private int rowCount;
    private String explanation;
    private Long queryId;
    private String status;
    private String errorMessage;
}
