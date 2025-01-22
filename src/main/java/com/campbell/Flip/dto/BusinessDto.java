package com.campbell.Flip.dto;

import com.campbell.Flip.entities.User;
import org.antlr.v4.runtime.misc.NotNull;

public class BusinessDto {

    @NotNull
    private String name;

    private String businessRegNumber;

    @NotNull
    private UserDto ceo;


    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getBusinessRegNumber() {
        return businessRegNumber;
    }

    public void setBusinessRegNumber(String businessRegNumber) {
        this.businessRegNumber = businessRegNumber;
    }

    public UserDto getCeo() {
        return ceo;
    }

    public void setCeo(UserDto ceo) {
        this.ceo = ceo;
    }
}
