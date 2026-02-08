# UUID Migration Notes

All entity IDs have been migrated from `Long` (integer) to `UUID` (Universally Unique Identifier).

## Changes Made

### 1. Entity Classes
All entity classes now use `UUID` for their `id` field:
- `User`
- `Business`
- `Branch`
- `Product`
- `Sale`
- `SaleItem`

**Generation Strategy:**
```java
@Id
@GeneratedValue(strategy = GenerationType.UUID)
private UUID id;
```

### 2. Repository Interfaces
All repositories now use `UUID` as the ID type:
- `UserRepository extends JpaRepository<User, UUID>`
- `BusinessRepository extends JpaRepository<Business, UUID>`
- `BranchRepository extends JpaRepository<Branch, UUID>`
- `ProductRepository extends JpaRepository<Product, UUID>`
- `SalesRepository extends JpaRepository<Sale, UUID>`
- `SaleItemRepository extends JpaRepository<SaleItem, UUID>`

### 3. Controllers
All controller endpoints that accept IDs in path variables now use `UUID`:
- `@PathVariable UUID businessId`
- `@PathVariable UUID branchId`
- `@PathVariable UUID productId`
- `@PathVariable UUID managerId`
- `@PathVariable UUID clerkId`
- etc.

### 4. Service Classes
Service methods that work with entity IDs now use `UUID`:
- `ProductService.generateProductQRCode(UUID productId)`
- `ProductService.updateStock(UUID productId, ...)`
- `ProductService.createProductFromBarcode(..., UUID branchId, ...)`

### 5. DTOs
DTOs that reference entity IDs have been updated:
- `WorkerDTO.branchId` is now `UUID`

## Database Migration

### Important Notes:

1. **Existing Data:** If you have existing data in your database, you'll need to:
   - Drop existing tables (data will be lost)
   - Let Hibernate recreate them with UUID columns
   - OR manually migrate existing data (complex process)

2. **PostgreSQL UUID Support:**
   - PostgreSQL natively supports UUID type
   - The `GenerationType.UUID` strategy will automatically use PostgreSQL's UUID type
   - No additional extensions needed (UUID is built-in)

3. **Fresh Database:**
   - If starting fresh, simply set `spring.jpa.hibernate.ddl-auto=update` or `create`
   - Hibernate will create tables with UUID columns automatically

### To Reset Database (Development Only):

```sql
-- Drop all tables (WARNING: This deletes all data!)
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
```

Then restart the application - Hibernate will recreate all tables with UUID IDs.

## API Changes

### URL Format Changes

**Before (Long IDs):**
```
GET /api/products/1/details
POST /api/business/1/register-manager
```

**After (UUID IDs):**
```
GET /api/products/550e8400-e29b-41d4-a716-446655440000/details
POST /api/business/550e8400-e29b-41d4-a716-446655440000/register-manager
```

### Example UUID Format:
```
550e8400-e29b-41d4-a716-446655440000
```

## Benefits of UUID

1. **Security:** UUIDs don't expose sequential information about your data
2. **Distributed Systems:** Can generate IDs without coordination
3. **No Collisions:** Virtually impossible to have duplicate IDs
4. **Privacy:** Harder to guess or enumerate resources

## Testing in Postman

When testing endpoints, use UUID format in URLs:

```
GET http://localhost:8080/api/business/{businessId}/managers
```

Where `{businessId}` is a UUID like: `550e8400-e29b-41d4-a716-446655440000`

**Note:** After registering a business, the response will include a `businessId` in UUID format. Use that UUID for subsequent requests.

## Compilation Status

✅ All code compiles successfully
✅ All entities use UUID
✅ All repositories use UUID
✅ All controllers use UUID
✅ All services use UUID

## Next Steps

1. **Backup existing database** (if you have data)
2. **Reset database** (development) or **migrate data** (production)
3. **Test all endpoints** with UUID format
4. **Update any frontend code** to use UUID instead of Long



