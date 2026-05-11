package com.dbcopilot.backend.service;

import com.dbcopilot.backend.entity.QueryHistory;
import com.dbcopilot.backend.entity.User;
import com.dbcopilot.backend.repository.QueryHistoryRepository;
import com.dbcopilot.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import jakarta.transaction.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class QueryHistoryService {

    @Autowired
    private QueryHistoryRepository queryHistoryRepository;

    @Autowired
    private UserRepository userRepository;

    public List<QueryHistory> getUserHistory(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return queryHistoryRepository.findTop20ByUserOrderByCreatedAtDesc(user);
    }

    public Optional<QueryHistory> getHistoryById(Long id) {
        return queryHistoryRepository.findById(id);
    }

    @Transactional
    public void deleteById(Long id, String username) {
        int deleted = queryHistoryRepository.deleteByIdAndUsername(id, username);
        if (deleted == 0) {
            throw new RuntimeException("History item not found or not owned by user");
        }
    }
}
