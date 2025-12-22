# Flip - Inventory Management Application

A Spring Boot application for inventory management with role-based access control (CEO, MANAGER, CLERK).

## Prerequisites

- **Java 21 (LTS)** - **IMPORTANT**: This project requires Java 21. Java 25 is not yet supported due to Lombok compatibility issues.
- Maven 3.6+ (or use the included Maven wrapper)
- PostgreSQL database

### Java Version Issue

If you have Java 25 installed and encounter compilation errors like `com.sun.tools.javac.code.TypeTag :: UNKNOWN`, you need to:

1. **Install Java 21 (LTS)** from [Oracle](https://www.oracle.com/java/technologies/downloads/#java21) or [Adoptium](https://adoptium.net/temurin/releases/?version=21)
2. **Set JAVA_HOME** to point to Java 21
3. **Verify** with `java -version` that Java 21 is being used

## Setup Instructions

### 1. Database Setup

1. Install PostgreSQL if not already installed
2. Create a database:
   ```sql
   CREATE DATABASE flip_db;
   ```
3. Update database credentials in `src/main/resources/application.properties` if needed:
   ```properties
   spring.datasource.username=postgres
   spring.datasource.password=postgres
   ```

### 2. JWT Secret Key Configuration

1. Generate a secure secret key (minimum 256 bits) using the provided utility:
   ```bash
   java -cp target/classes com.campbell.Flip.SecretKeyGenerator
   ```
   Or use any secure random string generator.

2. Update the JWT secret key in `src/main/resources/application.properties`:
   ```properties
   jwt.secret.key=your-generated-secret-key-here
   ```

### 3. Build the Application

Using Maven wrapper (Windows):
```bash
.\mvnw.cmd clean install
```

Using Maven wrapper (Linux/Mac):
```bash
./mvnw clean install
```

Or using Maven directly:
```bash
mvn clean install
```

## Running the Application

### Option 1: Using Maven Wrapper (Recommended)

Windows:
```bash
.\mvnw.cmd spring-boot:run
```

Linux/Mac:
```bash
./mvnw spring-boot:run
```

### Option 2: Using Maven

```bash
mvn spring-boot:run
```

### Option 3: Using Java directly

After building:
```bash
java -jar target/Flip-0.0.1-SNAPSHOT.jar
```

## Application Endpoints

The application runs on `http://localhost:8080` by default.

### Public Endpoints
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh-token` - Refresh access token
- `POST /api/business/register` - Register a new business

### Protected Endpoints

**CEO Role:**
- `/api/business/**` - Business management

**MANAGER Role:**
- `/api/products/**` - Product management
- `/api/analytics/**` - Analytics
- `GET /api/products/barcode/{barcode}/lookup` - Lookup product by UPC/EAN-13 barcode
- `POST /api/products/{branchId}/add-from-barcode` - Add product using barcode lookup

**CLERK Role:**
- `/api/sales/**` - Sales operations
- `POST /api/sales/scan` - Scan product by barcode (UPC/EAN-13) or product code

## API Usage Example

### Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"your_username","password":"your_password"}'
```

Response:
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Using Access Token
```bash
curl -X GET http://localhost:8080/api/products/{branchId}/list \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## Barcode Scanning Features

The application now supports UPC (12 digits) and EAN-13 (13 digits) barcode scanning for both sales and product onboarding.

### Barcode Scanning for Sales

Scan a product by barcode during checkout:
```bash
curl -X POST http://localhost:8080/api/sales/scan \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"productCode":"012345678901","quantity":1}'
```

The endpoint automatically detects if the identifier is a barcode (12 or 13 digits) or a product code and searches accordingly.

### Product Onboarding with Barcode

1. **Lookup product information by barcode:**
```bash
curl -X GET http://localhost:8080/api/products/barcode/012345678901/lookup \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

Response includes product details from external barcode database:
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

2. **Add product using barcode information:**
```bash
curl -X POST "http://localhost:8080/api/products/{branchId}/add-from-barcode?barcode=012345678901&price=29.99&stock=100" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Barcode Database

The application uses the **UPC Item DB API** (free tier) for barcode lookups. The API is enabled by default but can be disabled in `application.properties`:

```properties
barcode.api.enabled=false
```

When disabled, the system will only search the local database.

## Project Structure

```
src/
├── main/
│   ├── java/com/campbell/Flip/
│   │   ├── config/          # Security configuration
│   │   ├── controllers/     # REST controllers
│   │   ├── dto/             # Data Transfer Objects
│   │   ├── entities/        # JPA entities
│   │   ├── repository/      # JPA repositories
│   │   ├── service/         # Business logic
│   │   └── util/            # Utility classes (JWT)
│   └── resources/
│       └── application.properties
└── test/                    # Test files
```

## Troubleshooting

1. **Database Connection Error**: Ensure PostgreSQL is running and credentials are correct
2. **JWT Errors**: Make sure the secret key is set in `application.properties`
3. **Port Already in Use**: Change `server.port` in `application.properties` or stop the process using port 8080

## Technologies Used

- Spring Boot 3.4.1
- Spring Security
- Spring Data JPA
- PostgreSQL
- JWT (jjwt 0.11.5)
- ZXing (QR Code generation)
- Lombok
- Maven

