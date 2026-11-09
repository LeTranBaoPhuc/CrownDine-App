package com.crowndine.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.crowndine.model.Token;

@Repository
public interface TokenRepository extends JpaRepository<Token, Long> {
    @org.springframework.transaction.annotation.Transactional
    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.data.jpa.repository.Query("update Token t set t.isRevoked = true where t.username = :username")
    void revokeByUsername(@org.springframework.data.repository.query.Param("username") String username);
    Optional<Token> findByUsername(String username);

    Optional<Token> findByRefreshToken(String refreshToken);
}
