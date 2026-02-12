package com.campbell.Flip.service;

import org.springframework.stereotype.Service;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;

@Service
@RequiredArgsConstructor
public class EmailService {
    
    private final JavaMailSender javaMailSender;

    @Value("${spring.mail.username}")
    private String senderEmail;

    public void sendEmail(String to, String subject, String body) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(senderEmail);
            message.setTo(to);
            message.setSubject(subject);
            message.setText(body);
            javaMailSender.send(message);
            System.out.println("EMAIL SENT TO: " + to);
        } catch (Exception e) {
            System.err.println("ERROR SENDING EMAIL: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("Failed to send email to " + to + ": " + e.getMessage(), e);
        }
    }

    public void sendVerificationEmail(String to, String code) {
        String subject = "Flip Account Verification";
        String body = "Your verification code is: " + code + "\n\nPlease enter this code to verify your account.";
        sendEmail(to, subject, body);
    }

    public void sendPasswordResetEmail(String to, String code) {
        String subject = "Password Reset Request";
        String body = "Your password reset code is: " + code + "\n\nPlease enter this code to reset your password.";
        sendEmail(to, subject, body);
    }
}
