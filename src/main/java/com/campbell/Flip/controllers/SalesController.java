package com.campbell.Flip.controllers;

import com.campbell.Flip.dto.ScannedProductRequest;
import com.campbell.Flip.dto.SaleRequest;
import com.campbell.Flip.entities.Product;
import com.campbell.Flip.entities.Sale;
import com.campbell.Flip.service.ProductService;
import com.campbell.Flip.service.SalesService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/sales")
public class SalesController {

    @Autowired
    private ProductService productService;

    @Autowired
    private SalesService salesService;

    @PostMapping("/scan")
    public ResponseEntity<?> addProductToCart(@RequestBody ScannedProductRequest request) {
        try {
            Product product;
            
            // Try to find product by barcode first (UPC/EAN-13), then by product code
            String identifier = request.getProductCode();
            if (identifier == null || identifier.trim().isEmpty()) {
                return ResponseEntity.badRequest().body("Product code or barcode is required");
            }

            // Check if it's a barcode (12 or 13 digits)
            String normalized = identifier.replaceAll("[^0-9]", "");
            if (normalized.length() == 12 || normalized.length() == 13) {
                // It's a barcode (UPC or EAN-13)
                product = productService.getProductByBarcode(identifier);
            } else {
                // It's a product code
                product = productService.getProductCode(identifier);
            }

            if (product == null || product.getStock() < request.getQuantity()) {
                return ResponseEntity.badRequest().body("Product not available or insufficient stock.");
            }

            Map<String, Object> response = new HashMap<>();
            response.put("productId", product.getId());
            response.put("name", product.getName());
            response.put("price", product.getPrice());
            response.put("productCode", product.getProductCode());
            response.put("upc", product.getUpc());
            response.put("ean13", product.getEan13());
            response.put("stock", product.getStock());
            return ResponseEntity.ok(response);
        } catch (com.campbell.Flip.service.ProductService.ProductNotFoundException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error scanning product: " + e.getMessage());
        }
    }

    @PostMapping("/finalize")
    public ResponseEntity<Map<String, Object>> finalizeSale(@RequestBody SaleRequest saleRequest) {
        Sale sale = salesService.processSale(saleRequest);

        // Extract item names from the sale object
        List<String> itemNames = sale.getItems().stream()
                .map(item -> item.getName()) // Assuming SaleItem has a getName() method
                .toList();

        Map<String, Object> response = new HashMap<>();
        response.put("totalPrice", sale.getTotalPrice());
        response.put("items", itemNames);
        response.put("date", sale.getSaleDate());

        return ResponseEntity.ok(response);
    }



}
