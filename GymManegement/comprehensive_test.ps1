# Comprehensive API Test Script for Gym Management System
# Testing all 59 endpoints

$baseUrl = "http://localhost:5250"
$results = @()
$passCount = 0
$failCount = 0

# Get token
$token = Get-Content ".\test_token.txt" -Raw
$token = $token.Trim()
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

function Test-Endpoint {
    param(
        [string]$Method,
        [string]$Path,
        [string]$Body = $null,
        [int]$ExpectedStatus = 200,
        [string]$Description = ""
    )
    
    $url = "$baseUrl$Path"
    $result = @{
        Method = $Method
        Path = $Path
        Description = $Description
        Status = ""
        StatusCode = 0
        Response = ""
        Pass = $false
    }
    
    try {
        if ($Body) {
            $response = Invoke-RestMethod -Uri $url -Method $Method -Headers $headers -Body $Body -ContentType "application/json" -ErrorAction Stop
        } else {
            $response = Invoke-RestMethod -Uri $url -Method $Method -Headers $headers -ErrorAction Stop
        }
        
        $result.StatusCode = 200
        $result.Status = "✅ PASS"
        $result.Pass = $true
        $result.Response = ($response | ConvertTo-Json -Depth 2 -Compress).Substring(0, [Math]::Min(500, ($response | ConvertTo-Json -Depth 2 -Compress).Length))
        $script:passCount++
    } catch {
        $statusCode = 0
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        
        # Check if this is an expected failure (403 for DELETE)
        if ($Method -eq "DELETE" -and $statusCode -eq 403 -and $ExpectedStatus -eq 403) {
            $result.StatusCode = 403
            $result.Status = "✅ PASS (403 Expected)"
            $result.Pass = $true
            $result.Response = "403 Forbidden - Expected behavior (SuperAdmin only)"
            $script:passCount++
        } else {
            $result.StatusCode = $statusCode
            $result.Status = "❌ FAIL"
            $result.Pass = $false
            $result.Response = $_.Exception.Message
            $script:failCount++
        }
    }
    
    $script:results += $result
    Write-Output "$($result.Status) $Method $Path [$($result.StatusCode)]"
    return $result
}

Write-Output "=== STARTING COMPREHENSIVE API TEST ==="
Write-Output "Server: $baseUrl"
Write-Output "Testing 59 endpoints..."
Write-Output ""

# 1. AUTH (1 endpoint)
Write-Output "--- AUTH API (1 endpoint) ---"
Test-Endpoint -Method "POST" -Path "/api/auth/login" -Body '{"username":"gymadmin","password":"Gym@2026"}' -Description "Login"

# 2. MEMBER API (5 endpoints)
Write-Output "`n--- MEMBER API (5 endpoints) ---"
Test-Endpoint -Method "GET" -Path "/api/member?pageNumber=1&pageSize=10" -Description "Get all members"
Test-Endpoint -Method "GET" -Path "/api/member/0" -Description "Get member by ID"
$memberPost = Test-Endpoint -Method "POST" -Path "/api/member" -Body '{"fullName":"Retest Member","email":"retest@gym.com","phone":"0901234567","dateOfBirth":"1990-05-15","gender":"Male","address":"123 Retest St","emergencyContact":"0909999888","joinDate":"2025-01-01","status":"Active"}' -Description "Create member"
# Extract member ID from response if successful
if ($memberPost.Pass) {
    try {
        $memberResponse = $memberPost.Response | ConvertFrom-Json
        $memberId = $memberResponse.memberId
        Test-Endpoint -Method "PUT" -Path "/api/member/$memberId" -Body '{"fullName":"Retest Member Updated","email":"retest@gym.com","phone":"0901234567","dateOfBirth":"1990-05-15","gender":"Male","address":"456 Updated St","emergencyContact":"0909999888","joinDate":"2025-01-01","status":"Active"}' -Description "Update member"
        Test-Endpoint -Method "DELETE" -Path "/api/member/$memberId" -ExpectedStatus 403 -Description "Delete member (expect 403)"
    } catch {
        Test-Endpoint -Method "PUT" -Path "/api/member/9999" -Body '{"fullName":"Retest Member Updated","email":"retest@gym.com","phone":"0901234567","dateOfBirth":"1990-05-15","gender":"Male","address":"456 Updated St","emergencyContact":"0909999888","joinDate":"2025-01-01","status":"Active"}' -Description "Update member (fallback)"
        Test-Endpoint -Method "DELETE" -Path "/api/member/9999" -ExpectedStatus 403 -Description "Delete member (expect 403, fallback)"
    }
} else {
    Test-Endpoint -Method "PUT" -Path "/api/member/0" -Body '{"fullName":"Retest Member Updated","email":"retest@gym.com","phone":"0901234567","dateOfBirth":"1990-05-15","gender":"Male","address":"456 Updated St","emergencyContact":"0909999888","joinDate":"2025-01-01","status":"Active"}' -Description "Update member"
    Test-Endpoint -Method "DELETE" -Path "/api/member/0" -ExpectedStatus 403 -Description "Delete member (expect 403)"
}

