# Test 3 Fixed API Endpoints
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TESTING 3 FIXED API ENDPOINTS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Login
Write-Host "Step 1: Getting auth token..." -ForegroundColor Yellow
$loginBody = @{
    username = "gymadmin"
    password = "Gym@2026"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:5250/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    $token = $loginResponse.token
    $headers = @{ "Authorization" = "Bearer $token" }
    Write-Host "✅ Login successful`n" -ForegroundColor Green
} catch {
    Write-Host "❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 1: Trainer API
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST 1: GET /api/trainer (Previously 500 error)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
try {
    $trainers = Invoke-RestMethod -Uri "http://localhost:5250/api/trainer?pageNumber=1&pageSize=5" -Method Get -Headers $headers
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host "   Total trainers: $($trainers.totalCount)" -ForegroundColor White
    Write-Host "   Returned: $($trainers.items.Count) items" -ForegroundColor White
    if ($trainers.items.Count -gt 0) {
        Write-Host "   First trainer: $($trainers.items[0].fullName)" -ForegroundColor White
    }
    Write-Host ""
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}

# Test 2: Schedule POST
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST 2: POST /api/schedule (Previously 400 error)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$scheduleBody = @{
    trainerId = 0
    facilityId = 0
    className = "Test Class Fixed"
    startTime = "2025-07-15T09:00:00"
    endTime = "2025-07-15T10:00:00"
    maxParticipants = 20
    status = "Active"
} | ConvertTo-Json

try {
    $schedule = Invoke-RestMethod -Uri "http://localhost:5250/api/schedule" -Method Post -Body $scheduleBody -ContentType "application/json" -Headers $headers
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host "   Created schedule ID: $($schedule.scheduleId)" -ForegroundColor White
    Write-Host "   Class: $($schedule.className)" -ForegroundColor White
    Write-Host ""
    $createdScheduleId = $schedule.scheduleId
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "   Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
    Write-Host ""
    $createdScheduleId = $null
}

# Test 3: Session POST
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST 3: POST /api/session (Previously 500 error)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$sessionBody = @{
    memberId = 0
    scheduleId = 98
    registrationDate = "2025-07-15T09:00:00"
} | ConvertTo-Json

try {
    $session = Invoke-RestMethod -Uri "http://localhost:5250/api/session" -Method Post -Body $sessionBody -ContentType "application/json" -Headers $headers
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host "   Created session ID: $($session.sessionId)" -ForegroundColor White
    Write-Host "   Member ID: $($session.memberId)" -ForegroundColor White
    Write-Host "   Schedule ID: $($session.scheduleId)" -ForegroundColor White
    Write-Host ""
    $createdSessionId = $session.sessionId
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "   Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
    Write-Host ""
    $createdSessionId = $null
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. Trainer API:  " -NoNewline
if ($trainers) { Write-Host "✅ FIXED" -ForegroundColor Green } else { Write-Host "❌ STILL BROKEN" -ForegroundColor Red }
Write-Host "2. Schedule POST:" -NoNewline
if ($createdScheduleId) { Write-Host "✅ FIXED" -ForegroundColor Green } else { Write-Host "❌ STILL BROKEN" -ForegroundColor Red }
Write-Host "3. Session POST: " -NoNewline
if ($createdSessionId) { Write-Host "✅ FIXED" -ForegroundColor Green } else { Write-Host "❌ STILL BROKEN" -ForegroundColor Red }
Write-Host ""
