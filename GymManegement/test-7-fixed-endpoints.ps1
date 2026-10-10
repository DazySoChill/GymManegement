# Test 7 Fixed Endpoints (500 Errors)
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TESTING 7 FIXED API ENDPOINTS (500 ERRORS)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Start-Sleep -Seconds 5

# Login
Write-Host "Getting auth token..." -ForegroundColor Yellow
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

$passed = 0
$failed = 0

# Test 1: Member POST
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST 1: POST /api/member" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$memberBody = @{
    fullName = "Test Member Fixed"
    email = "testfixed@gym.com"
    phone = "0901234567"
    dateOfBirth = "1990-05-15"
    gender = "Male"
    address = "123 Test St"
    emergencyContact = "0909999888"
    joinDate = "2025-01-01"
    status = "Active"
} | ConvertTo-Json

try {
    $member = Invoke-RestMethod -Uri "http://localhost:5250/api/member" -Method Post -Body $memberBody -ContentType "application/json" -Headers $headers
    Write-Host "✅ SUCCESS - Created member ID: $($member.memberId)" -ForegroundColor Green
    $createdMemberId = $member.memberId
    $passed++
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $failed++
    $createdMemberId = $null
}
Write-Host ""

# Test 2: Member PUT
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST 2: PUT /api/member/0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$memberUpdateBody = @{
    fullName = "Member Updated"
    email = "member1@example.com"
    phone = "0900000001"
    dateOfBirth = "2007-10-09"
    gender = "Male"
    address = "Updated Address"
    emergencyContact = "0909999888"
    joinDate = "2025-01-01"
    status = "Active"
} | ConvertTo-Json

try {
    $updated = Invoke-RestMethod -Uri "http://localhost:5250/api/member/0" -Method Put -Body $memberUpdateBody -ContentType "application/json" -Headers $headers
    Write-Host "✅ SUCCESS - Updated member" -ForegroundColor Green
    $passed++
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test 3: Trainer POST
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST 3: POST /api/trainer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$trainerBody = @{
    fullName = "Test Trainer Fixed"
    email = "testtrainerfixed@gym.com"
    phone = "0902345001"
    specialization = "Cardio"
    experience = 3
    certification = "ACE Certified"
    status = "Active"
    hireDate = "2024-01-01T00:00:00"
} | ConvertTo-Json

try {
    $trainer = Invoke-RestMethod -Uri "http://localhost:5250/api/trainer" -Method Post -Body $trainerBody -ContentType "application/json" -Headers $headers
    Write-Host "✅ SUCCESS - Created trainer ID: $($trainer.trainerId)" -ForegroundColor Green
    $createdTrainerId = $trainer.trainerId
    $passed++
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $failed++
    $createdTrainerId = $null
}
Write-Host ""

# Test 4: Trainer PUT
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST 4: PUT /api/trainer/0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$trainerUpdateBody = @{
    fullName = "Trainer Updated"
    email = "trainer1@gym.com"
    phone = "0901234567"
    specialization = "Updated Spec"
    experience = 5
    certification = "Updated Cert"
    status = "Active"
    hireDate = "2024-01-01T00:00:00"
} | ConvertTo-Json

try {
    $updated = Invoke-RestMethod -Uri "http://localhost:5250/api/trainer/0" -Method Put -Body $trainerUpdateBody -ContentType "application/json" -Headers $headers
    Write-Host "✅ SUCCESS - Updated trainer" -ForegroundColor Green
    $passed++
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test 5: Session POST
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST 5: POST /api/session" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$sessionBody = @{
    memberId = 0
    scheduleId = 98
    registrationDate = "2025-07-20T09:00:00"
} | ConvertTo-Json

try {
    $session = Invoke-RestMethod -Uri "http://localhost:5250/api/session" -Method Post -Body $sessionBody -ContentType "application/json" -Headers $headers
    Write-Host "✅ SUCCESS - Created session ID: $($session.sessionId)" -ForegroundColor Green
    $createdSessionId = $session.sessionId
    $passed++
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $failed++
    $createdSessionId = $null
}
Write-Host ""

# Test 6: Invoice PUT
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST 6: PUT /api/invoice/0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$invoiceUpdateBody = @{
    memberId = 0
    membershipId = 1
    amount = 600000
    dueDate = "2025-08-01"
    status = "Paid"
    description = "Updated invoice"
} | ConvertTo-Json

try {
    $updated = Invoke-RestMethod -Uri "http://localhost:5250/api/invoice/0" -Method Put -Body $invoiceUpdateBody -ContentType "application/json" -Headers $headers
    Write-Host "✅ SUCCESS - Updated invoice" -ForegroundColor Green
    $passed++
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test 7: Checkin QR POST
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST 7: POST /api/checkin/qr" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$qrBody = @{
    qrCode = "M000001"
    facilityId = 0
} | ConvertTo-Json

try {
    $checkin = Invoke-RestMethod -Uri "http://localhost:5250/api/checkin/qr" -Method Post -Body $qrBody -ContentType "application/json"
    Write-Host "✅ SUCCESS - QR checkin completed" -ForegroundColor Green
    $passed++
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FINAL SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests: 7" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
$successRate = [math]::Round(($passed / 7) * 100, 1)
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if($successRate -ge 85) {"Green"} else {"Yellow"})

if ($passed -eq 7) {
    Write-Host "`n🎉 ALL 7 ENDPOINTS FIXED!" -ForegroundColor Green
    Write-Host "Expected new pass rate: ~47/59 (79.7%) minimum" -ForegroundColor Green
} elseif ($passed -ge 5) {
    Write-Host "`n⚠️ Most endpoints fixed, but $failed still failing" -ForegroundColor Yellow
} else {
    Write-Host "`n❌ More work needed" -ForegroundColor Red
}
Write-Host ""