# 3. TRAINER API (5 endpoints)
Write-Output "`n--- TRAINER API (5 endpoints) ---"
Test-Endpoint -Method "GET" -Path "/api/trainer?pageNumber=1&pageSize=10" -Description "Get all trainers"
Test-Endpoint -Method "GET" -Path "/api/trainer/0" -Description "Get trainer by ID"
$trainerPost = Test-Endpoint -Method "POST" -Path "/api/trainer" -Body '{"fullName":"Retest Trainer","email":"retesttrainer@gym.com","phone":"0902345001","specialization":"Cardio","experience":3,"certification":"ACE Certified","status":"Active","hireDate":"2024-01-01T00:00:00"}' -Description "Create trainer"
if ($trainerPost.Pass) {
    try {
        $trainerResponse = $trainerPost.Response | ConvertFrom-Json
        $trainerId = $trainerResponse.trainerId
        Test-Endpoint -Method "PUT" -Path "/api/trainer/$trainerId" -Body '{"fullName":"Retest Trainer Updated","email":"retesttrainer@gym.com","phone":"0902345001","specialization":"Strength Training","experience":4,"certification":"ACE Certified","status":"Active","hireDate":"2024-01-01T00:00:00"}' -Description "Update trainer"
        Test-Endpoint -Method "DELETE" -Path "/api/trainer/$trainerId" -ExpectedStatus 403 -Description "Delete trainer (expect 403)"
    } catch {
        Test-Endpoint -Method "PUT" -Path "/api/trainer/0" -Body '{"fullName":"Retest Trainer Updated","email":"retesttrainer@gym.com","phone":"0902345001","specialization":"Strength Training","experience":4,"certification":"ACE Certified","status":"Active","hireDate":"2024-01-01T00:00:00"}' -Description "Update trainer (fallback)"
        Test-Endpoint -Method "DELETE" -Path "/api/trainer/0" -ExpectedStatus 403 -Description "Delete trainer (expect 403, fallback)"
    }
} else {
    Test-Endpoint -Method "PUT" -Path "/api/trainer/0" -Body '{"fullName":"Retest Trainer Updated","email":"retesttrainer@gym.com","phone":"0902345001","specialization":"Strength Training","experience":4,"certification":"ACE Certified","status":"Active","hireDate":"2024-01-01T00:00:00"}' -Description "Update trainer"
    Test-Endpoint -Method "DELETE" -Path "/api/trainer/0" -ExpectedStatus 403 -Description "Delete trainer (expect 403)"
}

# 4. FACILITY API (5 endpoints)
Write-Output "`n--- FACILITY API (5 endpoints) ---"
Test-Endpoint -Method "GET" -Path "/api/facility?pageNumber=1&pageSize=10" -Description "Get all facilities"
Test-Endpoint -Method "GET" -Path "/api/facility/0" -Description "Get facility by ID"
$facilityPost = Test-Endpoint -Method "POST" -Path "/api/facility" -Body '{"name":"Retest Room","type":"Gym","capacity":30,"description":"Retest facility","status":"Available"}' -Description "Create facility"
if ($facilityPost.Pass) {
    try {
        $facilityResponse = $facilityPost.Response | ConvertFrom-Json
        $facilityId = $facilityResponse.facilityId
        Test-Endpoint -Method "PUT" -Path "/api/facility/$facilityId" -Body '{"name":"Retest Room Updated","type":"Yoga","capacity":20,"description":"Updated retest facility","status":"Available"}' -Description "Update facility"
        Test-Endpoint -Method "DELETE" -Path "/api/facility/$facilityId" -ExpectedStatus 403 -Description "Delete facility (expect 403)"
    } catch {
        Test-Endpoint -Method "PUT" -Path "/api/facility/0" -Body '{"name":"Retest Room Updated","type":"Yoga","capacity":20,"description":"Updated retest facility","status":"Available"}' -Description "Update facility (fallback)"
        Test-Endpoint -Method "DELETE" -Path "/api/facility/0" -ExpectedStatus 403 -Description "Delete facility (expect 403, fallback)"
    }
} else {
    Test-Endpoint -Method "PUT" -Path "/api/facility/0" -Body '{"name":"Retest Room Updated","type":"Yoga","capacity":20,"description":"Updated retest facility","status":"Available"}' -Description "Update facility"
    Test-Endpoint -Method "DELETE" -Path "/api/facility/0" -ExpectedStatus 403 -Description "Delete facility (expect 403)"
}

