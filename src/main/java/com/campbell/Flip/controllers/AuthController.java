package com.campbell.Flip.controllers;

import com.campbell.Flip.dto.LoginRequest;
import com.campbell.Flip.dto.RefreshTokenRequest;
import com.campbell.Flip.entities.User;
import com.campbell.Flip.repository.UserRepository;
import com.campbell.Flip.util.JwtUtil;
import com.campbell.Flip.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private UserService userService;

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest loginRequest) {
        Optional<User> userOptional = userRepository.findByUsername(loginRequest.getUsername());
        if (userOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Invalid username or password");
        }

        User user = userOptional.get();
        if (!passwordEncoder.matches(loginRequest.getPassword(), user.getPassword())) {
            return ResponseEntity.badRequest().body("Invalid username or password");
        }

        if (!user.isVerified()) {
            return ResponseEntity.status(403).body(Map.of(
                "message", "User is not verified",
                "email", user.getEmail()
            ));
        }

        String accessToken = jwtUtil.generateAccessToken(user);
        String refreshToken = jwtUtil.generateRefreshToken(user);

        return ResponseEntity.ok(
                Map.of("accessToken", accessToken, "refreshToken", refreshToken)
        );
    }

    @PostMapping("/refresh-token")
    public ResponseEntity<?> refreshAccessToken(@RequestBody RefreshTokenRequest refreshTokenRequest) {
        String refreshToken = refreshTokenRequest.getRefreshToken();
        String username = jwtUtil.extractUsername(refreshToken);

        if (jwtUtil.validateRefreshToken(refreshToken, username)) {
            Optional<User> userOptional = userRepository.findByUsername(username);
            if (userOptional.isPresent()) {
                String newAccessToken = jwtUtil.generateAccessToken(userOptional.get());
                return ResponseEntity.ok(Map.of("accessToken", newAccessToken));
            }
        }

        return ResponseEntity.badRequest().body("Invalid refresh token");
    }

    @PostMapping("/verify-email")
    public ResponseEntity<?> verifyEmail(@RequestBody Map<String, String> request) {
        String email = request.get("email");
        String code = request.get("code");
        
        if (userService.verifyUser(email, code)) {
            return ResponseEntity.ok(Map.of("message", "Account verified successfully"));
        } else {
            return ResponseEntity.badRequest().body("Invalid verification code");
        }
    }

    @PostMapping("/resend-verification")
    public ResponseEntity<?> resendVerification(@RequestBody Map<String, String> request) {
        String email = request.get("email");
        userService.resendVerificationCode(email);
        return ResponseEntity.ok(Map.of("message", "Verification code resent"));
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<?> forgotPassword(@RequestBody Map<String, String> request) {
        String email = request.get("email");
        Optional<User> userOptional = userService.findUserByEmail(email);
        
        if (userOptional.isPresent()) {
            // Generate 6-digit code
            String code = String.format("%06d", new java.util.Random().nextInt(999999));
            userService.createPasswordResetTokenForUser(userOptional.get(), code);
        }
        
        // We always return OK to prevent email enumeration
        return ResponseEntity.ok(Map.of("message", "If an account exists with that email, a verification code has been sent."));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<?> resetPassword(@RequestBody Map<String, String> request) {
        String code = request.get("token"); // Frontend sends 'token', which is now the code
        String newPassword = request.get("newPassword");
        
        Optional<User> userOptional = userService.getUserByPasswordResetToken(code);
        if (userOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Invalid or expired verification code.");
        }
        
        userService.changeUserPassword(userOptional.get(), newPassword);
        return ResponseEntity.ok(Map.of("message", "Password has been successfully reset."));
    }
}
