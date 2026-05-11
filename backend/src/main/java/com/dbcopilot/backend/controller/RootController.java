package com.dbcopilot.backend.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class RootController {

    @GetMapping("/")
    public Map<String, String> health() {
        return Map.of(
                "status", "UP",
                "service", "DBCopilot Backend",
                "version", "1.0.0"
        );
    }
}