# 5. SCHEDULE API (7 endpoints)
Write-Output "`n--- SCHEDULE API (7 endpoints) ---"
Test-Endpoint -Method "GET" -Path "/api/schedule?pageNumber=1&pageSize=10" -Description "Get all schedules"
Test-Endpoint -Method "GET" -Path "/api/schedule/98" -Description "Get schedule by ID"
$schedulePost = Test-Endpoint -Method "POST" -Path "/api/schedule" -Body '{"trainerId":0,"facilityId":0,"className":"Retest Class","dayOfWeek":1,"startTime":"2025-07-15T09:00:00","endTime":"2025-07-15T10:00:00","maxParticipants":20,"status":"Active"}' -Description "Create schedule"
if ($schedulePost.Pass) {
    try {
        $scheduleResponse = $schedulePost.Response | ConvertFrom-Json
        $scheduleId = $scheduleResponse.scheduleId
        Test-Endpoint -Method "PUT" -Path "/api/schedule/$scheduleId" -Body '{"trainerId":0,"facilityId":0,"className":"Retest Class Updated","dayOfWeek":2,"startTime":"2025-07-15T09:00:00","endTime":"2025-07-15T10:00:00","maxParticipants":25,"status":"Active"}' -Description "Update schedule"
        Test-Endpoint -Method "DELETE" -Path "/api/schedule/$scheduleId" -ExpectedStatus 403 -Description "Delete schedule (expect 403)"
    } catch {
        Test-Endpoint -Method "PUT" -Path "/api/schedule/98" -Body '{"trainerId":0,"facilityId":0,"className":"Retest Class Updated","dayOfWeek":2,"startTime":"2025-07-15T09:00:00","endTime":"2025-07-15T10:00:00","maxParticipants":25,"status":"Active"}' -Description "Update schedule (fallback)"
        Test-Endpoint -Method "DELETE" -Path "/api/schedule/98" -ExpectedStatus 403 -Description "Delete schedule (expect 403, fallback)"
    }
} else {
    Test-Endpoint -Method "PUT" -Path "/api/schedule/98" -Body '{"trainerId":0,"facilityId":0,"className":"Retest Class Updated","dayOfWeek":2,"startTime":"2025-07-15T09:00:00","endTime":"2025-07-15T10:00:00","maxParticipants":25,"status":"Active"}' -Description "Update schedule"
    Test-Endpoint -Method "DELETE" -Path "/api/schedule/98" -ExpectedStatus 403 -Description "Delete schedule (expect 403)"
}
Test-Endpoint -Method "GET" -Path "/api/schedule/trainer/0" -Description "Get schedules by trainer ID"
Test-Endpoint -Method "GET" -Path "/api/schedule/date/2025-07-15" -Description "Get schedules by date"

# 6. SESSION API (5 endpoints)
Write-Output "`n--- SESSION API (5 endpoints) ---"
Test-Endpoint -Method "GET" -Path "/api/session?pageNumber=1&pageSize=10" -Description "Get all sessions"
Test-Endpoint -Method "GET" -Path "/api/session/0" -Description "Get session by ID"
$sessionPost = Test-Endpoint -Method "POST" -Path "/api/session" -Body '{"scheduleId":98,"sessionDate":"2025-07-20T09:00:00","startTime":"2025-07-20T09:00:00","endTime":"2025-07-20T10:00:00","status":"Scheduled","notes":"Retest session"}' -Description "Create session"
Test-Endpoint -Method "GET" -Path "/api/session/schedule/98" -Description "Get sessions by schedule ID"
Test-Endpoint -Method "GET" -Path "/api/session/member/0" -Description "Get sessions by member ID"

