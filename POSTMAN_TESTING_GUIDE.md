# Postman Testing Guide for Flip Application

This guide will help you test all API endpoints using Postman.

## Base URL
```
http://localhost:8080
```

## Step 1: Setup Postman Environment

1. Open Postman
2. Click on "Environments" → "Create Environment"
3. Name it "Flip Local"
4. Add these variables:
   - `base_url`: `http://localhost:8080`
   - `access_token`: (leave empty, will be set automatically)
   - `refresh_token`: (leave empty, will be set automatically)

## Step 2: Authentication (Get Access Token)

### 2.1 Login

**Request:**
- **Method:** `POST`
- **URL:** `{{base_url}}/api/auth/login`
- **Headers:**
  - `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "username": "your_username",
  "password": "your_password"
}
```

**Expected Response:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Postman Test Script (to auto-save token):**
```javascript
if (pm.response.code === 200) {
    var jsonData = pm.response.json();
    pm.environment.set("access_token", jsonData.accessToken);
    pm.environment.set("refresh_token", jsonData.refreshToken);
}
```

### 2.2 Refresh Token

**Request:**
- **Method:** `POST`
- **URL:** `{{base_url}}/api/auth/refresh-token`
- **Headers:**
  - `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "refreshToken": "{{refresh_token}}"
}
```

## Step 3: Protected Endpoints (Require Authentication)

For all protected endpoints, add this header:
- **Authorization:** `Bearer {{access_token}}`

---

## Business Endpoints (CEO Role)

### Register Manager

**Request:**
- **Method:** `POST`
- **URL:** `{{base_url}}/api/business/{businessId}/register-manager`
- **Headers:**
  - `Authorization: Bearer {{access_token}}`
  - `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "username": "manager_user",
  "password": "password123",
  "firstname": "Jane",
  "lastname": "Smith",
  "email": "manager@example.com",
  "branchId": 1
}
```

**Note:** `branchId` is optional. If provided, the manager will be assigned to that branch and become the branch manager.

**Expected Response:**
```json
{
  "message": "Manager registered successfully",
  "managerId": 2,
  "username": "manager_user",
  "firstName": "Jane",
  "lastName": "Smith",
  "email": "manager@example.com",
  "branchId": 1,
  "branchName": "Main Branch"
}
```

### Register Clerk

**Request:**
- **Method:** `POST`
- **URL:** `{{base_url}}/api/business/{businessId}/register-clerk`
- **Headers:**
  - `Authorization: Bearer {{access_token}}`
  - `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "username": "clerk_user",
  "password": "password123",
  "firstname": "Bob",
  "lastname": "Johnson",
  "email": "clerk@example.com",
  "branchId": 1
}
```

**Note:** `branchId` is optional. If provided, the clerk will be assigned to that branch.

**Expected Response:**
```json
{
  "message": "Clerk registered successfully",
  "clerkId": 3,
  "username": "clerk_user",
  "firstName": "Bob",
  "lastName": "Johnson",
  "email": "clerk@example.com",
  "branchId": 1,
  "branchName": "Main Branch"
}
```

### List All Managers

**Request:**
- **Method:** `GET`
- **URL:** `{{base_url}}/api/business/{businessId}/managers`
- **Headers:**
  - `Authorization: Bearer {{access_token}}`

**Expected Response:**
```json
[
  {
    "managerId": 2,
    "username": "manager_user",
    "firstName": "Jane",
    "lastName": "Smith",
    "email": "manager@example.com",
    "branchId": 1,
    "branchName": "Main Branch"
  }
]
```

### List All Clerks

**Request:**
- **Method:** `GET`
- **URL:** `{{base_url}}/api/business/{businessId}/clerks`
- **Headers:**
  - `Authorization: Bearer {{access_token}}`

**Expected Response:**
```json
[
  {
    "clerkId": 3,
    "username": "clerk_user",
    "firstName": "Bob",
    "lastName": "Johnson",
    "email": "clerk@example.com",
    "branchId": 1,
    "branchName": "Main Branch"
  }
]
```

### Create Branch

