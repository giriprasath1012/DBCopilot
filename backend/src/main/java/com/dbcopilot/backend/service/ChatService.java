package com.dbcopilot.backend.service;

import com.dbcopilot.backend.dto.AiGenerateSqlRequest;
import com.dbcopilot.backend.dto.AiGenerateSqlResponse;
import com.dbcopilot.backend.dto.ChatQueryResponse;
import com.dbcopilot.backend.entity.QueryHistory;
import com.dbcopilot.backend.entity.User;
import com.dbcopilot.backend.repository.QueryHistoryRepository;
import com.dbcopilot.backend.repository.UserRepository;
import com.dbcopilot.backend.validator.SqlValidator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

@Service
public class ChatService {

    private static final Pattern WRITE_INTENT = Pattern.compile(
        "\\b(update|delete|remove|insert|drop|alter|truncate|modify)\\b",
        Pattern.CASE_INSENSITIVE
    );

    @Autowired
    private WebClient aiServiceWebClient;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private SqlValidator sqlValidator;

    @Autowired
    private QueryHistoryRepository queryHistoryRepository;

    @Autowired
    private UserRepository userRepository;

    public ChatQueryResponse processQuery(String message, String username) {
        if (WRITE_INTENT.matcher(message).find()) {
            return new ChatQueryResponse(
                "This is a read-only system. Data modification operations (UPDATE, DELETE, INSERT) are not permitted. Please ask a question to retrieve information instead.",
                null, null, 0, null, null, "REJECTED", null
            );
        }

        long startTime = System.currentTimeMillis();

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        QueryHistory history = new QueryHistory();
        history.setUser(user);
        history.setNaturalQuery(message);
        history.setCreatedAt(LocalDateTime.now());

        String generatedSql = null;
        String explanation = null;

        try {
            // Step 1: Call AI service to generate SQL
            AiGenerateSqlResponse aiResponse = aiServiceWebClient.post()
                    .uri("/generate-sql")
                    .bodyValue(new AiGenerateSqlRequest(message, null))
                    .retrieve()
                    .bodyToMono(AiGenerateSqlResponse.class)
                    .timeout(Duration.ofSeconds(120))
                    .block();

            if (aiResponse == null || aiResponse.getSql() == null || aiResponse.getSql().isBlank()) {
                throw new RuntimeException("AI service returned an empty response. Is Ollama running?");
            }

            generatedSql = aiResponse.getSql().trim();
            explanation = aiResponse.getExplanation();
            history.setGeneratedSql(generatedSql);

            // Step 2: Validate SQL for safety
            sqlValidator.validate(generatedSql);

            // Step 3: Execute against PostgreSQL
            List<Map<String, Object>> results = jdbcTemplate.queryForList(generatedSql);

            long executionTime = System.currentTimeMillis() - startTime;
            String summary = buildSummary(results, generatedSql);

            // Step 4: Save to history
            history.setStatus("SUCCESS");
            history.setResultSummary(summary);
            history.setRowCount(results.size());
            history.setExecutionTimeMs(executionTime);
            queryHistoryRepository.save(history);

            return new ChatQueryResponse(summary, generatedSql, results,
                    results.size(), explanation, history.getId(), "SUCCESS", null);

        } catch (WebClientResponseException e) {
            String errMsg = "AI service error: " + e.getResponseBodyAsString();
            return saveErrorAndReturn(history, generatedSql, errMsg);
        } catch (Exception e) {
            return saveErrorAndReturn(history, generatedSql, e.getMessage());
        }
    }

    private ChatQueryResponse saveErrorAndReturn(QueryHistory history, String sql, String errorMsg) {
        history.setStatus("ERROR");
        history.setGeneratedSql(sql);
        history.setErrorMessage(errorMsg);
        queryHistoryRepository.save(history);

        return new ChatQueryResponse(
                "Sorry, I could not process that query.",
                sql, null, 0, null,
                history.getId(), "ERROR", errorMsg);
    }

    private String buildSummary(List<Map<String, Object>> results, String sql) {
        if (results.isEmpty()) {
            return "No records found matching your query.";
        }
        // Single cell result (e.g. COUNT, SUM)
        if (results.size() == 1 && results.get(0).size() == 1) {
            Object value = results.get(0).values().iterator().next();
            String key = results.get(0).keySet().iterator().next();
            return key + ": " + value;
        }
        return "Found " + results.size() + " record" + (results.size() == 1 ? "" : "s") + ".";
    }
}
