package com.dbcopilot.backend.controller;

import com.dbcopilot.backend.dto.ChatQueryRequest;
import com.dbcopilot.backend.dto.ChatQueryResponse;
import com.dbcopilot.backend.service.ChatService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.Map;

@RestController
@RequestMapping("/api/chat")
public class ChatController {

    @Autowired
    private ChatService chatService;

    @PostMapping("/query")
    public ResponseEntity<?> query(@RequestBody ChatQueryRequest request, Principal principal) {
        if (request.getMessage() == null || request.getMessage().isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Message cannot be empty"));
        }
        ChatQueryResponse response = chatService.processQuery(request.getMessage(), principal.getName());
        return ResponseEntity.ok(response);
    }
}