**Request:**
- **Method:** `POST`
- **URL:** `{{base_url}}/api/business/{businessId}/create-branch`
- **Headers:**
  - `Authorization: Bearer {{access_token}}`
  - `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "name": "Main Branch",
  "location": "123 Main Street, City",
  "managerId": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Note:** 
- `name` is required
- `location` is optional
- `managerId` is optional - if provided, assigns a manager to the branch during creation

**Expected Response:**
```json
{
  "message": "Branch created successfully",
  "branchId": "550e8400-e29b-41d4-a716-446655440000",
  "branchName": "Main Branch",
  "location": "123 Main Street, City",
  "businessId": "550e8400-e29b-41d4-a716-446655440001",
  "businessName": "My Business",
  "manager": {
    "managerId": "550e8400-e29b-41d4-a716-446655440000",
    "username": "manager_user",
    "firstName": "Jane",
    "lastName": "Smith"
  }
}
```

### Register Business

**Request:**
- **Method:** `POST`
- **URL:** `{{base_url}}/api/business/register`
- **Headers:**
  - `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "name": "My Business",
  "businessRegNumber": "BR123456",
  "ceo": {
    "username": "ceo_user",
    "password": "password123",
    "firstname": "John",
    "lastname": "Doe",
    "email": "ceo@example.com"
  }
}
```

**Note:** The `businessRegNumber` field is optional. All CEO fields are required.

**Expected Response:**
```json
{
  "message": "Business registered successfully",
  "businessId": 1,
  "businessName": "My Business",
  "ceo": {
    "username": "ceo_user",
    "firstName": "John",
    "lastName": "Doe",
    "email": "ceo@example.com"
  }
}
```

---

## Product Endpoints (MANAGER Role)

### Lookup Product by Barcode (UPC/EAN-13)

**Request:**
- **Method:** `GET`
- **URL:** `{{base_url}}/api/products/barcode/012345678901/lookup`
- **Headers:**
  - `Authorization: Bearer {{access_token}}`
- **Note:** Replace `012345678901` with actual barcode (12 digits for UPC, 13 for EAN-13)

**Expected Response:**
```json
{
  "barcode": "012345678901",
  "title": "Product Name",
  "description": "Product description",
  "brand": "Brand Name",
  "model": "Model Number",
  "category": "Category",
  "imageUrl": "https://...",
  "suggestedPrice": 29.99
}
```

### Add Product from Barcode

**Request:**
- **Method:** `POST`
- **URL:** `{{base_url}}/api/products/{branchId}/add-from-barcode?barcode=012345678901&price=29.99&stock=100`
- **Headers:**
  - `Authorization: Bearer {{access_token}}`
- **Note:** Replace `{branchId}` with actual branch ID

### Add Product Manually

**Request:**
- **Method:** `POST`
- **URL:** `{{base_url}}/api/products/{branchId}/add`
- **Headers:**
  - `Authorization: Bearer {{access_token}}`
  - `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "name": "Product Name",
  "description": "Product description",
  "price": 29.99,
  "stock": 100,
  "productCode": "PROD001",
  "upc": "012345678901",
  "ean13": "0123456789012"
}
```

### List Products by Branch

**Request:**
- **Method:** `GET`
- **URL:** `{{base_url}}/api/products/{branchId}/list`
- **Headers:**
  - `Authorization: Bearer {{access_token}}`

### Get Product Details by Code

**Request:**
- **Method:** `GET`
- **URL:** `{{base_url}}/api/products/{productCode}/details`
- **Headers:**
  - `Authorization: Bearer {{access_token}}`

### Update Product

**Request:**
- **Method:** `PUT`
- **URL:** `{{base_url}}/api/products/{productId}/update`
- **Headers:**
  - `Authorization: Bearer {{access_token}}`
  - `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "name": "Updated Product Name",
  "description": "Updated description",
  "price": 39.99,
  "stock": 150,
  "productCode": "PROD001",
  "upc": "012345678901",
  "ean13": "0123456789012"
}
```

### Delete Product

**Request:**
- **Method:** `DELETE`
- **URL:** `{{base_url}}/api/products/{productId}/delete`
- **Headers:**
  - `Authorization: Bearer {{access_token}}`

### Generate QR Code for Product

**Request:**
- **Method:** `POST`
- **URL:** `{{base_url}}/api/products/{productId}/generate-qrcode`
- **Headers:**
  - `Authorization: Bearer {{access_token}}`

### Update Stock

**Request:**
- **Method:** `POST`
- **URL:** `{{base_url}}/api/products/{productId}/update-stock?quantitySold=5`
- **Headers:**
  - `Authorization: Bearer {{access_token}}`

---

## Sales Endpoints (CLERK Role)

### Scan Product (by Barcode or Product Code)

**Request:**
- **Method:** `POST`
- **URL:** `{{base_url}}/api/sales/scan`
- **Headers:**
  - `Authorization: Bearer {{access_token}}`
  - `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "productCode": "012345678901",
  "quantity": 1
}
```

**Note:** The `productCode` field accepts:
- Barcode (UPC: 12 digits, EAN-13: 13 digits)
- Product code (any other format)

**Expected Response:**
```json
{
  "productId": 1,
  "name": "Product Name",
  "price": 29.99,
  "productCode": "012345678901",
  "upc": "012345678901",
  "ean13": null,
  "stock": 100
}
```

### Finalize Sale

**Request:**
- **Method:** `POST`
- **URL:** `{{base_url}}/api/sales/finalize`
- **Headers:**
  - `Authorization: Bearer {{access_token}}`
  - `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "items": [
    {
      "productCode": "012345678901",
      "quantity": 2
    },
    {
      "productCode": "PROD001",
      "quantity": 1
    }
  ]
}
```

**Expected Response:**
```json
{
  "totalPrice": 89.97,
  "items": ["Product Name 1", "Product Name 2"],
  "date": "2025-12-06T12:00:00"
}
```

---

## Analytics Endpoints (MANAGER Role)

### Get Sales Analytics

**Request:**
- **Method:** `GET`
- **URL:** `{{base_url}}/api/analytics/sales/revenue?startDate=2025-01-01&endDate=2025-12-31`
- **Headers:**
  - `Authorization: Bearer {{access_token}}`

### Get Product Analytics

**Request:**
- **Method:** `GET`
- **URL:** `{{base_url}}/api/analytics/products/low-stock?threshold=10`
- **Headers:**
  - `Authorization: Bearer {{access_token}}`

---

## Postman Collection Setup

### Create a Collection

1. Click "New" → "Collection"
2. Name it "Flip API"
3. Add the environment variable reference: `{{base_url}}`

### Add Pre-request Script (for all requests)

In the Collection settings → Pre-request Script:
```javascript
// Auto-add Authorization header if token exists
if (pm.environment.get("access_token")) {
    pm.request.headers.add({
        key: "Authorization",
        value: "Bearer " + pm.environment.get("access_token")
    });
}
```

### Common Test Scripts

Add to Collection → Tests:
```javascript
// Check if response is successful
pm.test("Status code is 200 or 201", function () {
    pm.expect(pm.response.code).to.be.oneOf([200, 201]);
});

