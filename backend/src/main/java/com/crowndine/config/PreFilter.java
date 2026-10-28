package com.crowndine.config;

import com.crowndine.common.enums.ETokenType;
import com.crowndine.common.i18n.MessageService;
import com.crowndine.exception.ErrorResponse;
import com.crowndine.exception.JwtAuthenticationException;
import com.crowndine.security.CustomUserDetailsService;
import com.crowndine.service.auth.JwtService;
import com.crowndine.repository.TokenRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.NonNull;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Date;

@Component
@RequiredArgsConstructor
@Slf4j(topic = "PRE-REQUEST-FILTER")
public class PreFilter extends OncePerRequestFilter {

    private final JwtService jwtService;

    private final CustomUserDetailsService customUserDetailsService;

    private final TokenRepository tokenRepository;
    private final MessageService messageService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    @NonNull HttpServletResponse response,
                                    @NonNull FilterChain filterChain) throws ServletException, IOException {

        log.info("----------------------- Pre Filter -----------------------");

        final String authorization = request.getHeader("Authorization");

        if (StringUtils.isBlank(authorization) || !authorization.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        final String token = authorization.substring(7);

        String username = null;

        try {
            username = jwtService.extractUsername(token, ETokenType.ACCESS_TOKEN);
        } catch (JwtAuthenticationException e) {
            log.error("JWT Authentication Error, message={}", e.getMessage());
            sendErrorResponse(response, request.getRequestURI(), HttpServletResponse.SC_UNAUTHORIZED,
                    e.getErrorCode() != null ? e.getErrorCode().name() : "TOKEN_INVALID",
                    messageService.resolveMessageOrKey(e.getMessage()));
            return;
        } catch (Exception e) {
            log.error("Unexpected JWT Error: {}", e.getMessage());
            sendErrorResponse(response, request.getRequestURI(), HttpServletResponse.SC_UNAUTHORIZED,
                    "TOKEN_INVALID", "Mã xác thực không hợp lệ hoặc đã hết hạn");
            return;
        }

        if (StringUtils.isNotEmpty(username) && SecurityContextHolder.getContext().getAuthentication() == null) {
            try {
                UserDetails userDetails = customUserDetailsService.loadUserByUsername(username);

                if (jwtService.isTokenValid(token, ETokenType.ACCESS_TOKEN, userDetails)) {
                    if (!userDetails.isEnabled()) {
                        log.warn("User account is disabled/locked: {}", username);
                        sendErrorResponse(response, request.getRequestURI(), HttpServletResponse.SC_FORBIDDEN,
                                "ACCOUNT_DISABLED", "Tài khoản của bạn đã bị khóa hoặc chưa được kích hoạt");
                        return;
                    }
                    UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                            userDetails, null, userDetails.getAuthorities());
                    auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(auth);
                }
            } catch (UsernameNotFoundException e) {
                log.warn("Username from token not found in database: {}", username);
                sendErrorResponse(response, request.getRequestURI(), HttpServletResponse.SC_UNAUTHORIZED,
                        "USER_NOT_FOUND", "Tài khoản người dùng không tồn tại");
                return;
            }
        }

        filterChain.doFilter(request, response);
    }

    private void sendErrorResponse(HttpServletResponse response, String path, int status, String error, String message) throws IOException {
        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");

        ErrorResponse errorResponse = new ErrorResponse();
        errorResponse.setTimestamp(new Date());
        errorResponse.setStatus(status);
        errorResponse.setPath(path);
        errorResponse.setError(error);
        errorResponse.setMessage(message);

        ObjectMapper objectMapper = new ObjectMapper();
        response.getWriter().write(objectMapper.writeValueAsString(errorResponse));
    }
}
