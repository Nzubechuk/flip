package com.campbell.Flip.service;

import com.campbell.Flip.repository.DebtRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Component
public class DebtCleanupTask {

    @Autowired
    private DebtRepository debtRepository;

    /**
     * Runs every hour to clean up debts marked as PAID or RETURNED older than 24 hours.
     * 3600000 ms = 1 hour
     */
    @Scheduled(fixedRate = 3600000)
    public void cleanupOldDebts() {
        LocalDateTime cutoff = LocalDateTime.now().minusHours(24);
        var debtsToDelete = debtRepository.findByStatusNotAndUpdatedAtBefore(com.campbell.Flip.entities.DebtStatus.PENDING, cutoff);
        if (!debtsToDelete.isEmpty()) {
            debtRepository.deleteAll(debtsToDelete);
            System.out.println("Ran debt cleanup task at " + LocalDateTime.now() + ". Deleted " + debtsToDelete.size() + " old debts. Cutoff: " + cutoff);
        }
    }
}
