package com.campbell.Flip.controllers;

import com.campbell.Flip.entities.Debt;
import com.campbell.Flip.entities.DebtItem;
import com.campbell.Flip.service.DebtService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/debts")
public class DebtController {

    @Autowired
    private DebtService debtService;

    @PostMapping("/record")
    public ResponseEntity<Map<String, Object>> recordDebt(@RequestBody Map<String, Object> request) {
        String consumerName = (String) request.get("consumerName");
        List<Map<String, Object>> itemsData = (List<Map<String, Object>>) request.get("items");
        UUID branchId = UUID.fromString((String) request.get("branchId"));
        UUID businessId = UUID.fromString((String) request.get("businessId"));

        List<DebtItem> items = itemsData.stream().map(data -> {
            DebtItem item = new DebtItem();
            item.setName((String) data.get("name"));
            item.setProductCode((String) data.get("productCode"));
            Object quantityObj = data.get("quantity");
            if (quantityObj instanceof Number) {
                item.setQuantity(((Number) quantityObj).intValue());
            } else if (quantityObj instanceof String) {
                item.setQuantity(Integer.parseInt((String) quantityObj));
            }
            return item;
        }).toList();

        Debt savedDebt = debtService.recordDebt(consumerName, items, branchId, businessId);
        return ResponseEntity.ok(debtToMap(savedDebt));
    }

    @PostMapping("/{id}/paid")
    public ResponseEntity<Map<String, Object>> markAsPaid(@PathVariable UUID id) {
        Debt debt = debtService.markAsPaid(id);
        return ResponseEntity.ok(debtToMap(debt));
    }

    @PostMapping("/{id}/return")
    public ResponseEntity<Map<String, Object>> returnDebt(@PathVariable UUID id) {
        Debt debt = debtService.returnDebt(id);
        return ResponseEntity.ok(debtToMap(debt));
    }

    private Map<String, Object> debtToMap(Debt debt) {
        Map<String, Object> map = new java.util.HashMap<>();
        map.put("id", debt.getId());
        map.put("consumerName", debt.getConsumerName());
        map.put("totalAmount", debt.getTotalAmount());
        map.put("status", debt.getStatus());
        map.put("createdAt", debt.getCreatedAt());
        
        List<Map<String, Object>> items = debt.getItems().stream().map(item -> {
            Map<String, Object> itemMap = new java.util.HashMap<>();
            itemMap.put("id", item.getId());
            itemMap.put("name", item.getName());
            itemMap.put("productCode", item.getProductCode());
            itemMap.put("quantity", item.getQuantity());
            itemMap.put("price", item.getPrice());
            return itemMap;
        }).toList();
        map.put("items", items);

        if (debt.getBranch() != null) {
            Map<String, Object> branchMap = new java.util.HashMap<>();
            branchMap.put("id", debt.getBranch().getId());
            branchMap.put("name", debt.getBranch().getName());
            map.put("branch", branchMap);
        }

        if (debt.getBusiness() != null) {
            Map<String, Object> businessMap = new java.util.HashMap<>();
            businessMap.put("id", debt.getBusiness().getId());
            businessMap.put("name", debt.getBusiness().getName());
            map.put("business", businessMap);
        }

        return map;
    }

    @GetMapping("/business/{businessId}")
    public ResponseEntity<List<Map<String, Object>>> getDebtsByBusiness(@PathVariable UUID businessId) {
        List<Debt> debts = debtService.getDebtsByBusiness(businessId);
        return ResponseEntity.ok(debts.stream().map(this::debtToMap).toList());
    }

    @GetMapping("/branch/{branchId}")
    public ResponseEntity<List<Map<String, Object>>> getDebtsByBranch(@PathVariable UUID branchId) {
        List<Debt> debts = debtService.getDebtsByBranch(branchId);
        return ResponseEntity.ok(debts.stream().map(this::debtToMap).toList());
    }
}
