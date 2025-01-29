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
    public ResponseEntity<?> finalizeSale(@RequestBody SaleRequest saleRequest) {
        Sale sale = salesService.processSale(saleRequest);

        Map<String, Object> receipt = new HashMap<>();
        receipt.put("totalPrice", sale.getTotalPrice());
        receipt.put("items", sale.getItems());
        receipt.put("date", sale.getSaleDate());
        return ResponseEntity.ok(receipt);
    }
}
