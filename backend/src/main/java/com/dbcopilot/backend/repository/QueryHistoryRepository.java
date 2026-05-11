package com.dbcopilot.backend.repository;

import com.dbcopilot.backend.entity.QueryHistory;
import com.dbcopilot.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface QueryHistoryRepository extends JpaRepository<QueryHistory, Long> {
    List<QueryHistory> findByUserOrderByCreatedAtDesc(User user);
    List<QueryHistory> findTop20ByUserOrderByCreatedAtDesc(User user);

    @Modifying
    @Query("DELETE FROM QueryHistory qh WHERE qh.id = :id AND qh.user.username = :username")
    int deleteByIdAndUsername(@Param("id") Long id, @Param("username") String username);
}
