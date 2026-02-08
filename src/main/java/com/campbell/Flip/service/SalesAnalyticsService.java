package com.campbell.Flip.service;

import com.campbell.Flip.entities.Sale;
import com.campbell.Flip.entities.SaleItem;
import com.campbell.Flip.repository.SalesRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class SalesAnalyticsService {

    @Autowired
    private SalesRepository saleRepository;

    public double getTotalRevenue(LocalDate startDate, LocalDate endDate, UUID businessId, UUID branchId) {
        List<Sale> sales;
        if (branchId != null) {
            sales = saleRepository.findByBranchIdAndSaleDateBetween(branchId, startDate.atStartOfDay(), endDate.atTime(23, 59));
        } else {
            sales = saleRepository.findByBusinessIdAndSaleDateBetween(businessId, startDate.atStartOfDay(), endDate.atTime(23, 59));
        }
        return sales.stream().mapToDouble(Sale::getTotalPrice).sum();
    }

    public long getTotalTransactions(LocalDate startDate, LocalDate endDate, UUID businessId, UUID branchId) {
        if (branchId != null) {
            return saleRepository.countByBranchIdAndSaleDateBetween(branchId, startDate.atStartOfDay(), endDate.atTime(23, 59));
        }
        return saleRepository.countByBusinessIdAndSaleDateBetween(businessId, startDate.atStartOfDay(), endDate.atTime(23, 59));
    }

    public List<Map<String, Object>> getTotalTransactionsDetails(LocalDate startDate, LocalDate endDate, UUID businessId, UUID branchId) {
        List<Sale> sales;
        if (branchId != null) {
            sales = saleRepository.findByBranchIdAndSaleDateBetween(branchId, startDate.atStartOfDay(), endDate.atTime(23, 59));
        } else {
            sales = saleRepository.findByBusinessIdAndSaleDateBetween(businessId, startDate.atStartOfDay(), endDate.atTime(23, 59));
        }

        List<Map<String, Object>> transactionDetails = sales.stream()
                .flatMap(sale -> sale.getItems().stream())
                .map(item -> {
                    Map<String, Object> data = new HashMap<>();
                    data.put("product", item.getName());
                    data.put("quantity", item.getQuantity());
                    return data;
                })
                .collect(Collectors.toList());

        // Add total count at the end
        Map<String, Object> totalCount = new HashMap<>();
        totalCount.put("total_products", transactionDetails.size());
        transactionDetails.add(totalCount);

        return transactionDetails;
    }

    public List<Map<String, Object>> getBestSellingProducts(LocalDate startDate, LocalDate endDate, UUID businessId, UUID branchId) {
        List<Sale> sales;
        if (branchId != null) {
            sales = saleRepository.findByBranchIdAndSaleDateBetween(branchId, startDate.atStartOfDay(), endDate.atTime(23, 59));
        } else {
            sales = saleRepository.findByBusinessIdAndSaleDateBetween(businessId, startDate.atStartOfDay(), endDate.atTime(23, 59));
        }

        return sales.stream()
                .flatMap(sale -> sale.getItems().stream())
                .filter(item -> item.getProductCode() != null) // ✅ Ensure no null product codes
                .collect(Collectors.groupingBy(
                        SaleItem::getName,
                        Collectors.summingLong(SaleItem::getQuantity)
                ))
                .entrySet().stream()
                .map(entry -> {
                    Map<String, Object> productData = new HashMap<>();
                    productData.put("product", entry.getKey());
                    productData.put("quantity", entry.getValue());
                    return productData;
                })
                .collect(Collectors.toList());
    }
}
