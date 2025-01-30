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
        Product product = productService.getProductCode(request.getProductCode());
        if (product == null || product.getStock() < request.getQuantity()) {
            return ResponseEntity.badRequest().body("Product not available or insufficient stock.");
        }

        Map<String, Object> response = new HashMap<>();
        response.put("name", product.getName());
        response.put("price", product.getPrice());
        response.put("productCode", product.getProductCode());
        return ResponseEntity.ok(response);
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
