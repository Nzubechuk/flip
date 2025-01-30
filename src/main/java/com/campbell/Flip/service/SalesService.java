package com.campbell.Flip.service;

import com.campbell.Flip.dto.SaleRequest;
import com.campbell.Flip.entities.Product;
import com.campbell.Flip.entities.Sale;
import com.campbell.Flip.entities.SaleItem;
import com.campbell.Flip.repository.ProductRepository;
import com.campbell.Flip.repository.SalesRepository;
import com.campbell.Flip.repository.SaleItemRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
public class SalesService {

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private SalesRepository salesRepository;

    @Autowired
    private SaleItemRepository saleItemRepository;

    public Sale processSale(SaleRequest saleRequest) {
        List<SaleItem> saleItems = new ArrayList<>();
        double totalPrice = 0;

        // ✅ Create Sale first
        Sale sale = new Sale();
        sale.setSaleDate(LocalDateTime.now());

        for (SaleRequest.SaleItem item : saleRequest.getItems()) {
            Product product = productRepository.findByProductCode(item.getProductCode())
                    .orElseThrow(() -> new IllegalArgumentException("Product not found: " + item.getProductCode()));

            if (product.getStock() < item.getQuantity()) {
                throw new IllegalArgumentException("Insufficient stock for product: " + product.getProductCode());
            }

            // Deduct stock
            product.setStock(product.getStock() - item.getQuantity());
            productRepository.save(product);

            // ✅ Create SaleItem and associate it with Sale
            SaleItem saleItem = new SaleItem();
            saleItem.setProductCode(product.getProductCode());
            saleItem.setName(product.getName());
            saleItem.setQuantity(item.getQuantity());
            saleItem.setPrice(product.getPrice());
            saleItem.setSale(sale); // ✅ Associate with Sale

            saleItems.add(saleItem);

            // Update total price
            totalPrice += product.getPrice() * item.getQuantity();
        }

        // ✅ Save Sale
        sale.setItems(saleItems);
        sale.setTotalPrice(totalPrice);
        sale = salesRepository.save(sale); // Save Sale first to generate an ID

        // ✅ Save SaleItems after Sale is persisted
        saleItemRepository.saveAll(saleItems);

        return sale;
    }
}
