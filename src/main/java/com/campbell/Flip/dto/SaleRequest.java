package com.campbell.Flip.dto;


import org.antlr.v4.runtime.misc.NotNull;

import java.util.List;

public class SaleRequest {

    private List<SaleItem> items;

    public List<SaleItem> getItems() { return items; }
    public void setItems(List<SaleItem> items) { this.items = items; }

    public static class SaleItem {
        @NotNull
        private String productCode;

        @NotNull
        private Integer quantity;

        private String name;
        private Double price;

        // Getters and Setters
        public String getProductCode() { return productCode; }
        public void setProductCode(String productCode) { this.productCode = productCode; }

        public Integer getQuantity() { return quantity; }
        public void setQuantity(Integer quantity) { this.quantity = quantity; }

        public String getName() { return name; }
        public void setName(String name) { this.name = name; }

        public Double getPrice() { return price; }
        public void setPrice(Double price) { this.price = price; }
    }
}
