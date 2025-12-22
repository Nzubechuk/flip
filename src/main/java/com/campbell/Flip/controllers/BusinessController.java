package com.campbell.Flip.controllers;

import com.campbell.Flip.dto.BranchDto;
import com.campbell.Flip.dto.BusinessDto;
import com.campbell.Flip.dto.LoginRequest;
import com.campbell.Flip.dto.RefreshTokenRequest;
import com.campbell.Flip.dto.UserDto;
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
import java.util.UUID;

@CrossOrigin(origins = "http://localhost:5173")
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
        System.out.println("Received Payload: " + businessDto);

        // Validate business name
        if (businessDto.getName() == null || businessDto.getName().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("Business name is required");
        }

        // Check if business name already exists
        if (businessRepository.findByName(businessDto.getName().trim()).isPresent()) {
            return ResponseEntity.badRequest().body("Business with this name already exists");
        }

        // Validate CEO details - check if CEO object exists
        UserDto ceoDto = businessDto.getCeo();
        if (ceoDto == null) {
            return ResponseEntity.badRequest().body("CEO details are required");
        }

        // Validate all CEO fields
        if (ceoDto.getUsername() == null || ceoDto.getUsername().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("CEO username is required");
        }
        if (ceoDto.getPassword() == null || ceoDto.getPassword().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("CEO password is required");
        }
        if (ceoDto.getFirstname() == null || ceoDto.getFirstname().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("CEO first name is required");
        }
        if (ceoDto.getLastname() == null || ceoDto.getLastname().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("CEO last name is required");
        }
        if (ceoDto.getEmail() == null || ceoDto.getEmail().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("CEO email is required");
        }

        // Check if username already exists
        if (userRepository.findByUsername(ceoDto.getUsername().trim()).isPresent()) {
            return ResponseEntity.badRequest().body("Username already exists");
        }

        // Check if email already exists
        if (userRepository.findByEmail(ceoDto.getEmail().trim()).isPresent()) {
            return ResponseEntity.badRequest().body("Email already exists");
        }

        // Create CEO user
        User ceo = new User();
        ceo.setUsername(ceoDto.getUsername().trim());
        ceo.setPassword(passwordEncoder.encode(ceoDto.getPassword()));
        ceo.setFirstName(ceoDto.getFirstname().trim());
        ceo.setLastName(ceoDto.getLastname().trim());
        ceo.setEmail(ceoDto.getEmail().trim());
        ceo.setRole(Role.CEO);

        // Create business
        Business business = new Business();
        business.setName(businessDto.getName().trim());
        if (businessDto.getBusinessRegNumber() != null && !businessDto.getBusinessRegNumber().trim().isEmpty()) {
            business.setBusinessRegNumber(businessDto.getBusinessRegNumber().trim());
        }
        
        // Set bidirectional relationship
        business.setCeo(ceo);
        ceo.setBusiness(business);

        // Save business (CEO will be saved automatically due to cascade)
        businessRepository.save(business);

        // Return success response with CEO details (without password)
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Business registered successfully");
        response.put("businessId", business.getId());
        response.put("businessName", business.getName());
        Map<String, Object> ceoInfo = new HashMap<>();
        ceoInfo.put("username", ceo.getUsername());
        ceoInfo.put("firstName", ceo.getFirstName());
        ceoInfo.put("lastName", ceo.getLastName());
        ceoInfo.put("email", ceo.getEmail());
        response.put("ceo", ceoInfo);

        return ResponseEntity.ok(response);
    }
    @PutMapping("/{businessId}/update")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<?> updateBusiness(@PathVariable UUID businessId, @RequestBody BusinessDto businessDto) {
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
    public ResponseEntity<?> deleteBusiness(@PathVariable UUID businessId) {
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
                @PathVariable UUID businessId,
                @PathVariable UUID branchId,
                @RequestBody WorkerDTO managerDTO) {

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

            // Check if branch already has a manager
            if (branch.getManager() != null) {
                return ResponseEntity.badRequest().body("Branch already has a manager assigned");
            }

            // Validate manager details
            if (managerDTO.getUsername() == null || managerDTO.getUsername().trim().isEmpty()) {
                return ResponseEntity.badRequest().body("Username is required");
            }
            if (managerDTO.getPassword() == null || managerDTO.getPassword().trim().isEmpty()) {
                return ResponseEntity.badRequest().body("Password is required");
            }
            if (managerDTO.getFirstname() == null || managerDTO.getFirstname().trim().isEmpty()) {
                return ResponseEntity.badRequest().body("First name is required");
            }
            if (managerDTO.getLastname() == null || managerDTO.getLastname().trim().isEmpty()) {
                return ResponseEntity.badRequest().body("Last name is required");
            }
            if (managerDTO.getEmail() == null || managerDTO.getEmail().trim().isEmpty()) {
                return ResponseEntity.badRequest().body("Email is required");
            }

            // Check if username already exists
            if (userRepository.findByUsername(managerDTO.getUsername().trim()).isPresent()) {
                return ResponseEntity.badRequest().body("Username already exists");
            }

            // Check if email already exists
            if (userRepository.findByEmail(managerDTO.getEmail().trim()).isPresent()) {
                return ResponseEntity.badRequest().body("Email already exists");
            }

            // Create and save the manager
            User manager = new User();
            manager.setUsername(managerDTO.getUsername().trim());
            manager.setPassword(passwordEncoder.encode(managerDTO.getPassword()));
            manager.setFirstName(managerDTO.getFirstname().trim());
            manager.setLastName(managerDTO.getLastname().trim());
            manager.setEmail(managerDTO.getEmail().trim());
            manager.setRole(Role.MANAGER);
            manager.setBusiness(business);
            manager.setBranch(branch);

            userRepository.save(manager);

            // Link manager to the branch
            branch.setManager(manager);
            branchRepository.save(branch);

            Map<String, Object> response = new HashMap<>();
            response.put("message", "Manager added to branch successfully");
            response.put("managerId", manager.getId());
            response.put("username", manager.getUsername());
            response.put("branchId", branch.getId());
            response.put("branchName", branch.getName());

            return ResponseEntity.ok(response);
        }

        @PutMapping("/{businessId}/manager/{managerId}/update")
        @PreAuthorize("hasRole('CEO')")
        public ResponseEntity<?> updateManager(
                @PathVariable UUID businessId,
                @PathVariable UUID managerId,
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
                @PathVariable UUID businessId,
                @PathVariable UUID managerId) {

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



    /**
     * Create a new branch for a business (CEO only)
     * Optionally assign a manager during creation
     */
    @PostMapping("/{businessId}/create-branch")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<?> createBranch(
            @PathVariable UUID businessId,
            @RequestBody BranchDto branchDto) {

        // Validate business existence
        Optional<Business> businessOptional = businessRepository.findById(businessId);
        if (businessOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Business not found");
        }

        Business business = businessOptional.get();

        // Validate branch name
        if (branchDto.getName() == null || branchDto.getName().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("Branch name is required");
        }

        // Check for duplicate branch names within the same business
        if (branchRepository.findByNameAndBusiness(branchDto.getName().trim(), business).isPresent()) {
            return ResponseEntity.badRequest().body("Branch with this name already exists in this business");
        }

        // Create branch
        Branch branch = new Branch();
        branch.setName(branchDto.getName().trim());
        if (branchDto.getLocation() != null && !branchDto.getLocation().trim().isEmpty()) {
            branch.setLocation(branchDto.getLocation().trim());
        }
        branch.setBusiness(business);

        // Optionally assign manager if provided
        User manager = null;
        if (branchDto.getManagerId() != null) {
            Optional<User> managerOptional = userRepository.findById(branchDto.getManagerId());
            if (managerOptional.isEmpty()) {
                return ResponseEntity.badRequest().body("Manager not found with the provided ID");
            }

            manager = managerOptional.get();

            // Validate manager belongs to the same business
            if (!manager.getBusiness().equals(business)) {
                return ResponseEntity.badRequest().body("Manager does not belong to this business");
            }

            // Validate manager role
            if (manager.getRole() != Role.MANAGER) {
                return ResponseEntity.badRequest().body("User is not a manager");
            }

            // Check if manager is already assigned to another branch
            if (manager.getBranch() != null) {
                return ResponseEntity.badRequest().body("Manager is already assigned to another branch");
            }

            // Assign manager to branch
            branch.setManager(manager);
            manager.setBranch(branch);
        }

        // Save branch
        Branch savedBranch = branchRepository.save(branch);
        if (manager != null) {
            userRepository.save(manager);
        }

        // Build response
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Branch created successfully");
        response.put("branchId", savedBranch.getId());
        response.put("branchName", savedBranch.getName());
        response.put("location", savedBranch.getLocation());
        response.put("businessId", business.getId());
        response.put("businessName", business.getName());
        
        if (manager != null) {
            Map<String, Object> managerInfo = new HashMap<>();
            managerInfo.put("managerId", manager.getId());
            managerInfo.put("username", manager.getUsername());
            managerInfo.put("firstName", manager.getFirstName());
            managerInfo.put("lastName", manager.getLastName());
            response.put("manager", managerInfo);
        }

        return ResponseEntity.ok(response);
    }

    /**
     * Legacy endpoint - kept for backward compatibility
     * @deprecated Use createBranch instead
     */
    @PostMapping("/{businessId}/add-branch")
    @PreAuthorize("hasRole('CEO')")
    @Deprecated
    public ResponseEntity<?> addBranch(@PathVariable UUID businessId, @RequestBody Branch branch) {
        // Convert Branch entity to BranchDto and use createBranch
        BranchDto branchDto = new BranchDto();
        branchDto.setName(branch.getName());
        branchDto.setLocation(branch.getLocation());
        if (branch.getManager() != null) {
            branchDto.setManagerId(branch.getManager().getId());
        }
        return createBranch(businessId, branchDto);
    }
    // Update Branch
    @PutMapping("/{businessId}/branch/{branchId}/update")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<?> updateBranch(@PathVariable UUID businessId, @PathVariable UUID branchId, @RequestBody Branch branchDetails) {
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
    public ResponseEntity<?> deleteBranch(@PathVariable UUID businessId, @PathVariable UUID branchId) {
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
    public ResponseEntity<?> getAllBranches(@PathVariable UUID businessId) {
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

    /**
     * Register a new MANAGER user (CEO only)
     * Can optionally assign to a specific branch
     */
    @PostMapping("/{businessId}/register-manager")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<?> registerManager(
            @PathVariable UUID businessId,
            @RequestBody WorkerDTO managerDTO) {

        // Validate business existence
        Optional<Business> businessOptional = businessRepository.findById(businessId);
        if (businessOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Business not found");
        }

        Business business = businessOptional.get();

        // Validate manager details
        if (managerDTO.getUsername() == null || managerDTO.getUsername().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("Username is required");
        }
        if (managerDTO.getPassword() == null || managerDTO.getPassword().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("Password is required");
        }
        if (managerDTO.getFirstname() == null || managerDTO.getFirstname().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("First name is required");
        }
        if (managerDTO.getLastname() == null || managerDTO.getLastname().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("Last name is required");
        }
        if (managerDTO.getEmail() == null || managerDTO.getEmail().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("Email is required");
        }

        // Check if username already exists
        if (userRepository.findByUsername(managerDTO.getUsername().trim()).isPresent()) {
            return ResponseEntity.badRequest().body("Username already exists");
        }

        // Check if email already exists
        if (userRepository.findByEmail(managerDTO.getEmail().trim()).isPresent()) {
            return ResponseEntity.badRequest().body("Email already exists");
        }

        // Validate branch if provided
        Branch branch = null;
        if (managerDTO.getBranchId() != null) {
            UUID branchId = managerDTO.getBranchId();
            Optional<Branch> branchOptional = branchRepository.findById(branchId);
            if (branchOptional.isEmpty()) {
                return ResponseEntity.badRequest().body("Branch not found");
            }
            branch = branchOptional.get();
            if (!branch.getBusiness().equals(business)) {
                return ResponseEntity.badRequest().body("Branch does not belong to this business");
            }
            // Check if branch already has a manager
            if (branch.getManager() != null) {
                return ResponseEntity.badRequest().body("Branch already has a manager assigned");
            }
        }

        // Create manager user
        User manager = new User();
        manager.setUsername(managerDTO.getUsername().trim());
        manager.setPassword(passwordEncoder.encode(managerDTO.getPassword()));
        manager.setFirstName(managerDTO.getFirstname().trim());
        manager.setLastName(managerDTO.getLastname().trim());
        manager.setEmail(managerDTO.getEmail().trim());
        manager.setRole(Role.MANAGER);
        manager.setBusiness(business);
        
        if (branch != null) {
            manager.setBranch(branch);
            branch.setManager(manager);
        }

        userRepository.save(manager);
        if (branch != null) {
            branchRepository.save(branch);
        }

        // Build response
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Manager registered successfully");
        response.put("managerId", manager.getId());
        response.put("username", manager.getUsername());
        response.put("firstName", manager.getFirstName());
        response.put("lastName", manager.getLastName());
        response.put("email", manager.getEmail());
        if (branch != null) {
            response.put("branchId", branch.getId());
            response.put("branchName", branch.getName());
        }

        return ResponseEntity.ok(response);
    }

    /**
     * Register a new CLERK user (CEO only)
     * Can optionally assign to a specific branch
     */
    @PostMapping("/{businessId}/register-clerk")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<?> registerClerk(
            @PathVariable UUID businessId,
            @RequestBody WorkerDTO clerkDTO) {

        // Validate business existence
        Optional<Business> businessOptional = businessRepository.findById(businessId);
        if (businessOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Business not found");
        }

        Business business = businessOptional.get();

        // Validate clerk details
        if (clerkDTO.getUsername() == null || clerkDTO.getUsername().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("Username is required");
        }
        if (clerkDTO.getPassword() == null || clerkDTO.getPassword().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("Password is required");
        }
        if (clerkDTO.getFirstname() == null || clerkDTO.getFirstname().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("First name is required");
        }
        if (clerkDTO.getLastname() == null || clerkDTO.getLastname().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("Last name is required");
        }
        if (clerkDTO.getEmail() == null || clerkDTO.getEmail().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("Email is required");
        }

        // Check if username already exists
        if (userRepository.findByUsername(clerkDTO.getUsername().trim()).isPresent()) {
            return ResponseEntity.badRequest().body("Username already exists");
        }

        // Check if email already exists
        if (userRepository.findByEmail(clerkDTO.getEmail().trim()).isPresent()) {
            return ResponseEntity.badRequest().body("Email already exists");
        }

        // Validate branch if provided
        Branch branch = null;
        if (clerkDTO.getBranchId() != null) {
            UUID branchId = clerkDTO.getBranchId();
            Optional<Branch> branchOptional = branchRepository.findById(branchId);
            if (branchOptional.isEmpty()) {
                return ResponseEntity.badRequest().body("Branch not found");
            }
            branch = branchOptional.get();
            if (!branch.getBusiness().equals(business)) {
                return ResponseEntity.badRequest().body("Branch does not belong to this business");
            }
        }

        // Create clerk user
        User clerk = new User();
        clerk.setUsername(clerkDTO.getUsername().trim());
        clerk.setPassword(passwordEncoder.encode(clerkDTO.getPassword()));
        clerk.setFirstName(clerkDTO.getFirstname().trim());
        clerk.setLastName(clerkDTO.getLastname().trim());
        clerk.setEmail(clerkDTO.getEmail().trim());
        clerk.setRole(Role.CLERK);
        clerk.setBusiness(business);
        
        if (branch != null) {
            clerk.setBranch(branch);
        }

        userRepository.save(clerk);

        // Build response
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Clerk registered successfully");
        response.put("clerkId", clerk.getId());
        response.put("username", clerk.getUsername());
        response.put("firstName", clerk.getFirstName());
        response.put("lastName", clerk.getLastName());
        response.put("email", clerk.getEmail());
        if (branch != null) {
            response.put("branchId", branch.getId());
            response.put("branchName", branch.getName());
        }

        return ResponseEntity.ok(response);
    }

    /**
     * List all managers for a business (CEO only)
     */
    @GetMapping("/{businessId}/managers")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<?> getAllManagers(@PathVariable UUID businessId) {
        Optional<Business> businessOptional = businessRepository.findById(businessId);
        if (businessOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Business not found");
        }

        Business business = businessOptional.get();
        List<User> managers = userRepository.findAllByBusinessAndRole(business, Role.MANAGER);

        List<Map<String, Object>> response = managers.stream().map(manager -> {
            Map<String, Object> managerData = new HashMap<>();
            managerData.put("managerId", manager.getId());
            managerData.put("username", manager.getUsername());
            managerData.put("firstName", manager.getFirstName());
            managerData.put("lastName", manager.getLastName());
            managerData.put("email", manager.getEmail());
            if (manager.getBranch() != null) {
                managerData.put("branchId", manager.getBranch().getId());
                managerData.put("branchName", manager.getBranch().getName());
            }
            return managerData;
        }).toList();

        return ResponseEntity.ok(response);
    }

    /**
     * List all clerks for a business (CEO only)
     */
    @GetMapping("/{businessId}/clerks")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<?> getAllClerks(@PathVariable UUID businessId) {
        Optional<Business> businessOptional = businessRepository.findById(businessId);
        if (businessOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Business not found");
        }

        Business business = businessOptional.get();
        List<User> clerks = userRepository.findAllByBusinessAndRole(business, Role.CLERK);

        List<Map<String, Object>> response = clerks.stream().map(clerk -> {
            Map<String, Object> clerkData = new HashMap<>();
            clerkData.put("clerkId", clerk.getId());
            clerkData.put("username", clerk.getUsername());
            clerkData.put("firstName", clerk.getFirstName());
            clerkData.put("lastName", clerk.getLastName());
            clerkData.put("email", clerk.getEmail());
            if (clerk.getBranch() != null) {
                clerkData.put("branchId", clerk.getBranch().getId());
                clerkData.put("branchName", clerk.getBranch().getName());
            }
            return clerkData;
        }).toList();

        return ResponseEntity.ok(response);
    }

}
