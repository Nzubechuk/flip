package com.campbell.Flip.repository;

import com.campbell.Flip.entities.Branch;
import com.campbell.Flip.entities.Product;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ProductRepository extends JpaRepository<Product, UUID> {
    List<Product> findByBranch(Branch branch);
    Optional<Product> findByProductCode(String productCode);
    Optional<Product> findByUpc(String upc);
    Optional<Product> findByEan13(String ean13);
}
