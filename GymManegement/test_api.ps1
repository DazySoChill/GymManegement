# API Test Script
$baseUrl = "http://localhost:5250"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing API Endpoints with Seed Data" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Admin Login
Write-Host "1. Testing Admin Login..." -ForegroundColor Yellow
try {
    $body = @{username='admin'; password='password'} | ConvertTo-Json
    $response = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login" -Method Post -Body $body -ContentType 'application/json'
    Write-Host "   ✓ SUCCESS" -ForegroundColor Green
    Write-Host "   - Username: $($response.username)" -ForegroundColor Gray
    Write-Host "   - Role: $($response.role)" -ForegroundColor Gray
    Write-Host "   - Email: $($response.email)" -ForegroundColor Gray
    $adminToken = $response.token
} catch {
    Write-Host "   ✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 2: Trainer Login
Write-Host "2. Testing Trainer Login..." -ForegroundColor Yellow
try {
    $body = @{username='trainer'; password='password'} | ConvertTo-Json
    $response = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login" -Method Post -Body $body -ContentType 'application/json'
    Write-Host "   ✓ SUCCESS" -ForegroundColor Green
    Write-Host "   - Username: $($response.username)" -ForegroundColor Gray
    Write-Host "   - Role: $($response.role)" -ForegroundColor Gray
    $trainerToken = $response.token
} catch {
    Write-Host "   ✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 3: Member Login
Write-Host "3. Testing Member Login..." -ForegroundColor Yellow
try {
    $body = @{username='member'; password='password'} | ConvertTo-Json
    $response = Invoke-RestMethod -Uri "$baseUrl/api/Auth/login" -Method Post -Body $body -ContentType 'application/json'
    Write-Host "   ✓ SUCCESS" -ForegroundColor Green
    Write-Host "   - Username: $($response.username)" -ForegroundColor Gray
    Write-Host "   - Role: $($response.role)" -ForegroundColor Gray
    Write-Host "   - MemberId: $($response.memberId)" -ForegroundColor Gray
    $memberToken = $response.token
} catch {
    Write-Host "   ✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 4: Get Members (Admin)
if ($adminToken) {
    Write-Host "4. Testing GET /api/Member (Admin)..." -ForegroundColor Yellow
    try {
        $headers = @{Authorization = "Bearer $adminToken"}
        $response = Invoke-RestMethod -Uri "$baseUrl/api/Member?pageNumber=1&pageSize=10" -Method Get -Headers $headers
        Write-Host "   ✓ SUCCESS" -ForegroundColor Green
        Write-Host "   - Total Members: $($response.Total)" -ForegroundColor Gray
    } catch {
        Write-Host "   ✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

# Test 5: Get Active Membership (Member)
if ($memberToken) {
    Write-Host "5. Testing GET /api/Membership/member/1/active (Member)..." -ForegroundColor Yellow
    try {
        $headers = @{Authorization = "Bearer $memberToken"}
        $response = Invoke-RestMethod -Uri "$baseUrl/api/Membership/member/1/active" -Method Get -Headers $headers
        Write-Host "   ✓ SUCCESS" -ForegroundColor Green
        Write-Host "   - Package: $($response.packageName)" -ForegroundColor Gray
        Write-Host "   - Price: $($response.price)" -ForegroundColor Gray
    } catch {
        Write-Host "   ✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

# Test 6: Get Trainers
if ($adminToken) {
    Write-Host "6. Testing GET /api/Trainer (Admin)..." -ForegroundColor Yellow
    try {
        $headers = @{Authorization = "Bearer $adminToken"}
        $response = Invoke-RestMethod -Uri "$baseUrl/api/Trainer?pageNumber=1&pageSize=10" -Method Get -Headers $headers
        Write-Host "   ✓ SUCCESS" -ForegroundColor Green
        Write-Host "   - Total Trainers: $($response.Total)" -ForegroundColor Gray
    } catch {
        Write-Host "   ✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
