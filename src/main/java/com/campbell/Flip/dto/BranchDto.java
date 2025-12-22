package com.campbell.Flip.dto;

import java.util.UUID;

/**
 * DTO for Branch creation and updates
 */
public class BranchDto {
    private String name;
    private String location;
    private UUID managerId; // Optional: assign manager during creation

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public UUID getManagerId() {
        return managerId;
    }

    public void setManagerId(UUID managerId) {
        this.managerId = managerId;
    }
}


