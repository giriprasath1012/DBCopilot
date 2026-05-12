package com.dbcopilot.backend.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
public class SchemaService {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private static final Set<String> EXCLUDED_TABLES = Set.of("users", "query_history");

    public String buildSchemaDescription() {
        Map<String, List<String>> pkMap = fetchPrimaryKeys();
        Map<String, String> fkMap = fetchForeignKeys();
        Map<String, List<Map<String, Object>>> columns = fetchColumns();

        StringBuilder sb = new StringBuilder();

        for (Map.Entry<String, List<Map<String, Object>>> entry : columns.entrySet()) {
            String table = entry.getKey();
            sb.append("Table: ").append(table).append("\n  Columns: ");

            List<String> colDefs = new ArrayList<>();
            for (Map<String, Object> col : entry.getValue()) {
                String colName = (String) col.get("column_name");
                String dataType = (String) col.get("data_type");
                String colDefault = (String) col.get("column_default");

                StringBuilder def = new StringBuilder();
                def.append(colName).append(" (").append(normaliseType(dataType));

                if (pkMap.getOrDefault(table, List.of()).contains(colName)) {
                    def.append(", PK");
                }
                if (fkMap.containsKey(table + "." + colName)) {
                    def.append(", FK→").append(fkMap.get(table + "." + colName));
                }
                if (colDefault != null && colDefault.contains("nextval")) {
                    def.append(", SERIAL");
                }
                def.append(")");
                colDefs.add(def.toString());
            }

            sb.append(String.join(", ", colDefs)).append("\n\n");
        }

        return sb.toString().trim();
    }

    private Map<String, List<Map<String, Object>>> fetchColumns() {
        String sql = """
                SELECT table_name, column_name, data_type, column_default, is_nullable
                FROM information_schema.columns
                WHERE table_schema = 'public'
                ORDER BY table_name, ordinal_position
                """;

        List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql);
        Map<String, List<Map<String, Object>>> result = new LinkedHashMap<>();

        for (Map<String, Object> row : rows) {
            String table = (String) row.get("table_name");
            if (EXCLUDED_TABLES.contains(table)) continue;
            result.computeIfAbsent(table, k -> new ArrayList<>()).add(row);
        }
        return result;
    }

    private Map<String, List<String>> fetchPrimaryKeys() {
        String sql = """
                SELECT kcu.table_name, kcu.column_name
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage kcu
                  ON tc.constraint_name = kcu.constraint_name
                 AND tc.table_schema    = kcu.table_schema
                WHERE tc.constraint_type = 'PRIMARY KEY'
                  AND tc.table_schema    = 'public'
                """;

        Map<String, List<String>> result = new HashMap<>();
        jdbcTemplate.queryForList(sql).forEach(row -> {
            String table = (String) row.get("table_name");
            String col = (String) row.get("column_name");
            result.computeIfAbsent(table, k -> new ArrayList<>()).add(col);
        });
        return result;
    }

    private Map<String, String> fetchForeignKeys() {
        String sql = """
                SELECT
                    kcu.table_name,
                    kcu.column_name,
                    ccu.table_name  AS foreign_table,
                    ccu.column_name AS foreign_column
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage kcu
                  ON tc.constraint_name = kcu.constraint_name
                 AND tc.table_schema    = kcu.table_schema
                JOIN information_schema.constraint_column_usage ccu
                  ON ccu.constraint_name = tc.constraint_name
                WHERE tc.constraint_type = 'FOREIGN KEY'
                  AND tc.table_schema    = 'public'
                """;

        Map<String, String> result = new HashMap<>();
        jdbcTemplate.queryForList(sql).forEach(row -> {
            String key = row.get("table_name") + "." + row.get("column_name");
            String ref = row.get("foreign_table") + "." + row.get("foreign_column");
            result.put(key, ref);
        });
        return result;
    }

    private String normaliseType(String pgType) {
        return switch (pgType.toLowerCase()) {
            case "character varying" -> "varchar";
            case "integer", "bigint", "smallint" -> "integer";
            case "numeric", "decimal" -> "numeric";
            case "timestamp without time zone", "timestamp with time zone" -> "timestamp";
            case "boolean" -> "boolean";
            default -> pgType;
        };
    }
}
