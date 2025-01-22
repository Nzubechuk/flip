package com.campbell.Flip.service;

import com.campbell.Flip.entities.Business;
import com.campbell.Flip.entities.Role;
import com.campbell.Flip.entities.User;
import com.campbell.Flip.exceptions.BadCredentialsException;
import com.campbell.Flip.repository.UserRepository;
import com.campbell.Flip.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Collections;

@Service
public class UserService {
    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    public User registerCeo(String firstName, String lastName, String email, String username, String password, String businessName, String businessRegNumber) {
        Business business = new Business();
        business.setName(businessName);
        business.setBusinessRegNumber(businessRegNumber);

        User ceo = new User();
        ceo.setFirstName(firstName);
        ceo.setEmail(email);
        ceo.setLastName(lastName);
        ceo.setUsername(username);
        ceo.setPassword(passwordEncoder.encode(password));
        ceo.setRole(Role.CEO);
        ceo.setBusiness(business);

        return userRepository.save(ceo);
    }

    public String authenticate(String username, String password) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        if (passwordEncoder.matches(password, user.getPassword())) {
            // Use the generateAccessToken method from JwtUtil
            return jwtUtil.generateAccessToken(user);
        } else {
            throw new BadCredentialsException("Invalid credentials");
        }
    }
}
