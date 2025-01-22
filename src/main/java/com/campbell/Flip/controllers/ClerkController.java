package com.campbell.Flip.controllers;

import com.campbell.Flip.dto.WorkerDTO;
import com.campbell.Flip.entities.Branch;
import com.campbell.Flip.entities.Role;
import com.campbell.Flip.entities.User;
import com.campbell.Flip.repository.BranchRepository;
import com.campbell.Flip.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.Optional;

@RestController
@RequestMapping("/api/clerks")
public class ClerkController {

    private final UserRepository userRepository;
    private final BranchRepository branchRepository;
    private final PasswordEncoder passwordEncoder;

    public ClerkController(UserRepository userRepository, BranchRepository branchRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.branchRepository = branchRepository;
        this.passwordEncoder = passwordEncoder;
    }

    // Add Clerk
    @PostMapping("/branches/{branchId}/add")
    @PreAuthorize("hasRole('MANAGER')")
    public ResponseEntity<?> addClerk(@PathVariable Long branchId, @RequestBody WorkerDTO clerkDTO, Principal principal) {
        Optional<Branch> branchOptional = branchRepository.findById(branchId);

        if (branchOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Branch not found");
        }

        Branch branch = branchOptional.get();
        if (!branch.getManager().getUsername().equals(principal.getName())) {
            return ResponseEntity.status(403).body("Unauthorized to add clerks to this branch");
        }

        if (clerkDTO.getUsername() == null || clerkDTO.getPassword() == null) {
            return ResponseEntity.badRequest().body("Clerk details are incomplete");
        }

        User clerk = new User();
        clerk.setUsername(clerkDTO.getUsername());
        clerk.setPassword(passwordEncoder.encode(clerkDTO.getPassword())); // Set encoded password
        clerk.setRole(Role.CLERK);
        clerk.setBranch(branch);

        userRepository.save(clerk);
        return ResponseEntity.ok("Clerk added successfully");
    }

    // Update Clerk
    @PutMapping("/{clerkId}/update")
    @PreAuthorize("hasRole('MANAGER')")
    public ResponseEntity<?> updateClerk(@PathVariable Long clerkId, @RequestBody WorkerDTO clerkDTO, Principal principal) {
        Optional<User> clerkOptional = userRepository.findById(clerkId);

        if (clerkOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Clerk not found");
        }

        User clerk = clerkOptional.get();
        if (!clerk.getBranch().getManager().getUsername().equals(principal.getName())) {
            return ResponseEntity.status(403).body("Unauthorized to update this clerk");
        }

        clerk.setUsername(clerkDTO.getUsername());
        userRepository.save(clerk);
        return ResponseEntity.ok("Clerk updated successfully");
    }

    // Delete Clerk
    @DeleteMapping("/{clerkId}/delete")
    @PreAuthorize("hasRole('MANAGER')")
    public ResponseEntity<?> deleteClerk(@PathVariable Long clerkId, Principal principal) {
        Optional<User> clerkOptional = userRepository.findById(clerkId);

        if (clerkOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Clerk not found");
        }

        User clerk = clerkOptional.get();
        if (!clerk.getBranch().getManager().getUsername().equals(principal.getName())) {
            return ResponseEntity.status(403).body("Unauthorized to delete this clerk");
        }

        userRepository.delete(clerk);
        return ResponseEntity.ok("Clerk deleted successfully");
    }
}
