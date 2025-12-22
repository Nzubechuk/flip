# 403 Forbidden Error - Role Configuration Fix

## Problem
The branch endpoint (and other CEO endpoints) were returning 403 Forbidden errors because of a mismatch between how roles were defined and how they were checked.

## Root Cause
1. **SecurityConfig** was using `hasAuthority("CEO")` - expects authority "CEO"
2. **Controllers** were using `@PreAuthorize("hasRole('CEO')")` - expects authority "ROLE_CEO"
3. **CustomUserDetailsService** was creating authority as just "CEO" (without ROLE_ prefix)

Spring Security's `hasRole()` method automatically adds "ROLE_" prefix when checking, so:
- `hasRole("CEO")` looks for authority "ROLE_CEO"
- `hasAuthority("CEO")` looks for authority "CEO"

## Solution
Made everything consistent by using `hasRole()` everywhere and adding "ROLE_" prefix to authorities:

1. **Updated CustomUserDetailsService**: Now creates authorities with "ROLE_" prefix
   ```java
   String roleName = "ROLE_" + user.getRole().name(); // "ROLE_CEO"
   ```

2. **Updated SecurityConfig**: Changed from `hasAuthority()` to `hasRole()`
   ```java
   .requestMatchers("/api/business/**").hasRole("CEO")  // Now expects "ROLE_CEO"
   ```

## Testing
After this fix:
1. **Re-authenticate** - Get a new JWT token (old tokens won't work with new role format)
2. **Use the new token** in Authorization header: `Bearer <new_token>`
3. **Test the endpoint** - Should now work correctly

## Important Notes
- **Old JWT tokens won't work** - Users need to login again to get new tokens
- The role in the JWT token claim is still just "CEO" (not "ROLE_CEO"), but that's fine because we load the user from database and add the prefix
- This follows Spring Security best practices for role-based access control


