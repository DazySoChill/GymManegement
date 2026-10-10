# Full API Test - All 59 Endpoints
$ErrorActionPreference = "Continue"
$baseUrl = "http://localhost:5250"
$token = (Get-Content ".\test_token.txt" -Raw).Trim()
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

$results = [System.Collections.ArrayList]::new()
$passCount = 0
$failCount = 0

function Test-API {
    param($Method, $Path, $Body = $null, $ExpectForbidden = $false, $Desc = "")
    
    $url = "$baseUrl$Path"
    $result = [PSCustomObject]@{
        Method = $Method
        Path = $Path
        Description = $Desc
        Status = ""
        StatusCode = 0
        Response = ""
    }
    
    try {
        if ($Body) {
            $resp = Invoke-RestMethod -Uri $url -Method $Method -Headers $headers -Body $Body -ContentType "application/json"
        } else {
            $resp = Invoke-RestMethod -Uri $url -Method $Method -Headers $headers
        }
        
        $result.StatusCode = 200
        $result.Status = "PASS"
        $result.Response = ($resp | ConvertTo-Json -Depth 2 -Compress).Substring(0, [Math]::Min(300, ($resp | ConvertTo-Json -Depth 2 -Compress).Length))
        $script:passCount++
        return $result
    } catch {
        $statusCode = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
        
        if ($ExpectForbidden -and $statusCode -eq 403) {
            $result.StatusCode = 403
            $result.Status = "PASS (403)"
            $result.Response = "403 Forbidden - Expected"
            $script:passCount++
        } else {
            $result.StatusCode = $statusCode
            $result.Status = "FAIL"
            $result.Response = $_.Exception.Message.Substring(0, [Math]::Min(200, $_.Exception.Message.Length))
            $script:failCount++
        }
        return $result
    }
}

Write-Host "=== COMPREHENSIVE API TEST - 59 ENDPOINTS ===" -ForegroundColor Cyan
Write-Host "Server: $baseUrl" -ForegroundColor Yellow
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host ""

# 1. AUTH (1)
Write-Host "AUTH API (1)" -ForegroundColor Green
$results.Add((Test-API -Method POST -Path "/api/auth/login" -Body '{"username":"gymadmin","password":"Gym@2026"}' -Desc "Login")) | Out-Null

