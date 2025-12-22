package com.campbell.Flip.controllers;

import com.campbell.Flip.service.ProductAnalyticsService;
import com.campbell.Flip.service.SalesAnalyticsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/analytics")
public class AnalyticsController {

    @Autowired
    private SalesAnalyticsService salesAnalyticsService;

    @Autowired
    private ProductAnalyticsService productAnalyticsService;

    @GetMapping("/sales/revenue")
    public ResponseEntity<Double> getTotalRevenue(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return ResponseEntity.ok(salesAnalyticsService.getTotalRevenue(startDate, endDate));
    }

    @GetMapping("/sales/transactions")
    public ResponseEntity<List<Map<String, Object>>> getTotalTransactions(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {

        List<Map<String, Object>> transactionsData = salesAnalyticsService.getTotalTransactionsDetails(startDate, endDate);
        return ResponseEntity.ok(transactionsData);
    }

    @GetMapping("/sales/best-selling")
    public ResponseEntity<List<Map<String, Object>>> getBestSellingProducts(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {

        List<Map<String, Object>> bestSellingProducts = salesAnalyticsService.getBestSellingProducts(startDate, endDate);
        return ResponseEntity.ok(bestSellingProducts);
    }

    @GetMapping("/products/low-stock")
    public ResponseEntity<List<Map<String, Object>>> getLowStockProducts(@RequestParam int threshold) {
        List<Map<String, Object>> lowStockProducts = productAnalyticsService.getFilteredLowStockProducts(threshold);
        return ResponseEntity.ok(lowStockProducts);
    }

    @GetMapping("/products/most-stocked")
    public ResponseEntity<List<Map<String, Object>>> getMostStockedProducts() {
        List<Map<String, Object>> mostStockedProducts = productAnalyticsService.getFilteredMostStockedProducts();
        return ResponseEntity.ok(mostStockedProducts);
    }
}
