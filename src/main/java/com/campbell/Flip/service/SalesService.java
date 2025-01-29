package com.campbell.Flip.service;

import com.campbell.Flip.dto.SaleRequest;
import com.campbell.Flip.entities.Product;
import com.campbell.Flip.entities.Sale;
import com.campbell.Flip.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
public class SalesService {

    @Autowired
    private ProductRepository productRepository;

    public Sale processSale(SaleRequest saleRequest) {
        List<Sale.SaleItem> saleItems = new ArrayList<>();
        double totalPrice = 0;

        for (SaleRequest.SaleItem item : saleRequest.getItems()) {
            // Properly handle Optional<Product>
            Product product = productRepository.findByProductCode(item.getProductCode())
                    .orElseThrow(() -> new IllegalArgumentException("Product not found with code: " + item.getProductCode()));

            // Check stock availability
            if (product.getStock() < item.getQuantity()) {
                throw new IllegalArgumentException("Insufficient stock for product code: " + item.getProductCode());
            }

            // Deduct stock
            product.setStock(product.getStock() - item.getQuantity());
            productRepository.save(product);

            // Add to sale items
            Sale.SaleItem saleItem = new Sale.SaleItem();
            saleItem.setProductCode(product.getProductCode());
            saleItem.setName(product.getName()); // Optional: Include product name
            saleItem.setQuantity(item.getQuantity());
            saleItems.add(saleItem);

            // Update total price
            totalPrice += product.getPrice() * item.getQuantity();
        }

        // Create and return sale
        Sale sale = new Sale();
        sale.setItems(saleItems);
        sale.setTotalPrice(totalPrice);
        sale.setSaleDate(LocalDateTime.now());
        return sale;
    }
}
