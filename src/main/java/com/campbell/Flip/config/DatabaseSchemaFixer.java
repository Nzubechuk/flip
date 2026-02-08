package com.campbell.Flip.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
public class DatabaseSchemaFixer implements CommandLineRunner {

    private final JdbcTemplate jdbcTemplate;

    public DatabaseSchemaFixer(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void run(String... args) throws Exception {
        System.out.println("Checking and fixing database schema...");
        try {
            // Add is_verified column if missing
            jdbcTemplate.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE");
            
            // Add verification_code column if missing
            jdbcTemplate.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_code VARCHAR(255)");
            
            System.out.println("Database schema updated successfully.");
        } catch (Exception e) {
            System.out.println("Schema update warning: " + e.getMessage());
        }
    }
}
