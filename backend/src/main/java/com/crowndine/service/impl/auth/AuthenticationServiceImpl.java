package com.crowndine.service.impl.auth;

import com.crowndine.common.enums.ERole;
import com.crowndine.common.enums.ETokenType;
import com.crowndine.common.enums.EUserStatus;
import com.crowndine.common.enums.ErrorCode;
import com.crowndine.dto.request.*;
import com.crowndine.dto.response.TokenResponse;
import com.crowndine.exception.InvalidDataException;
import com.crowndine.exception.JwtAuthenticationException;
import com.crowndine.exception.ResourceNotFoundException;
import com.crowndine.model.Role;
import com.crowndine.model.Token;
import com.crowndine.model.User;
import com.crowndine.repository.RoleRepository;
import com.crowndine.repository.UserRepository;
import com.crowndine.service.auth.AuthenticationService;
import com.crowndine.service.auth.JwtService;
import com.crowndine.service.mail.MailService;
import com.crowndine.service.token.TokenService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j(topic = "AUTH-SERVICE")
public class AuthenticationServiceImpl implements AuthenticationService {

    @Value("${endpoint.confirmUser}")
    private String endPointConfirmUser;

    @Value("${endpoint.endPointResetPassword}")
    private String endPointResetPassword;

    private final UserRepository userRepository;
    private final JwtService jwtService;
    private final RoleRepository roleRepository;
    private final MailService mailService;
    private final AuthenticationManager authenticationManager;
    private final PasswordEncoder passwordEncoder;
    private final TokenService tokenService;

