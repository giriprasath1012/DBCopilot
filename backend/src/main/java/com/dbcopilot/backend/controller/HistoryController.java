package com.dbcopilot.backend.controller;

import com.dbcopilot.backend.entity.QueryHistory;
import com.dbcopilot.backend.service.QueryHistoryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/history")
public class HistoryController {

    @Autowired
    private QueryHistoryService historyService;

    @GetMapping
    public ResponseEntity<List<QueryHistory>> getHistory(Principal principal) {
        List<QueryHistory> history = historyService.getUserHistory(principal.getName());
        return ResponseEntity.ok(history);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteHistory(@PathVariable Long id, Principal principal) {
        historyService.deleteById(id, principal.getName());
        return ResponseEntity.noContent().build();
    }
}
