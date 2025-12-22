package com.campbell.Flip.repository;

import com.campbell.Flip.entities.Branch;
import com.campbell.Flip.entities.Business;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BranchRepository extends JpaRepository<Branch, UUID> {
    List<Branch> findAllByBusiness(Business business);
    Optional<Branch> findByNameAndBusiness(String name, Business business);
}
