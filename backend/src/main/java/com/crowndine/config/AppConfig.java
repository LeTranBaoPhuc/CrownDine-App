package com.crowndine.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityCustomizer;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;

import static org.springframework.security.config.http.SessionCreationPolicy.STATELESS;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import java.util.Arrays;
import java.util.List;

import org.springframework.http.HttpMethod;
import com.crowndine.security.CustomUserDetailsService;
import com.crowndine.security.CustomAuthenticationEntryPoint;
import com.crowndine.security.CustomAccessDeniedHandler;

import lombok.NonNull;
import lombok.RequiredArgsConstructor;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class AppConfig {

    private final PreFilter preFilter;
    private final CustomUserDetailsService userDetailsService;
    private final CustomAuthenticationEntryPoint authenticationEntryPoint;
    private final CustomAccessDeniedHandler accessDeniedHandler;

    @Value("${app.cors.allowed-origin-patterns:${app.cors.allowed-origins:http://localhost:5173}}")
    private String[] allowedOriginPatterns;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http.cors(Customizer.withDefaults())
                .csrf(AbstractHttpConfigurer::disable)
                .exceptionHandling(exception -> exception
                        .authenticationEntryPoint(authenticationEntryPoint)
                        .accessDeniedHandler(accessDeniedHandler))
                .authorizeHttpRequests(request -> request
                        // 1. Công khai (Public endpoints)
                        .requestMatchers("/api/auth/**").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/categories/**").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/items/**").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/combos/**").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/layout/**").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/feedbacks/**").permitAll()
                        .requestMatchers("/api/feedbacks/items/**").permitAll()
                        .requestMatchers("/api/payments/payos-ipn").permitAll()
                        .requestMatchers("/img/**").permitAll()
                        .requestMatchers("/ws-restaurant/**").permitAll()
                        .requestMatchers("/api/ai/**").permitAll()

                        // 2. Quyền Quản trị viên (ADMIN only)
                        .requestMatchers("/api/dashboard/**").hasAnyAuthority("ADMIN", "ROLE_ADMIN")
                        .requestMatchers("/api/staffs/**").hasAnyAuthority("ADMIN", "ROLE_ADMIN")
                        .requestMatchers(HttpMethod.GET, "/api/users").hasAnyAuthority("ADMIN", "ROLE_ADMIN")
                        .requestMatchers(HttpMethod.POST, "/api/categories/**", "/api/items/**", "/api/combos/**", "/api/vouchers/**", "/api/layout/**").hasAnyAuthority("ADMIN", "ROLE_ADMIN")
                        .requestMatchers(HttpMethod.PUT, "/api/categories/**", "/api/items/**", "/api/combos/**", "/api/layout/**").hasAnyAuthority("ADMIN", "ROLE_ADMIN")
                        .requestMatchers(HttpMethod.PATCH, "/api/vouchers/**", "/api/layout/**").hasAnyAuthority("ADMIN", "ROLE_ADMIN")
                        .requestMatchers(HttpMethod.DELETE, "/api/categories/**", "/api/items/**", "/api/combos/**", "/api/layout/**").hasAnyAuthority("ADMIN", "ROLE_ADMIN")

                        // 3. Quyền Nhân viên & Quản trị viên (STAFF & ADMIN)
                        .requestMatchers("/api/order-details/**").hasAnyAuthority("STAFF", "ADMIN", "ROLE_STAFF", "ROLE_ADMIN")
                        .requestMatchers("/api/user-vouchers/**").hasAnyAuthority("STAFF", "ADMIN", "ROLE_STAFF", "ROLE_ADMIN")
                        .requestMatchers("/api/users/customer/**").hasAnyAuthority("STAFF", "ADMIN", "ROLE_STAFF", "ROLE_ADMIN")

                        // 4. Các tài nguyên còn lại: Bắt buộc xác thực JWT
                        .anyRequest().authenticated())
                .sessionManagement(manager -> manager.sessionCreationPolicy(STATELESS))
                .authenticationProvider(authenticationProvider())
                .addFilterBefore(preFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        if (allowedOriginPatterns != null && allowedOriginPatterns.length > 0) {
            configuration.setAllowedOriginPatterns(Arrays.asList(allowedOriginPatterns));
        } else {
            configuration.setAllowedOriginPatterns(List.of("*"));
        }
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setExposedHeaders(List.of("Authorization", "X-Refresh-Token", "Content-Disposition", "*"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    @Bean
    public WebSecurityCustomizer ignoreResources() {
        return webSecurity -> webSecurity.ignoring()
                .requestMatchers("/actuator/**", "/v3/**", "/webjars/**", "/swagger-ui*/*swagger-initializer.js",
                        "/swagger-ui*/**");
    }

    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(@NonNull CorsRegistry registry) {
                registry.addMapping("/**")
                        .allowedOriginPatterns(allowedOriginPatterns != null && allowedOriginPatterns.length > 0 ? allowedOriginPatterns : new String[]{"*"})
                        .allowedMethods("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD")
                        .allowedHeaders("*")
                        .exposedHeaders("Authorization", "X-Refresh-Token", "Content-Disposition")
                        .allowCredentials(true)
                        .maxAge(3600);
            }
        };
    }    @Bean
    public org.springframework.web.client.RestTemplate restTemplate() {
        return new org.springframework.web.client.RestTemplate();
    }

//    @Bean
//    public com.fasterxml.jackson.databind.ObjectMapper objectMapper() {
//        return new com.fasterxml.jackson.databind.ObjectMapper();
//    }

    @Bean
    public org.springframework.transaction.support.TransactionTemplate transactionTemplate(
            jakarta.persistence.EntityManagerFactory entityManagerFactory) {
        org.springframework.orm.jpa.JpaTransactionManager transactionManager =
                new org.springframework.orm.jpa.JpaTransactionManager();
        transactionManager.setEntityManagerFactory(entityManagerFactory);
        return new org.springframework.transaction.support.TransactionTemplate(transactionManager);
    }
}
