package com.campbell.Flip.controllers;

import com.campbell.Flip.dto.BusinessDto;
import com.campbell.Flip.dto.LoginRequest;
import com.campbell.Flip.dto.RefreshTokenRequest;
import com.campbell.Flip.dto.WorkerDTO;
import com.campbell.Flip.entities.Branch;
import com.campbell.Flip.entities.Business;
import com.campbell.Flip.entities.Role;
import com.campbell.Flip.entities.User;
import com.campbell.Flip.repository.*;
import com.campbell.Flip.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/business")
public class BusinessController {

    @Autowired
    private BusinessRepository businessRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private BranchRepository branchRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    @PostMapping("/register")
    public ResponseEntity<?> registerBusiness(@Validated @RequestBody BusinessDto businessDto) {
        // Validate CEO details
        if (businessDto.getCeo().getUsername() == null || businessDto.getCeo().getPassword() == null ||
                businessDto.getCeo().getFirstname() == null || businessDto.getCeo().getLastname() == null ||
                businessDto.getCeo().getEmail() == null) {
            return ResponseEntity.badRequest().body("CEO details (username, password, firstName, lastName, email) are required");
        }

        User ceo = new User();
        ceo.setUsername(businessDto.getCeo().getUsername());
        ceo.setPassword(passwordEncoder.encode(businessDto.getCeo().getPassword()));
        ceo.setFirstName(businessDto.getCeo().getFirstname());
        ceo.setLastName(businessDto.getCeo().getLastname());
        ceo.setEmail(businessDto.getCeo().getEmail());
        ceo.setRole(Role.CEO);

        Business business = new Business();
        business.setName(businessDto.getName());
        business.setBusinessRegNumber(businessDto.getBusinessRegNumber());
        business.setCeo(ceo);

        ceo.setBusiness(business);

        businessRepository.save(business);

        return ResponseEntity.ok("Business registered successfully");
    }
    @PutMapping("/{businessId}/update")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<?> updateBusiness(@PathVariable Long businessId, @RequestBody BusinessDto businessDto) {
        Optional<Business> businessOptional = businessRepository.findById(businessId);
        if (businessOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Business not found");
        }

        Business business = businessOptional.get();

        // Update business details
        if (businessDto.getName() != null) {
            business.setName(businessDto.getName());
        }
        if (businessDto.getBusinessRegNumber() != null) {
            business.setBusinessRegNumber(businessDto.getBusinessRegNumber());
        }

        businessRepository.save(business);
        return ResponseEntity.ok("Business updated successfully");
    }

    @DeleteMapping("/{businessId}/delete")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<?> deleteBusiness(@PathVariable Long businessId) {
        Optional<Business> businessOptional = businessRepository.findById(businessId);
        if (businessOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Business not found");
        }

        // Remove all branches associated with the business
        branchRepository.deleteAll(branchRepository.findAllByBusiness(businessOptional.get()));

        // Delete the business
        businessRepository.deleteById(businessId);
        return ResponseEntity.ok("Business deleted successfully");
    }

        @PostMapping("/{businessId}/branch/{branchId}/add-manager")
        @PreAuthorize("hasRole('CEO')")
        public ResponseEntity<?> addManagerToBranch(
                @PathVariable Long businessId,
                @PathVariable Long branchId,
                @RequestBody WorkerDTO managerDTO) {

            // Validate manager details
            if (managerDTO.getUsername() == null || managerDTO.getPassword() == null) {
                return ResponseEntity.badRequest().body("Manager details are incomplete");
            }

            // Validate business existence
            Optional<Business> businessOptional = businessRepository.findById(businessId);
            if (businessOptional.isEmpty()) {
                return ResponseEntity.badRequest().body("Business not found");
            }

            Business business = businessOptional.get();

            // Validate branch existence and ownership
            Optional<Branch> branchOptional = branchRepository.findById(branchId);
            if (branchOptional.isEmpty() || !branchOptional.get().getBusiness().equals(business)) {
                return ResponseEntity.badRequest().body("Branch not found or does not belong to the specified business");
            }

            Branch branch = branchOptional.get();

            // Check if username already exists
            if (userRepository.findByUsername(managerDTO.getUsername()).isPresent()) {
                return ResponseEntity.badRequest().body("Username already exists");
            }

            // Create and save the manager
            User manager = new User();
            manager.setUsername(managerDTO.getUsername());
            manager.setPassword(passwordEncoder.encode(managerDTO.getPassword()));
            manager.setRole(Role.MANAGER); // Ensure the role is set to MANAGER
            manager.setBusiness(business);
            manager.setBranch(branch);

            userRepository.save(manager);

            // Link manager to the branch
            branch.setManager(manager);
            branchRepository.save(branch);

            return ResponseEntity.ok("Manager added to branch successfully");
        }

