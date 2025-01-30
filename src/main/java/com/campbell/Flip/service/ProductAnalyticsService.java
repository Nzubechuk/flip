package com.campbell.Flip.service;

import com.campbell.Flip.entities.Product;
import com.campbell.Flip.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.stream.Collectors;

@Service
public class ProductAnalyticsService {

    @Autowired
    private ProductRepository productRepository;

    public List<Map<String, Object>> getFilteredLowStockProducts(int threshold) {
        return productRepository.findAll().stream()
                .filter(product -> product.getStock() < threshold)
                .map(product -> {
                    Map<String, Object> productData = new HashMap<>();
                    productData.put("name", product.getName());
                    productData.put("stock", product.getStock());
                    productData.put("price", product.getPrice());
                    return productData;
                })
                .collect(Collectors.toList());
    }

    public List<Map<String, Object>> getFilteredMostStockedProducts() {
        return productRepository.findAll().stream()
                .sorted((p1, p2) -> Integer.compare(p2.getStock(), p1.getStock()))
                .limit(5)
                .map(product -> {
                    Map<String, Object> productData = new HashMap<>();
                    productData.put("name", product.getName());
                    productData.put("stock", product.getStock());
                    productData.put("price", product.getPrice());
                    return productData;
                })
                .collect(Collectors.toList());
    }
}
