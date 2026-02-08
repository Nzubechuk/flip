package com.campbell.Flip.repository;

import com.campbell.Flip.entities.Business;
import com.campbell.Flip.entities.Receipt;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ReceiptRepository extends JpaRepository<Receipt, UUID> {
    List<Receipt> findAllByBusinessOrderByReceiptDateDesc(Business business);
}
