package com.campbell.Flip.service;

import com.campbell.Flip.entities.Product;
import com.campbell.Flip.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class ProductService {

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private QRCodeService qrCodeService;


    public String generateProductQRCode(Long productId) throws Exception {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new IllegalArgumentException("Product not found with ID: " + productId));

        if (product.getProductCode() == null || product.getProductCode().isEmpty()) {
            throw new IllegalArgumentException("Product code cannot be null or empty");
        }

        return qrCodeService.generateQRCode(product.getName(), product.getProductCode());
    }

    public Product updateStock(Long productId, int quantitySold) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new IllegalArgumentException("Product not found with ID: " + productId));

        if (quantitySold < 0) {
            throw new IllegalArgumentException("Quantity sold cannot be negative");
        }

        if (product.getStock() < quantitySold) {
            throw new IllegalArgumentException("Insufficient stock for product: " + product.getName());
        }

        product.setStock(product.getStock() - quantitySold);
        return productRepository.save(product);
    }

    public Product getProductCode(String productCode) {
        if (productCode == null || productCode.trim().isEmpty()) {
            throw new IllegalArgumentException("Product code cannot be null or empty");
        }

        return productRepository.findByProductCode(productCode)
                .orElseThrow(() -> new RuntimeException("Product not found with code: " + productCode));
    }
}
