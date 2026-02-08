package com.campbell.Flip.service;

import com.campbell.Flip.entities.Business;
import com.campbell.Flip.entities.Role;
import com.campbell.Flip.entities.User;
import com.campbell.Flip.exceptions.BadCredentialsException;
import com.campbell.Flip.entities.PasswordResetToken;
import com.campbell.Flip.repository.PasswordResetTokenRepository;
import com.campbell.Flip.repository.UserRepository;
import com.campbell.Flip.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.UUID;

import java.util.Collections;

@Service
public class UserService {
    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private PasswordResetTokenRepository tokenRepository;

    @Autowired
    private EmailService emailService;

    public User registerCeo(String firstName, String lastName, String email, String username, String password, String businessName, String businessRegNumber) {
        Business business = new Business();
        business.setName(businessName);
        business.setBusinessRegNumber(businessRegNumber);
        
        // Generate 6-digit verification code
        String code = String.format("%06d", new java.util.Random().nextInt(999999));

        User ceo = new User();
        ceo.setFirstName(firstName);
        ceo.setEmail(email);
        ceo.setLastName(lastName);
        ceo.setUsername(username);
        ceo.setPassword(passwordEncoder.encode(password));
        ceo.setRole(Role.CEO);
        ceo.setBusiness(business);
        ceo.setVerified(false); // Not verified initially
        ceo.setVerificationCode(code);

        User savedUser = userRepository.save(ceo);
        emailService.sendVerificationEmail(email, code);
        return savedUser;
    }

    public String authenticate(String username, String password) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        if (!user.isVerified()) {
            throw new BadCredentialsException("User is not verified");
        }

        if (passwordEncoder.matches(password, user.getPassword())) {
            // Use the generateAccessToken method from JwtUtil
            return jwtUtil.generateAccessToken(user);
        } else {
            throw new BadCredentialsException("Invalid credentials");
        }
    }

    public boolean verifyUser(String email, String code) {
        Optional<User> userOptional = userRepository.findByEmail(email);
        if (userOptional.isPresent()) {
            User user = userOptional.get();
            if (code.equals(user.getVerificationCode())) {
                user.setVerified(true);
                user.setVerificationCode(null); // Clear code after use
                userRepository.save(user);
                return true;
            }
        }
        return false;
    }

    public void resendVerificationCode(String email) {
        Optional<User> userOptional = userRepository.findByEmail(email);
        if (userOptional.isPresent()) {
            User user = userOptional.get();
            if (!user.isVerified()) {
                String code = String.format("%06d", new java.util.Random().nextInt(999999));
                user.setVerificationCode(code);
                userRepository.save(user);
                emailService.sendVerificationEmail(email, code);
            }
        }
    }

    @Transactional
    public void createPasswordResetTokenForUser(User user, String token) {
        // Delete existing token if any
        tokenRepository.deleteByUser(user);
        
        // We ignore the passed token argument and generate a 6-digit code locally
        // But to keep signature same, we can just use the token passed if the caller generates it
        // Let's assume the caller (Controller) will pass the 6-digit code
        
        PasswordResetToken myToken = new PasswordResetToken(token, user, 60); // 60 minutes expiry
        tokenRepository.save(myToken);
        emailService.sendPasswordResetEmail(user.getEmail(), token);
    }

    public Optional<User> findUserByEmail(String email) {
        return userRepository.findByEmail(email);
    }

    public Optional<User> getUserByPasswordResetToken(String token) {
        return tokenRepository.findByToken(token)
                .filter(t -> !t.isExpired())
                .map(PasswordResetToken::getUser);
    }

    @Transactional
    public void changeUserPassword(User user, String password) {
        user.setPassword(passwordEncoder.encode(password));
        userRepository.save(user);
        // Delete the token after use
        tokenRepository.deleteByUser(user);
    }
}
