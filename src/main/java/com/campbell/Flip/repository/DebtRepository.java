package com.campbell.Flip.repository;

import com.campbell.Flip.entities.Debt;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface DebtRepository extends JpaRepository<Debt, UUID> {
    List<Debt> findByBusinessId(UUID businessId);
    List<Debt> findByBranchId(UUID branchId);
    
    List<Debt> findByStatusNotAndUpdatedAtBefore(com.campbell.Flip.entities.DebtStatus status, java.time.LocalDateTime cutoff);
}
