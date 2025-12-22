package com.campbell.Flip.service;

import com.campbell.Flip.dto.BarcodeProductInfo;
import com.campbell.Flip.entities.Product;
import com.campbell.Flip.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.UUID;

@Service
public class ProductService {

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private QRCodeService qrCodeService;

    @Autowired
    private BarcodeService barcodeService;


    public String generateProductQRCode(UUID productId) throws Exception {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new IllegalArgumentException("Product not found with ID: " + productId));

        if (product.getProductCode() == null || product.getProductCode().isEmpty()) {
            throw new IllegalArgumentException("Product code cannot be null or empty");
        }

        return qrCodeService.generateQRCode(product.getName(), product.getProductCode());
    }

    public Product updateStock(UUID productId, int quantitySold) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new IllegalArgumentException("Product not found with ID: " + productId));

        if (quantitySold < 0) {
            throw new IllegalArgumentException("Quantity sold cannot be negative");
        }

        if (product.getStock() < quantitySold) {
            throw new IllegalArgumentException("Insufficient stock for product: " + product.getName());
        }

        product.setStock(product.getStock() - quantitySold);
        return productRepository.save(product);
    }

    public Product getProductCode(String productCode) {
        if (productCode == null || productCode.trim().isEmpty()) {
            throw new IllegalArgumentException("Product code cannot be null or empty");
        }

        return productRepository.findByProductCode(productCode)
                .orElseThrow(() -> new RuntimeException("Product not found with code: " + productCode));
    }

    /**
     * Lookup product by barcode (UPC or EAN-13)
     * First checks local database, then external barcode database if not found
     */
    public Product getProductByBarcode(String barcode) {
        if (barcode == null || barcode.trim().isEmpty()) {
            throw new IllegalArgumentException("Barcode cannot be null or empty");
        }

        String normalizedBarcode = barcode.replaceAll("[^0-9]", "");

        // First, try to find in local database by UPC
        Optional<Product> productByUpc = productRepository.findByUpc(normalizedBarcode);
        if (productByUpc.isPresent()) {
            return productByUpc.get();
        }

        // Then try EAN-13
        Optional<Product> productByEan = productRepository.findByEan13(normalizedBarcode);
        if (productByEan.isPresent()) {
            return productByEan.get();
        }

        // If not found locally, try external barcode database
        try {
            BarcodeProductInfo barcodeInfo = barcodeService.lookupBarcode(normalizedBarcode);
            if (barcodeInfo != null) {
                throw new ProductNotFoundException("Product found in barcode database but not in local inventory. " +
                        "Please add product first. Product: " + barcodeInfo.getTitle());
            }
        } catch (BarcodeService.BarcodeApiException e) {
            // Re-throw API exceptions with more context
            throw new ProductNotFoundException("Unable to lookup barcode: " + e.getMessage());
        }

        throw new ProductNotFoundException("Product not found with barcode: " + barcode);
    }

    /**
     * Lookup product information from barcode database for onboarding
     * Returns product information that can be used to create a new product
     */
    public BarcodeProductInfo lookupBarcodeForOnboarding(String barcode) {
        if (barcode == null || barcode.trim().isEmpty()) {
            throw new IllegalArgumentException("Barcode cannot be null or empty");
        }

        String normalizedBarcode = barcode.replaceAll("[^0-9]", "");

        // Check if product already exists
        Optional<Product> existingProduct = productRepository.findByUpc(normalizedBarcode);
        if (existingProduct.isPresent()) {
            throw new IllegalArgumentException("Product with UPC " + normalizedBarcode + " already exists");
        }

        existingProduct = productRepository.findByEan13(normalizedBarcode);
        if (existingProduct.isPresent()) {
            throw new IllegalArgumentException("Product with EAN-13 " + normalizedBarcode + " already exists");
        }

        // Lookup in external database
        try {
            BarcodeProductInfo info = barcodeService.lookupBarcode(normalizedBarcode);
            if (info == null) {
                throw new ProductNotFoundException("Product not found in barcode database: " + barcode);
            }
            return info;
        } catch (BarcodeService.BarcodeApiException e) {
            // Re-throw API exceptions with more context
            throw new ProductNotFoundException("Unable to lookup barcode: " + e.getMessage());
        }
    }

    /**
     * Create or update product with barcode information
     */
    public Product createProductFromBarcode(BarcodeProductInfo barcodeInfo, UUID branchId, Double price, Integer stock) {
        if (barcodeInfo == null || barcodeInfo.getBarcode() == null) {
            throw new IllegalArgumentException("Barcode information is required");
        }

        String normalizedBarcode = barcodeInfo.getBarcode().replaceAll("[^0-9]", "");
        BarcodeService.BarcodeType barcodeType = barcodeService.getBarcodeType(normalizedBarcode);

        Product product = new Product();
        product.setName(barcodeInfo.getTitle() != null ? barcodeInfo.getTitle() : "Unknown Product");
        product.setDescription(barcodeInfo.getDescription());
        product.setPrice(price != null ? price : (barcodeInfo.getSuggestedPrice() != null ? barcodeInfo.getSuggestedPrice() : 0.0));
        product.setStock(stock != null ? stock : 0);

        // Set barcode based on type
        if (barcodeType == BarcodeService.BarcodeType.UPC) {
            product.setUpc(normalizedBarcode);
        } else if (barcodeType == BarcodeService.BarcodeType.EAN13) {
            product.setEan13(normalizedBarcode);
        }

        // Generate product code from barcode if not provided
        product.setProductCode(normalizedBarcode);

        return product;
    }

    public static class ProductNotFoundException extends RuntimeException {
        public ProductNotFoundException(String message) {
            super(message);
        }
    }
}