# 7. MEMBERSHIP API (7 endpoints)
Write-Output "`n--- MEMBERSHIP API (7 endpoints) ---"
Test-Endpoint -Method "GET" -Path "/api/membership?pageNumber=1&pageSize=10" -Description "Get all memberships"
Test-Endpoint -Method "GET" -Path "/api/membership/498" -Description "Get membership by ID"
$membershipPost = Test-Endpoint -Method "POST" -Path "/api/membership" -Body '{"memberId":0,"planName":"Monthly Basic","startDate":"2025-07-01","endDate":"2025-07-31","price":500000,"status":"Active"}' -Description "Create membership"
if ($membershipPost.Pass) {
    try {
        $membershipResponse = $membershipPost.Response | ConvertFrom-Json
        $membershipId = $membershipResponse.membershipId
        Test-Endpoint -Method "PUT" -Path "/api/membership/$membershipId" -Body '{"memberId":0,"planName":"Monthly Basic Updated","startDate":"2025-07-01","endDate":"2025-07-31","price":500000,"status":"Active"}' -Description "Update membership"
        Test-Endpoint -Method "DELETE" -Path "/api/membership/$membershipId" -ExpectedStatus 403 -Description "Delete membership (expect 403)"
    } catch {
        Test-Endpoint -Method "PUT" -Path "/api/membership/498" -Body '{"memberId":0,"planName":"Monthly Basic Updated","startDate":"2025-07-01","endDate":"2025-07-31","price":500000,"status":"Active"}' -Description "Update membership (fallback)"
        Test-Endpoint -Method "DELETE" -Path "/api/membership/498" -ExpectedStatus 403 -Description "Delete membership (expect 403, fallback)"
    }
} else {
    Test-Endpoint -Method "PUT" -Path "/api/membership/498" -Body '{"memberId":0,"planName":"Monthly Basic Updated","startDate":"2025-07-01","endDate":"2025-07-31","price":500000,"status":"Active"}' -Description "Update membership"
    Test-Endpoint -Method "DELETE" -Path "/api/membership/498" -ExpectedStatus 403 -Description "Delete membership (expect 403)"
}
Test-Endpoint -Method "GET" -Path "/api/membership/active" -Description "Get active memberships"
Test-Endpoint -Method "GET" -Path "/api/membership/expiring" -Description "Get expiring memberships"

# 8. CHECKIN API (6 endpoints)
Write-Output "`n--- CHECKIN API (6 endpoints) ---"
Test-Endpoint -Method "GET" -Path "/api/checkin?pageNumber=1&pageSize=10" -Description "Get all checkins"
Test-Endpoint -Method "GET" -Path "/api/checkin/0" -Description "Get checkin by ID"
Test-Endpoint -Method "POST" -Path "/api/checkin" -Body '{"memberId":0,"facilityId":0,"checkinTime":"2025-07-15T09:00:00","checkoutTime":"2025-07-15T10:00:00","notes":"Retest checkin"}' -Description "Create checkin"
Test-Endpoint -Method "GET" -Path "/api/checkin/member/0" -Description "Get checkins by member ID"
Test-Endpoint -Method "GET" -Path "/api/checkin/date/2025-07-15" -Description "Get checkins by date"
Test-Endpoint -Method "POST" -Path "/api/checkin/qr" -Body '{"memberId":0,"facilityId":0}' -Description "QR checkin"

# 9. INVOICE API (7 endpoints)
Write-Output "`n--- INVOICE API (7 endpoints) ---"
Test-Endpoint -Method "GET" -Path "/api/invoice?pageNumber=1&pageSize=10" -Description "Get all invoices"
Test-Endpoint -Method "GET" -Path "/api/invoice/0" -Description "Get invoice by ID"
$invoicePost = Test-Endpoint -Method "POST" -Path "/api/invoice" -Body '{"memberId":0,"membershipId":498,"amount":500000,"dueDate":"2025-08-01","status":"Unpaid","description":"Retest invoice"}' -Description "Create invoice"
if ($invoicePost.Pass) {
    try {
        $invoiceResponse = $invoicePost.Response | ConvertFrom-Json
        $invoiceId = $invoiceResponse.invoiceId
        Test-Endpoint -Method "PUT" -Path "/api/invoice/$invoiceId" -Body '{"memberId":0,"membershipId":498,"amount":500000,"dueDate":"2025-08-01","status":"Unpaid","description":"Updated retest invoice"}' -Description "Update invoice"
        Test-Endpoint -Method "DELETE" -Path "/api/invoice/$invoiceId" -ExpectedStatus 403 -Description "Delete invoice (expect 403)"
    } catch {
        Test-Endpoint -Method "PUT" -Path "/api/invoice/0" -Body '{"memberId":0,"membershipId":498,"amount":500000,"dueDate":"2025-08-01","status":"Unpaid","description":"Updated retest invoice"}' -Description "Update invoice (fallback)"
        Test-Endpoint -Method "DELETE" -Path "/api/invoice/0" -ExpectedStatus 403 -Description "Delete invoice (expect 403, fallback)"
    }
} else {
    Test-Endpoint -Method "PUT" -Path "/api/invoice/0" -Body '{"memberId":0,"membershipId":498,"amount":500000,"dueDate":"2025-08-01","status":"Unpaid","description":"Updated retest invoice"}' -Description "Update invoice"
    Test-Endpoint -Method "DELETE" -Path "/api/invoice/0" -ExpectedStatus 403 -Description "Delete invoice (expect 403)"
}
Test-Endpoint -Method "GET" -Path "/api/invoice/member/0" -Description "Get invoices by member ID"
Test-Endpoint -Method "GET" -Path "/api/invoice/unpaid" -Description "Get unpaid invoices"

