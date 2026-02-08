package com.campbell.Flip.service;

import com.campbell.Flip.entities.Product;
import com.campbell.Flip.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Service
public class ProductAnalyticsService {

    @Autowired
    private ProductRepository productRepository;

    public List<Map<String, Object>> getFilteredLowStockProducts(int threshold, UUID businessId, UUID branchId) {
        List<Product> products;
        if (branchId != null) {
            products = productRepository.findByBranchId(branchId);
        } else {
            products = productRepository.findByBusinessId(businessId);
        }

        return products.stream()
                .filter(product -> product.getStock() < threshold)
                .map(product -> {
                    Map<String, Object> productData = new HashMap<>();
                    productData.put("product", product.getName());
                    productData.put("stock", product.getStock());
                    productData.put("price", product.getPrice());
                    productData.put("branch", product.getBranch() != null ? product.getBranch().getName() : "Unknown");
                    return productData;
                })
                .collect(Collectors.toList());
    }

    public List<Map<String, Object>> getFilteredMostStockedProducts(UUID businessId, UUID branchId) {
        List<Product> products;
        if (branchId != null) {
            products = productRepository.findByBranchId(branchId);
        } else {
            products = productRepository.findByBusinessId(businessId);
        }

        return products.stream()
                .sorted((p1, p2) -> Integer.compare(p2.getStock(), p1.getStock()))
                .limit(5)
                .map(product -> {
                    Map<String, Object> productData = new HashMap<>();
                    productData.put("product", product.getName());
                    productData.put("stock", product.getStock());
                    productData.put("price", product.getPrice());
                    productData.put("branch", product.getBranch() != null ? product.getBranch().getName() : "Unknown");
                    return productData;
                })
                .collect(Collectors.toList());
    }
}
