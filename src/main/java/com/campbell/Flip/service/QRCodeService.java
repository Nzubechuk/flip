package com.campbell.Flip.service;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import org.springframework.stereotype.Service;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

@Service
public class QRCodeService {

    public String generateQRCode(String name, String productCode) throws Exception {

        if (name == null || name.trim().isEmpty()) {
            throw new IllegalArgumentException("Product name cannot be null or empty.");
        }
        if (productCode == null || productCode.trim().isEmpty()) {
            throw new IllegalArgumentException("Product code cannot be null or empty.");
        }

        try {

            Path directoryPath = Paths.get("qrcodes");
            if (!Files.exists(directoryPath)) {
                Files.createDirectories(directoryPath);
            }

            String qrContent = "Product Name: " + name + ", Product Code: " + productCode;

            QRCodeWriter qrCodeWriter = new QRCodeWriter();
            BitMatrix bitMatrix = qrCodeWriter.encode(qrContent, BarcodeFormat.QR_CODE, 300, 300);

            String sanitizedName = name.replaceAll("[^a-zA-Z0-9_-]", "_"); // Sanitize name for file compatibility
            String fileName = sanitizedName + "_" + productCode + ".png"; // Add product code for uniqueness
            Path filePath = directoryPath.resolve(fileName);

            MatrixToImageWriter.writeToPath(bitMatrix, "PNG", filePath);

            return filePath.toString();
        } catch (Exception e) {
            throw new Exception("Failed to generate QR code for product: " + name + " (" + productCode + ")", e);
        }
    }
}
