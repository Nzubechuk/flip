package com.campbell.Flip.controllers;

import com.campbell.Flip.dto.ProductDTO;
import com.campbell.Flip.dto.WorkerDTO;
import com.campbell.Flip.entities.*;
import com.campbell.Flip.repository.BranchRepository;
import com.campbell.Flip.repository.BusinessRepository;
import com.campbell.Flip.repository.ProductRepository;
import com.campbell.Flip.repository.UserRepository;
import com.campbell.Flip.service.ProductService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.*;
import java.util.UUID;

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

    @Autowired
    private ProductService productService;

    // Add Product
    @PostMapping("/add")
    @PreAuthorize("hasAnyRole('MANAGER', 'CEO')")
    public ResponseEntity<?> addProduct(@RequestBody ProductDTO productDTO, Principal principal) {
        
        Optional<User> userOptional = userRepository.findByUsername(principal.getName());
        if (userOptional.isEmpty()) {
            return ResponseEntity.status(403).body("User not found");
        }
        User currentUser = userOptional.get();

        Branch branch = null;
        Business business = currentUser.getBusiness(); // Default to user's business

        // Determine Branch
        if (productDTO.getBranchId() != null) {
            Optional<Branch> branchOptional = branchRepository.findById(productDTO.getBranchId());
            if (branchOptional.isEmpty()) {
                return ResponseEntity.badRequest().body("Branch not found");
            }
            branch = branchOptional.get();
            business = branch.getBusiness(); // Use branch's business
        } else {
            // No branch ID provided
            if (currentUser.getRole() == Role.MANAGER) {
                // Manager MUST have a branch inferred if not provided
                // Find branch where this user is manager
                // Note: Branch entity has 'manager' field. We need to query Branch repository by manager
                // Assuming efficient way or bidirectional, but here let's assume Manager user object doesn't have list of branches directly?
                // Actually Branch has 'manager_id'.
                // Ideally, we iterate businesses branches or query.
                // Simplified: User should have a way to know their branch?
                // Let's assume for now if Manager doesn't provide ID, we try to find it via business or deny?
                // Re-reading user request: "no need for select branch... it should just be for the assigned manager branch"
                // So we need to find the branch managed by this user.
                
                // Let's implement a quick lookup or check if we can get it from context.
                // For now, let's assume we can fetch it.
                // Since BranchRepository is available:
                List<Branch> managedBranches = branchRepository.findAll().stream()
                    .filter(b -> b.getManager() != null && b.getManager().getId().equals(currentUser.getId()))
                    .toList();
                
                if (managedBranches.isEmpty()) {
                    return ResponseEntity.badRequest().body("You are a Manager but not assigned to any branch.");
                }
                branch = managedBranches.get(0); // Assume 1 branch per manager
                business = branch.getBusiness();
            } else if (currentUser.getRole() == Role.CEO) {
                // CEO can add product without branch (global/business level)
                // Just ensure they have a business
                if (business == null) {
                    return ResponseEntity.status(403).body("CEO must be associated with a business");
                }
                // branch stays null
            }
        }

        // Validate Access
        if (business == null) {
             return ResponseEntity.badRequest().body("Business context not found");
        }
        
        if (currentUser.getRole() == Role.CEO) {
            if (!currentUser.getBusiness().equals(business)) {
                 return ResponseEntity.status(403).body("Unauthorized to add products to this business");
            }
        } else if (currentUser.getRole() == Role.MANAGER) {
             // Manager must belong to same business and (if branch exists) manage it
             if (!currentUser.getBusiness().equals(business)) {
                 return ResponseEntity.status(403).body("Unauthorized: Different business");
             }
             if (branch != null && (branch.getManager() == null || !branch.getManager().getId().equals(currentUser.getId()))) {
                  // Fallback: If managed branch is just one of the business branches but not THE manager?
                  // Previous logic allowed any Manager of the business to add if branch has no manager. Keep that logic?
                  // Stick to: If user provided a branch ID, they must be authorized for it.
                  if (branch.getManager() != null && !branch.getManager().getId().equals(currentUser.getId())) {
                      return ResponseEntity.status(403).body("Unauthorized to manage this specific branch");
                  }
             }
        }

        Product product = new Product();
        product.setName(productDTO.getName());
        product.setDescription(productDTO.getDescription());
        product.setPrice(productDTO.getPrice());
        product.setStock(productDTO.getStock());
        product.setProductCode(productDTO.getProductCode());
        product.setUpc(productDTO.getUpc());
        product.setEan13(productDTO.getEan13());
        product.setCategory(productDTO.getCategory());
        product.setBranch(branch);
        product.setBusiness(business); 

        productRepository.save(product);
        return ResponseEntity.ok("Product added successfully");
    }

    // Update Product
    @PutMapping("/{productId}/update")
    @PreAuthorize("hasAnyRole('MANAGER', 'CEO')")
    public ResponseEntity<?> updateProduct(@PathVariable UUID productId, @RequestBody ProductDTO productDTO, Principal principal) {
        Optional<Product> productOptional = productRepository.findById(productId);

        if (productOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Product not found");
        }

        Product product = productOptional.get();
        Branch branch = product.getBranch();

        // Validate manager/CEO access
        Optional<User> userOptional = userRepository.findByUsername(principal.getName());
        if (userOptional.isEmpty()) {
            return ResponseEntity.status(403).body("User not found");
        }
        User currentUser = userOptional.get();
        
        // CEO can update any product in their business
        if (currentUser.getRole() == Role.CEO) {
            if (currentUser.getBusiness() == null || !currentUser.getBusiness().equals(product.getBusiness())) {
                return ResponseEntity.status(403).body("Unauthorized to manage this product");
            }
        } else if (branch.getManager() != null) {
            // Manager can update products in their assigned branch
            if (!branch.getManager().getUsername().equals(principal.getName())) {
                return ResponseEntity.status(403).body("Unauthorized to manage this product");
            }
        } else {
            // Branch has no manager - verify user is a MANAGER from the same business
            if (currentUser.getRole() != Role.MANAGER) {
                return ResponseEntity.status(403).body("Only managers can update products in branches without assigned managers");
            }
            if (currentUser.getBusiness() == null || !currentUser.getBusiness().equals(product.getBusiness())) {
                return ResponseEntity.status(403).body("Manager must belong to the same business as the product");
            }
        }

        product.setName(productDTO.getName());
        product.setDescription(productDTO.getDescription());
        product.setPrice(productDTO.getPrice());
        product.setStock(productDTO.getStock());
        product.setProductCode(productDTO.getProductCode());
        product.setCategory(productDTO.getCategory());

        productRepository.save(product);
        return ResponseEntity.ok("Product updated successfully");
    }

    // Delete Product
    @DeleteMapping("/{productId}/delete")
    @PreAuthorize("hasAnyRole('MANAGER', 'CEO')")
    public ResponseEntity<?> deleteProduct(@PathVariable UUID productId, Principal principal) {
        Optional<Product> productOptional = productRepository.findById(productId);

        if (productOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Product not found");
        }

        Product product = productOptional.get();
        Branch branch = product.getBranch();

        // Validate manager/CEO access
        Optional<User> userOptional = userRepository.findByUsername(principal.getName());
        if (userOptional.isEmpty()) {
            return ResponseEntity.status(403).body("User not found");
        }
        User currentUser = userOptional.get();
        
        // CEO can delete any product in their business
        if (currentUser.getRole() == Role.CEO) {
            if (currentUser.getBusiness() == null || !currentUser.getBusiness().equals(product.getBusiness())) {
                return ResponseEntity.status(403).body("Unauthorized to delete this product");
            }
        } else if (branch.getManager() != null) {
            // Manager can delete products in their assigned branch
            if (!branch.getManager().getUsername().equals(principal.getName())) {
                return ResponseEntity.status(403).body("Unauthorized to delete this product");
            }
        } else {
            // Branch has no manager - verify user is a MANAGER from the same business
            if (currentUser.getRole() != Role.MANAGER) {
                return ResponseEntity.status(403).body("Only managers can delete products in branches without assigned managers");
            }
            if (currentUser.getBusiness() == null || !currentUser.getBusiness().equals(product.getBusiness())) {
                return ResponseEntity.status(403).body("Manager must belong to the same business as the product");
            }
        }

        productRepository.delete(product);
        return ResponseEntity.ok("Product deleted successfully");
    }

    // List Products
    @GetMapping("/{branchId}/list")
    @PreAuthorize("hasRole('MANAGER') or hasRole('CEO')")
    public ResponseEntity<?> listProducts(@PathVariable UUID branchId, Principal principal) {
        Optional<Branch> branchOptional = branchRepository.findById(branchId);

        if (branchOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Branch not found");
        }

        Branch branch = branchOptional.get();
        Business business = branch.getBusiness();
        if (business == null) {
            return ResponseEntity.badRequest().body("Branch is not associated with any business");
        }

        // Validate manager access
        // If branch has a manager, check if user is that manager or CEO
        // If branch has no manager, allow any MANAGER from the same business or CEO
        boolean hasAccess = false;
        if (branch.getManager() != null) {
            hasAccess = branch.getManager().getUsername().equals(principal.getName()) ||
                    (business.getCeo() != null && isCeoOfBusiness(business.getCeo().getUsername(), principal.getName()));
        } else {
            // Branch has no manager - allow MANAGER from same business or CEO
            Optional<User> userOptional = userRepository.findByUsername(principal.getName());
            if (userOptional.isPresent()) {
                User user = userOptional.get();
                if (user.getRole() == Role.MANAGER && user.getBusiness() != null && user.getBusiness().equals(business)) {
                    hasAccess = true;
                } else if (business.getCeo() != null && isCeoOfBusiness(business.getCeo().getUsername(), principal.getName())) {
                    hasAccess = true;
                }
            }
        }
        
        if (!hasAccess) {
            return ResponseEntity.status(403).body("Unauthorized to view products in this branch");
        }

            List<Product> products = productRepository.findByBranch(branch);

            List<Map<String, Object>> response = products.stream().map(product -> {
                Map<String, Object> productData = new HashMap<>();
                productData.put("productId", product.getId());
                productData.put("name", product.getName());
                productData.put("description", product.getDescription());
                productData.put("price", product.getPrice());
                productData.put("stock", product.getStock());
                productData.put("stock", product.getStock());
                productData.put("productCode", product.getProductCode());
                productData.put("category", product.getCategory());
                productData.put("branchId", product.getBranch().getId());
                return productData;
            }).toList();

            Map<String, Object> branchData = new HashMap<>();
            branchData.put("branchName", branch.getName());
            branchData.put("products", response);

            return ResponseEntity.ok(branchData);
    }

    // List All Products for a Business (CEO)
    @GetMapping("/business/{businessId}/all")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<?> listProductsByBusiness(@PathVariable UUID businessId, Principal principal) {
        Optional<Business> businessOptional = businessRepository.findById(businessId);

        if (businessOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Business not found");
        }

        Business business = businessOptional.get();

        // Validate CEO access
        if (business.getCeo() == null || !business.getCeo().getUsername().equals(principal.getName())) {
            return ResponseEntity.status(403).body("Unauthorized to view products in this business");
        }

        List<Product> products = productRepository.findByBusinessId(businessId);

        List<Map<String, Object>> response = products.stream().map(product -> {
            Map<String, Object> productData = new HashMap<>();
            productData.put("productId", product.getId());
            productData.put("name", product.getName());
            productData.put("description", product.getDescription());
            productData.put("price", product.getPrice());
            productData.put("stock", product.getStock());
            productData.put("productCode", product.getProductCode());
            productData.put("category", product.getCategory());
            productData.put("branchId", product.getBranch() != null ? product.getBranch().getId() : null);
            productData.put("branchName", product.getBranch() != null ? product.getBranch().getName() : "Global/No Branch");
            return productData;
        }).toList();

        return ResponseEntity.ok(response);
    }

    private boolean isCeoOfBusiness(String ceoUsername, String principalName) {
        return ceoUsername != null && ceoUsername.equals(principalName);
    }

    @PostMapping("/{productId}/generate-qrcode")
    public ResponseEntity<?> generateQRCode(@PathVariable UUID productId) {
        try {
            String qrCodePath = productService.generateProductQRCode(productId);
            return ResponseEntity.ok("QR code generated at: " + qrCodePath);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(500).body("An unexpected error occurred: " + e.getMessage());
        }
    }


    @GetMapping("/{productCode}/details")
    public ResponseEntity<?> getProductDetails(@PathVariable String productCode) {
        Product product = productService.getProductCode(productCode); // Updated to use proper service method
        if (product == null) {
            return ResponseEntity.badRequest().body("Product not found");
        }

        // Create response map for product details
        Map<String, Object> productData = new HashMap<>();
        productData.put("productId", product.getId());
        productData.put("name", product.getName());
        productData.put("description", product.getDescription());
        productData.put("price", product.getPrice());
        productData.put("stock", product.getStock());
        productData.put("productCode", product.getProductCode());
        productData.put("category", product.getCategory());

        return ResponseEntity.ok(productData);
    }


    @PostMapping("/{productId}/update-stock")
    public ResponseEntity<?> updateStock(@PathVariable UUID productId, @RequestParam int quantitySold) {
        try {
            Product updatedProduct = productService.updateStock(productId, quantitySold);

            // Create a response map with the desired fields
            Map<String, Object> productResponse = new HashMap<>();
            productResponse.put("productId", updatedProduct.getId());
            productResponse.put("name", updatedProduct.getName());
            productResponse.put("description", updatedProduct.getDescription());
            productResponse.put("price", updatedProduct.getPrice());
            productResponse.put("stock", updatedProduct.getStock());
            productResponse.put("productCode", updatedProduct.getProductCode());
            productResponse.put("category", updatedProduct.getCategory());

            return ResponseEntity.ok(productResponse);
        } catch (Exception e) {
            return ResponseEntity.status(500).body(e.getMessage());
        }
    }

    /**
     * Lookup product information by barcode (UPC or EAN-13) for onboarding
     * This endpoint searches external barcode databases to get product information
     */
    /**
     * Lookup product information by barcode (UPC or EAN-13) for onboarding
     * Uses UPC Item DB API to fetch product details
     * 
     * @param barcode UPC (12 digits) or EAN-13 (13 digits) barcode
     * @return Product information from UPC Item DB
     */
    @GetMapping("/barcode/{barcode}/lookup")
    @PreAuthorize("hasRole('MANAGER')")
    public ResponseEntity<?> lookupBarcodeForOnboarding(@PathVariable String barcode) {
        try {
            com.campbell.Flip.dto.BarcodeProductInfo barcodeInfo = productService.lookupBarcodeForOnboarding(barcode);
            
            Map<String, Object> response = new HashMap<>();
            response.put("barcode", barcodeInfo.getBarcode());
            response.put("title", barcodeInfo.getTitle());
            response.put("description", barcodeInfo.getDescription());
            response.put("brand", barcodeInfo.getBrand());
            response.put("model", barcodeInfo.getModel());
            response.put("category", barcodeInfo.getCategory());
            response.put("imageUrl", barcodeInfo.getImageUrl());
            response.put("suggestedPrice", barcodeInfo.getSuggestedPrice());
            
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (ProductService.ProductNotFoundException e) {
            return ResponseEntity.status(404).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", "Error looking up barcode: " + e.getMessage()));
        }
    }

    /**
     * Add product using barcode information from external database
     */
    @PostMapping("/{branchId}/add-from-barcode")
    @PreAuthorize("hasRole('MANAGER')")
    public ResponseEntity<?> addProductFromBarcode(
            @PathVariable UUID branchId,
            @RequestParam String barcode,
            @RequestParam(required = false) Double price,
            @RequestParam(required = false, defaultValue = "0") Integer stock,
            Principal principal) {
        try {
            Optional<Branch> branchOptional = branchRepository.findById(branchId);
            if (branchOptional.isEmpty()) {
                return ResponseEntity.badRequest().body("Branch not found");
            }

            Branch branch = branchOptional.get();
            Business business = branch.getBusiness();
            if (business == null) {
                return ResponseEntity.badRequest().body("Branch is not associated with any business");
            }

            // Validate manager access
            // If branch has a manager, only that manager can add products
            // If branch has no manager, allow any MANAGER from the same business
            if (branch.getManager() != null) {
                if (!branch.getManager().getUsername().equals(principal.getName())) {
                    return ResponseEntity.status(403).body("Unauthorized to manage this branch");
                }
            } else {
                // Branch has no manager - verify user is a MANAGER from the same business
                Optional<User> userOptional = userRepository.findByUsername(principal.getName());
                if (userOptional.isEmpty() || userOptional.get().getRole() != Role.MANAGER) {
                    return ResponseEntity.status(403).body("Only managers can add products to branches without assigned managers");
                }
                User user = userOptional.get();
                if (user.getBusiness() == null || !user.getBusiness().equals(business)) {
                    return ResponseEntity.status(403).body("Manager must belong to the same business as the branch");
                }
            }

            // Lookup barcode information
            com.campbell.Flip.dto.BarcodeProductInfo barcodeInfo = productService.lookupBarcodeForOnboarding(barcode);
            
            // Create product from barcode info
            Product product = productService.createProductFromBarcode(barcodeInfo, branchId, price, stock);
            product.setCategory(barcodeInfo.getCategory());
            product.setBranch(branch);
            product.setBusiness(business);

            // Save product
            Product savedProduct = productRepository.save(product);

            Map<String, Object> response = new HashMap<>();
            response.put("message", "Product added successfully from barcode");
            response.put("productId", savedProduct.getId());
            response.put("name", savedProduct.getName());
            response.put("productCode", savedProduct.getProductCode());
            response.put("upc", savedProduct.getUpc());
            response.put("ean13", savedProduct.getEan13());
            response.put("category", savedProduct.getCategory());
            
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (ProductService.ProductNotFoundException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error adding product from barcode: " + e.getMessage());
        }
    }

}
