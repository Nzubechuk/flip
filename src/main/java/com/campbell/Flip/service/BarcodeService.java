package com.campbell.Flip.service;

import com.campbell.Flip.dto.BarcodeProductInfo;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientRequestException;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.time.Duration;

/**
 * Service for looking up product information from UPC Item DB API
 * Supports UPC (12 digits) and EAN-13 (13 digits) barcode formats
 * 
 * API Documentation: https://www.upcitemdb.com/api/
 * Free Tier: 100 requests per day (no API key required)
 * Paid Plans: Require API key in header
 */
@Service
public class BarcodeService {

    private static final Logger logger = LoggerFactory.getLogger(BarcodeService.class);
    
    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    @Value("${barcode.api.url:https://api.upcitemdb.com/prod/trial}")
    private String barcodeApiBaseUrl;

    @Value("${barcode.api.enabled:true}")
    private boolean apiEnabled;

    @Value("${barcode.api.key:}")
    private String apiKey; // Optional: for paid plans

    @Value("${barcode.api.timeout:10}")
    private int timeoutSeconds;

    public BarcodeService() {
        this.objectMapper = new ObjectMapper();
        this.webClient = WebClient.builder()
                .baseUrl("https://api.upcitemdb.com/prod/trial")
                .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(2 * 1024 * 1024))
                .build();
    }

    /**
     * Lookup product information by barcode (UPC or EAN-13)
     * @param barcode The barcode to lookup (UPC 12 digits or EAN-13 13 digits)
     * @return BarcodeProductInfo containing product details, or null if not found
     */
    public BarcodeProductInfo lookupBarcode(String barcode) {
        if (barcode == null || barcode.trim().isEmpty()) {
            throw new IllegalArgumentException("Barcode cannot be null or empty");
        }

        // Normalize barcode (remove spaces, dashes)
        String normalizedBarcode = barcode.replaceAll("[^0-9]", "");

        // Validate barcode format
        if (!isValidBarcode(normalizedBarcode)) {
            throw new IllegalArgumentException("Invalid barcode format. Must be UPC (12 digits) or EAN-13 (13 digits)");
        }

        if (!apiEnabled) {
            logger.debug("Barcode API is disabled. Skipping external lookup for barcode: {}", normalizedBarcode);
            return null; // API disabled, return null to use local database lookup
        }

        try {
            logger.info("Looking up barcode in UPC Item DB: {}", normalizedBarcode);
            
            // Build request with optional API key for paid plans
            WebClient.RequestHeadersSpec<?> requestSpec = webClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/lookup")
                            .queryParam("upc", normalizedBarcode)
                            .build());
            
            // Add API key header if provided (for paid plans)
            if (apiKey != null && !apiKey.trim().isEmpty()) {
                requestSpec = (WebClient.RequestHeadersSpec<?>) requestSpec.header("user_key", apiKey.trim());
                logger.debug("Using API key for barcode lookup");
            }

            // Make API call
            String response = requestSpec
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(timeoutSeconds))
                    .block();

            BarcodeProductInfo result = parseApiResponse(response, normalizedBarcode);
            if (result != null) {
                logger.info("Successfully found product in UPC Item DB: {}", result.getTitle());
            } else {
                logger.debug("Product not found in UPC Item DB for barcode: {}", normalizedBarcode);
            }
            return result;
            
        } catch (WebClientResponseException.NotFound e) {
            // Product not found in external database
            logger.debug("Product not found in UPC Item DB (404): {}", normalizedBarcode);
            return null;
        } catch (WebClientResponseException.TooManyRequests e) {
            // Rate limit exceeded
            logger.warn("UPC Item DB rate limit exceeded for barcode: {}. Please wait or upgrade plan.", normalizedBarcode);
            throw new BarcodeApiException("Rate limit exceeded. Please try again later or upgrade your API plan.");
        } catch (WebClientResponseException.Unauthorized e) {
            // Invalid API key
            logger.error("Unauthorized access to UPC Item DB. Check API key configuration.");
            throw new BarcodeApiException("Invalid API key. Please check your barcode.api.key configuration.");
        } catch (WebClientRequestException e) {
            // Network/connection error
            logger.error("Network error connecting to UPC Item DB: {}", e.getMessage());
            throw new BarcodeApiException("Unable to connect to barcode API. Please check your internet connection.");
        } catch (Exception e) {
            // Other errors
            logger.error("Error looking up barcode in external API: {}", e.getMessage(), e);
            throw new BarcodeApiException("Error looking up barcode: " + e.getMessage());
        }
    }

    /**
     * Validate barcode format (UPC or EAN-13)
     */
    private boolean isValidBarcode(String barcode) {
        if (barcode == null) {
            return false;
        }
        // UPC: 12 digits, EAN-13: 13 digits
        return barcode.matches("^\\d{12}$") || barcode.matches("^\\d{13}$");
    }

    /**
     * Parse API response from UPC Item DB
     * Response format: {"code": "OK", "total": 1, "offset": 0, "items": [...]}
     */
    private BarcodeProductInfo parseApiResponse(String response, String barcode) {
        try {
            if (response == null || response.trim().isEmpty()) {
                logger.warn("Empty response from UPC Item DB API");
                return null;
            }

            JsonNode rootNode = objectMapper.readTree(response);
            String code = rootNode.path("code").asText();
            String message = rootNode.path("message").asText("");

            // Check response code
            if (!"OK".equals(code)) {
                logger.debug("UPC Item DB returned code '{}': {}", code, message);
                return null; // Product not found or error
            }

            JsonNode items = rootNode.path("items");
            if (!items.isArray() || items.size() == 0) {
                logger.debug("No items found in UPC Item DB response");
                return null;
            }

            // Use first item (most relevant result)
            JsonNode firstItem = items.get(0);
            BarcodeProductInfo info = new BarcodeProductInfo();
            info.setBarcode(barcode);
            
            // Extract basic product information
            info.setTitle(firstItem.path("title").asText("").trim());
            info.setDescription(firstItem.path("description").asText("").trim());
            info.setBrand(firstItem.path("brand").asText("").trim());
            info.setModel(firstItem.path("model").asText("").trim());
            info.setCategory(firstItem.path("category").asText("").trim());
            
            // Extract images (API may return array of image URLs)
            JsonNode images = firstItem.path("images");
            if (images.isArray() && images.size() > 0) {
                // Use first image URL
                String imageUrl = images.get(0).asText("").trim();
                if (!imageUrl.isEmpty()) {
                    info.setImageUrl(imageUrl);
                }
            } else if (images.isTextual()) {
                // Sometimes images is a single string
                String imageUrl = images.asText("").trim();
                if (!imageUrl.isEmpty()) {
                    info.setImageUrl(imageUrl);
                }
            }

            // Extract price from offers
            JsonNode offers = firstItem.path("offers");
            if (offers.isArray() && offers.size() > 0) {
                JsonNode firstOffer = offers.get(0);
                String priceStr = firstOffer.path("price").asText("").trim();
                if (!priceStr.isEmpty()) {
                    try {
                        // Remove currency symbols and commas, then parse
                        String cleanPrice = priceStr.replaceAll("[^0-9.]", "");
                        if (!cleanPrice.isEmpty()) {
                            info.setSuggestedPrice(Double.parseDouble(cleanPrice));
                        }
                    } catch (NumberFormatException e) {
                        logger.debug("Could not parse price: {}", priceStr);
                    }
                }
            }

            // If title is empty, try alternative fields
            if (info.getTitle().isEmpty()) {
                String name = firstItem.path("name").asText("").trim();
                if (!name.isEmpty()) {
                    info.setTitle(name);
                }
            }

            logger.debug("Parsed product info: {} - {}", info.getTitle(), info.getBrand());
            return info;
            
        } catch (com.fasterxml.jackson.core.JsonProcessingException e) {
            logger.error("Error parsing JSON response from UPC Item DB: {}", e.getMessage());
            return null;
        } catch (Exception e) {
            logger.error("Unexpected error parsing barcode API response: {}", e.getMessage(), e);
            return null;
        }
    }

    /**
     * Determine if a barcode is UPC (12 digits) or EAN-13 (13 digits)
     */
    public BarcodeType getBarcodeType(String barcode) {
        if (barcode == null) {
            return null;
        }
        String normalized = barcode.replaceAll("[^0-9]", "");
        if (normalized.length() == 12) {
            return BarcodeType.UPC;
        } else if (normalized.length() == 13) {
            return BarcodeType.EAN13;
        }
        return null;
    }

    public enum BarcodeType {
        UPC, EAN13
    }

    /**
     * Custom exception for barcode API errors
     */
    public static class BarcodeApiException extends RuntimeException {
        public BarcodeApiException(String message) {
            super(message);
        }

        public BarcodeApiException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}