# 10. PAYMENT API (7 endpoints)
Write-Output "`n--- PAYMENT API (7 endpoints) ---"
Test-Endpoint -Method "GET" -Path "/api/payment?pageNumber=1&pageSize=10" -Description "Get all payments"
Test-Endpoint -Method "GET" -Path "/api/payment/0" -Description "Get payment by ID"
$paymentPost = Test-Endpoint -Method "POST" -Path "/api/payment" -Body '{"invoiceId":0,"memberId":0,"amount":500000,"paymentDate":"2025-07-15T09:00:00","paymentMethod":"Cash","status":"Completed","notes":"Retest payment"}' -Description "Create payment"
if ($paymentPost.Pass) {
    try {
        $paymentResponse = $paymentPost.Response | ConvertFrom-Json
        $paymentId = $paymentResponse.paymentId
        Test-Endpoint -Method "PUT" -Path "/api/payment/$paymentId" -Body '{"invoiceId":0,"memberId":0,"amount":500000,"paymentDate":"2025-07-15T09:00:00","paymentMethod":"Cash","status":"Completed","notes":"Updated retest payment"}' -Description "Update payment"
        Test-Endpoint -Method "DELETE" -Path "/api/payment/$paymentId" -ExpectedStatus 403 -Description "Delete payment (expect 403)"
    } catch {
        Test-Endpoint -Method "PUT" -Path "/api/payment/0" -Body '{"invoiceId":0,"memberId":0,"amount":500000,"paymentDate":"2025-07-15T09:00:00","paymentMethod":"Cash","status":"Completed","notes":"Updated retest payment"}' -Description "Update payment (fallback)"
        Test-Endpoint -Method "DELETE" -Path "/api/payment/0" -ExpectedStatus 403 -Description "Delete payment (expect 403, fallback)"
    }
} else {
    Test-Endpoint -Method "PUT" -Path "/api/payment/0" -Body '{"invoiceId":0,"memberId":0,"amount":500000,"paymentDate":"2025-07-15T09:00:00","paymentMethod":"Cash","status":"Completed","notes":"Updated retest payment"}' -Description "Update payment"
    Test-Endpoint -Method "DELETE" -Path "/api/payment/0" -ExpectedStatus 403 -Description "Delete payment (expect 403)"
}
Test-Endpoint -Method "GET" -Path "/api/payment/invoice/0" -Description "Get payments by invoice ID"
Test-Endpoint -Method "GET" -Path "/api/payment/member/0" -Description "Get payments by member ID"

# 11. REPORT API (4 endpoints)
Write-Output "`n--- REPORT API (4 endpoints) ---"
Test-Endpoint -Method "GET" -Path "/api/report/revenue?startDate=2025-01-01&endDate=2025-12-31" -Description "Get revenue report"
Test-Endpoint -Method "GET" -Path "/api/report/members" -Description "Get members report"
Test-Endpoint -Method "GET" -Path "/api/report/trainers" -Description "Get trainers report"
Test-Endpoint -Method "GET" -Path "/api/report/facilities" -Description "Get facilities report"

# Summary
Write-Output "`n=== TEST SUMMARY ==="
Write-Output "Total: $($passCount + $failCount)/59"
Write-Output "Passed: $passCount"
Write-Output "Failed: $failCount"
Write-Output "Pass Rate: $([math]::Round(($passCount / 59) * 100, 1))%"

# Save results to file
$results | Export-Csv -Path ".\test_results.csv" -NoTypeInformation -Encoding UTF8
Write-Output "`nResults saved to test_results.csv"
