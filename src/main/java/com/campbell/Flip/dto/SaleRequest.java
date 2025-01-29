package com.campbell.Flip.dto;

import java.util.List;

public class SaleRequest {
    private List<SaleItem> items;

    // Getters and Setters
    public List<SaleItem> getItems() {
        return items;
    }

    public void setItems(List<SaleItem> items) {
        this.items = items;
    }

    public static class SaleItem {
        private String productCode;
        private int quantity;

        // Getters and Setters
        public String getProductCode() {
            return productCode;
        }

        public void setProductCode(String productCode) {
            this.productCode = productCode;
        }

        public int getQuantity() {
            return quantity;
        }

        public void setQuantity(int quantity) {
            this.quantity = quantity;
        }
    }
}
