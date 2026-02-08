package com.campbell.Flip.dto;

import org.antlr.v4.runtime.misc.NotNull;

public class ProductDTO {
    private String name;
    private String description;
    private Double price;
    private Integer stock;
    private String productCode;
    private String upc;
    private String ean13;

    private String category;
    private java.util.UUID branchId;


    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Double getPrice() {
        return price;
    }

    public void setPrice(Double price) {
        this.price = price;
    }

    public Integer getStock() {
        return stock;
    }

    public void setStock(Integer stock) {
        this.stock = stock;
    }

    public String getProductCode() {
        return productCode;
    }

    public void setProductCode(String productCode) {
        this.productCode = productCode;
    }

    public String getUpc() {
        return upc;
    }

    public void setUpc(String upc) {
        this.upc = upc;
    }

    public String getEan13() {
        return ean13;
    }

    public void setEan13(String ean13) {
        this.ean13 = ean13;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public java.util.UUID getBranchId() {
        return branchId;
    }

    public void setBranchId(java.util.UUID branchId) {
        this.branchId = branchId;
    }
}
