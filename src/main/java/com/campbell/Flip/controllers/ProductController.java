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
    @PostMapping("/{branchId}/add")
    @PreAuthorize("hasRole('MANAGER')")
    public ResponseEntity<?> addProduct(@PathVariable UUID branchId, @RequestBody ProductDTO productDTO, Principal principal) {
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

        Product product = new Product();
        product.setName(productDTO.getName());
        product.setDescription(productDTO.getDescription());
        product.setPrice(productDTO.getPrice());
        product.setStock(productDTO.getStock());
        product.setProductCode(productDTO.getProductCode());
        product.setUpc(productDTO.getUpc());
        product.setEan13(productDTO.getEan13());
        product.setBranch(branch);
        product.setBusiness(business); // Link the product to the business

        productRepository.save(product);
        return ResponseEntity.ok("Product added successfully");
    }

    // Update Product
    @PutMapping("/{productId}/update")
    @PreAuthorize("hasRole('MANAGER')")
    public ResponseEntity<?> updateProduct(@PathVariable UUID productId, @RequestBody ProductDTO productDTO, Principal principal) {
        Optional<Product> productOptional = productRepository.findById(productId);

        if (productOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Product not found");
        }

        Product product = productOptional.get();
        Branch branch = product.getBranch();

        // Validate manager access
        if (branch.getManager() != null) {
            if (!branch.getManager().getUsername().equals(principal.getName())) {
                return ResponseEntity.status(403).body("Unauthorized to manage this product");
            }
        } else {
            // Branch has no manager - verify user is a MANAGER from the same business
            Optional<User> userOptional = userRepository.findByUsername(principal.getName());
            if (userOptional.isEmpty() || userOptional.get().getRole() != Role.MANAGER) {
                return ResponseEntity.status(403).body("Only managers can update products in branches without assigned managers");
            }
            User user = userOptional.get();
            if (user.getBusiness() == null || !user.getBusiness().equals(product.getBusiness())) {
                return ResponseEntity.status(403).body("Manager must belong to the same business as the product");
            }
        }

        product.setName(productDTO.getName());
        product.setDescription(productDTO.getDescription());
        product.setPrice(productDTO.getPrice());
        product.setStock(productDTO.getStock());
        product.setProductCode(productDTO.getProductCode());

        productRepository.save(product);
        return ResponseEntity.ok("Product updated successfully");
    }

    // Delete Product
    @DeleteMapping("/{productId}/delete")
    @PreAuthorize("hasRole('MANAGER')")
    public ResponseEntity<?> deleteProduct(@PathVariable UUID productId, Principal principal) {
        Optional<Product> productOptional = productRepository.findById(productId);

        if (productOptional.isEmpty()) {
            return ResponseEntity.badRequest().body("Product not found");
        }

        Product product = productOptional.get();
        Branch branch = product.getBranch();

        // Validate manager access
        if (branch.getManager() != null) {
            if (!branch.getManager().getUsername().equals(principal.getName())) {
                return ResponseEntity.status(403).body("Unauthorized to delete this product");
            }
        } else {
            // Branch has no manager - verify user is a MANAGER from the same business
            Optional<User> userOptional = userRepository.findByUsername(principal.getName());
            if (userOptional.isEmpty() || userOptional.get().getRole() != Role.MANAGER) {
                return ResponseEntity.status(403).body("Only managers can delete products in branches without assigned managers");
            }
            User user = userOptional.get();
            if (user.getBusiness() == null || !user.getBusiness().equals(product.getBusiness())) {
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
            productData.put("productCode", product.getProductCode());
            productData.put("branchId", product.getBranch().getId());
            return productData;
        }).toList();

        Map<String, Object> branchData = new HashMap<>();
        branchData.put("branchName", branch.getName());
        branchData.put("products", response);

        return ResponseEntity.ok(branchData);
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
