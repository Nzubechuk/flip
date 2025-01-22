package com.campbell.Flip;

import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import java.util.Base64;

public class SecretKeyGenerator {
    public static void main(String[] args) throws Exception {
        // Specify the algorithm (e.g., AES)
        KeyGenerator keyGenerator = KeyGenerator.getInstance("AES");

        // Specify the key size (128, 192, or 256 bits for AES)
        keyGenerator.init(256); // 256-bit key for AES

        // Generate the key
        SecretKey secretKey = keyGenerator.generateKey();

        // Convert the key to a Base64 string for storage
        String encodedKey = Base64.getEncoder().encodeToString(secretKey.getEncoded());
        System.out.println("Generated Secret Key: " + encodedKey);
    }
}

