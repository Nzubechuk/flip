package com.campbell.Flip.service;

import com.resend.Resend;
import com.resend.services.emails.model.CreateEmailOptions;
import com.resend.services.emails.model.CreateEmailResponse;
import com.resend.core.exception.ResendException;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Value;
import jakarta.annotation.PostConstruct;

@Service
public class EmailService {

    @Value("${resend.api.key}")
    private String resendApiKey;

    private Resend resend;

    @PostConstruct
    public void init() {
        this.resend = new Resend(resendApiKey);
    }

    public void sendEmail(String to, String subject, String body) {
        try {
            // "onboarding@resend.dev" is the default sender for testing.
            // Once you verify your domain on Resend, you can change this to "support@flipapp.ng" etc.
            CreateEmailOptions params = CreateEmailOptions.builder()
                .from("Flip App <onboarding@resend.dev>")
                .to(to)
                .subject(subject)
                .text(body)
                .build();

            CreateEmailResponse data = resend.emails().send(params);
            System.out.println("EMAIL SENT VIA RESEND. ID: " + data.getId());
        } catch (ResendException e) {
            System.err.println("RESEND API ERROR: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("Failed to send email via Resend: " + e.getMessage(), e);
        } catch (Exception e) {
            System.err.println("UNEXPECTED EMAIL ERROR: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("Unexpected error sending email", e);
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