# 2. MEMBER (5)
Write-Host "MEMBER API (5)" -ForegroundColor Green
$results.Add((Test-API -Method GET -Path "/api/member?pageNumber=1&pageSize=10" -Desc "Get all members")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/member/0" -Desc "Get member by ID")) | Out-Null
$memberPost = Test-API -Method POST -Path "/api/member" -Body '{"fullName":"Retest Member","email":"retest@gym.com","phone":"0901234567","dateOfBirth":"1990-05-15","gender":"Male","address":"123 Retest St","emergencyContact":"0909999888","joinDate":"2025-01-01","status":"Active"}' -Desc "Create member"
$results.Add($memberPost) | Out-Null
$memberId = if ($memberPost.StatusCode -eq 200) { try { ($memberPost.Response | ConvertFrom-Json).memberId } catch { 0 } } else { 0 }
$results.Add((Test-API -Method PUT -Path "/api/member/$memberId" -Body '{"fullName":"Retest Member Updated","email":"retest@gym.com","phone":"0901234567","dateOfBirth":"1990-05-15","gender":"Male","address":"456 Updated St","emergencyContact":"0909999888","joinDate":"2025-01-01","status":"Active"}' -Desc "Update member")) | Out-Null
$results.Add((Test-API -Method DELETE -Path "/api/member/$memberId" -ExpectForbidden $true -Desc "Delete member")) | Out-Null

# 3. TRAINER (5)
Write-Host "TRAINER API (5)" -ForegroundColor Green
$results.Add((Test-API -Method GET -Path "/api/trainer?pageNumber=1&pageSize=10" -Desc "Get all trainers")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/trainer/0" -Desc "Get trainer by ID")) | Out-Null
$trainerPost = Test-API -Method POST -Path "/api/trainer" -Body '{"fullName":"Retest Trainer","email":"retesttrainer@gym.com","phone":"0902345001","specialization":"Cardio","experience":3,"certification":"ACE Certified","status":"Active","hireDate":"2024-01-01T00:00:00"}' -Desc "Create trainer"
$results.Add($trainerPost) | Out-Null
$trainerId = if ($trainerPost.StatusCode -eq 200) { try { ($trainerPost.Response | ConvertFrom-Json).trainerId } catch { 0 } } else { 0 }
$results.Add((Test-API -Method PUT -Path "/api/trainer/$trainerId" -Body '{"fullName":"Retest Trainer Updated","email":"retesttrainer@gym.com","phone":"0902345001","specialization":"Strength Training","experience":4,"certification":"ACE Certified","status":"Active","hireDate":"2024-01-01T00:00:00"}' -Desc "Update trainer")) | Out-Null
$results.Add((Test-API -Method DELETE -Path "/api/trainer/$trainerId" -ExpectForbidden $true -Desc "Delete trainer")) | Out-Null

# 4. FACILITY (5)
Write-Host "FACILITY API (5)" -ForegroundColor Green
$results.Add((Test-API -Method GET -Path "/api/facility?pageNumber=1&pageSize=10" -Desc "Get all facilities")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/facility/0" -Desc "Get facility by ID")) | Out-Null
$facilityPost = Test-API -Method POST -Path "/api/facility" -Body '{"name":"Retest Room","type":"Gym","capacity":30,"description":"Retest facility","status":"Available"}' -Desc "Create facility"
$results.Add($facilityPost) | Out-Null
$facilityId = if ($facilityPost.StatusCode -eq 200) { try { ($facilityPost.Response | ConvertFrom-Json).facilityId } catch { 0 } } else { 0 }
$results.Add((Test-API -Method PUT -Path "/api/facility/$facilityId" -Body '{"name":"Retest Room Updated","type":"Yoga","capacity":20,"description":"Updated retest facility","status":"Available"}' -Desc "Update facility")) | Out-Null
$results.Add((Test-API -Method DELETE -Path "/api/facility/$facilityId" -ExpectForbidden $true -Desc "Delete facility")) | Out-Null

# 5. SCHEDULE (7)
Write-Host "SCHEDULE API (7)" -ForegroundColor Green
$results.Add((Test-API -Method GET -Path "/api/schedule?pageNumber=1&pageSize=10" -Desc "Get all schedules")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/schedule/98" -Desc "Get schedule by ID")) | Out-Null
$schedulePost = Test-API -Method POST -Path "/api/schedule" -Body '{"trainerId":0,"facilityId":0,"className":"Retest Class","dayOfWeek":1,"startTime":"2025-07-15T09:00:00","endTime":"2025-07-15T10:00:00","maxParticipants":20,"status":"Active"}' -Desc "Create schedule"
$results.Add($schedulePost) | Out-Null
$scheduleId = if ($schedulePost.StatusCode -eq 200) { try { ($schedulePost.Response | ConvertFrom-Json).scheduleId } catch { 98 } } else { 98 }
$results.Add((Test-API -Method PUT -Path "/api/schedule/$scheduleId" -Body '{"trainerId":0,"facilityId":0,"className":"Retest Class Updated","dayOfWeek":2,"startTime":"2025-07-15T09:00:00","endTime":"2025-07-15T10:00:00","maxParticipants":25,"status":"Active"}' -Desc "Update schedule")) | Out-Null
$results.Add((Test-API -Method DELETE -Path "/api/schedule/$scheduleId" -ExpectForbidden $true -Desc "Delete schedule")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/schedule/trainer/0" -Desc "Get schedules by trainer")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/schedule/date/2025-07-15" -Desc "Get schedules by date")) | Out-Null

# 6. SESSION (5)
Write-Host "SESSION API (5)" -ForegroundColor Green
$results.Add((Test-API -Method GET -Path "/api/session?pageNumber=1&pageSize=10" -Desc "Get all sessions")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/session/0" -Desc "Get session by ID")) | Out-Null
$sessionPost = Test-API -Method POST -Path "/api/session" -Body '{"scheduleId":98,"sessionDate":"2025-07-20T09:00:00","startTime":"2025-07-20T09:00:00","endTime":"2025-07-20T10:00:00","status":"Scheduled","notes":"Retest session"}' -Desc "Create session"
$results.Add($sessionPost) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/session/schedule/98" -Desc "Get sessions by schedule")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/session/member/0" -Desc "Get sessions by member")) | Out-Null

# 7. MEMBERSHIP (7)
Write-Host "MEMBERSHIP API (7)" -ForegroundColor Green
$results.Add((Test-API -Method GET -Path "/api/membership?pageNumber=1&pageSize=10" -Desc "Get all memberships")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/membership/498" -Desc "Get membership by ID")) | Out-Null
$membershipPost = Test-API -Method POST -Path "/api/membership" -Body '{"memberId":0,"planName":"Monthly Basic","startDate":"2025-07-01","endDate":"2025-07-31","price":500000,"status":"Active"}' -Desc "Create membership"
$results.Add($membershipPost) | Out-Null
$membershipId = if ($membershipPost.StatusCode -eq 200) { try { ($membershipPost.Response | ConvertFrom-Json).membershipId } catch { 498 } } else { 498 }
$results.Add((Test-API -Method PUT -Path "/api/membership/$membershipId" -Body '{"memberId":0,"planName":"Monthly Basic Updated","startDate":"2025-07-01","endDate":"2025-07-31","price":500000,"status":"Active"}' -Desc "Update membership")) | Out-Null
$results.Add((Test-API -Method DELETE -Path "/api/membership/$membershipId" -ExpectForbidden $true -Desc "Delete membership")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/membership/active" -Desc "Get active memberships")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/membership/expiring" -Desc "Get expiring memberships")) | Out-Null

# 8. CHECKIN (6)
Write-Host "CHECKIN API (6)" -ForegroundColor Green
$results.Add((Test-API -Method GET -Path "/api/checkin?pageNumber=1&pageSize=10" -Desc "Get all checkins")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/checkin/0" -Desc "Get checkin by ID")) | Out-Null
$results.Add((Test-API -Method POST -Path "/api/checkin" -Body '{"memberId":0,"facilityId":0,"checkinTime":"2025-07-15T09:00:00","checkoutTime":"2025-07-15T10:00:00","notes":"Retest checkin"}' -Desc "Create checkin")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/checkin/member/0" -Desc "Get checkins by member")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/checkin/date/2025-07-15" -Desc "Get checkins by date")) | Out-Null
$results.Add((Test-API -Method POST -Path "/api/checkin/qr" -Body '{"memberId":0,"facilityId":0}' -Desc "QR checkin")) | Out-Null

# 9. INVOICE (7)
Write-Host "INVOICE API (7)" -ForegroundColor Green
$results.Add((Test-API -Method GET -Path "/api/invoice?pageNumber=1&pageSize=10" -Desc "Get all invoices")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/invoice/0" -Desc "Get invoice by ID")) | Out-Null
$invoicePost = Test-API -Method POST -Path "/api/invoice" -Body '{"memberId":0,"membershipId":498,"amount":500000,"dueDate":"2025-08-01","status":"Unpaid","description":"Retest invoice"}' -Desc "Create invoice"
$results.Add($invoicePost) | Out-Null
$invoiceId = if ($invoicePost.StatusCode -eq 200) { try { ($invoicePost.Response | ConvertFrom-Json).invoiceId } catch { 0 } } else { 0 }
$results.Add((Test-API -Method PUT -Path "/api/invoice/$invoiceId" -Body '{"memberId":0,"membershipId":498,"amount":500000,"dueDate":"2025-08-01","status":"Unpaid","description":"Updated retest invoice"}' -Desc "Update invoice")) | Out-Null
$results.Add((Test-API -Method DELETE -Path "/api/invoice/$invoiceId" -ExpectForbidden $true -Desc "Delete invoice")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/invoice/member/0" -Desc "Get invoices by member")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/invoice/unpaid" -Desc "Get unpaid invoices")) | Out-Null

# 10. PAYMENT (7)
Write-Host "PAYMENT API (7)" -ForegroundColor Green
$results.Add((Test-API -Method GET -Path "/api/payment?pageNumber=1&pageSize=10" -Desc "Get all payments")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/payment/0" -Desc "Get payment by ID")) | Out-Null
$paymentPost = Test-API -Method POST -Path "/api/payment" -Body '{"invoiceId":0,"memberId":0,"amount":500000,"paymentDate":"2025-07-15T09:00:00","paymentMethod":"Cash","status":"Completed","notes":"Retest payment"}' -Desc "Create payment"
$results.Add($paymentPost) | Out-Null
$paymentId = if ($paymentPost.StatusCode -eq 200) { try { ($paymentPost.Response | ConvertFrom-Json).paymentId } catch { 0 } } else { 0 }
$results.Add((Test-API -Method PUT -Path "/api/payment/$paymentId" -Body '{"invoiceId":0,"memberId":0,"amount":500000,"paymentDate":"2025-07-15T09:00:00","paymentMethod":"Cash","status":"Completed","notes":"Updated retest payment"}' -Desc "Update payment")) | Out-Null
$results.Add((Test-API -Method DELETE -Path "/api/payment/$paymentId" -ExpectForbidden $true -Desc "Delete payment")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/payment/invoice/0" -Desc "Get payments by invoice")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/payment/member/0" -Desc "Get payments by member")) | Out-Null

# 11. REPORT (4)
Write-Host "REPORT API (4)" -ForegroundColor Green
$results.Add((Test-API -Method GET -Path "/api/report/revenue?startDate=2025-01-01&endDate=2025-12-31" -Desc "Revenue report")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/report/members" -Desc "Members report")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/report/trainers" -Desc "Trainers report")) | Out-Null
$results.Add((Test-API -Method GET -Path "/api/report/facilities" -Desc "Facilities report")) | Out-Null

Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total: $($passCount + $failCount)/59"
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor Red
Write-Host "Pass Rate: $([math]::Round(($passCount / 59) * 100, 1))%"

# Save results
$results | Export-Csv -Path ".\full_test_results.csv" -NoTypeInformation -Encoding UTF8
Write-Host "`nResults saved to full_test_results.csv"
