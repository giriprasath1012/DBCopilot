package com.dbcopilot.backend.controller;

import com.dbcopilot.backend.entity.QueryHistory;
import com.dbcopilot.backend.service.QueryHistoryService;
import com.dbcopilot.backend.validator.SqlValidator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.security.Principal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/export")
public class ExportController {

    @Autowired
    private QueryHistoryService historyService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private SqlValidator sqlValidator;

    @GetMapping("/csv/{queryId}")
    public ResponseEntity<byte[]> exportCsv(@PathVariable Long queryId, Principal principal) {
        Optional<QueryHistory> historyOpt = historyService.getHistoryById(queryId);

        if (historyOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        QueryHistory history = historyOpt.get();
        String sql = history.getGeneratedSql();

        if (sql == null || !sqlValidator.isValid(sql)) {
            return ResponseEntity.badRequest().build();
        }

        try {
            List<Map<String, Object>> results = jdbcTemplate.queryForList(sql);
            byte[] csvBytes = generateCsv(results).getBytes(StandardCharsets.UTF_8);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.parseMediaType("text/csv"));
            headers.setContentDispositionFormData("attachment", "query_results.csv");
            headers.setContentLength(csvBytes.length);

            return ResponseEntity.ok().headers(headers).body(csvBytes);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    private String generateCsv(List<Map<String, Object>> results) {
        if (results.isEmpty()) return "";

        List<String> headers = new ArrayList<>(results.get(0).keySet());
        StringBuilder sb = new StringBuilder();

        sb.append(String.join(",", headers)).append("\n");

        for (Map<String, Object> row : results) {
            List<String> values = headers.stream()
                    .map(h -> {
                        Object v = row.get(h);
                        if (v == null) return "";
                        String s = v.toString().replace("\"", "\"\"");
                        return "\"" + s + "\"";
                    })
                    .collect(Collectors.toList());
            sb.append(String.join(",", values)).append("\n");
        }

        return sb.toString();
    }
}
