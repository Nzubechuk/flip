package com.campbell.Flip.repository;

import com.campbell.Flip.entities.Branch;
import com.campbell.Flip.entities.Product;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ProductRepository extends JpaRepository<Product, Long> {
    List<Product> findByBranch(Branch branch);
    Optional<Product> findByProductCode (String productCode);

}
