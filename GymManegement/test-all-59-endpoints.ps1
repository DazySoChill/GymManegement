# ===================================================================
# COMPREHENSIVE TEST - ALL 59 API ENDPOINTS
# Account: gymadmin / Gym@2026
# Server: http://localhost:5250
# ===================================================================

$ErrorActionPreference = "Continue"
$baseUrl = "http://localhost:5250/api"
$results = @()
$passed = 0
$failed = 0

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TESTING ALL 59 API ENDPOINTS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ===================================================================
# STEP 1: LOGIN AND GET TOKEN
# ===================================================================
Write-Host "[1/59] POST /api/auth/login" -ForegroundColor Yellow
$loginBody = @{
    username = "gymadmin"
    password = "Gym@2026"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    $token = $loginResponse.token
    $headers = @{ "Authorization" = "Bearer $token" }
    Write-Host "✅ PASS - Token received" -ForegroundColor Green
    $results += [PSCustomObject]@{
        No = 1
        Endpoint = "POST /api/auth/login"
        Status = 200
        Result = "PASS"
        Notes = "Token received"
    }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{
        No = 1
        Endpoint = "POST /api/auth/login"
        Status = $_.Exception.Response.StatusCode.value__
        Result = "FAIL"
        Notes = $_.Exception.Message
    }
    $failed++
    Write-Host "Cannot proceed without token. Exiting." -ForegroundColor Red
    exit 1
}
Write-Host ""

# ===================================================================
# MEMBER ENDPOINTS (5)
# ===================================================================
Write-Host "=== MEMBER API ===" -ForegroundColor Cyan

# 2. GET /api/member
Write-Host "[2/59] GET /api/member" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/member" -Headers $headers
    Write-Host "✅ PASS - Got $($response.Count) members" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 2; Endpoint = "GET /api/member"; Status = 200; Result = "PASS"; Notes = "$($response.Count) members" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 2; Endpoint = "GET /api/member"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 3. GET /api/member/1
Write-Host "[3/59] GET /api/member/1" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/member/1" -Headers $headers
    Write-Host "✅ PASS - Got member: $($response.fullName)" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 3; Endpoint = "GET /api/member/1"; Status = 200; Result = "PASS"; Notes = "Member: $($response.fullName)" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 3; Endpoint = "GET /api/member/1"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 4. POST /api/member
Write-Host "[4/59] POST /api/member" -ForegroundColor Yellow
$memberBody = @{
    fullName = "Test Final Member"
    email = "testfinal_$(Get-Date -Format 'yyyyMMddHHmmss')@gym.com"
    phone = "0901234567"
    address = "123 Test St"
    dateOfBirth = "1990-01-01T00:00:00"
    gender = "Male"
    membershipId = 1
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/member" -Method Post -Body $memberBody -ContentType "application/json" -Headers $headers
    $createdMemberId = $response.memberId
    Write-Host "✅ PASS - Created member ID: $createdMemberId" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 4; Endpoint = "POST /api/member"; Status = 201; Result = "PASS"; Notes = "Created ID: $createdMemberId" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 4; Endpoint = "POST /api/member"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
    $createdMemberId = $null
}

