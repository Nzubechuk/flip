package com.campbell.Flip.controllers;

import com.campbell.Flip.entities.Business;
import com.campbell.Flip.entities.Receipt;
import com.campbell.Flip.repository.BusinessRepository;
import com.campbell.Flip.repository.ReceiptRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@CrossOrigin(origins = "http://localhost:5173")
@RestController
@RequestMapping("/api/receipts")
public class ReceiptController {

    @Autowired
    private ReceiptRepository receiptRepository;

    @Autowired
    private BusinessRepository businessRepository;

    @PostMapping("/{businessId}")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<?> addReceipt(@PathVariable UUID businessId, @RequestBody Map<String, Object> payload) {
        Optional<Business> businessOptional = businessRepository.findById(businessId);
        if (businessOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Business not found");
        }

        String description = (String) payload.get("description");
        Object amountObj = payload.get("amount");
        String supplier = (String) payload.get("supplier");

        if (description == null || description.trim().isEmpty()) {
            return ResponseEntity.badRequest().body("Description is required");
        }
        if (amountObj == null) {
            return ResponseEntity.badRequest().body("Amount is required");
        }

        Double amount;
        if (amountObj instanceof Integer) {
            amount = ((Integer) amountObj).doubleValue();
        } else if (amountObj instanceof Double) {
            amount = (Double) amountObj;
        } else {
             return ResponseEntity.badRequest().body("Invalid amount format");
        }

        Receipt receipt = new Receipt();
        receipt.setDescription(description);
        receipt.setAmount(amount);
        receipt.setSupplier(supplier);
        receipt.setBusiness(businessOptional.get());
        receipt.setRecordedBy("CEO"); // Since only CEO can access this for now

        receiptRepository.save(receipt);

        return ResponseEntity.ok(Map.of("message", "Receipt recorded successfully"));
    }

    @GetMapping("/{businessId}")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<?> getReceipts(@PathVariable UUID businessId) {
        Optional<Business> businessOptional = businessRepository.findById(businessId);
        if (businessOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Business not found");
        }

        List<Receipt> receipts = receiptRepository.findAllByBusinessOrderByReceiptDateDesc(businessOptional.get());
        return ResponseEntity.ok(receipts);
    }
}