        @PutMapping("/{businessId}/manager/{managerId}/update")
        @PreAuthorize("hasRole('CEO')")
        public ResponseEntity<?> updateManager(
                @PathVariable Long businessId,
                @PathVariable Long managerId,
                @RequestBody WorkerDTO workerDTO) {

            // Validate business existence
            Optional<Business> businessOptional = businessRepository.findById(businessId);
            if (businessOptional.isEmpty()) {
                return ResponseEntity.badRequest().body("Business not found");
            }

            // Validate manager existence and role
            Optional<User> managerOptional = userRepository.findById(managerId);
            if (managerOptional.isEmpty() || managerOptional.get().getRole() != Role.MANAGER) {
                return ResponseEntity.badRequest().body("Manager not found or invalid role");
            }

            User manager = managerOptional.get();

            // Update manager details
            if (workerDTO.getUsername() != null) {
                if (userRepository.findByUsername(workerDTO.getUsername()).isPresent() &&
                        !manager.getUsername().equals(workerDTO.getUsername())) {
                    return ResponseEntity.badRequest().body("Username already exists");
                }
                manager.setUsername(workerDTO.getUsername());
            }
            if (workerDTO.getPassword() != null) {
                manager.setPassword(passwordEncoder.encode(workerDTO.getPassword()));
            }

            userRepository.save(manager);

            return ResponseEntity.ok("Manager updated successfully");
        }

        @DeleteMapping("/{businessId}/manager/{managerId}/delete")
        @PreAuthorize("hasRole('CEO')")
        public ResponseEntity<?> deleteManager(
                @PathVariable Long businessId,
                @PathVariable Long managerId) {

            // Validate business existence
            Optional<Business> businessOptional = businessRepository.findById(businessId);
            if (businessOptional.isEmpty()) {
                return ResponseEntity.badRequest().body("Business not found");
            }

            // Validate manager existence and role
            Optional<User> managerOptional = userRepository.findById(managerId);
            if (managerOptional.isEmpty() || managerOptional.get().getRole() != Role.MANAGER) {
                return ResponseEntity.badRequest().body("Manager not found or invalid role");
            }

            User manager = managerOptional.get();

            // Unlink manager from branch
            Branch branch = manager.getBranch();
            if (branch != null) {
                branch.setManager(null);
                branchRepository.save(branch);
            }

            // Delete the manager
            userRepository.delete(manager);

            return ResponseEntity.ok("Manager deleted successfully");
        }



    @PostMapping("/{businessId}/add-branch")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<?> addBranch(@PathVariable Long businessId, @RequestBody Branch branch) {
        Optional<Business> businessOptional = businessRepository.findById(businessId);
        if (businessOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Business not found");
        }

        Business business = businessOptional.get();
        branch.setBusiness(business);
        branchRepository.save(branch);

        return ResponseEntity.ok("Branch added successfully");
    }
    // Update Branch
    @PutMapping("/{businessId}/branch/{branchId}/update")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<?> updateBranch(@PathVariable Long businessId, @PathVariable Long branchId, @RequestBody Branch branchDetails) {
        Optional<Business> businessOptional = businessRepository.findById(businessId);
        if (businessOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Business not found");
        }

        Optional<Branch> branchOptional = branchRepository.findById(branchId);
        if (branchOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Branch not found");
        }

        Branch branch = branchOptional.get();
        branch.setName(branchDetails.getName());
        branch.setLocation(branchDetails.getLocation());

        branchRepository.save(branch);
        return ResponseEntity.ok("Branch updated successfully");
    }

    // Delete Branch
    @DeleteMapping("/{businessId}/branch/{branchId}/delete")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<?> deleteBranch(@PathVariable Long businessId, @PathVariable Long branchId) {
        Optional<Business> businessOptional = businessRepository.findById(businessId);
        if (businessOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Business not found");
        }

        if (!branchRepository.existsById(branchId)) {
            return ResponseEntity.badRequest().body("Branch not found");
        }

        branchRepository.deleteById(branchId);
        return ResponseEntity.ok("Branch deleted successfully");
    }



    @GetMapping("/{businessId}/branches")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<?> getAllBranches(@PathVariable Long businessId) {
        Optional<Business> businessOptional = businessRepository.findById(businessId);
        if (businessOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Business not found");
        }

        Business business = businessOptional.get();

        List<Branch> branches = branchRepository.findAllByBusiness(business);

        // Build a response with branch details
        List<Map<String, Object>> response = branches.stream().map(branch -> {
            Map<String, Object> branchData = new HashMap<>();
            branchData.put("branchId", branch.getId());
            branchData.put("branchName", branch.getName());
            branchData.put("location", branch.getLocation());
            return branchData;
        }).toList();

        return ResponseEntity.ok(response);
    }

}
