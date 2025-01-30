package com.campbell.Flip.repository;

import com.campbell.Flip.entities.Sale;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface SalesRepository extends JpaRepository<Sale, Long> {

    List<Sale> findBySaleDateBetween(LocalDateTime startDate, LocalDateTime endDate);

    long countBySaleDateBetween(LocalDateTime startDate, LocalDateTime endDate);
}
