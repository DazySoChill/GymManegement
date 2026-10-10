# 🧪 COMPREHENSIVE API TEST GUIDE
**Gym Management System - Complete API Testing với Admin Account**

**Date:** 2026-10-10  
**Admin Account:** gymadmin / Gym@2026  
**Server:** http://localhost:5250

---

## 📋 MỤC LỤC

1. [Chuẩn Bị](#1-chuẩn-bị)
2. [Auth API Tests](#2-auth-api-tests)
3. [Members API Tests](#3-members-api-tests)
4. [Trainers API Tests](#4-trainers-api-tests)
5. [Facilities API Tests](#5-facilities-api-tests)
6. [Schedules API Tests](#6-schedules-api-tests)
7. [Sessions API Tests](#7-sessions-api-tests)
8. [Memberships API Tests](#8-memberships-api-tests)
9. [Checkins API Tests](#9-checkins-api-tests)
10. [Invoices API Tests](#10-invoices-api-tests)
11. [Payments API Tests](#11-payments-api-tests)
12. [Reports API Tests](#12-reports-api-tests)
13. [Test Results Template](#13-test-results-template)

---

## 1. CHUẨN BỊ

### Khởi động server
```powershell
cd "d:\Workspace\Độ án 2\GymManegement\GymManegement"
dotnet run
```

### Mở Swagger (Optional)
```
http://localhost:5250/swagger
```

### Base URL
```
http://localhost:5250/api
```

---

## 2. AUTH API TESTS

### 2.1. Login ✅ CRITICAL
**Endpoint:** `POST /api/auth/login`

**Input:**
```json
{
  "username": "gymadmin",
  "password": "Gym@2026"
}
```

**Expected Output:**
```json
{
  "token": "eyJhbGc...",
  "username": "gymadmin",
  "fullName": "Gym Administrator",
  "email": "gymadmin@gym.com",
  "role": "Admin",
  "memberId": null
}
```

**PowerShell Test:**
```powershell
$body = '{"username":"gymadmin","password":"Gym@2026"}'
$response = Invoke-RestMethod -Uri "http://localhost:5250/api/auth/login" -Method Post -Body $body -ContentType "application/json"
$token = $response.token
Write-Host "Token: $token"
```

**Success Criteria:**
- ✅ Status: 200 OK
- ✅ Token nhận được (JWT format)
- ✅ Role = Admin

---

### 2.2. Get Profile ✅
**Endpoint:** `GET /api/auth/profile`

**Headers:**
```
Authorization: Bearer {token_from_login}
```

**PowerShell Test:**
```powershell
$headers = @{ "Authorization" = "Bearer $token" }
$profile = Invoke-RestMethod -Uri "http://localhost:5250/api/auth/profile" -Headers $headers
$profile
```

**Expected Output:**
```json
{
  "userId": "514",
  "username": "gymadmin",
  "fullName": "Gym Administrator",
  "email": "gymadmin@gym.com",
  "role": "Admin",
  "memberId": null
}
```

---

### 2.3. Change Password
**Endpoint:** `POST /api/auth/change-password`

**Input:**
```json
{
  "oldPassword": "Gym@2026",
  "newPassword": "NewPassword@2026"
}
```

**Note:** ⚠️ Chỉ test nếu muốn đổi password. Sau khi đổi phải dùng password mới!

---

## 3. MEMBERS API TESTS

### 3.1. Get All Members (Paginated) ✅
**Endpoint:** `GET /api/members?pageNumber=1&pageSize=10`

**PowerShell Test:**
```powershell
$members = Invoke-RestMethod -Uri "http://localhost:5250/api/members?pageNumber=1&pageSize=10" -Headers $headers
Write-Host "Total Members: $($members.totalItems)"
Write-Host "Current Page: $($members.currentPage)/$($members.totalPages)"
$members.items | Select-Object -First 3 | Format-Table
```

**Expected Output:**
```json
{
  "items": [
    {
      "memberId": 1,
      "fullName": "Member 1",
      "email": "member1@test.com",
      "phone": "0901234567",
      "qrCode": "M000001",
      "createdAt": "2024-01-01T00:00:00"
    }
  ],
  "currentPage": 1,
  "totalPages": 50,
  "totalItems": 500,
  "pageSize": 10
}
```

---

### 3.2. Get Member By ID ✅
**Endpoint:** `GET /api/members/{id}`

**PowerShell Test:**
```powershell
$member = Invoke-RestMethod -Uri "http://localhost:5250/api/members/1" -Headers $headers
$member
```

**Test với IDs:** 1, 5, 10, 100, 500

---

### 3.3. Search Members
**Endpoint:** `GET /api/members?searchTerm={text}`

**PowerShell Test:**
```powershell
$search = Invoke-RestMethod -Uri "http://localhost:5250/api/members?searchTerm=member1&pageNumber=1&pageSize=10" -Headers $headers
$search.items | Format-Table
```

**Test Search Terms:**
- `member1` - tìm theo tên
- `test.com` - tìm theo email
- `090` - tìm theo phone

---

### 3.4. Create New Member ✅
**Endpoint:** `POST /api/members`

**Input:**
```json
{
  "fullName": "Test Member New",
  "email": "testmembernew@test.com",
  "phone": "0912345678",
  "dateOfBirth": "1990-01-01"
}
```

**PowerShell Test:**
```powershell
$newMember = @{
    fullName = "Test Member New"
    email = "testmembernew@test.com"
    phone = "0912345678"
    dateOfBirth = "1990-01-01"
} | ConvertTo-Json

$created = Invoke-RestMethod -Uri "http://localhost:5250/api/members" -Method Post -Body $newMember -ContentType "application/json" -Headers $headers
Write-Host "Created Member ID: $($created.memberId)"
Write-Host "QR Code: $($created.qrCode)"
```

**Success Criteria:**
- ✅ Status: 201 Created
- ✅ MemberId nhận được
- ✅ QRCode auto-generated (format: M000XXX)

---

### 3.5. Update Member
**Endpoint:** `PUT /api/members/{id}`

**Input:**
```json
{
  "fullName": "Updated Member Name",
  "email": "updated@test.com",
  "phone": "0987654321",
  "dateOfBirth": "1990-01-01"
}
```

**PowerShell Test:**
```powershell
$updateMember = @{
    fullName = "Updated Member Name"
    email = "updated@test.com"
    phone = "0987654321"
    dateOfBirth = "1990-01-01"
} | ConvertTo-Json

$updated = Invoke-RestMethod -Uri "http://localhost:5250/api/members/1" -Method Put -Body $updateMember -ContentType "application/json" -Headers $headers
$updated
```

---

### 3.6. Delete Member (Soft Delete)
**Endpoint:** `DELETE /api/members/{id}`

**PowerShell Test:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5250/api/members/501" -Method Delete -Headers $headers
Write-Host "Member 501 deleted (soft delete)"
```

**Note:** Soft delete - record vẫn còn trong DB với IsDeleted=1

---

## 4. TRAINERS API TESTS

### 4.1. Get All Trainers ✅
**Endpoint:** `GET /api/trainers?pageNumber=1&pageSize=10`

**PowerShell Test:**
```powershell
$trainers = Invoke-RestMethod -Uri "http://localhost:5250/api/trainers?pageNumber=1&pageSize=10" -Headers $headers
Write-Host "Total Trainers: $($trainers.totalItems)"
$trainers.items | Select-Object -First 3 | Format-Table
```

---

### 4.2. Get Trainer By ID
**Endpoint:** `GET /api/trainers/{id}`

**Test IDs:** 1, 5, 10, 50

---

### 4.3. Create New Trainer ✅
**Endpoint:** `POST /api/trainers`

**Input:**
```json
{
  "fullName": "Test Trainer New",
  "email": "testtrainer@test.com",
  "phone": "0923456789",
  "specialty": "Yoga & Fitness",
  "hireDate": "2024-01-01",
  "salary": 15000000
}
```

**PowerShell Test:**
```powershell
$newTrainer = @{
    fullName = "Test Trainer New"
    email = "testtrainer@test.com"
    phone = "0923456789"
    specialty = "Yoga & Fitness"
    hireDate = "2024-01-01"
    salary = 15000000
} | ConvertTo-Json

$created = Invoke-RestMethod -Uri "http://localhost:5250/api/trainers" -Method Post -Body $newTrainer -ContentType "application/json" -Headers $headers
Write-Host "Created Trainer ID: $($created.trainerId)"
```

---

### 4.4. Update Trainer
**Endpoint:** `PUT /api/trainers/{id}`

**Input:** Same as Create (with changes)

---

### 4.5. Delete Trainer
**Endpoint:** `DELETE /api/trainers/{id}`

---

## 5. FACILITIES API TESTS

### 5.1. Get All Facilities ✅
**Endpoint:** `GET /api/facilities?pageNumber=1&pageSize=10`

**PowerShell Test:**
```powershell
$facilities = Invoke-RestMethod -Uri "http://localhost:5250/api/facilities?pageNumber=1&pageSize=10" -Headers $headers
$facilities.items | Format-Table
```

---

### 5.2. Get Active Facilities ✅ NEW
**Endpoint:** `GET /api/facilities/active`

**PowerShell Test:**
```powershell
$active = Invoke-RestMethod -Uri "http://localhost:5250/api/facilities/active" -Headers $headers
Write-Host "Active Facilities: $($active.totalItems)"
```

---

### 5.3. Create New Facility ✅
**Endpoint:** `POST /api/facilities`

**Input:**
```json
{
  "facilityName": "Test Yoga Room",
  "facilityType": "Room",
  "capacity": 20,
  "status": "Active"
}
```

**PowerShell Test:**
```powershell
$newFacility = @{
    facilityName = "Test Yoga Room"
    facilityType = "Room"
    capacity = 20
    status = "Active"
} | ConvertTo-Json

$created = Invoke-RestMethod -Uri "http://localhost:5250/api/facilities" -Method Post -Body $newFacility -ContentType "application/json" -Headers $headers
Write-Host "Created Facility ID: $($created.facilityId)"
```

**Facility Types:** Room, Equipment, Other  
**Status Values:** Active, Maintenance, Unavailable

---

## 6. SCHEDULES API TESTS

### 6.1. Get All Schedules ✅
**Endpoint:** `GET /api/schedules?pageNumber=1&pageSize=10`

**PowerShell Test:**
```powershell
$schedules = Invoke-RestMethod -Uri "http://localhost:5250/api/schedules?pageNumber=1&pageSize=10" -Headers $headers
$schedules.items | Select-Object className, dayOfWeek, startTime, endTime | Format-Table
```

---

### 6.2. Create New Schedule ✅
**Endpoint:** `POST /api/schedules`

**Input:**
```json
{
  "className": "Morning Yoga Class",
  "trainerId": 1,
  "facilityId": 1,
  "startTime": "2025-01-20T06:00:00",
  "endTime": "2025-01-20T07:30:00",
  "maxCapacity": 20
}
```

**PowerShell Test:**
```powershell
$newSchedule = @{
    className = "Morning Yoga Class"
    trainerId = 1
    facilityId = 1
    startTime = "2025-01-20T06:00:00"
    endTime = "2025-01-20T07:30:00"
    maxCapacity = 20
} | ConvertTo-Json

$created = Invoke-RestMethod -Uri "http://localhost:5250/api/schedules" -Method Post -Body $newSchedule -ContentType "application/json" -Headers $headers
Write-Host "Created Schedule ID: $($created.scheduleId)"
```

**Note:** Use ISO 8601 DateTime format (YYYY-MM-DDTHH:MM:SS) for startTime and endTime. The database stores these as DATETIME columns.

---

## 7. SESSIONS API TESTS

### 7.1. Get All Sessions ✅
**Endpoint:** `GET /api/sessions?pageNumber=1&pageSize=10`

**PowerShell Test:**
```powershell
$sessions = Invoke-RestMethod -Uri "http://localhost:5250/api/sessions?pageNumber=1&pageSize=10" -Headers $headers
$sessions.items | Select-Object sessionId, memberId, scheduleId, status | Format-Table
```

---

### 7.2. Create New Session (Member Registration) ✅
**Endpoint:** `POST /api/sessions`

**Input:**
```json
{
  "memberId": 1,
  "scheduleId": 1,
  "registrationDate": "2024-01-15",
  "status": "Confirmed"
}
```

**PowerShell Test:**
```powershell
$newSession = @{
    memberId = 1
    scheduleId = 1
    registrationDate = (Get-Date -Format "yyyy-MM-dd")
    status = "Confirmed"
} | ConvertTo-Json

$created = Invoke-RestMethod -Uri "http://localhost:5250/api/sessions" -Method Post -Body $newSession -ContentType "application/json" -Headers $headers
Write-Host "Created Session ID: $($created.sessionId)"
```

**Status Values:** Confirmed, Cancelled, Completed

---

### 7.3. Update Session Status ✅ NEW
**Endpoint:** `PUT /api/sessions/{id}/status`

**Input:**
```json
{
  "status": "Completed"
}
```

**PowerShell Test:**
```powershell
$updateStatus = @{
    status = "Completed"
} | ConvertTo-Json

$updated = Invoke-RestMethod -Uri "http://localhost:5250/api/sessions/1/status" -Method Put -Body $updateStatus -ContentType "application/json" -Headers $headers
```

---

## 8. MEMBERSHIPS API TESTS

### 8.1. Get Memberships By Member ✅
**Endpoint:** `GET /api/memberships/member/{memberId}`

**PowerShell Test:**
```powershell
$memberships = Invoke-RestMethod -Uri "http://localhost:5250/api/memberships/member/1" -Headers $headers
$memberships | Format-Table
```

---

### 8.2. Get Active Membership ✅
**Endpoint:** `GET /api/memberships/member/{memberId}/active`

**PowerShell Test:**
```powershell
$active = Invoke-RestMethod -Uri "http://localhost:5250/api/memberships/member/1/active" -Headers $headers
$active
```

---

### 8.3. Create New Membership ✅
**Endpoint:** `POST /api/memberships`

**Input:**
```json
{
  "memberId": 1,
  "packageName": "Monthly",
  "price": 500000,
  "startDate": "2024-01-01",
  "endDate": "2024-01-31",
  "status": "Active"
}
```

**PowerShell Test:**
```powershell
$newMembership = @{
    memberId = 1
    packageName = "Monthly"
    price = 500000
    startDate = "2024-01-01"
    endDate = "2024-01-31"
    status = "Active"
} | ConvertTo-Json

$created = Invoke-RestMethod -Uri "http://localhost:5250/api/memberships" -Method Post -Body $newMembership -ContentType "application/json" -Headers $headers
Write-Host "Created Membership ID: $($created.membershipId)"
Write-Host "Auto-created Invoice ID: Check invoices API"
```

**Package Names:** Monthly, Quarterly, Annual  
**Status Values:** Active, Expired, Cancelled

**Note:** ✅ Tự động tạo Invoice khi tạo Membership!

---

### 8.4. Renew Membership ✅ NEW
**Endpoint:** `POST /api/memberships/{id}/renew`

**Input:**
```json
{
  "packageName": "Monthly",
  "price": 500000,
  "startDate": "2024-02-01",
  "endDate": "2024-02-28"
}
```

**PowerShell Test:**
```powershell
$renewData = @{
    packageName = "Monthly"
    price = 500000
    startDate = "2024-02-01"
    endDate = "2024-02-28"
} | ConvertTo-Json

$renewed = Invoke-RestMethod -Uri "http://localhost:5250/api/memberships/1/renew" -Method Post -Body $renewData -ContentType "application/json" -Headers $headers
Write-Host "Renewed Membership ID: $($renewed.membershipId)"
```

---

## 9. CHECKINS API TESTS

### 9.1. Get All Checkins ✅
**Endpoint:** `GET /api/checkins?pageNumber=1&pageSize=10`

**PowerShell Test:**
```powershell
$checkins = Invoke-RestMethod -Uri "http://localhost:5250/api/checkins?pageNumber=1&pageSize=10" -Headers $headers
$checkins.items | Select-Object checkinId, memberId, checkinTime | Format-Table
```

---

### 9.2. Manual Checkin ✅
**Endpoint:** `POST /api/checkins/manual`

**Input:**
```json
{
  "memberId": 1,
  "checkinTime": "2024-01-15T10:30:00"
}
```

**PowerShell Test:**
```powershell
$checkinData = @{
    memberId = 1
    checkinTime = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
} | ConvertTo-Json

$checkin = Invoke-RestMethod -Uri "http://localhost:5250/api/checkins/manual" -Method Post -Body $checkinData -ContentType "application/json" -Headers $headers
Write-Host "Checkin ID: $($checkin.checkinId)"
```

**Validation:**
- ✅ Member must have active membership
- ✅ Cannot checkin twice same day

---

### 9.3. QR Code Checkin ✅
**Endpoint:** `POST /api/checkins/qr` (Public - No Auth)

**Input:**
```json
{
  "qrCode": "M000001"
}
```

**PowerShell Test:**
```powershell
$qrData = '{"qrCode":"M000001"}'
$checkin = Invoke-RestMethod -Uri "http://localhost:5250/api/checkins/qr" -Method Post -Body $qrData -ContentType "application/json"
Write-Host "QR Checkin Success: $($checkin.memberId)"
```

**Test QR Codes:** M000001, M000002, M000005, M000010

---

## 10. INVOICES API TESTS

### 10.1. Get All Invoices ✅
**Endpoint:** `GET /api/invoices?pageNumber=1&pageSize=10`

**PowerShell Test:**
```powershell
$invoices = Invoke-RestMethod -Uri "http://localhost:5250/api/invoices?pageNumber=1&pageSize=10" -Headers $headers
$invoices.items | Select-Object invoiceId, amount, status, dueDate | Format-Table
```

---

### 10.2. Get Invoice By ID
**Endpoint:** `GET /api/invoices/{id}`

---

### 10.3. Get Invoices By Member
**Endpoint:** `GET /api/invoices/member/{memberId}`

**PowerShell Test:**
```powershell
$memberInvoices = Invoke-RestMethod -Uri "http://localhost:5250/api/invoices/member/1" -Headers $headers
$memberInvoices | Format-Table
```

---

### 10.4. Get Overdue Invoices ✅
**Endpoint:** `GET /api/invoices/overdue`

**PowerShell Test:**
```powershell
$overdue = Invoke-RestMethod -Uri "http://localhost:5250/api/invoices/overdue" -Headers $headers
Write-Host "Overdue Invoices: $($overdue.Count)"
$overdue | Format-Table
```

---

### 10.5. Update Invoice Status ✅ NEW
**Endpoint:** `PUT /api/invoices/{id}/status`

**Input:**
```json
{
  "status": "Paid",
  "description": "Payment received"
}
```

**PowerShell Test:**
```powershell
$updateInvoice = @{
    status = "Paid"
    description = "Payment received"
} | ConvertTo-Json

$updated = Invoke-RestMethod -Uri "http://localhost:5250/api/invoices/1/status" -Method Put -Body $updateInvoice -ContentType "application/json" -Headers $headers
```

**Status Values:** Pending, Paid, Overdue, Cancelled

---

## 11. PAYMENTS API TESTS

### 11.1. Get Payments By Invoice ✅
**Endpoint:** `GET /api/payments/invoice/{invoiceId}`

**PowerShell Test:**
```powershell
$payments = Invoke-RestMethod -Uri "http://localhost:5250/api/payments/invoice/1" -Headers $headers
$payments | Format-Table
```

---

### 11.2. Create Payment ✅
**Endpoint:** `POST /api/payments`

**Input:**
```json
{
  "invoiceId": 1,
  "amount": 500000,
  "paymentDate": "2024-01-15",
  "paymentMethod": "Cash"
}
```

**PowerShell Test:**
```powershell
$newPayment = @{
    invoiceId = 1
    amount = 500000
    paymentDate = (Get-Date -Format "yyyy-MM-dd")
    paymentMethod = "Cash"
} | ConvertTo-Json

$created = Invoke-RestMethod -Uri "http://localhost:5250/api/payments" -Method Post -Body $newPayment -ContentType "application/json" -Headers $headers
Write-Host "Created Payment ID: $($created.paymentId)"
Write-Host "Invoice Status Auto-Updated!"
```

**Payment Methods:** Cash, BankTransfer, CreditCard, EWallet

**Note:** ✅ Tự động update Invoice.Status = Paid khi payment đủ!

---

### 11.3. Update Payment Status ✅ NEW
**Endpoint:** `PUT /api/payments/{id}/status`

**Input:**
```json
{
  "paymentMethod": "BankTransfer"
}
```

---

## 12. REPORTS API TESTS

### 12.1. Get Active Members ✅
**Endpoint:** `GET /api/reports/active-members`

**PowerShell Test:**
```powershell
$activeMembers = Invoke-RestMethod -Uri "http://localhost:5250/api/reports/active-members" -Headers $headers
Write-Host "Active Members Count: $($activeMembers.Count)"
$activeMembers | Select-Object -First 10 | Format-Table
```

---

### 12.2. Get Revenue Report ✅
**Endpoint:** `GET /api/reports/revenue?month={m}&year={y}`

**PowerShell Test:**
```powershell
$month = (Get-Date).Month
$year = (Get-Date).Year
$revenue = Invoke-RestMethod -Uri "http://localhost:5250/api/reports/revenue?month=$month&year=$year" -Headers $headers
Write-Host "Total Revenue: $($revenue.totalRevenue)"
$revenue
```

---

### 12.3. Get Revenue Detail ✅
**Endpoint:** `GET /api/reports/revenue/detail?month={m}&year={y}`

**PowerShell Test:**
```powershell
$revenueDetail = Invoke-RestMethod -Uri "http://localhost:5250/api/reports/revenue/detail?month=$month&year=$year" -Headers $headers
$revenueDetail | Format-Table
```

---

## 13. TEST RESULTS TEMPLATE

### Copy template này để record test results:

```
================================================================================
API TEST RESULTS - {Date}
Tester: {Your Name}
Admin: gymadmin / Gym@2026
================================================================================

[1/12] AUTH API
  ✅/❌ 1.1 Login
  ✅/❌ 1.2 Get Profile
  ✅/❌ 1.3 Change Password (optional)

[2/12] MEMBERS API
  ✅/❌ 2.1 Get All (Paginated)
  ✅/❌ 2.2 Get By ID
  ✅/❌ 2.3 Search
  ✅/❌ 2.4 Create
  ✅/❌ 2.5 Update
  ✅/❌ 2.6 Delete

[3/12] TRAINERS API
  ✅/❌ 3.1 Get All
  ✅/❌ 3.2 Get By ID
  ✅/❌ 3.3 Create
  ✅/❌ 3.4 Update
  ✅/❌ 3.5 Delete

[4/12] FACILITIES API
  ✅/❌ 4.1 Get All
  ✅/❌ 4.2 Get Active (NEW)
  ✅/❌ 4.3 Create
  ✅/❌ 4.4 Update
  ✅/❌ 4.5 Delete

[5/12] SCHEDULES API
  ✅/❌ 5.1 Get All
  ✅/❌ 5.2 Get By ID
  ✅/❌ 5.3 Create
  ✅/❌ 5.4 Update
  ✅/❌ 5.5 Delete

[6/12] SESSIONS API
  ✅/❌ 6.1 Get All
  ✅/❌ 6.2 Create
  ✅/❌ 6.3 Update Status (NEW)
  ✅/❌ 6.4 Delete

[7/12] MEMBERSHIPS API
  ✅/❌ 7.1 Get By Member
  ✅/❌ 7.2 Get Active
  ✅/❌ 7.3 Create (auto creates Invoice)
  ✅/❌ 7.4 Update
  ✅/❌ 7.5 Renew (NEW)

[8/12] CHECKINS API
  ✅/❌ 8.1 Get All
  ✅/❌ 8.2 Manual Checkin
  ✅/❌ 8.3 QR Checkin (public)

[9/12] INVOICES API
  ✅/❌ 9.1 Get All
  ✅/❌ 9.2 Get By ID
  ✅/❌ 9.3 Get By Member
  ✅/❌ 9.4 Get Overdue
  ✅/❌ 9.5 Update Status (NEW)

[10/12] PAYMENTS API
  ✅/❌ 10.1 Get By Invoice
  ✅/❌ 10.2 Create (auto updates Invoice)
  ✅/❌ 10.3 Update Status (NEW)

[11/12] REPORTS API
  ✅/❌ 11.1 Active Members
  ✅/❌ 11.2 Revenue Report
  ✅/❌ 11.3 Revenue Detail

[12/12] BUSINESS LOGIC VERIFICATION
  ✅/❌ Auto-create Member on Register
  ✅/❌ Auto-generate QRCode
  ✅/❌ Auto-create Invoice on Membership
  ✅/❌ Auto-update Invoice on Payment

================================================================================
SUMMARY
Total Tests: XX
Passed: XX
Failed: XX
Success Rate: XX%
================================================================================
```

---

## AUTOMATED TEST SCRIPT

Save as `run-all-tests.ps1`:

```powershell
# Complete API Test Script
$baseUrl = "http://localhost:5250/api"
$results = @()

Write-Host "Starting API Tests..." -ForegroundColor Cyan

# 1. Login
$loginBody = '{"username":"gymadmin","password":"Gym@2026"}'
$login = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$token = $login.token
$headers = @{ "Authorization" = "Bearer $token" }
$results += "✅ Auth/Login"

# 2. Get Profile
$profile = Invoke-RestMethod -Uri "$baseUrl/auth/profile" -Headers $headers
$results += "✅ Auth/Profile"

# 3. Members
$members = Invoke-RestMethod -Uri "$baseUrl/members?pageNumber=1&pageSize=5" -Headers $headers
$results += "✅ Members/GetAll: $($members.totalItems) members"

# ... continue for all APIs ...

# Summary
Write-Host "`nTest Results:" -ForegroundColor Green
$results | ForEach-Object { Write-Host $_ }
```

---

**Last Updated:** 2026-10-10  
**Status:** Ready for Testing  
**Next:** Run tests và ghi kết quả vào template
