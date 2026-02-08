package com.campbell.Flip.service;

import com.campbell.Flip.entities.*;
import com.campbell.Flip.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class DebtService {

    @Autowired
    private DebtRepository debtRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private SalesRepository salesRepository;

    @Autowired
    private SaleItemRepository saleItemRepository;

    @Autowired
    private BranchRepository branchRepository;

    @Autowired
    private BusinessRepository businessRepository;

    @Transactional
    public Debt recordDebt(String consumerName, List<DebtItem> items, UUID branchId, UUID businessId) {
        Debt debt = new Debt();
        debt.setConsumerName(consumerName);
        debt.setStatus(DebtStatus.PENDING);
        
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new IllegalArgumentException("Branch not found"));
        debt.setBranch(branch);
        
        Business business = businessRepository.findById(businessId)
                .orElseThrow(() -> new IllegalArgumentException("Business not found"));
        debt.setBusiness(business);

        double totalAmount = 0;
        for (DebtItem item : items) {
            Product product = productRepository.findByProductCode(item.getProductCode())
                    .orElseThrow(() -> new IllegalArgumentException("Product not found: " + item.getProductCode()));

            if (product.getStock() < item.getQuantity()) {
                throw new IllegalArgumentException("Insufficient stock for product: " + product.getName());
            }

            product.setStock(product.getStock() - item.getQuantity());
            productRepository.save(product);

            item.setPrice(product.getPrice());
            item.setDebt(debt);
            totalAmount += item.getPrice() * item.getQuantity();
        }

        debt.setItems(items);
        debt.setTotalAmount(totalAmount);
        return debtRepository.save(debt);
    }

    @Transactional
    public Debt markAsPaid(UUID debtId) {
        Debt debt = debtRepository.findById(debtId)
                .orElseThrow(() -> new IllegalArgumentException("Debt not found: " + debtId));

        if (debt.getStatus() != DebtStatus.PENDING) {
            throw new IllegalStateException("Debt is already " + debt.getStatus());
        }

        // Create a Sale record
        Sale sale = new Sale();
        sale.setSaleDate(LocalDateTime.now());
        sale.setTotalPrice(debt.getTotalAmount());
        sale.setBranch(debt.getBranch());
        sale.setBusiness(debt.getBusiness());

        List<SaleItem> saleItems = new ArrayList<>();
        for (DebtItem debtItem : debt.getItems()) {
            SaleItem saleItem = new SaleItem();
            saleItem.setProductCode(debtItem.getProductCode());
            saleItem.setName(debtItem.getName());
            saleItem.setQuantity(debtItem.getQuantity());
            saleItem.setPrice(debtItem.getPrice());
            saleItem.setSale(sale);
            saleItems.add(saleItem);
        }

        sale.setItems(saleItems);
        salesRepository.save(sale);
        saleItemRepository.saveAll(saleItems);

        debt.setStatus(DebtStatus.PAID);
        return debtRepository.save(debt);
    }

    @Transactional
    public Debt returnDebt(UUID debtId) {
        Debt debt = debtRepository.findById(debtId)
                .orElseThrow(() -> new IllegalArgumentException("Debt not found: " + debtId));

        if (debt.getStatus() != DebtStatus.PENDING) {
            throw new IllegalStateException("Debt is already " + debt.getStatus());
        }

        // Restore stock
        for (DebtItem debtItem : debt.getItems()) {
            Product product = productRepository.findByProductCode(debtItem.getProductCode())
                    .orElseThrow(() -> new IllegalArgumentException("Product not found: " + debtItem.getProductCode()));
            
            product.setStock(product.getStock() + debtItem.getQuantity());
            productRepository.save(product);
        }

        debt.setStatus(DebtStatus.RETURNED);
        return debtRepository.save(debt);
    }

    public List<Debt> getDebtsByBusiness(UUID businessId) {
        return debtRepository.findByBusinessId(businessId);
    }

    public List<Debt> getDebtsByBranch(UUID branchId) {
        return debtRepository.findByBranchId(branchId);
    }
}
