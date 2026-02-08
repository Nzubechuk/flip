package com.campbell.Flip.controllers;

import com.campbell.Flip.entities.Role;
import com.campbell.Flip.entities.User;
import com.campbell.Flip.repository.UserRepository;
import com.campbell.Flip.service.ProductAnalyticsService;
import com.campbell.Flip.service.SalesAnalyticsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/analytics")
public class AnalyticsController {

    @Autowired
    private SalesAnalyticsService salesAnalyticsService;

    @Autowired
    private ProductAnalyticsService productAnalyticsService;

    @Autowired
    private UserRepository userRepository;

    @GetMapping("/sales/revenue")
    @PreAuthorize("hasAnyRole('MANAGER', 'CEO')")
    public ResponseEntity<?> getTotalRevenue(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) UUID branchId,
            Principal principal) {
        
        User user = getUser(principal);
        if (user.getBusiness() == null) {
            return ResponseEntity.badRequest().body("User is not associated with any business");
        }
        UUID businessId = user.getBusiness().getId();
        UUID effectiveBranchId = getEffectiveBranchId(user, branchId);

        return ResponseEntity.ok(salesAnalyticsService.getTotalRevenue(startDate, endDate, businessId, effectiveBranchId));
    }

    @GetMapping("/sales/transactions")
    @PreAuthorize("hasAnyRole('MANAGER', 'CEO')")
    public ResponseEntity<?> getTotalTransactions(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) UUID branchId,
            Principal principal) {

        User user = getUser(principal);
        if (user.getBusiness() == null) {
            return ResponseEntity.badRequest().body("User is not associated with any business");
        }
        UUID businessId = user.getBusiness().getId();
        UUID effectiveBranchId = getEffectiveBranchId(user, branchId);

        List<Map<String, Object>> transactionsData = salesAnalyticsService.getTotalTransactionsDetails(startDate, endDate, businessId, effectiveBranchId);
        return ResponseEntity.ok(transactionsData);
    }

    @GetMapping("/sales/best-selling")
    @PreAuthorize("hasAnyRole('MANAGER', 'CEO')")
    public ResponseEntity<?> getBestSellingProducts(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) UUID branchId,
            Principal principal) {

        User user = getUser(principal);
        if (user.getBusiness() == null) {
            return ResponseEntity.badRequest().body("User is not associated with any business");
        }
        UUID businessId = user.getBusiness().getId();
        UUID effectiveBranchId = getEffectiveBranchId(user, branchId);

        List<Map<String, Object>> bestSellingProducts = salesAnalyticsService.getBestSellingProducts(startDate, endDate, businessId, effectiveBranchId);
        return ResponseEntity.ok(bestSellingProducts);
    }

    @GetMapping("/products/low-stock")
    @PreAuthorize("hasAnyRole('MANAGER', 'CEO')")
    public ResponseEntity<?> getLowStockProducts(
            @RequestParam int threshold,
            @RequestParam(required = false) UUID branchId,
            Principal principal) {
        
        User user = getUser(principal);
        if (user.getBusiness() == null) {
            return ResponseEntity.badRequest().body("User is not associated with any business");
        }
        UUID businessId = user.getBusiness().getId();
        UUID effectiveBranchId = getEffectiveBranchId(user, branchId);

        List<Map<String, Object>> lowStockProducts = productAnalyticsService.getFilteredLowStockProducts(threshold, businessId, effectiveBranchId);
        return ResponseEntity.ok(lowStockProducts);
    }

    @GetMapping("/products/most-stocked")
    @PreAuthorize("hasAnyRole('MANAGER', 'CEO')")
    public ResponseEntity<?> getMostStockedProducts(
            @RequestParam(required = false) UUID branchId,
            Principal principal) {
        
        User user = getUser(principal);
        if (user.getBusiness() == null) {
            return ResponseEntity.badRequest().body("User is not associated with any business");
        }
        UUID businessId = user.getBusiness().getId();
        UUID effectiveBranchId = getEffectiveBranchId(user, branchId);

        List<Map<String, Object>> mostStockedProducts = productAnalyticsService.getFilteredMostStockedProducts(businessId, effectiveBranchId);
        return ResponseEntity.ok(mostStockedProducts);
    }

    private User getUser(Principal principal) {
        return userRepository.findByUsername(principal.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    private UUID getEffectiveBranchId(User user, UUID requestedBranchId) {
        if (user.getRole() == Role.MANAGER) {
            return user.getBranch() != null ? user.getBranch().getId() : null; // Managers only see their branch
        }
        return requestedBranchId; // CEOs can filter by any branch in their business (enforced in service)
    }
}
