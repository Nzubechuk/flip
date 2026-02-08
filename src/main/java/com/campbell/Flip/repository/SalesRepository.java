package com.campbell.Flip.repository;

import com.campbell.Flip.entities.Sale;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface SalesRepository extends JpaRepository<Sale, UUID> {

    List<Sale> findBySaleDateBetween(LocalDateTime startDate, LocalDateTime endDate);

    List<Sale> findByBranchIdAndSaleDateBetween(UUID branchId, LocalDateTime startDate, LocalDateTime endDate);

    List<Sale> findByBusinessIdAndSaleDateBetween(UUID businessId, LocalDateTime startDate, LocalDateTime endDate);

    long countBySaleDateBetween(LocalDateTime startDate, LocalDateTime endDate);

    long countByBranchIdAndSaleDateBetween(UUID branchId, LocalDateTime startDate, LocalDateTime endDate);

    long countByBusinessIdAndSaleDateBetween(UUID businessId, LocalDateTime startDate, LocalDateTime endDate);
}
