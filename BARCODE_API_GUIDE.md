# UPC Barcode API Integration Guide

This application uses the **UPC Item DB API** to lookup product information by UPC (12 digits) or EAN-13 (13 digits) barcodes.

## API Configuration

### Free Tier (Default)
- **100 requests per day**
- **No API key required**
- **No sign-up needed**

### Paid Plans
- **Dev Plan**: $99/month - 20,000 lookups/day
- **Pro Plan**: $699/month - 150,000 lookups/day
- Requires API key configuration

## Configuration

Edit `src/main/resources/application.properties`:

```properties
# Enable/disable barcode API
barcode.api.enabled=true

# API base URL (default: free tier)
barcode.api.url=https://api.upcitemdb.com/prod/trial

# API key (optional - only for paid plans)
barcode.api.key=your_api_key_here

# Request timeout in seconds
barcode.api.timeout=10
```

## API Endpoints

### 1. Lookup Product by Barcode (For Onboarding)

**Endpoint:** `GET /api/products/barcode/{barcode}/lookup`

**Authorization:** Manager role required

**Example Request:**
```bash
GET /api/products/barcode/012345678901/lookup
Authorization: Bearer <token>
```

**Example Response:**
```json
{
  "barcode": "012345678901",
  "title": "Product Name",
  "description": "Product description",
  "brand": "Brand Name",
  "model": "Model Number",
  "category": "Category",
  "imageUrl": "https://example.com/image.jpg",
  "suggestedPrice": 29.99
}
```

### 2. Add Product from Barcode

**Endpoint:** `POST /api/products/{branchId}/add-from-barcode`

**Authorization:** Manager role required

**Query Parameters:**
- `barcode` (required): UPC or EAN-13 barcode
- `price` (optional): Override suggested price
- `stock` (optional): Initial stock quantity (default: 0)

**Example Request:**
```bash
POST /api/products/{branchId}/add-from-barcode?barcode=012345678901&price=29.99&stock=10
Authorization: Bearer <token>
```

### 3. Scan Product During Sale

**Endpoint:** `POST /api/sales/scan`

**Authorization:** Clerk role required

**Request Body:**
```json
{
  "productCode": "012345678901",
  "quantity": 1
}
```

The system automatically detects if the code is a barcode (12 or 13 digits) and searches accordingly.

## Supported Barcode Formats

1. **UPC (Universal Product Code)**: 12 digits
   - Example: `012345678901`

2. **EAN-13 (European Article Number)**: 13 digits
   - Example: `0123456789012`

## How It Works

1. **Local Database First**: The system first checks if the product exists in your local database
2. **External API Lookup**: If not found locally, it queries the UPC Item DB API
3. **Product Creation**: Manager can create products using the fetched information
4. **Sales Scanning**: Clerks can scan barcodes during checkout

## Error Handling

The API handles various error scenarios:

- **Product Not Found**: Returns 404 with error message
- **Rate Limit Exceeded**: Returns error message (free tier: 100/day)
- **Invalid API Key**: Returns error if using paid plan with invalid key
- **Network Errors**: Returns error if unable to connect to API
- **Invalid Barcode Format**: Returns 400 Bad Request

## Rate Limiting

### Free Tier
- **100 combined requests per day**
- Resets at midnight UTC
- Exceeding limit returns rate limit error

### Best Practices
1. **Cache Results**: Consider caching frequently looked-up products
2. **Monitor Usage**: Track API calls to avoid hitting limits
3. **Upgrade Plan**: If needed, upgrade to paid plan for higher limits

## Testing

### Test with Sample UPC Codes

Try these sample UPC codes for testing:
- `012345678901` (Generic test code)
- `036000291452` (Real product - may vary)

### Example cURL Commands

```bash
# Lookup barcode
curl -X GET "http://localhost:8080/api/products/barcode/012345678901/lookup" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Add product from barcode
curl -X POST "http://localhost:8080/api/products/{branchId}/add-from-barcode?barcode=012345678901&price=29.99&stock=10" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## API Documentation

For more information about the UPC Item DB API:
- **API Documentation**: https://www.upcitemdb.com/api/
- **Developer Portal**: https://devs.upcitemdb.com/
- **Rate Limits**: https://www.upcitemdb.com/wp/docs/main/development/api-rate-limits/

## Troubleshooting

### "Rate limit exceeded" Error
- You've exceeded the free tier limit (100 requests/day)
- Wait until next day or upgrade to paid plan
- Check `barcode.api.enabled` is set correctly

### "Unable to connect to barcode API" Error
- Check internet connection
- Verify API URL is correct
- Check firewall settings

### "Invalid API key" Error
- Verify API key is correct (paid plans only)
- Check `barcode.api.key` in application.properties
- Ensure no extra spaces in API key

### Product Not Found
- Barcode may not exist in UPC Item DB database
- Try a different barcode
- Some products may not be in the database

## Logging

The service logs important events:
- Successful lookups
- API errors
- Rate limit warnings
- Network errors

Check application logs for detailed information.