// Auto-save tokens from login
if (pm.request.url.toString().includes("/api/auth/login")) {
    if (pm.response.code === 200) {
        var jsonData = pm.response.json();
        pm.environment.set("access_token", jsonData.accessToken);
        pm.environment.set("refresh_token", jsonData.refreshToken);
    }
}
```

---

## Testing Workflow

### Complete Testing Flow

1. **Start the application:**
   ```powershell
   .\SET_JAVA21.ps1
   .\mvnw.cmd spring-boot:run
   ```

2. **Test Authentication:**
   - Login endpoint (save token automatically)

3. **Test Product Onboarding with Barcode:**
   - Lookup barcode: `GET /api/products/barcode/{barcode}/lookup`
   - Add product from barcode: `POST /api/products/{branchId}/add-from-barcode`

4. **Test Sales with Barcode:**
   - Scan product: `POST /api/sales/scan` (use barcode in productCode field)
   - Finalize sale: `POST /api/sales/finalize`

---

## Common Issues & Solutions

### Issue: 401 Unauthorized
**Solution:** Make sure you've logged in and the token is set in environment variables.

### Issue: 403 Forbidden
**Solution:** Check that your user has the correct role (CEO, MANAGER, or CLERK).

### Issue: Barcode not found
**Solution:** 
- Verify barcode format (12 digits for UPC, 13 for EAN-13)
- Check if barcode API is enabled in `application.properties`
- Try a known barcode like: `012345678901` (test barcode)

### Issue: Connection refused
**Solution:** Make sure the Spring Boot application is running on port 8080.

---

## Sample Test Barcodes

For testing purposes, you can use these sample barcodes:
- UPC: `012345678901`
- EAN-13: `0123456789012`

**Note:** Real barcodes from products will return actual product information from the UPC Item DB API.

---

## Quick Reference: All Endpoints

### Public Endpoints
- `POST /api/auth/login`
- `POST /api/auth/refresh-token`
- `POST /api/business/register`

### CEO Endpoints
- `GET /api/business/**`
- `POST /api/business/**`

### MANAGER Endpoints
- `GET /api/products/**`
- `POST /api/products/**`
- `PUT /api/products/**`
- `DELETE /api/products/**`
- `GET /api/analytics/**`

### CLERK Endpoints
- `POST /api/sales/scan`
- `POST /api/sales/finalize`

---

## Tips

1. **Use Environment Variables:** Always use `{{base_url}}` and `{{access_token}}` instead of hardcoding values.

2. **Save Responses:** Use Postman's "Save Response" feature to save example responses.

3. **Use Collections:** Organize requests into folders (Auth, Products, Sales, etc.).

4. **Test Scripts:** Add validation tests to ensure APIs work correctly.

5. **Variables:** Use variables for IDs (like `{{branchId}}`, `{{productId}}`) that you get from previous requests.

