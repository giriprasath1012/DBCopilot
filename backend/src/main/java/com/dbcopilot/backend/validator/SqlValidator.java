package com.dbcopilot.backend.validator;

import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class SqlValidator {

    private static final List<String> BLOCKED_KEYWORDS = List.of(
            "DELETE", "UPDATE", "INSERT", "DROP", "ALTER",
            "TRUNCATE", "CREATE", "REPLACE", "EXEC", "EXECUTE",
            "GRANT", "REVOKE", "MERGE", "CALL"
    );

    public void validate(String sql) {
        if (sql == null || sql.trim().isEmpty()) {
            throw new IllegalArgumentException("Generated SQL is empty. Please rephrase your query.");
        }

        String upperSql = sql.trim().toUpperCase();

        if (!upperSql.startsWith("SELECT")) {
            throw new IllegalArgumentException(
                    "Only SELECT queries are allowed. The AI generated an unsafe query type.");
        }

        for (String keyword : BLOCKED_KEYWORDS) {
            // Match whole word to avoid false positives (e.g. "SELECTED" matching "SELECT")
            if (upperSql.matches(".*\\b" + keyword + "\\b.*")) {
                throw new SecurityException("Blocked keyword detected: " + keyword +
                        ". Only read-only queries are permitted.");
            }
        }
    }

    public boolean isValid(String sql) {
        try {
            validate(sql);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