    @Value("${google.client-id:}")
    private String googleClientId;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public TokenResponse accessToken(LoginRequest request, HttpServletRequest httpServletRequest) {
        List<String> roles;

        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.getUsername(), request.getPassword()));

            roles = extractRoles(authentication.getAuthorities());

        } catch (BadCredentialsException e) {
            log.error("errorMessage: {}", e.getMessage());
            throw new BadCredentialsException(e.getMessage());
        }

        String accessToken = jwtService.generateAccessToken(request.getUsername(), roles);
        String refreshToken = jwtService.generateRefreshToken(request.getUsername(), roles);

        // save token to db
        tokenService.saveToken(request.getUsername(), refreshToken, httpServletRequest);

        return TokenResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .build();
    }

    @Override
    public TokenResponse refreshToken(HttpServletRequest request) {
        log.info("Get new access token called");
        final String refreshToken = request.getHeader("X-Refresh-Token");

        if (!StringUtils.hasText(refreshToken)) {
            throw new InvalidDataException("auth.refresh_token_empty");
        }

        // Kiem tra JWT
        final String username = jwtService.extractUsername(refreshToken, ETokenType.REFRESH_TOKEN);

        // Kiem tra DB sau
        Token token = tokenService.getByRefreshToken(refreshToken);

        if (Boolean.TRUE.equals(token.getIsRevoked())) {
            throw new InvalidDataException("auth.token_revoked");
        }

        if (token.getExpiredAt().isBefore(LocalDateTime.now())) {
            throw new InvalidDataException("auth.refresh_token_expired");
        }

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("Invalid username"));

        jwtService.isTokenValid(refreshToken, ETokenType.REFRESH_TOKEN, user);

        List<String> roles = extractRoles(user.getAuthorities());

        String accessToken = jwtService.generateAccessToken(username, roles);

        return TokenResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .username(user.getUsername())
                .build();
    }

    private List<String> extractRoles(Collection<? extends GrantedAuthority> authorities) {
        return authorities.stream()
                .map(GrantedAuthority::getAuthority)
                .toList();
    }

    @Override
    public void logout(HttpServletRequest request) {

        final String refreshToken = request.getHeader("X-Refresh-Token");

        if (!StringUtils.hasText(refreshToken)) {
            throw new InvalidDataException("auth.token_missing");
        }

        // Kiem tra JWT
        final String username = jwtService.extractUsername(refreshToken, ETokenType.REFRESH_TOKEN);

        tokenService.revokedByRefreshToken(refreshToken);

        log.info("Logout successful username {} ", username);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long register(RegisterRequest request) {
        log.info("Processing register for user: {}", request.getUsername());

        if (!request.getPassword().equals(request.getConfirmPassword())) {
            throw new InvalidDataException("auth.confirm_password_mismatch");
        }

        if (userRepository.existsByUsername(request.getUsername())) {
            throw new InvalidDataException("auth.username_exists");
        }

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new InvalidDataException("auth.email_exists");
        }

        if (userRepository.existsByPhone(request.getPhone())) {
            throw new InvalidDataException("auth.phone_exists");
        }

        String otp = String.format("%06d", new java.security.SecureRandom().nextInt(1000000));

        // save to db
        User user = new User();
        user.setUsername(request.getUsername());
        user.setEmail(request.getEmail().trim().toLowerCase());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setGender(request.getGender());
        user.setDateOfBirth(request.getBirthday());
        user.setPhone(request.getPhone());
        user.setFirstName(request.getFirstName());
        user.setLastName(request.getLastName());
        user.setVerificationCode(otp);
        user.setVerificationExpiration(LocalDateTime.now().plusMinutes(5));
        user.setStatus(EUserStatus.INACTIVE);

        mailService.sendOtpEmail(request.getEmail().trim().toLowerCase(), otp);

        userRepository.save(user);

        log.info("User {} has been registered", user.getUsername());

        return user.getId();
    }

    @Override
    public void forgotPassword(ForgotPasswordRequest request) {
        log.info("Processing forgot password for user: {}", request.getEmail());
        Optional<User> userOptional = userRepository.findByEmail(request.getEmail());
        if (userOptional.isEmpty()) {
            log.info("Forgot password requested for non-existent email {}", request.getEmail());
            return;
        }

        User user = userOptional.get();

        String resetPasswordToken = jwtService.generateResetPasswordToken(user.getUsername());
        mailService.sendResetPasswordLink(request.getEmail(), endPointResetPassword, resetPasswordToken);

        log.info("User {} has been sent email to reset password", user.getUsername());
    }

    @Override
    public boolean confirmRegister(String verifyCode) {
        log.info("Processing verify code for register");

        User user = userRepository.findByVerificationCode(verifyCode)
                .orElseThrow(() -> new ResourceNotFoundException("auth.user_not_found_by_verification_code"));

        if (LocalDateTime.now().isAfter(user.getVerificationExpiration())) {
            log.error("Verification code expired for user {}", user.getUsername());
            return false;
        }

        user.setStatus(EUserStatus.ACTIVE);
        user.setVerificationCode(null);
        user.setVerificationExpiration(null);

        Role role = roleRepository.findByName(ERole.USER);
        user.setRoles(new HashSet<>(List.of(role)));

        userRepository.save(user);

        log.info("User {} has been verified", user.getUsername());
        return true;
    }

    @Override
    public void verifyResetPasswordToken(String token) {
        getUserFromResetPasswordToken(token);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void resetPassword(String token, ResetPasswordRequest request) {
        User user = getUserFromResetPasswordToken(token);

        if (!request.getPassword().equals(request.getConfirmPassword())) {
            throw new InvalidDataException("auth.confirm_password_mismatch");
        }

        user.setPassword(passwordEncoder.encode(request.getPassword()));

        userRepository.save(user);

        log.info("Reset password successfully");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public TokenResponse googleLogin(GoogleLoginRequest request, HttpServletRequest httpServletRequest) {
        log.info("Verifying Google Auth Token");

        try {
            String email = null;
            String googleId = null;
            String firstName = null;
            String lastName = null;
            String pictureUrl = null;

            String token = request.getToken();
            boolean decodedAsJwt = false;

            // 1. Kiểm tra nếu là JWT ID Token OIDC (bắt đầu bằng eyJ và có đúng 3 phần header.payload.signature)
            if (token != null && token.startsWith("eyJ") && token.split("\\.").length == 3) {
                try {
                    log.info("Verifying as Google OIDC ID Token (JWT)");
                    NimbusJwtDecoder jwtDecoder = NimbusJwtDecoder.withIssuerLocation("https://accounts.google.com").build();
                    Jwt jwt = jwtDecoder.decode(token);

                    if (StringUtils.hasText(googleClientId) && !jwt.getAudience().contains(googleClientId)) {
                        log.error("Invalid Audience in ID Token");
                        throw new InvalidDataException("Token belongs to a different client");
                    }

                    email = jwt.getClaim("email");
                    googleId = jwt.getSubject();
                    firstName = jwt.getClaim("given_name");
                    lastName = jwt.getClaim("family_name");
                    pictureUrl = jwt.getClaim("picture");
                    decodedAsJwt = true;
                } catch (Exception e) {
                    log.warn("Failed to decode token as JWT ({}), attempting fallback to Google userinfo endpoint", e.getMessage());
                }
            }

            // 2. Nếu không phải JWT hoặc giải mã JWT thất bại (ví dụ Google trả về access token dạng ya29.xxx)
            if (!decodedAsJwt) {
                log.info("Verifying as Google OAuth2 Access Token via Google userinfo API");
                org.springframework.web.client.RestTemplate restTemplate = new org.springframework.web.client.RestTemplate();
                org.springframework.http.HttpHeaders headers = new org.springframework.http.HttpHeaders();
                headers.setBearerAuth(token);
                org.springframework.http.HttpEntity<?> entity = new org.springframework.http.HttpEntity<>(headers);

                try {
                    org.springframework.http.ResponseEntity<Map> response = restTemplate.exchange(
                            "https://www.googleapis.com/oauth2/v3/userinfo",
                            org.springframework.http.HttpMethod.GET,
                            entity,
                            Map.class
                    );

                    if (!response.getStatusCode().is2xxSuccessful() || response.getBody() == null) {
                        throw new InvalidDataException("Không thể xác thực mã truy cập từ Google");
                    }

                    Map<String, Object> body = response.getBody();
                    email = (String) body.get("email");
                    googleId = (String) body.get("sub");
                    firstName = (String) body.get("given_name");
                    lastName = (String) body.get("family_name");
                    pictureUrl = (String) body.get("picture");
                } catch (Exception ex) {
                    log.error("Error verifying access token from Google: {}", ex.getMessage());
                    throw new InvalidDataException("Xác thực tài khoản Google thất bại: " + ex.getMessage());
                }
            }

            if (!StringUtils.hasText(email) || !StringUtils.hasText(googleId)) {
                throw new InvalidDataException("Không thể lấy thông tin định danh từ tài khoản Google");
            }

            // Logic to find or create user
            Optional<User> userOptional = userRepository.findByGoogleId(googleId);
            User user = null;

            if (userOptional.isPresent()) {
                user = userOptional.get();
            } else {
                userOptional = userRepository.findByEmail(email);

                if (userOptional.isPresent()) {
                    user = userOptional.get();
                    user.setGoogleId(googleId);
                    if (user.getAvatarUrl() == null) {
                        user.setAvatarUrl(pictureUrl);
                    }
                    userRepository.save(user);
                } else {
                    user = new User();
                    user.setEmail(email);

                    String baseUsername = email.contains("@") ? email.split("@")[0] : email;
                    if (baseUsername.length() > 35) {
                        baseUsername = baseUsername.substring(0, 35);
                    }
                    String generatedUsername = baseUsername;
                    int suffix = 1;
                    while (userRepository.existsByUsername(generatedUsername)) {
                        generatedUsername = baseUsername + suffix++;
                    }
                    user.setUsername(generatedUsername);

                    user.setFirstName(firstName != null ? firstName : "User");
                    user.setLastName(lastName != null ? lastName : "Google");
                    user.setGoogleId(googleId);
                    user.setAvatarUrl(pictureUrl);
                    user.setStatus(EUserStatus.ACTIVE);

                    Role role = roleRepository.findByName(ERole.USER);
                    user.setRoles(new HashSet<>(List.of(role)));

                    userRepository.save(user);
                }
            }

            List<String> roles = extractRoles(user.getAuthorities());
            String accessToken = jwtService.generateAccessToken(user.getUsername(), roles);
            String refreshToken = jwtService.generateRefreshToken(user.getUsername(), roles);

            tokenService.saveToken(user.getUsername(), refreshToken, httpServletRequest);

            return TokenResponse.builder()
                    .accessToken(accessToken)
                    .refreshToken(refreshToken)
                    .username(user.getUsername())
                    .build();

        } catch (Exception e) {
            log.error("Error during Google OAuth2 Nimbus verification: ", e);
            throw new InvalidDataException("Google authentication failed: " + e.getMessage());
        }
    }

    private User getUserFromResetPasswordToken(String token) {
        String username;
        try {
            username = jwtService.extractUsername(token, ETokenType.RESET_PASSWORD_TOKEN);
        } catch (JwtAuthenticationException e) {
            if (e.getErrorCode() == ErrorCode.TOKEN_EXPIRED) {
                throw new InvalidDataException("auth.reset_password_token_expired");
            }
            throw new InvalidDataException("auth.reset_password_token_invalid");
        }

        User user = userRepository.findByUsername(username).orElseThrow(() -> new ResourceNotFoundException("auth.account_not_found"));

        jwtService.isTokenValid(token, ETokenType.RESET_PASSWORD_TOKEN, user);
        return user;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void sendForgotPasswordOtp(ForgotPasswordSendOtpRequest request) {
        log.info("Processing send forgot password OTP for email: {}", request.getEmail());
        User user = userRepository.findByEmail(request.getEmail().trim().toLowerCase())
                .orElseThrow(() -> new ResourceNotFoundException("Email không tồn tại trong hệ thống"));

        String otp = String.format("%06d", new Random().nextInt(1000000));
        user.setVerificationCode(otp);
        user.setVerificationExpiration(LocalDateTime.now().plusMinutes(5));
        userRepository.save(user);

        mailService.sendOtpEmail(user.getEmail(), otp);
        log.info("Successfully sent forgot password OTP to email: {}", request.getEmail());
    }

    @Override
    public void verifyForgotPasswordOtp(ForgotPasswordVerifyOtpRequest request) {
        log.info("Processing verify forgot password OTP for email: {}", request.getEmail());
        User user = userRepository.findByEmail(request.getEmail().trim().toLowerCase())
                .orElseThrow(() -> new ResourceNotFoundException("Email không tồn tại trong hệ thống"));

        if (user.getVerificationCode() == null || !user.getVerificationCode().equals(request.getOtp().trim())) {
            throw new InvalidDataException("Mã OTP không chính xác");
        }

        if (user.getVerificationExpiration() == null || LocalDateTime.now().isAfter(user.getVerificationExpiration())) {
            throw new InvalidDataException("Mã OTP đã hết hạn, vui lòng yêu cầu mã mới");
        }

        log.info("Successfully verified OTP for email: {}", request.getEmail());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void resetPasswordWithOtp(ForgotPasswordResetRequest request) {
        log.info("Processing reset password with OTP for email: {}", request.getEmail());
        User user = userRepository.findByEmail(request.getEmail().trim().toLowerCase())
                .orElseThrow(() -> new ResourceNotFoundException("Email không tồn tại trong hệ thống"));

        if (user.getVerificationCode() == null || !user.getVerificationCode().equals(request.getOtp().trim())) {
            throw new InvalidDataException("Mã OTP không chính xác");
        }

        if (user.getVerificationExpiration() == null || LocalDateTime.now().isAfter(user.getVerificationExpiration())) {
            throw new InvalidDataException("Mã OTP đã hết hạn, vui lòng yêu cầu mã mới");
        }

        if (!request.getPassword().equals(request.getConfirmPassword())) {
            throw new InvalidDataException("Mật khẩu xác nhận không khớp");
        }

        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setVerificationCode(null);
        user.setVerificationExpiration(null);
        userRepository.save(user);

        log.info("Successfully reset password with OTP for user: {}", user.getUsername());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void verifyRegisterOtp(com.crowndine.dto.request.VerifyRegisterOtpRequest request) {
        log.info("Processing verify register OTP for email: {}", request.getEmail());

        User user = userRepository.findByEmail(request.getEmail().trim().toLowerCase())
                .orElseThrow(() -> new ResourceNotFoundException("auth.user_not_found"));

        if (user.getStatus() == EUserStatus.ACTIVE) {
            log.info("User {} already active", user.getUsername());
            return;
        }

        if (user.getVerificationExpiration() == null || LocalDateTime.now().isAfter(user.getVerificationExpiration())) {
            throw new InvalidDataException("Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.");
        }

        if (user.getVerificationCode() == null || !user.getVerificationCode().trim().equals(request.getOtp().trim())) {
            throw new InvalidDataException("Mã OTP không chính xác. Vui lòng kiểm tra lại.");
        }

        user.setStatus(EUserStatus.ACTIVE);
        user.setVerificationCode(null);
        user.setVerificationExpiration(null);

        Role role = roleRepository.findByName(ERole.USER);
        if (role != null) {
            user.setRoles(new HashSet<>(List.of(role)));
        }

        userRepository.save(user);
        log.info("User {} has been activated with ERole.USER successfully", user.getUsername());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void resendRegisterOtp(String email) {
        log.info("Processing resend register OTP for email: {}", email);

        User user = userRepository.findByEmail(email.trim().toLowerCase())
                .orElseThrow(() -> new ResourceNotFoundException("auth.user_not_found"));

        if (user.getStatus() == EUserStatus.ACTIVE) {
            throw new InvalidDataException("Tài khoản này đã được kích hoạt, không cần gửi lại OTP.");
        }

        String otp = String.format("%06d", new java.security.SecureRandom().nextInt(1000000));
        user.setVerificationCode(otp);
        user.setVerificationExpiration(LocalDateTime.now().plusMinutes(5));
        userRepository.save(user);

        mailService.sendOtpEmail(email.trim().toLowerCase(), otp);
        log.info("Resent register OTP to email {}", email);
    }

}
