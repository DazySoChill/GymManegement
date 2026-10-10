# Comprehensive API Test Script for Gym Management System
# Date: 2025-01-15
# Admin Account: gymadmin / Gym@2026

$baseUrl = "http://localhost:5250"
$token = ""
$results = @()
$testCount = 0
$passCount = 0
$failCount = 0

# Helper function to test endpoint
function Test-Endpoint {
    param(
        [string]$Method,
        [string]$Url,
        [object]$Body = $null,
        [string]$Description
    )
    
    $global:testCount++
    $result = @{
        Method = $Method
        Url = $Url
        Description = $Description
        Status = ""
        Response = ""
        Pass = $false
    }
    
    try {
        $headers = @{
            "Authorization" = "Bearer $global:token"
            "Content-Type" = "application/json"
        }
        
        if ($Body) {
            $jsonBody = $Body | ConvertTo-Json -Depth 10
            $response = Invoke-RestMethod -Uri $Url -Method $Method -Headers $headers -Body $jsonBody -ErrorAction Stop
        } else {
            $response = Invoke-RestMethod -Uri $Url -Method $Method -Headers $headers -ErrorAction Stop
        }
        
        $result.Status = "200 OK"
        $result.Response = $response | ConvertTo-Json -Depth 3 -Compress
        $result.Pass = $true
        $global:passCount++
        Write-Host "✅ PASS: $Description" -ForegroundColor Green
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $result.Status = "$statusCode - $($_.Exception.Message)"
        $result.Response = $_.Exception.Message
        $result.Pass = $false
        $global:failCount++
        Write-Host "❌ FAIL: $Description - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    $global:results += $result
    return $result
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "GYM MANAGEMENT API - COMPREHENSIVE TEST" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Login
Write-Host "`n[1/10] AUTHENTICATION" -ForegroundColor Yellow
try {
    $loginBody = @{
        username = "gymadmin"
        password = "Gym@2026"
    } | ConvertTo-Json
    
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
    $global:token = $loginResponse.token
    Write-Host "✅ Login successful! Token obtained." -ForegroundColor Green
    Write-Host "   User: $($loginResponse.fullName) ($($loginResponse.role))" -ForegroundColor Gray
} catch {
    Write-Host "❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Test MEMBER API
Write-Host "`n[2/10] MEMBER API" -ForegroundColor Yellow
$memberList = Test-Endpoint -Method "GET" -Url "$baseUrl/api/member?pageNumber=1&pageSize=10" -Description "Get Members List"
$firstMemberId = ($memberList.Response | ConvertFrom-Json).data[0].memberId

Test-Endpoint -Method "GET" -Url "$baseUrl/api/member/$firstMemberId" -Description "Get Member by ID ($firstMemberId)"

$newMemberBody = @{
    fullName = "Test Member API"
    email = "testmember@gym.com"
    phone = "0901234999"
    dateOfBirth = "1990-05-15"
    gender = "Male"
    address = "123 Test Street"
    emergencyContact = "0909999888"
    joinDate = "2025-01-01"
    status = "Active"
}
$createMember = Test-Endpoint -Method "POST" -Url "$baseUrl/api/member" -Body $newMemberBody -Description "Create New Member"
$newMemberId = ($createMember.Response | ConvertFrom-Json).memberId

if ($newMemberId) {
    $updateMemberBody = $newMemberBody.Clone()
    $updateMemberBody.fullName = "Test Member Updated"
    $updateMemberBody.address = "456 Updated Street"
    Test-Endpoint -Method "PUT" -Url "$baseUrl/api/member/$newMemberId" -Body $updateMemberBody -Description "Update Member ($newMemberId)"
    
    Test-Endpoint -Method "DELETE" -Url "$baseUrl/api/member/$newMemberId" -Description "Delete Member ($newMemberId)"
}

# Step 3: Test TRAINER API
Write-Host "`n[3/10] TRAINER API" -ForegroundColor Yellow
$trainerList = Test-Endpoint -Method "GET" -Url "$baseUrl/api/trainer?pageNumber=1&pageSize=10" -Description "Get Trainers List"
$firstTrainerId = ($trainerList.Response | ConvertFrom-Json).data[0].trainerId

Test-Endpoint -Method "GET" -Url "$baseUrl/api/trainer/$firstTrainerId" -Description "Get Trainer by ID ($firstTrainerId)"

$newTrainerBody = @{
    fullName = "Test Trainer API"
    email = "testtrainer@gym.com"
    phone = "0902345001"
    specialization = "Cardio"
    experience = 3
    certification = "ACE Certified"
    status = "Active"
    hireDate = "2024-01-01"
}
$createTrainer = Test-Endpoint -Method "POST" -Url "$baseUrl/api/trainer" -Body $newTrainerBody -Description "Create New Trainer"
$newTrainerId = ($createTrainer.Response | ConvertFrom-Json).trainerId

if ($newTrainerId) {
    $updateTrainerBody = $newTrainerBody.Clone()
    $updateTrainerBody.fullName = "Test Trainer Updated"
    $updateTrainerBody.specialization = "Strength Training"
    Test-Endpoint -Method "PUT" -Url "$baseUrl/api/trainer/$newTrainerId" -Body $updateTrainerBody -Description "Update Trainer ($newTrainerId)"
    
    Test-Endpoint -Method "DELETE" -Url "$baseUrl/api/trainer/$newTrainerId" -Description "Delete Trainer ($newTrainerId)"
}

# Step 4: Test FACILITY API
Write-Host "`n[4/10] FACILITY API" -ForegroundColor Yellow
$facilityList = Test-Endpoint -Method "GET" -Url "$baseUrl/api/facility?pageNumber=1&pageSize=10" -Description "Get Facilities List"
$firstFacilityId = ($facilityList.Response | ConvertFrom-Json).data[0].facilityId

Test-Endpoint -Method "GET" -Url "$baseUrl/api/facility/$firstFacilityId" -Description "Get Facility by ID ($firstFacilityId)"

$newFacilityBody = @{
    name = "Test Room API"
    type = "Gym"
    capacity = 30
    description = "Test facility"
    status = "Available"
}
$createFacility = Test-Endpoint -Method "POST" -Url "$baseUrl/api/facility" -Body $newFacilityBody -Description "Create New Facility"
$newFacilityId = ($createFacility.Response | ConvertFrom-Json).facilityId

if ($newFacilityId) {
    $updateFacilityBody = $newFacilityBody.Clone()
    $updateFacilityBody.name = "Test Room Updated"
    $updateFacilityBody.type = "Yoga"
    Test-Endpoint -Method "PUT" -Url "$baseUrl/api/facility/$newFacilityId" -Body $updateFacilityBody -Description "Update Facility ($newFacilityId)"
    
    Test-Endpoint -Method "DELETE" -Url "$baseUrl/api/facility/$newFacilityId" -Description "Delete Facility ($newFacilityId)"
}

# Step 5: Test SCHEDULE API
Write-Host "`n[5/10] SCHEDULE API" -ForegroundColor Yellow
$scheduleList = Test-Endpoint -Method "GET" -Url "$baseUrl/api/schedule?pageNumber=1&pageSize=10" -Description "Get Schedules List"
$firstScheduleId = ($scheduleList.Response | ConvertFrom-Json).data[0].scheduleId

Test-Endpoint -Method "GET" -Url "$baseUrl/api/schedule/$firstScheduleId" -Description "Get Schedule by ID ($firstScheduleId)"

$newScheduleBody = @{
    trainerId = $firstTrainerId
    facilityId = $firstFacilityId
    className = "Test Class API"
    dayOfWeek = 1
    startTime = "09:00:00"
    endTime = "10:00:00"
    maxParticipants = 20
    status = "Active"
}
$createSchedule = Test-Endpoint -Method "POST" -Url "$baseUrl/api/schedule" -Body $newScheduleBody -Description "Create New Schedule"
$newScheduleId = ($createSchedule.Response | ConvertFrom-Json).scheduleId

if ($newScheduleId) {
    $updateScheduleBody = $newScheduleBody.Clone()
    $updateScheduleBody.className = "Test Class Updated"
    Test-Endpoint -Method "PUT" -Url "$baseUrl/api/schedule/$newScheduleId" -Body $updateScheduleBody -Description "Update Schedule ($newScheduleId)"
    
    Test-Endpoint -Method "DELETE" -Url "$baseUrl/api/schedule/$newScheduleId" -Description "Delete Schedule ($newScheduleId)"
}

Test-Endpoint -Method "GET" -Url "$baseUrl/api/schedule/trainer/$firstTrainerId" -Description "Get Schedules by Trainer ID"
Test-Endpoint -Method "GET" -Url "$baseUrl/api/schedule/date/2025-01-15" -Description "Get Schedules by Date"

# Step 6: Test SESSION API
Write-Host "`n[6/10] SESSION API" -ForegroundColor Yellow
$sessionList = Test-Endpoint -Method "GET" -Url "$baseUrl/api/session?pageNumber=1&pageSize=10" -Description "Get Sessions List"
$firstSessionId = ($sessionList.Response | ConvertFrom-Json).data[0].sessionId

Test-Endpoint -Method "GET" -Url "$baseUrl/api/session/$firstSessionId" -Description "Get Session by ID ($firstSessionId)"

$newSessionBody = @{
    scheduleId = $firstScheduleId
    sessionDate = "2025-07-20"
    startTime = "09:00:00"
    endTime = "10:00:00"
    status = "Scheduled"
    notes = "Test session"
}
$createSession = Test-Endpoint -Method "POST" -Url "$baseUrl/api/session" -Body $newSessionBody -Description "Create New Session"
$newSessionId = ($createSession.Response | ConvertFrom-Json).sessionId

if ($newSessionId) {
    $updateSessionBody = $newSessionBody.Clone()
    $updateSessionBody.notes = "Updated test session"
    Test-Endpoint -Method "PUT" -Url "$baseUrl/api/session/$newSessionId" -Body $updateSessionBody -Description "Update Session ($newSessionId)"
    
    Test-Endpoint -Method "DELETE" -Url "$baseUrl/api/session/$newSessionId" -Description "Delete Session ($newSessionId)"
}

Test-Endpoint -Method "GET" -Url "$baseUrl/api/session/schedule/$firstScheduleId" -Description "Get Sessions by Schedule ID"
Test-Endpoint -Method "GET" -Url "$baseUrl/api/session/member/$firstMemberId" -Description "Get Sessions by Member ID"

# Step 7: Test MEMBERSHIP API
Write-Host "`n[7/10] MEMBERSHIP API" -ForegroundColor Yellow
$membershipList = Test-Endpoint -Method "GET" -Url "$baseUrl/api/membership?pageNumber=1&pageSize=10" -Description "Get Memberships List"
$firstMembershipId = ($membershipList.Response | ConvertFrom-Json).data[0].membershipId

Test-Endpoint -Method "GET" -Url "$baseUrl/api/membership/$firstMembershipId" -Description "Get Membership by ID ($firstMembershipId)"

$newMembershipBody = @{
    memberId = $firstMemberId
    planName = "Monthly Basic"
    startDate = "2025-07-01"
    endDate = "2025-07-31"
    price = 500000
    status = "Active"
}
$createMembership = Test-Endpoint -Method "POST" -Url "$baseUrl/api/membership" -Body $newMembershipBody -Description "Create New Membership"
$newMembershipId = ($createMembership.Response | ConvertFrom-Json).membershipId

if ($newMembershipId) {
    $updateMembershipBody = $newMembershipBody.Clone()
    $updateMembershipBody.planName = "Monthly Basic Updated"
    Test-Endpoint -Method "PUT" -Url "$baseUrl/api/membership/$newMembershipId" -Body $updateMembershipBody -Description "Update Membership ($newMembershipId)"
    
    Test-Endpoint -Method "DELETE" -Url "$baseUrl/api/membership/$newMembershipId" -Description "Delete Membership ($newMembershipId)"
}

Test-Endpoint -Method "GET" -Url "$baseUrl/api/membership/active" -Description "Get Active Memberships"
Test-Endpoint -Method "GET" -Url "$baseUrl/api/membership/expiring" -Description "Get Expiring Memberships"

# Step 8: Test CHECKIN API
Write-Host "`n[8/10] CHECKIN API" -ForegroundColor Yellow
$checkinList = Test-Endpoint -Method "GET" -Url "$baseUrl/api/checkin?pageNumber=1&pageSize=10" -Description "Get Checkins List"
$firstCheckinId = ($checkinList.Response | ConvertFrom-Json).data[0].checkinId

Test-Endpoint -Method "GET" -Url "$baseUrl/api/checkin/$firstCheckinId" -Description "Get Checkin by ID ($firstCheckinId)"

$newCheckinBody = @{
    memberId = $firstMemberId
    facilityId = $firstFacilityId
    checkinTime = "2025-07-15T09:00:00"
    checkoutTime = "2025-07-15T10:00:00"
    notes = "Test checkin"
}
$createCheckin = Test-Endpoint -Method "POST" -Url "$baseUrl/api/checkin" -Body $newCheckinBody -Description "Create New Checkin"

Test-Endpoint -Method "GET" -Url "$baseUrl/api/checkin/member/$firstMemberId" -Description "Get Checkins by Member ID"
Test-Endpoint -Method "GET" -Url "$baseUrl/api/checkin/date/2025-07-15" -Description "Get Checkins by Date"

$qrCheckinBody = @{
    memberId = $firstMemberId
    facilityId = $firstFacilityId
}
Test-Endpoint -Method "POST" -Url "$baseUrl/api/checkin/qr" -Body $qrCheckinBody -Description "QR Code Checkin"

# Step 9: Test INVOICE API
Write-Host "`n[9/10] INVOICE API" -ForegroundColor Yellow
$invoiceList = Test-Endpoint -Method "GET" -Url "$baseUrl/api/invoice?pageNumber=1&pageSize=10" -Description "Get Invoices List"
$firstInvoiceId = ($invoiceList.Response | ConvertFrom-Json).data[0].invoiceId

Test-Endpoint -Method "GET" -Url "$baseUrl/api/invoice/$firstInvoiceId" -Description "Get Invoice by ID ($firstInvoiceId)"

$newInvoiceBody = @{
    memberId = $firstMemberId
    membershipId = $firstMembershipId
    amount = 500000
    dueDate = "2025-08-01"
    status = "Unpaid"
    description = "Test invoice"
}
$createInvoice = Test-Endpoint -Method "POST" -Url "$baseUrl/api/invoice" -Body $newInvoiceBody -Description "Create New Invoice"
$newInvoiceId = ($createInvoice.Response | ConvertFrom-Json).invoiceId

if ($newInvoiceId) {
    $updateInvoiceBody = $newInvoiceBody.Clone()
    $updateInvoiceBody.description = "Updated test invoice"
    Test-Endpoint -Method "PUT" -Url "$baseUrl/api/invoice/$newInvoiceId" -Body $updateInvoiceBody -Description "Update Invoice ($newInvoiceId)"
    
    Test-Endpoint -Method "DELETE" -Url "$baseUrl/api/invoice/$newInvoiceId" -Description "Delete Invoice ($newInvoiceId)"
}

Test-Endpoint -Method "GET" -Url "$baseUrl/api/invoice/member/$firstMemberId" -Description "Get Invoices by Member ID"
Test-Endpoint -Method "GET" -Url "$baseUrl/api/invoice/unpaid" -Description "Get Unpaid Invoices"

# Step 10: Test PAYMENT API
Write-Host "`n[10/10] PAYMENT API" -ForegroundColor Yellow
$paymentList = Test-Endpoint -Method "GET" -Url "$baseUrl/api/payment?pageNumber=1&pageSize=10" -Description "Get Payments List"
$firstPaymentId = ($paymentList.Response | ConvertFrom-Json).data[0].paymentId

Test-Endpoint -Method "GET" -Url "$baseUrl/api/payment/$firstPaymentId" -Description "Get Payment by ID ($firstPaymentId)"

$newPaymentBody = @{
    invoiceId = $firstInvoiceId
    memberId = $firstMemberId
    amount = 500000
    paymentDate = "2025-07-15T09:00:00"
    paymentMethod = "Cash"
    status = "Completed"
    notes = "Test payment"
}
$createPayment = Test-Endpoint -Method "POST" -Url "$baseUrl/api/payment" -Body $newPaymentBody -Description "Create New Payment"
$newPaymentId = ($createPayment.Response | ConvertFrom-Json).paymentId

if ($newPaymentId) {
    $updatePaymentBody = $newPaymentBody.Clone()
    $updatePaymentBody.notes = "Updated test payment"
    Test-Endpoint -Method "PUT" -Url "$baseUrl/api/payment/$newPaymentId" -Body $updatePaymentBody -Description "Update Payment ($newPaymentId)"
    
    Test-Endpoint -Method "DELETE" -Url "$baseUrl/api/payment/$newPaymentId" -Description "Delete Payment ($newPaymentId)"
}

Test-Endpoint -Method "GET" -Url "$baseUrl/api/payment/invoice/$firstInvoiceId" -Description "Get Payments by Invoice ID"
Test-Endpoint -Method "GET" -Url "$baseUrl/api/payment/member/$firstMemberId" -Description "Get Payments by Member ID"

# Test REPORT API
Write-Host "`n[BONUS] REPORT API" -ForegroundColor Yellow
Test-Endpoint -Method "GET" -Url "$baseUrl/api/report/revenue?startDate=2025-01-01&endDate=2025-12-31" -Description "Get Revenue Report"
Test-Endpoint -Method "GET" -Url "$baseUrl/api/report/members" -Description "Get Members Report"
Test-Endpoint -Method "GET" -Url "$baseUrl/api/report/trainers" -Description "Get Trainers Report"
Test-Endpoint -Method "GET" -Url "$baseUrl/api/report/facilities" -Description "Get Facilities Report"

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests: $testCount" -ForegroundColor White
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor Red
$successRate = [math]::Round(($passCount / $testCount) * 100, 2)
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { "Green" } elseif ($successRate -ge 70) { "Yellow" } else { "Red" })
Write-Host "========================================`n" -ForegroundColor Cyan

# Save results to file
Write-Host "Saving detailed results to API_TEST_RESULTS_DETAILED.md..." -ForegroundColor Cyan
$results | Export-Csv -Path "test-results.csv" -NoTypeInformation
Write-Host "Results also saved to test-results.csv" -ForegroundColor Gray