# 5. PUT /api/member/{id}
Write-Host "[5/59] PUT /api/member/$createdMemberId" -ForegroundColor Yellow
if ($createdMemberId) {
    $memberUpdateBody = @{
        fullName = "Test Final Member Updated"
        email = "testfinal_updated@gym.com"
        phone = "0901234568"
        address = "Updated Address"
        dateOfBirth = "1990-01-01T00:00:00"
        gender = "Male"
        membershipId = 1
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/member/$createdMemberId" -Method Put -Body $memberUpdateBody -ContentType "application/json" -Headers $headers
        Write-Host "✅ PASS - Updated member" -ForegroundColor Green
        $results += [PSCustomObject]@{ No = 5; Endpoint = "PUT /api/member/{id}"; Status = 200; Result = "PASS"; Notes = "Updated ID: $createdMemberId" }
        $passed++
    } catch {
        Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{ No = 5; Endpoint = "PUT /api/member/{id}"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
        $failed++
    }
} else {
    Write-Host "⚠️ SKIP - No member ID to update" -ForegroundColor Yellow
    $results += [PSCustomObject]@{ No = 5; Endpoint = "PUT /api/member/{id}"; Status = 0; Result = "SKIP"; Notes = "No member created" }
}

# 6. DELETE /api/member/{id}
Write-Host "[6/59] DELETE /api/member/$createdMemberId" -ForegroundColor Yellow
if ($createdMemberId) {
    try {
        Invoke-RestMethod -Uri "$baseUrl/member/$createdMemberId" -Method Delete -Headers $headers
        Write-Host "✅ PASS - Deleted member" -ForegroundColor Green
        $results += [PSCustomObject]@{ No = 6; Endpoint = "DELETE /api/member/{id}"; Status = 204; Result = "PASS"; Notes = "Deleted ID: $createdMemberId" }
        $passed++
    } catch {
        Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{ No = 6; Endpoint = "DELETE /api/member/{id}"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
        $failed++
    }
} else {
    Write-Host "⚠️ SKIP - No member ID to delete" -ForegroundColor Yellow
    $results += [PSCustomObject]@{ No = 6; Endpoint = "DELETE /api/member/{id}"; Status = 0; Result = "SKIP"; Notes = "No member created" }
}

Write-Host ""

# ===================================================================
# TRAINER ENDPOINTS (5)
# ===================================================================
Write-Host "=== TRAINER API ===" -ForegroundColor Cyan

# 7. GET /api/trainer
Write-Host "[7/59] GET /api/trainer" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/trainer" -Headers $headers
    Write-Host "✅ PASS - Got $($response.Count) trainers" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 7; Endpoint = "GET /api/trainer"; Status = 200; Result = "PASS"; Notes = "$($response.Count) trainers" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 7; Endpoint = "GET /api/trainer"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 8. GET /api/trainer/1
Write-Host "[8/59] GET /api/trainer/1" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/trainer/1" -Headers $headers
    Write-Host "✅ PASS - Got trainer: $($response.fullName)" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 8; Endpoint = "GET /api/trainer/1"; Status = 200; Result = "PASS"; Notes = "Trainer: $($response.fullName)" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 8; Endpoint = "GET /api/trainer/1"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 9. POST /api/trainer
Write-Host "[9/59] POST /api/trainer" -ForegroundColor Yellow
$trainerBody = @{
    fullName = "Test Final Trainer"
    email = "trainerfinal_$(Get-Date -Format 'yyyyMMddHHmmss')@gym.com"
    phone = "0912345678"
    specialization = "Yoga"
    hireDate = "2024-01-15T00:00:00"
    salary = 5000000
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/trainer" -Method Post -Body $trainerBody -ContentType "application/json" -Headers $headers
    $createdTrainerId = $response.trainerId
    Write-Host "✅ PASS - Created trainer ID: $createdTrainerId" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 9; Endpoint = "POST /api/trainer"; Status = 201; Result = "PASS"; Notes = "Created ID: $createdTrainerId" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 9; Endpoint = "POST /api/trainer"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
    $createdTrainerId = $null
}

# 10. PUT /api/trainer/{id}
Write-Host "[10/59] PUT /api/trainer/$createdTrainerId" -ForegroundColor Yellow
if ($createdTrainerId) {
    $trainerUpdateBody = @{
        fullName = "Test Final Trainer Updated"
        email = "trainerfinal_updated@gym.com"
        phone = "0912345679"
        specialization = "Yoga & Pilates"
        hireDate = "2024-01-15T00:00:00"
        salary = 6000000
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/trainer/$createdTrainerId" -Method Put -Body $trainerUpdateBody -ContentType "application/json" -Headers $headers
        Write-Host "✅ PASS - Updated trainer" -ForegroundColor Green
        $results += [PSCustomObject]@{ No = 10; Endpoint = "PUT /api/trainer/{id}"; Status = 200; Result = "PASS"; Notes = "Updated ID: $createdTrainerId" }
        $passed++
    } catch {
        Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{ No = 10; Endpoint = "PUT /api/trainer/{id}"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
        $failed++
    }
} else {
    Write-Host "⚠️ SKIP - No trainer ID to update" -ForegroundColor Yellow
    $results += [PSCustomObject]@{ No = 10; Endpoint = "PUT /api/trainer/{id}"; Status = 0; Result = "SKIP"; Notes = "No trainer created" }
}

# 11. DELETE /api/trainer/{id}
Write-Host "[11/59] DELETE /api/trainer/$createdTrainerId" -ForegroundColor Yellow
if ($createdTrainerId) {
    try {
        Invoke-RestMethod -Uri "$baseUrl/trainer/$createdTrainerId" -Method Delete -Headers $headers
        Write-Host "✅ PASS - Deleted trainer" -ForegroundColor Green
        $results += [PSCustomObject]@{ No = 11; Endpoint = "DELETE /api/trainer/{id}"; Status = 204; Result = "PASS"; Notes = "Deleted ID: $createdTrainerId" }
        $passed++
    } catch {
        Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{ No = 11; Endpoint = "DELETE /api/trainer/{id}"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
        $failed++
    }
} else {
    Write-Host "⚠️ SKIP - No trainer ID to delete" -ForegroundColor Yellow
    $results += [PSCustomObject]@{ No = 11; Endpoint = "DELETE /api/trainer/{id}"; Status = 0; Result = "SKIP"; Notes = "No trainer created" }
}

Write-Host ""

# ===================================================================
# FACILITY ENDPOINTS (5)
# ===================================================================
Write-Host "=== FACILITY API ===" -ForegroundColor Cyan

# 12. GET /api/facility
Write-Host "[12/59] GET /api/facility" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/facility" -Headers $headers
    Write-Host "✅ PASS - Got $($response.Count) facilities" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 12; Endpoint = "GET /api/facility"; Status = 200; Result = "PASS"; Notes = "$($response.Count) facilities" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 12; Endpoint = "GET /api/facility"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 13. GET /api/facility/1
Write-Host "[13/59] GET /api/facility/1" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/facility/1" -Headers $headers
    Write-Host "✅ PASS - Got facility: $($response.name)" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 13; Endpoint = "GET /api/facility/1"; Status = 200; Result = "PASS"; Notes = "Facility: $($response.name)" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 13; Endpoint = "GET /api/facility/1"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 14. POST /api/facility
Write-Host "[14/59] POST /api/facility" -ForegroundColor Yellow
$facilityBody = @{
    name = "Test Room Final"
    type = "GymRoom"
    capacity = 20
    description = "Test facility"
    status = "Available"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/facility" -Method Post -Body $facilityBody -ContentType "application/json" -Headers $headers
    $createdFacilityId = $response.facilityId
    Write-Host "✅ PASS - Created facility ID: $createdFacilityId" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 14; Endpoint = "POST /api/facility"; Status = 201; Result = "PASS"; Notes = "Created ID: $createdFacilityId" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 14; Endpoint = "POST /api/facility"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
    $createdFacilityId = $null
}

# 15. PUT /api/facility/{id}
Write-Host "[15/59] PUT /api/facility/$createdFacilityId" -ForegroundColor Yellow
if ($createdFacilityId) {
    $facilityUpdateBody = @{
        name = "Test Room Final Updated"
        type = "GymRoom"
        capacity = 25
        description = "Updated facility"
        status = "Available"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/facility/$createdFacilityId" -Method Put -Body $facilityUpdateBody -ContentType "application/json" -Headers $headers
        Write-Host "✅ PASS - Updated facility" -ForegroundColor Green
        $results += [PSCustomObject]@{ No = 15; Endpoint = "PUT /api/facility/{id}"; Status = 200; Result = "PASS"; Notes = "Updated ID: $createdFacilityId" }
        $passed++
    } catch {
        Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{ No = 15; Endpoint = "PUT /api/facility/{id}"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
        $failed++
    }
} else {
    Write-Host "⚠️ SKIP - No facility ID to update" -ForegroundColor Yellow
    $results += [PSCustomObject]@{ No = 15; Endpoint = "PUT /api/facility/{id}"; Status = 0; Result = "SKIP"; Notes = "No facility created" }
}

# 16. DELETE /api/facility/{id}
Write-Host "[16/59] DELETE /api/facility/$createdFacilityId" -ForegroundColor Yellow
if ($createdFacilityId) {
    try {
        Invoke-RestMethod -Uri "$baseUrl/facility/$createdFacilityId" -Method Delete -Headers $headers
        Write-Host "✅ PASS - Deleted facility" -ForegroundColor Green
        $results += [PSCustomObject]@{ No = 16; Endpoint = "DELETE /api/facility/{id}"; Status = 204; Result = "PASS"; Notes = "Deleted ID: $createdFacilityId" }
        $passed++
    } catch {
        Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{ No = 16; Endpoint = "DELETE /api/facility/{id}"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
        $failed++
    }
} else {
    Write-Host "⚠️ SKIP - No facility ID to delete" -ForegroundColor Yellow
    $results += [PSCustomObject]@{ No = 16; Endpoint = "DELETE /api/facility/{id}"; Status = 0; Result = "SKIP"; Notes = "No facility created" }
}

Write-Host ""

# ===================================================================
# SCHEDULE ENDPOINTS (7)
# ===================================================================
Write-Host "=== SCHEDULE API ===" -ForegroundColor Cyan

# 17. GET /api/schedule
Write-Host "[17/59] GET /api/schedule" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/schedule" -Headers $headers
    Write-Host "✅ PASS - Got $($response.Count) schedules" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 17; Endpoint = "GET /api/schedule"; Status = 200; Result = "PASS"; Notes = "$($response.Count) schedules" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 17; Endpoint = "GET /api/schedule"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 18. GET /api/schedule/1
Write-Host "[18/59] GET /api/schedule/1" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/schedule/1" -Headers $headers
    Write-Host "✅ PASS - Got schedule" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 18; Endpoint = "GET /api/schedule/1"; Status = 200; Result = "PASS"; Notes = "Schedule retrieved" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 18; Endpoint = "GET /api/schedule/1"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 19. POST /api/schedule
Write-Host "[19/59] POST /api/schedule" -ForegroundColor Yellow
$scheduleBody = @{
    trainerId = 1
    facilityId = 1
    startTime = "2025-08-01T08:00:00"
    endTime = "2025-08-01T09:00:00"
    dayOfWeek = "Monday"
    maxCapacity = 15
    status = "Active"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/schedule" -Method Post -Body $scheduleBody -ContentType "application/json" -Headers $headers
    $createdScheduleId = $response.scheduleId
    Write-Host "✅ PASS - Created schedule ID: $createdScheduleId" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 19; Endpoint = "POST /api/schedule"; Status = 201; Result = "PASS"; Notes = "Created ID: $createdScheduleId" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 19; Endpoint = "POST /api/schedule"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
    $createdScheduleId = $null
}

# 20. PUT /api/schedule/{id}
Write-Host "[20/59] PUT /api/schedule/$createdScheduleId" -ForegroundColor Yellow
if ($createdScheduleId) {
    $scheduleUpdateBody = @{
        trainerId = 1
        facilityId = 1
        startTime = "2025-08-01T09:00:00"
        endTime = "2025-08-01T10:00:00"
        dayOfWeek = "Monday"
        maxCapacity = 20
        status = "Active"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/schedule/$createdScheduleId" -Method Put -Body $scheduleUpdateBody -ContentType "application/json" -Headers $headers
        Write-Host "✅ PASS - Updated schedule" -ForegroundColor Green
        $results += [PSCustomObject]@{ No = 20; Endpoint = "PUT /api/schedule/{id}"; Status = 200; Result = "PASS"; Notes = "Updated ID: $createdScheduleId" }
        $passed++
    } catch {
        Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{ No = 20; Endpoint = "PUT /api/schedule/{id}"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
        $failed++
    }
} else {
    Write-Host "⚠️ SKIP - No schedule ID to update" -ForegroundColor Yellow
    $results += [PSCustomObject]@{ No = 20; Endpoint = "PUT /api/schedule/{id}"; Status = 0; Result = "SKIP"; Notes = "No schedule created" }
}

# 21. DELETE /api/schedule/{id}
Write-Host "[21/59] DELETE /api/schedule/$createdScheduleId" -ForegroundColor Yellow
if ($createdScheduleId) {
    try {
        Invoke-RestMethod -Uri "$baseUrl/schedule/$createdScheduleId" -Method Delete -Headers $headers
        Write-Host "✅ PASS - Deleted schedule" -ForegroundColor Green
        $results += [PSCustomObject]@{ No = 21; Endpoint = "DELETE /api/schedule/{id}"; Status = 204; Result = "PASS"; Notes = "Deleted ID: $createdScheduleId" }
        $passed++
    } catch {
        Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{ No = 21; Endpoint = "DELETE /api/schedule/{id}"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
        $failed++
    }
} else {
    Write-Host "⚠️ SKIP - No schedule ID to delete" -ForegroundColor Yellow
    $results += [PSCustomObject]@{ No = 21; Endpoint = "DELETE /api/schedule/{id}"; Status = 0; Result = "SKIP"; Notes = "No schedule created" }
}

# 22. GET /api/schedule/trainer/1
Write-Host "[22/59] GET /api/schedule/trainer/1" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/schedule/trainer/1" -Headers $headers
    Write-Host "✅ PASS - Got trainer schedules" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 22; Endpoint = "GET /api/schedule/trainer/1"; Status = 200; Result = "PASS"; Notes = "$($response.Count) schedules" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 22; Endpoint = "GET /api/schedule/trainer/1"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 23. GET /api/schedule/date/2025-08-01
Write-Host "[23/59] GET /api/schedule/date/2025-08-01" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/schedule/date/2025-08-01" -Headers $headers
    Write-Host "✅ PASS - Got schedules by date" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 23; Endpoint = "GET /api/schedule/date/{date}"; Status = 200; Result = "PASS"; Notes = "$($response.Count) schedules" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 23; Endpoint = "GET /api/schedule/date/{date}"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

Write-Host ""

# ===================================================================
# SESSION ENDPOINTS (5)
# ===================================================================
Write-Host "=== SESSION API ===" -ForegroundColor Cyan

# 24. GET /api/session
Write-Host "[24/59] GET /api/session" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/session" -Headers $headers
    Write-Host "✅ PASS - Got $($response.Count) sessions" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 24; Endpoint = "GET /api/session"; Status = 200; Result = "PASS"; Notes = "$($response.Count) sessions" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 24; Endpoint = "GET /api/session"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 25. GET /api/session/1
Write-Host "[25/59] GET /api/session/1" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/session/1" -Headers $headers
    Write-Host "✅ PASS - Got session" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 25; Endpoint = "GET /api/session/1"; Status = 200; Result = "PASS"; Notes = "Session retrieved" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 25; Endpoint = "GET /api/session/1"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 26. POST /api/session
Write-Host "[26/59] POST /api/session" -ForegroundColor Yellow
$sessionBody = @{
    scheduleId = 1
    memberId = 1
    sessionDate = "2025-08-01T08:00:00"
    status = "Scheduled"
    notes = "Test session"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/session" -Method Post -Body $sessionBody -ContentType "application/json" -Headers $headers
    $createdSessionId = $response.sessionId
    Write-Host "✅ PASS - Created session ID: $createdSessionId" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 26; Endpoint = "POST /api/session"; Status = 201; Result = "PASS"; Notes = "Created ID: $createdSessionId" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 26; Endpoint = "POST /api/session"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
    $createdSessionId = $null
}

# 27. GET /api/session/schedule/1
Write-Host "[27/59] GET /api/session/schedule/1" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/session/schedule/1" -Headers $headers
    Write-Host "✅ PASS - Got schedule sessions" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 27; Endpoint = "GET /api/session/schedule/1"; Status = 200; Result = "PASS"; Notes = "$($response.Count) sessions" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 27; Endpoint = "GET /api/session/schedule/1"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 28. GET /api/session/member/1
Write-Host "[28/59] GET /api/session/member/1" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/session/member/1" -Headers $headers
    Write-Host "✅ PASS - Got member sessions" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 28; Endpoint = "GET /api/session/member/1"; Status = 200; Result = "PASS"; Notes = "$($response.Count) sessions" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 28; Endpoint = "GET /api/session/member/1"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

Write-Host ""

# ===================================================================
# MEMBERSHIP ENDPOINTS (7)
# ===================================================================
Write-Host "=== MEMBERSHIP API ===" -ForegroundColor Cyan

# 29. GET /api/membership
Write-Host "[29/59] GET /api/membership" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/membership" -Headers $headers
    Write-Host "✅ PASS - Got $($response.Count) memberships" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 29; Endpoint = "GET /api/membership"; Status = 200; Result = "PASS"; Notes = "$($response.Count) memberships" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 29; Endpoint = "GET /api/membership"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 30. GET /api/membership/1
Write-Host "[30/59] GET /api/membership/1" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/membership/1" -Headers $headers
    Write-Host "✅ PASS - Got membership" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 30; Endpoint = "GET /api/membership/1"; Status = 200; Result = "PASS"; Notes = "Membership retrieved" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 30; Endpoint = "GET /api/membership/1"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 31. POST /api/membership
Write-Host "[31/59] POST /api/membership" -ForegroundColor Yellow
$membershipBody = @{
    name = "Test Plan Final"
    duration = 30
    price = 500000
    description = "Test membership plan"
    status = "Active"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/membership" -Method Post -Body $membershipBody -ContentType "application/json" -Headers $headers
    $createdMembershipId = $response.membershipId
    Write-Host "✅ PASS - Created membership ID: $createdMembershipId" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 31; Endpoint = "POST /api/membership"; Status = 201; Result = "PASS"; Notes = "Created ID: $createdMembershipId" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 31; Endpoint = "POST /api/membership"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
    $createdMembershipId = $null
}

# 32. PUT /api/membership/{id}
Write-Host "[32/59] PUT /api/membership/$createdMembershipId" -ForegroundColor Yellow
if ($createdMembershipId) {
    $membershipUpdateBody = @{
        name = "Test Plan Final Updated"
        duration = 60
        price = 900000
        description = "Updated membership plan"
        status = "Active"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/membership/$createdMembershipId" -Method Put -Body $membershipUpdateBody -ContentType "application/json" -Headers $headers
        Write-Host "✅ PASS - Updated membership" -ForegroundColor Green
        $results += [PSCustomObject]@{ No = 32; Endpoint = "PUT /api/membership/{id}"; Status = 200; Result = "PASS"; Notes = "Updated ID: $createdMembershipId" }
        $passed++
    } catch {
        Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{ No = 32; Endpoint = "PUT /api/membership/{id}"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
        $failed++
    }
} else {
    Write-Host "⚠️ SKIP - No membership ID to update" -ForegroundColor Yellow
    $results += [PSCustomObject]@{ No = 32; Endpoint = "PUT /api/membership/{id}"; Status = 0; Result = "SKIP"; Notes = "No membership created" }
}

# 33. DELETE /api/membership/{id}
Write-Host "[33/59] DELETE /api/membership/$createdMembershipId" -ForegroundColor Yellow
if ($createdMembershipId) {
    try {
        Invoke-RestMethod -Uri "$baseUrl/membership/$createdMembershipId" -Method Delete -Headers $headers
        Write-Host "✅ PASS - Deleted membership" -ForegroundColor Green
        $results += [PSCustomObject]@{ No = 33; Endpoint = "DELETE /api/membership/{id}"; Status = 204; Result = "PASS"; Notes = "Deleted ID: $createdMembershipId" }
        $passed++
    } catch {
        Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{ No = 33; Endpoint = "DELETE /api/membership/{id}"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
        $failed++
    }
} else {
    Write-Host "⚠️ SKIP - No membership ID to delete" -ForegroundColor Yellow
    $results += [PSCustomObject]@{ No = 33; Endpoint = "DELETE /api/membership/{id}"; Status = 0; Result = "SKIP"; Notes = "No membership created" }
}

# 34. GET /api/membership/active
Write-Host "[34/59] GET /api/membership/active" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/membership/active" -Headers $headers
    Write-Host "✅ PASS - Got active memberships" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 34; Endpoint = "GET /api/membership/active"; Status = 200; Result = "PASS"; Notes = "$($response.Count) active" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 34; Endpoint = "GET /api/membership/active"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 35. GET /api/membership/expiring
Write-Host "[35/59] GET /api/membership/expiring" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/membership/expiring" -Headers $headers
    Write-Host "✅ PASS - Got expiring memberships" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 35; Endpoint = "GET /api/membership/expiring"; Status = 200; Result = "PASS"; Notes = "$($response.Count) expiring" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 35; Endpoint = "GET /api/membership/expiring"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

Write-Host ""

# ===================================================================
# CHECKIN ENDPOINTS (6)
# ===================================================================
Write-Host "=== CHECKIN API ===" -ForegroundColor Cyan

# 36. GET /api/checkin
Write-Host "[36/59] GET /api/checkin" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/checkin" -Headers $headers
    Write-Host "✅ PASS - Got $($response.Count) checkins" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 36; Endpoint = "GET /api/checkin"; Status = 200; Result = "PASS"; Notes = "$($response.Count) checkins" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 36; Endpoint = "GET /api/checkin"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 37. GET /api/checkin/1
Write-Host "[37/59] GET /api/checkin/1" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/checkin/1" -Headers $headers
    Write-Host "✅ PASS - Got checkin" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 37; Endpoint = "GET /api/checkin/1"; Status = 200; Result = "PASS"; Notes = "Checkin retrieved" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 37; Endpoint = "GET /api/checkin/1"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 38. POST /api/checkin
Write-Host "[38/59] POST /api/checkin" -ForegroundColor Yellow
$checkinBody = @{
    memberId = 1
    facilityId = 1
    checkinTime = "2025-07-20T09:00:00"
    checkoutTime = "2025-07-20T10:00:00"
    notes = "Test checkin"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/checkin" -Method Post -Body $checkinBody -ContentType "application/json" -Headers $headers
    $createdCheckinId = $response.checkinId
    Write-Host "✅ PASS - Created checkin ID: $createdCheckinId" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 38; Endpoint = "POST /api/checkin"; Status = 201; Result = "PASS"; Notes = "Created ID: $createdCheckinId" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 38; Endpoint = "POST /api/checkin"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 39. GET /api/checkin/member/1
Write-Host "[39/59] GET /api/checkin/member/1" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/checkin/member/1" -Headers $headers
    Write-Host "✅ PASS - Got member checkins" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 39; Endpoint = "GET /api/checkin/member/1"; Status = 200; Result = "PASS"; Notes = "$($response.Count) checkins" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 39; Endpoint = "GET /api/checkin/member/1"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 40. GET /api/checkin/date/2025-07-20
Write-Host "[40/59] GET /api/checkin/date/2025-07-20" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/checkin/date/2025-07-20" -Headers $headers
    Write-Host "✅ PASS - Got checkins by date" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 40; Endpoint = "GET /api/checkin/date/{date}"; Status = 200; Result = "PASS"; Notes = "$($response.Count) checkins" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 40; Endpoint = "GET /api/checkin/date/{date}"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 41. POST /api/checkin/qr
Write-Host "[41/59] POST /api/checkin/qr" -ForegroundColor Yellow
$qrBody = @{
    qrCode = "M000001"
    facilityId = 1
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/checkin/qr" -Method Post -Body $qrBody -ContentType "application/json"
    Write-Host "✅ PASS - QR checkin successful" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 41; Endpoint = "POST /api/checkin/qr"; Status = 200; Result = "PASS"; Notes = "QR checkin OK" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 41; Endpoint = "POST /api/checkin/qr"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

Write-Host ""

# ===================================================================
# INVOICE ENDPOINTS (7)
# ===================================================================
Write-Host "=== INVOICE API ===" -ForegroundColor Cyan

# 42. GET /api/invoice
Write-Host "[42/59] GET /api/invoice" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/invoice" -Headers $headers
    Write-Host "✅ PASS - Got $($response.Count) invoices" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 42; Endpoint = "GET /api/invoice"; Status = 200; Result = "PASS"; Notes = "$($response.Count) invoices" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 42; Endpoint = "GET /api/invoice"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 43. GET /api/invoice/1
Write-Host "[43/59] GET /api/invoice/1" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/invoice/1" -Headers $headers
    Write-Host "✅ PASS - Got invoice" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 43; Endpoint = "GET /api/invoice/1"; Status = 200; Result = "PASS"; Notes = "Invoice retrieved" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 43; Endpoint = "GET /api/invoice/1"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 44. POST /api/invoice
Write-Host "[44/59] POST /api/invoice" -ForegroundColor Yellow
$invoiceBody = @{
    memberId = 1
    amount = 500000
    issueDate = "2025-07-20T00:00:00"
    dueDate = "2025-08-20T00:00:00"
    status = "Unpaid"
    description = "Test invoice"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/invoice" -Method Post -Body $invoiceBody -ContentType "application/json" -Headers $headers
    $createdInvoiceId = $response.invoiceId
    Write-Host "✅ PASS - Created invoice ID: $createdInvoiceId" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 44; Endpoint = "POST /api/invoice"; Status = 201; Result = "PASS"; Notes = "Created ID: $createdInvoiceId" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 44; Endpoint = "POST /api/invoice"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
    $createdInvoiceId = $null
}

# 45. PUT /api/invoice/{id}
Write-Host "[45/59] PUT /api/invoice/$createdInvoiceId" -ForegroundColor Yellow
if ($createdInvoiceId) {
    $invoiceUpdateBody = @{
        memberId = 1
        amount = 600000
        issueDate = "2025-07-20T00:00:00"
        dueDate = "2025-08-20T00:00:00"
        status = "Paid"
        description = "Updated invoice"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/invoice/$createdInvoiceId" -Method Put -Body $invoiceUpdateBody -ContentType "application/json" -Headers $headers
        Write-Host "✅ PASS - Updated invoice" -ForegroundColor Green
        $results += [PSCustomObject]@{ No = 45; Endpoint = "PUT /api/invoice/{id}"; Status = 200; Result = "PASS"; Notes = "Updated ID: $createdInvoiceId" }
        $passed++
    } catch {
        Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{ No = 45; Endpoint = "PUT /api/invoice/{id}"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
        $failed++
    }
} else {
    Write-Host "⚠️ SKIP - No invoice ID to update" -ForegroundColor Yellow
    $results += [PSCustomObject]@{ No = 45; Endpoint = "PUT /api/invoice/{id}"; Status = 0; Result = "SKIP"; Notes = "No invoice created" }
}

# 46. DELETE /api/invoice/{id}
Write-Host "[46/59] DELETE /api/invoice/$createdInvoiceId" -ForegroundColor Yellow
if ($createdInvoiceId) {
    try {
        Invoke-RestMethod -Uri "$baseUrl/invoice/$createdInvoiceId" -Method Delete -Headers $headers
        Write-Host "✅ PASS - Deleted invoice" -ForegroundColor Green
        $results += [PSCustomObject]@{ No = 46; Endpoint = "DELETE /api/invoice/{id}"; Status = 204; Result = "PASS"; Notes = "Deleted ID: $createdInvoiceId" }
        $passed++
    } catch {
        Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{ No = 46; Endpoint = "DELETE /api/invoice/{id}"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
        $failed++
    }
} else {
    Write-Host "⚠️ SKIP - No invoice ID to delete" -ForegroundColor Yellow
    $results += [PSCustomObject]@{ No = 46; Endpoint = "DELETE /api/invoice/{id}"; Status = 0; Result = "SKIP"; Notes = "No invoice created" }
}

# 47. GET /api/invoice/member/1
Write-Host "[47/59] GET /api/invoice/member/1" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/invoice/member/1" -Headers $headers
    Write-Host "✅ PASS - Got member invoices" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 47; Endpoint = "GET /api/invoice/member/1"; Status = 200; Result = "PASS"; Notes = "$($response.Count) invoices" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 47; Endpoint = "GET /api/invoice/member/1"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 48. GET /api/invoice/unpaid
Write-Host "[48/59] GET /api/invoice/unpaid" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/invoice/unpaid" -Headers $headers
    Write-Host "✅ PASS - Got unpaid invoices" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 48; Endpoint = "GET /api/invoice/unpaid"; Status = 200; Result = "PASS"; Notes = "$($response.Count) unpaid" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 48; Endpoint = "GET /api/invoice/unpaid"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

Write-Host ""

# ===================================================================
# PAYMENT ENDPOINTS (7)
# ===================================================================
Write-Host "=== PAYMENT API ===" -ForegroundColor Cyan

# 49. GET /api/payment
Write-Host "[49/59] GET /api/payment" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/payment" -Headers $headers
    Write-Host "✅ PASS - Got $($response.Count) payments" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 49; Endpoint = "GET /api/payment"; Status = 200; Result = "PASS"; Notes = "$($response.Count) payments" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 49; Endpoint = "GET /api/payment"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 50. GET /api/payment/1
Write-Host "[50/59] GET /api/payment/1" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/payment/1" -Headers $headers
    Write-Host "✅ PASS - Got payment" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 50; Endpoint = "GET /api/payment/1"; Status = 200; Result = "PASS"; Notes = "Payment retrieved" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 50; Endpoint = "GET /api/payment/1"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 51. POST /api/payment
Write-Host "[51/59] POST /api/payment" -ForegroundColor Yellow
$paymentBody = @{
    invoiceId = 1
    amount = 500000
    paymentDate = "2025-07-20T00:00:00"
    paymentMethod = "Cash"
    status = "Completed"
    notes = "Test payment"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/payment" -Method Post -Body $paymentBody -ContentType "application/json" -Headers $headers
    $createdPaymentId = $response.paymentId
    Write-Host "✅ PASS - Created payment ID: $createdPaymentId" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 51; Endpoint = "POST /api/payment"; Status = 201; Result = "PASS"; Notes = "Created ID: $createdPaymentId" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 51; Endpoint = "POST /api/payment"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
    $createdPaymentId = $null
}

# 52. PUT /api/payment/{id}
Write-Host "[52/59] PUT /api/payment/$createdPaymentId" -ForegroundColor Yellow
if ($createdPaymentId) {
    $paymentUpdateBody = @{
        invoiceId = 1
        amount = 500000
        paymentDate = "2025-07-20T00:00:00"
        paymentMethod = "BankTransfer"
        status = "Completed"
        notes = "Updated payment"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/payment/$createdPaymentId" -Method Put -Body $paymentUpdateBody -ContentType "application/json" -Headers $headers
        Write-Host "✅ PASS - Updated payment" -ForegroundColor Green
        $results += [PSCustomObject]@{ No = 52; Endpoint = "PUT /api/payment/{id}"; Status = 200; Result = "PASS"; Notes = "Updated ID: $createdPaymentId" }
        $passed++
    } catch {
        Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{ No = 52; Endpoint = "PUT /api/payment/{id}"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
        $failed++
    }
} else {
    Write-Host "⚠️ SKIP - No payment ID to update" -ForegroundColor Yellow
    $results += [PSCustomObject]@{ No = 52; Endpoint = "PUT /api/payment/{id}"; Status = 0; Result = "SKIP"; Notes = "No payment created" }
}

# 53. DELETE /api/payment/{id}
Write-Host "[53/59] DELETE /api/payment/$createdPaymentId" -ForegroundColor Yellow
if ($createdPaymentId) {
    try {
        Invoke-RestMethod -Uri "$baseUrl/payment/$createdPaymentId" -Method Delete -Headers $headers
        Write-Host "✅ PASS - Deleted payment" -ForegroundColor Green
        $results += [PSCustomObject]@{ No = 53; Endpoint = "DELETE /api/payment/{id}"; Status = 204; Result = "PASS"; Notes = "Deleted ID: $createdPaymentId" }
        $passed++
    } catch {
        Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{ No = 53; Endpoint = "DELETE /api/payment/{id}"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
        $failed++
    }
} else {
    Write-Host "⚠️ SKIP - No payment ID to delete" -ForegroundColor Yellow
    $results += [PSCustomObject]@{ No = 53; Endpoint = "DELETE /api/payment/{id}"; Status = 0; Result = "SKIP"; Notes = "No payment created" }
}

# 54. GET /api/payment/invoice/1
Write-Host "[54/59] GET /api/payment/invoice/1" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/payment/invoice/1" -Headers $headers
    Write-Host "✅ PASS - Got invoice payments" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 54; Endpoint = "GET /api/payment/invoice/1"; Status = 200; Result = "PASS"; Notes = "$($response.Count) payments" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 54; Endpoint = "GET /api/payment/invoice/1"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 55. GET /api/payment/member/1
Write-Host "[55/59] GET /api/payment/member/1" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/payment/member/1" -Headers $headers
    Write-Host "✅ PASS - Got member payments" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 55; Endpoint = "GET /api/payment/member/1"; Status = 200; Result = "PASS"; Notes = "$($response.Count) payments" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 55; Endpoint = "GET /api/payment/member/1"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

Write-Host ""

# ===================================================================
# REPORT ENDPOINTS (4)
# ===================================================================
Write-Host "=== REPORT API ===" -ForegroundColor Cyan

# 56. GET /api/report/revenue
Write-Host "[56/59] GET /api/report/revenue?startDate=2025-01-01&endDate=2025-12-31" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/report/revenue?startDate=2025-01-01&endDate=2025-12-31" -Headers $headers
    Write-Host "✅ PASS - Got revenue report" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 56; Endpoint = "GET /api/report/revenue"; Status = 200; Result = "PASS"; Notes = "Revenue data OK" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 56; Endpoint = "GET /api/report/revenue"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 57. GET /api/report/members
Write-Host "[57/59] GET /api/report/members" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/report/members" -Headers $headers
    Write-Host "✅ PASS - Got members report" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 57; Endpoint = "GET /api/report/members"; Status = 200; Result = "PASS"; Notes = "Members data OK" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 57; Endpoint = "GET /api/report/members"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 58. GET /api/report/trainers
Write-Host "[58/59] GET /api/report/trainers" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/report/trainers" -Headers $headers
    Write-Host "✅ PASS - Got trainers report" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 58; Endpoint = "GET /api/report/trainers"; Status = 200; Result = "PASS"; Notes = "Trainers data OK" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 58; Endpoint = "GET /api/report/trainers"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

# 59. GET /api/report/facilities
Write-Host "[59/59] GET /api/report/facilities" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/report/facilities" -Headers $headers
    Write-Host "✅ PASS - Got facilities report" -ForegroundColor Green
    $results += [PSCustomObject]@{ No = 59; Endpoint = "GET /api/report/facilities"; Status = 200; Result = "PASS"; Notes = "Facilities data OK" }
    $passed++
} catch {
    Write-Host "❌ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $results += [PSCustomObject]@{ No = 59; Endpoint = "GET /api/report/facilities"; Status = $_.Exception.Response.StatusCode.value__; Result = "FAIL"; Notes = $_.Exception.Message }
    $failed++
}

Write-Host ""

# ===================================================================
# SUMMARY
# ===================================================================
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "FINAL SUMMARY" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Total Tests: 59" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
$successRate = [math]::Round(($passed / 59) * 100, 1)
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if($successRate -ge 85) {"Green"} elseif($successRate -ge 70) {"Yellow"} else {"Red"})
Write-Host ""

# Export results
$results | Export-Csv -Path "API_TEST_RESULTS_RAW.csv" -NoTypeInformation -Encoding UTF8
Write-Host "Results exported to: API_TEST_RESULTS_RAW.csv" -ForegroundColor Cyan

# Return results for processing
return $results
