package com.campbell.Flip.repository;

import com.campbell.Flip.entities.Organization;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface OrganizationRepository extends JpaRepository<Organization, String> {
    Optional<Organization> findByApiKey(String apiKey);
    Optional<Organization> findByEmail(String email);
}
