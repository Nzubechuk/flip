package com.campbell.Flip.service;

import com.campbell.Flip.entities.User;
import com.campbell.Flip.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.Collections;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    @Autowired
    private UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        // Fetch the user from the database
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with username: " + username));

        // Map the role to a GrantedAuthority with ROLE_ prefix for hasRole() to work
        // Spring Security's hasRole() automatically adds "ROLE_" prefix when checking
        String roleName = "ROLE_" + user.getRole().name();
        GrantedAuthority authority = new SimpleGrantedAuthority(roleName);

        // Return Spring Security's User object
        return org.springframework.security.core.userdetails.User.builder()
                .username(user.getUsername())
                .password(user.getPassword()) // Password should already be encoded
                .authorities(Collections.singletonList(authority)) // Single role
                .build();
    }
}
