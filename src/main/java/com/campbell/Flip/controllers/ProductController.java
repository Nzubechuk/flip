package com.campbell.Flip.controllers;

import com.campbell.Flip.dto.ProductDTO;
import com.campbell.Flip.dto.WorkerDTO;
import com.campbell.Flip.entities.*;
import com.campbell.Flip.repository.BranchRepository;
import com.campbell.Flip.repository.BusinessRepository;
import com.campbell.Flip.repository.ProductRepository;
import com.campbell.Flip.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.*;

@RestController
@RequestMapping("/api/products")
public class ProductController {

    private final ProductRepository productRepository;
    private final BranchRepository branchRepository;
    private final UserRepository userRepository;
    private final BusinessRepository businessRepository;
    private final PasswordEncoder passwordEncoder;

    public ProductController(ProductRepository productRepository, BranchRepository branchRepository,
                             UserRepository userRepository, BusinessRepository businessRepository,
                             PasswordEncoder passwordEncoder) {
        this.productRepository = productRepository;
        this.branchRepository = branchRepository;
        this.userRepository = userRepository;
        this.businessRepository = businessRepository;
        this.passwordEncoder = passwordEncoder;
    }

    // Add Product
    @PostMapping("/{branchId}/add")
    @PreAuthorize("hasRole('MANAGER')")
    public ResponseEntity<?> addProduct(@PathVariable Long branchId, @RequestBody ProductDTO productDTO, Principal principal) {
        Optional<Branch> branchOptional = branchRepository.findById(branchId);

        if (branchOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Branch not found");
        }

        Branch branch = branchOptional.get();

        // Check if the branch belongs to a valid business
        Business business = branch.getBusiness();
        if (business == null) {
            return ResponseEntity.badRequest().body("Branch is not associated with any business");
        }

        // Validate manager access
        if (!branch.getManager().getUsername().equals(principal.getName())) {
            return ResponseEntity.status(403).body("Unauthorized to manage this branch");
        }

        Product product = new Product();
        product.setName(productDTO.getName());
        product.setDescription(productDTO.getDescription());
        product.setPrice(productDTO.getPrice());
        product.setStock(productDTO.getStock());
        product.setBranch(branch);
        product.setBusiness(business); // Link the product to the business

        productRepository.save(product);
        return ResponseEntity.ok("Product added successfully");
    }

    // Update Product
    @PutMapping("/{productId}/update")
    @PreAuthorize("hasRole('MANAGER')")
    public ResponseEntity<?> updateProduct(@PathVariable Long productId, @RequestBody ProductDTO productDTO, Principal principal) {
        Optional<Product> productOptional = productRepository.findById(productId);

        if (productOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Product not found");
        }

        Product product = productOptional.get();
        Branch branch = product.getBranch();

        if (!branch.getManager().getUsername().equals(principal.getName())) {
            return ResponseEntity.status(403).body("Unauthorized to manage this product");
        }

        product.setName(productDTO.getName());
        product.setDescription(productDTO.getDescription());
        product.setPrice(productDTO.getPrice());
        product.setStock(productDTO.getStock());

        productRepository.save(product);
        return ResponseEntity.ok("Product updated successfully");
    }

    // Delete Product
    @DeleteMapping("/{productId}/delete")
    @PreAuthorize("hasRole('MANAGER')")
    public ResponseEntity<?> deleteProduct(@PathVariable Long productId, Principal principal) {
        Optional<Product> productOptional = productRepository.findById(productId);

        if (productOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Product not found");
        }

        Product product = productOptional.get();
        Branch branch = product.getBranch();

        if (!branch.getManager().getUsername().equals(principal.getName())) {
            return ResponseEntity.status(403).body("Unauthorized to delete this product");
        }

        productRepository.delete(product);
        return ResponseEntity.ok("Product deleted successfully");
    }

    // List Products
    @GetMapping("/{branchId}/list")
    @PreAuthorize("hasRole('MANAGER') or hasRole('CEO')")
    public ResponseEntity<?> listProducts(@PathVariable Long branchId, Principal principal) {
        Optional<Branch> branchOptional = branchRepository.findById(branchId);

        if (branchOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Branch not found");
        }

        Branch branch = branchOptional.get();
        Business business = branch.getBusiness();

        if (branch.getManager().getUsername().equals(principal.getName()) ||
                isCeoOfBusiness(business.getCeo().getUsername(), principal.getName())) {
            List<Product> products = productRepository.findByBranch(branch);

            List<Map<String, Object>> response = products.stream().map(product -> {
                Map<String, Object> productData = new HashMap<>();
                productData.put("productId", product.getId());
                productData.put("name", product.getName());
                productData.put("description", product.getDescription());
                productData.put("price", product.getPrice());
                productData.put("stock", product.getStock());
                productData.put("branchId", product.getBranch().getId());
                return productData;
            }).toList();

            Map<String, Object> branchData = new HashMap<>();
            branchData.put("branchName", branch.getName());
            branchData.put("products", response);

            return ResponseEntity.ok(branchData);
        }

        return ResponseEntity.status(403).body("Unauthorized to view products of this branch");
    }

    private boolean isCeoOfBusiness(String ceoUsername, String principalName) {
        return ceoUsername != null && ceoUsername.equals(principalName);
    }
}
