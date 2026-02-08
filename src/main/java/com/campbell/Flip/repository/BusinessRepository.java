package com.campbell.Flip.repository;

import com.campbell.Flip.entities.Business;
import com.campbell.Flip.entities.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface BusinessRepository extends JpaRepository<Business, UUID> {
    Optional<Business> findByName(String name);
    Optional<Business> findByCeo(User ceo);
}
