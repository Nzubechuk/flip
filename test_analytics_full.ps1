$baseUrl = "http://localhost:8080"
$timestamp = Get-Date -Format "yyyyMMddHHmmss"

# 1. Register Business (creates CEO)
$ceoUsername = "ceo_$timestamp"
$ceoPassword = "password123"
$businessRegBody = @{
    name = "Test Business $timestamp"
    ceo = @{
        username = $ceoUsername
        password = $ceoPassword
        firstname = "Test"
        lastname = "CEO"
        email = "ceo_$timestamp@test.com"
    }
}

Write-Host "1. Registering Business (CEO)..."
try {
    $item = Invoke-RestMethod -Uri "$baseUrl/api/business/register" -Method Post -Body ($businessRegBody | ConvertTo-Json) -ContentType "application/json"
    $businessId = $item.businessId
    Write-Host "   Success! Business ID: $businessId" -ForegroundColor Green
} catch {
    Write-Host "   Failed to register business: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# 2. Login as CEO
Write-Host "2. Logging in as CEO..."
try {
    $loginBody = @{ username = $ceoUsername; password = $ceoPassword } | ConvertTo-Json
    $ceoLogin = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    $ceoToken = $ceoLogin.accessToken
    Write-Host "   Success! CEO Token obtained." -ForegroundColor Green
} catch {
    Write-Host "   Failed to login as CEO: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# 3. Register Manager (using CEO token)
$managerUsername = "manager_$timestamp"
$managerPassword = "password123"
$managerRegBody = @{
    username = $managerUsername
    password = $managerPassword
    firstname = "Test"
    lastname = "Manager"
    email = "manager_$timestamp@test.com"
    branchId = 1 # Assuming branch 1 exists or is created? Actually we might need to create a branch first or just ignore if optional.
    # Guide says branchId is optional.
}

Write-Host "3. Registering Manager..."
try {
    $headers = @{ Authorization = "Bearer $ceoToken" }
    # URL: /api/business/{businessId}/register-manager
    # Note: businessId from step 1
    Invoke-RestMethod -Uri "$baseUrl/api/business/$businessId/register-manager" -Method Post -Body ($managerRegBody | ConvertTo-Json) -ContentType "application/json" -Headers $headers
    Write-Host "   Success! Manager registered." -ForegroundColor Green
} catch {
    Write-Host "   Failed to register manager: $($_.Exception.Message)" -ForegroundColor Red
    # Continue anyway to see if login works (maybe it failed but user created?)
}

# 4. Login as Manager
Write-Host "4. Logging in as New Manager..."
$managerToken = $null
try {
    $loginBody = @{ username = $managerUsername; password = $managerPassword } | ConvertTo-Json
    $managerLogin = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    $managerToken = $managerLogin.accessToken
    Write-Host "   Success! Manager Token obtained." -ForegroundColor Green
} catch {
    Write-Host "   Failed to login as Manager: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# 5. Access Analytics as Manager
Write-Host "5. accessing Analytics as New Manager..."
try {
    $headers = @{ Authorization = "Bearer $managerToken" }
    $url = "$baseUrl/api/analytics/sales/revenue?startDate=2025-01-01&endDate=2025-12-31"
    $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers
    Write-Host "   Success! Analytics Result: $response" -ForegroundColor Green
} catch {
    Write-Host "   Failed to access analytics: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "   Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    }
}
