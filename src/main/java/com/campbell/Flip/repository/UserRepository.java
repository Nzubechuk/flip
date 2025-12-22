package com.campbell.Flip.repository;

import com.campbell.Flip.entities.Business;
import com.campbell.Flip.entities.Role;
import com.campbell.Flip.entities.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);
    List<User> findAllByBusinessAndRole(Business business, Role role);
}
