package com.crowndine.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.crowndine.dto.request.ForgotPasswordRequest;
import com.crowndine.dto.request.ForgotPasswordResetRequest;
import com.crowndine.dto.request.ForgotPasswordSendOtpRequest;
import com.crowndine.dto.request.ForgotPasswordVerifyOtpRequest;
import com.crowndine.dto.request.GoogleLoginRequest;
import com.crowndine.dto.request.LoginRequest;
import com.crowndine.dto.request.RegisterRequest;
import com.crowndine.dto.request.ResetPasswordRequest;
import com.crowndine.dto.request.VerifyRegisterOtpRequest;
import com.crowndine.dto.request.ResendRegisterOtpRequest;
import com.crowndine.dto.response.ApiResponse;
import com.crowndine.dto.response.TokenResponse;
import com.crowndine.service.auth.AuthenticationService;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@Validated
@RequiredArgsConstructor
@RequestMapping("/api/auth")
@Slf4j(topic = "API-AUTH-CONTROLLER")
public class ApiAuthController {

    private final AuthenticationService authenticationService;

    @PostMapping("/login")
    public ResponseEntity<TokenResponse> login(@Valid @RequestBody LoginRequest request, HttpServletRequest httpServletRequest) {
        log.info("Login request for user: {}", request.getUsername());
        return new ResponseEntity<>(authenticationService.accessToken(request, httpServletRequest), HttpStatus.OK);
    }

    @PostMapping("/google-login")
    public ResponseEntity<TokenResponse> googleLogin(@Valid @RequestBody GoogleLoginRequest request, HttpServletRequest httpServletRequest) {
        log.info("Google login request");
        return new ResponseEntity<>(authenticationService.googleLogin(request, httpServletRequest), HttpStatus.OK);
    }

    @PostMapping("/refresh-token")
    public ResponseEntity<TokenResponse> refreshToken(HttpServletRequest request) {
        log.info("Get new access token");
        return new ResponseEntity<>(authenticationService.refreshToken(request), HttpStatus.OK);
    }

    @PostMapping("/logout")
    public ApiResponse logout(HttpServletRequest request) {
        authenticationService.logout(request);
        return ApiResponse.builder()
                .status(200)
                .message("Successfully logged out")
                .build();
    }

    @PostMapping("/register")
    public ApiResponse register(@Valid @RequestBody RegisterRequest request) {
        log.info("Register request for user: {}", request.getUsername());

        Long userId = authenticationService.register(request);
        return ApiResponse.builder()
                .status(200)
                .message("Register successfully, check email verification")
                .data(userId)
                .build();
    }

    @PostMapping("verify-register")
    public ApiResponse verifyRegister(@RequestParam String verifyCode) {
        log.info("Verify register request for user, verify code: {}", verifyCode);

        boolean isSuccess = authenticationService.confirmRegister(verifyCode);

        return ApiResponse.builder()
                .status(isSuccess ? 200 : 404)
                .message(isSuccess ? "Verify successfully" : "Verify register failed")
                .build();
    }

    @PostMapping("register/verify-otp")
    public ApiResponse verifyRegisterOtp(@Valid @RequestBody VerifyRegisterOtpRequest request) {
        log.info("Verify register OTP for email: {}", request.getEmail());
        authenticationService.verifyRegisterOtp(request);
        return ApiResponse.builder()
                .status(200)
                .message("Xác thực tài khoản thành công! Bạn có thể đăng nhập ngay.")
                .build();
    }

    @PostMapping("register/resend-otp")
    public ApiResponse resendRegisterOtp(@Valid @RequestBody ResendRegisterOtpRequest request) {
        log.info("Resend register OTP for email: {}", request.getEmail());
        authenticationService.resendRegisterOtp(request.getEmail());
        return ApiResponse.builder()
                .status(200)
                .message("Mã OTP mới đã được gửi vào email của bạn.")
                .build();
    }

    // Nhap email
    @PostMapping("forgot-password")
    public ApiResponse forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
        log.info("Forgot password request for email: {}", request.getEmail());
        authenticationService.forgotPassword(request);
        return ApiResponse.builder()
                .status(200)
                .message("If the account exists, a reset password email has been sent")
                .build();
    }

    @GetMapping("reset-password")
    public ApiResponse verifyResetPasswordToken(@RequestParam String token) {
        log.info("Verify reset password token request");
        authenticationService.verifyResetPasswordToken(token);
        return ApiResponse.builder()
                .status(200)
                .message("Reset password token is valid")
                .build();
    }

    @PostMapping("reset-password")
    public ApiResponse resetPassword(@Valid @RequestBody ResetPasswordRequest request,
            @RequestParam String token) {
        log.info("Reset Password request");
        authenticationService.resetPassword(token, request);
        return ApiResponse.builder()
                .status(200)
                .message("Reset password successfully")
                .build();
    }

    @PostMapping("forgot-password/otp")
    public ApiResponse sendForgotPasswordOtp(@Valid @RequestBody ForgotPasswordSendOtpRequest request) {
        log.info("Send forgot password OTP for email: {}", request.getEmail());
        authenticationService.sendForgotPasswordOtp(request);
        return ApiResponse.builder()
                .status(HttpStatus.OK.value())
                .message("Mã OTP đặt lại mật khẩu đã được gửi đến email của bạn")
                .build();
    }

    @PostMapping("forgot-password/verify-otp")
    public ApiResponse verifyForgotPasswordOtp(@Valid @RequestBody ForgotPasswordVerifyOtpRequest request) {
        log.info("Verify forgot password OTP for email: {}", request.getEmail());
        authenticationService.verifyForgotPasswordOtp(request);
        return ApiResponse.builder()
                .status(HttpStatus.OK.value())
                .message("Xác thực mã OTP thành công")
                .build();
    }

    @PostMapping("forgot-password/reset-by-otp")
    public ApiResponse resetPasswordWithOtp(@Valid @RequestBody ForgotPasswordResetRequest request) {
        log.info("Reset password with OTP for email: {}", request.getEmail());
        authenticationService.resetPasswordWithOtp(request);
        return ApiResponse.builder()
                .status(HttpStatus.OK.value())
                .message("Đặt lại mật khẩu thành công. Vui lòng đăng nhập lại.")
                .build();
    }
}
