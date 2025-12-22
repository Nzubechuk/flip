$baseUrl = "http://localhost:8080"
$managerCreds = @{ username = "manager_user"; password = "password123" }
$ceoCreds = @{ username = "ceo_user"; password = "password123" }
$clerkCreds = @{ username = "clerk_user"; password = "password123" }

function Get-Token {
    param($creds)
    try {
        $body = $creds | ConvertTo-Json
        $response = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
        return $response.accessToken
    } catch {
        Write-Host "Failed to login as $($creds.username): $_"
        return $null
    }
}

function Test-Analytics {
    param($token, $role)
    if (-not $token) { return }
    
    $headers = @{ Authorization = "Bearer $token" }
    $url = "$baseUrl/api/analytics/sales/revenue?startDate=2025-01-01&endDate=2025-12-31"
    
    try {
        Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ErrorAction Stop
        Write-Host "[$role] Success: Accessed analytics." -ForegroundColor Green
    } catch {
        Write-Host "[$role] Failed: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
             $statusCode = $_.Exception.Response.StatusCode.value__
             Write-Host "[$role] Status Code: $statusCode" -ForegroundColor Red
        }
    }
}

Write-Host "--- Testing Analytics Endpoint ---"

$ceoToken = Get-Token $ceoCreds
if ($ceoToken) { Test-Analytics $ceoToken "CEO" }

$managerToken = Get-Token $managerCreds
if ($managerToken) { Test-Analytics $managerToken "MANAGER" }

$clerkToken = Get-Token $clerkCreds
if ($clerkToken) { Test-Analytics $clerkToken "CLERK" }
