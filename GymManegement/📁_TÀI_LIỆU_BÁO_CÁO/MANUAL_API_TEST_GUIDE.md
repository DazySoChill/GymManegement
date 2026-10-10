# Manual API Test Guide - GymManagement System

## Setup & Authentication

### Base URL
```
http://localhost:5062
```

### Admin Credentials
```
Username: gymadmin
Password: Gym@2026
```

### Get Authentication Token

**Request:**
```powershell
$loginBody = @{
    username = "gymadmin"
    password = "Gym@2026"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:5062/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$token = $response.token
$headers = @{ "Authorization" = "Bearer $token" }

Write-Host "Token obtained: $token"
```

**Expected Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "username": "gymadmin",
  "role": "Admin"
}
```

---

## Module 1: Authentication (1 endpoint)

### ✅ POST /api/auth/login
Login with username and password.

**Request:**
```json
{
  "username": "gymadmin",
  "password": "Gym@2026"
}
```

**PowerShell:**
```powershell
$body = '{"username":"gymadmin","password":"Gym@2026"}'
Invoke-RestMethod -Uri "http://localhost:5062/api/auth/login" -Method Post -Body $body -ContentType "application/json"
```

---

## Module 2: Members (5 endpoints)

### ✅ GET /api/member
Get all members with pagination.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/member?pageNumber=1&pageSize=10" -Headers $headers
```

### ✅ GET /api/member/{id}
Get member by ID.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/member/1" -Headers $headers
```

### ✅ POST /api/member
Create a new member.

**Request:**
```json
{
  "fullName": "Test Member",
  "email": "testmember@gym.com",
  "phone": "0901234567",
  "dateOfBirth": "1990-01-01T00:00:00",
  "address": "123 Test Street",
  "emergencyContact": "0909876543",
  "qrCode": "QR_TEST_001"
}
```

**PowerShell:**
```powershell
$memberBody = @{
    fullName = "Test Member"
    email = "testmember@gym.com"
    phone = "0901234567"
    dateOfBirth = "1990-01-01T00:00:00"
    address = "123 Test Street"
    emergencyContact = "0909876543"
    qrCode = "QR_TEST_001"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5062/api/member" -Method Post -Body $memberBody -ContentType "application/json" -Headers $headers
```

### ✅ PUT /api/member/{id}
Update an existing member.

**Request:**
```json
{
  "fullName": "Updated Member Name",
  "email": "updated@gym.com",
  "phone": "0901234999",
  "dateOfBirth": "1990-01-01T00:00:00",
  "address": "456 Updated Street",
  "emergencyContact": "0909876999"
}
```

**PowerShell:**
```powershell
$updateBody = @{
    fullName = "Updated Member Name"
    email = "updated@gym.com"
    phone = "0901234999"
    dateOfBirth = "1990-01-01T00:00:00"
    address = "456 Updated Street"
    emergencyContact = "0909876999"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5062/api/member/1" -Method Put -Body $updateBody -ContentType "application/json" -Headers $headers
```

### ⚠️ DELETE /api/member/{id}
Soft delete a member (requires SuperAdmin role - Admin cannot delete).

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/member/1" -Method Delete -Headers $headers
```

**Expected:** 403 Forbidden (Admin doesn't have permission)

---

## Module 3: Memberships (7 endpoints)

### ✅ GET /api/membership
Get all memberships with pagination.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/membership?pageNumber=1&pageSize=10" -Headers $headers
```

### ✅ GET /api/membership/{id}
Get membership by ID.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/membership/1" -Headers $headers
```

### ✅ GET /api/membership/member/{memberId}
Get all memberships for a specific member.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/membership/member/1" -Headers $headers
```

### ✅ GET /api/membership/member/{memberId}/active
Get the active membership for a specific member.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/membership/member/1/active" -Headers $headers
```

### ✅ GET /api/membership/active (NEW)
Get all active memberships (EndDate >= today).

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/membership/active" -Headers $headers
```

### ✅ GET /api/membership/expiring (NEW)
Get memberships expiring soon (within 7 days by default).

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/membership/expiring?daysAhead=7" -Headers $headers
```

### ✅ POST /api/membership
Create a new membership (also auto-creates an invoice).

**Request:**
```json
{
  "memberId": 1,
  "packageName": "Premium Monthly Package",
  "price": 500000,
  "startDate": "2025-01-01T00:00:00",
  "endDate": "2025-02-01T00:00:00"
}
```

**PowerShell:**
```powershell
$membershipBody = @{
    memberId = 1
    packageName = "Premium Monthly Package"
    price = 500000
    startDate = "2025-01-01T00:00:00"
    endDate = "2025-02-01T00:00:00"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5062/api/membership" -Method Post -Body $membershipBody -ContentType "application/json" -Headers $headers
```

**Note:** This endpoint was previously failing due to incorrect test input. The DTO requires `memberId`, `packageName`, `price`, `startDate`, `endDate` (NOT `name`, `duration`, `description`, `status`).

### ✅ PUT /api/membership/{id}
Update an existing membership.

**Request:**
```json
{
  "packageName": "Updated Package Name",
  "price": 600000,
  "startDate": "2025-01-01T00:00:00",
  "endDate": "2025-03-01T00:00:00"
}
```

**PowerShell:**
```powershell
$updateMembershipBody = @{
    packageName = "Updated Package Name"
    price = 600000
    startDate = "2025-01-01T00:00:00"
    endDate = "2025-03-01T00:00:00"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5062/api/membership/1" -Method Put -Body $updateMembershipBody -ContentType "application/json" -Headers $headers
```

### ⚠️ DELETE /api/membership/{id}
Soft delete a membership (requires SuperAdmin role).

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/membership/1" -Method Delete -Headers $headers
```

**Expected:** 403 Forbidden (Admin doesn't have permission)

---

## Module 4: Trainers (5 endpoints)

### ✅ GET /api/trainer
Get all trainers with pagination.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/trainer?pageNumber=1&pageSize=10" -Headers $headers
```

### ✅ GET /api/trainer/{id}
Get trainer by ID.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/trainer/1" -Headers $headers
```

### ✅ POST /api/trainer
Create a new trainer.

**Request:**
```json
{
  "fullName": "Test Trainer",
  "email": "trainer@gym.com",
  "phone": "0901111111",
  "specialization": "Yoga, Pilates",
  "bio": "Experienced yoga instructor"
}
```

**PowerShell:**
```powershell
$trainerBody = @{
    fullName = "Test Trainer"
    email = "trainer@gym.com"
    phone = "0901111111"
    specialization = "Yoga, Pilates"
    bio = "Experienced yoga instructor"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5062/api/trainer" -Method Post -Body $trainerBody -ContentType "application/json" -Headers $headers
```

### ✅ PUT /api/trainer/{id}
Update an existing trainer.

**Request:**
```json
{
  "fullName": "Updated Trainer Name",
  "email": "updated_trainer@gym.com",
  "phone": "0902222222",
  "specialization": "Yoga, Pilates, Meditation",
  "bio": "Updated bio"
}
```

**PowerShell:**
```powershell
$updateTrainerBody = @{
    fullName = "Updated Trainer Name"
    email = "updated_trainer@gym.com"
    phone = "0902222222"
    specialization = "Yoga, Pilates, Meditation"
    bio = "Updated bio"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5062/api/trainer/1" -Method Put -Body $updateTrainerBody -ContentType "application/json" -Headers $headers
```

### ⚠️ DELETE /api/trainer/{id}
Soft delete a trainer (requires SuperAdmin role).

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/trainer/1" -Method Delete -Headers $headers
```

**Expected:** 403 Forbidden (Admin doesn't have permission)

---

## Module 5: Schedules (5 endpoints)

### ✅ GET /api/schedule
Get all schedules with pagination.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/schedule?pageNumber=1&pageSize=10" -Headers $headers
```

### ✅ GET /api/schedule/{id}
Get schedule by ID.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/schedule/1" -Headers $headers
```

### ✅ GET /api/schedule/trainer/{trainerId}
Get all schedules for a specific trainer.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/schedule/trainer/1" -Headers $headers
```

### ✅ GET /api/schedule/date/{date} (NEW)
Get schedules for a specific date.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/schedule/date/2025-08-01" -Headers $headers
```

### ✅ POST /api/schedule
Create a new schedule.

**Request:**
```json
{
  "className": "Morning Yoga",
  "trainerId": 1,
  "facilityId": 1,
  "startTime": "2025-08-01T08:00:00",
  "endTime": "2025-08-01T09:00:00",
  "maxCapacity": 20
}
```

**PowerShell:**
```powershell
$scheduleBody = @{
    className = "Morning Yoga"
    trainerId = 1
    facilityId = 1
    startTime = "2025-08-01T08:00:00"
    endTime = "2025-08-01T09:00:00"
    maxCapacity = 20
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5062/api/schedule" -Method Post -Body $scheduleBody -ContentType "application/json" -Headers $headers
```

### ✅ PUT /api/schedule/{id}
Update an existing schedule.

**Request:**
```json
{
  "className": "Updated Yoga Class",
  "trainerId": 1,
  "facilityId": 1,
  "startTime": "2025-08-01T09:00:00",
  "endTime": "2025-08-01T10:00:00",
  "maxCapacity": 25
}
```

**PowerShell:**
```powershell
$updateScheduleBody = @{
    className = "Updated Yoga Class"
    trainerId = 1
    facilityId = 1
    startTime = "2025-08-01T09:00:00"
    endTime = "2025-08-01T10:00:00"
    maxCapacity = 25
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5062/api/schedule/1" -Method Put -Body $updateScheduleBody -ContentType "application/json" -Headers $headers
```

### ⚠️ DELETE /api/schedule/{id}
Soft delete a schedule (requires Admin or SuperAdmin role).

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/schedule/1" -Method Delete -Headers $headers
```

---

## Module 6: Sessions (7 endpoints)

### ✅ GET /api/session
Get all sessions with pagination.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/session?pageNumber=1&pageSize=10" -Headers $headers
```

### ✅ GET /api/session/{id}
Get session by ID.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/session/1" -Headers $headers
```

### ✅ GET /api/session/schedule/{scheduleId}
Get all sessions for a specific schedule.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/session/schedule/1" -Headers $headers
```

### ✅ GET /api/session/member/{memberId} (NEW)
Get all sessions for a specific member.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/session/member/1" -Headers $headers
```

### ✅ POST /api/session
Register a member for a session.

**Request:**
```json
{
  "memberId": 1,
  "scheduleId": 1,
  "registrationDate": "2025-08-01T08:00:00",
  "status": "Registered"
}
```

**PowerShell:**
```powershell
$sessionBody = @{
    memberId = 1
    scheduleId = 1
    registrationDate = "2025-08-01T08:00:00"
    status = "Registered"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5062/api/session" -Method Post -Body $sessionBody -ContentType "application/json" -Headers $headers
```

**Note:** This endpoint was previously failing due to incorrect test input. The DTO requires `memberId`, `scheduleId`, `registrationDate`, `status` (NOT `sessionDate`, `notes`). Valid status values: "Registered", "Attended", "Cancelled".

### ✅ PUT /api/session/{id}
Update session status.

**Request:**
```json
{
  "status": "Attended"
}
```

**PowerShell:**
```powershell
$updateSessionBody = @{
    status = "Attended"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5062/api/session/1" -Method Put -Body $updateSessionBody -ContentType "application/json" -Headers $headers
```

### ✅ PUT /api/session/{id}/status
Update session status (alternative endpoint).

**PowerShell:**
```powershell
$statusBody = @{
    status = "Cancelled"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5062/api/session/1/status" -Method Put -Body $statusBody -ContentType "application/json" -Headers $headers
```

### ⚠️ DELETE /api/session/{id}
Soft delete a session (requires Admin or SuperAdmin role).

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/session/1" -Method Delete -Headers $headers
```

---

## Module 7: Check-ins (6 endpoints)

### ✅ GET /api/checkin
Get all check-ins with pagination.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/checkin?pageNumber=1&pageSize=10" -Headers $headers
```

### ✅ GET /api/checkin/{id}
Get check-in by ID.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/checkin/1" -Headers $headers
```

### ✅ GET /api/checkin/member/{memberId}
Get all check-ins for a specific member.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/checkin/member/1" -Headers $headers
```

### ✅ GET /api/checkin/date-range
Get check-ins within a date range.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/checkin/date-range?from=2025-07-01&to=2025-07-31" -Headers $headers
```

### ✅ GET /api/checkin/date/{date} (NEW)
Get check-ins for a specific date.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/checkin/date/2025-07-20" -Headers $headers
```

### ✅ POST /api/checkin/manual
Manual check-in by Admin/Trainer.

**Request:**
```json
{
  "memberId": 1,
  "checkinTime": "2025-07-20T08:30:00"
}
```

**PowerShell:**
```powershell
$checkinBody = @{
    memberId = 1
    checkinTime = "2025-07-20T08:30:00"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5062/api/checkin/manual" -Method Post -Body $checkinBody -ContentType "application/json" -Headers $headers
```

### ✅ POST /api/checkin/qr
Check-in using QR code (no authentication required).

**Request:**
```json
{
  "qrCode": "QR_MEMBER_001"
}
```

**PowerShell:**
```powershell
$qrBody = @{
    qrCode = "QR_MEMBER_001"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5062/api/checkin/qr" -Method Post -Body $qrBody -ContentType "application/json"
```

---

## Module 8: Invoices (7 endpoints)

### ✅ GET /api/invoice
Get all invoices with pagination.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/invoice?pageNumber=1&pageSize=10" -Headers $headers
```

### ✅ GET /api/invoice/{id}
Get invoice by ID.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/invoice/1" -Headers $headers
```

### ✅ GET /api/invoice/member/{memberId}
Get all invoices for a specific member.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/invoice/member/1" -Headers $headers
```

### ✅ GET /api/invoice/status/{status}
Get invoices by status (e.g., "Paid", "Pending", "Unpaid").

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/invoice/status/Pending" -Headers $headers
```

### ✅ GET /api/invoice/overdue
Get overdue invoices.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/invoice/overdue" -Headers $headers
```

### ✅ GET /api/invoice/unpaid (NEW)
Get all unpaid invoices (status = "Unpaid" or "Pending").

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/invoice/unpaid" -Headers $headers
```

### ✅ POST /api/invoice
Create a new invoice.

**Request:**
```json
{
  "membershipId": 1,
  "totalAmount": 500000,
  "invoiceDate": "2025-01-01T00:00:00",
  "dueDate": "2025-01-31T00:00:00",
  "description": "Monthly membership fee"
}
```

**PowerShell:**
```powershell
$invoiceBody = @{
    membershipId = 1
    totalAmount = 500000
    invoiceDate = "2025-01-01T00:00:00"
    dueDate = "2025-01-31T00:00:00"
    description = "Monthly membership fee"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5062/api/invoice" -Method Post -Body $invoiceBody -ContentType "application/json" -Headers $headers
```

### ✅ PUT /api/invoice/{id}
Update invoice status.

**Request:**
```json
{
  "status": "Paid"
}
```

**PowerShell:**
```powershell
$updateInvoiceBody = @{
    status = "Paid"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5062/api/invoice/1" -Method Put -Body $updateInvoiceBody -ContentType "application/json" -Headers $headers
```

### ⚠️ DELETE /api/invoice/{id}
Soft delete an invoice (requires SuperAdmin role).

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/invoice/1" -Method Delete -Headers $headers
```

**Expected:** 403 Forbidden (Admin doesn't have permission)

---

## Module 9: Payments (6 endpoints)

### ✅ GET /api/payment
Get all payments with pagination.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/payment?pageNumber=1&pageSize=10" -Headers $headers
```

### ✅ GET /api/payment/{id}
Get payment by ID.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/payment/1" -Headers $headers
```

### ✅ GET /api/payment/invoice/{invoiceId}
Get all payments for a specific invoice.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/payment/invoice/1" -Headers $headers
```

### ✅ GET /api/payment/member/{memberId} (NEW)
Get all payments for a specific member.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/payment/member/1" -Headers $headers
```

### ✅ POST /api/payment
Create a new payment (also auto-updates invoice status).

**Request:**
```json
{
  "invoiceId": 1,
  "amount": 500000,
  "paymentDate": "2025-01-15T00:00:00",
  "paymentMethod": "Bank Transfer"
}
```

**PowerShell:**
```powershell
$paymentBody = @{
    invoiceId = 1
    amount = 500000
    paymentDate = "2025-01-15T00:00:00"
    paymentMethod = "Bank Transfer"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5062/api/payment" -Method Post -Body $paymentBody -ContentType "application/json" -Headers $headers
```

### ✅ PUT /api/payment/{id}
Update a payment.

**Request:**
```json
{
  "amount": 550000,
  "paymentDate": "2025-01-16T00:00:00",
  "paymentMethod": "Cash"
}
```

**PowerShell:**
```powershell
$updatePaymentBody = @{
    amount = 550000
    paymentDate = "2025-01-16T00:00:00"
    paymentMethod = "Cash"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5062/api/payment/1" -Method Put -Body $updatePaymentBody -ContentType "application/json" -Headers $headers
```

### ⚠️ DELETE /api/payment/{id}
Soft delete a payment (requires SuperAdmin role).

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/payment/1" -Method Delete -Headers $headers
```

**Expected:** 403 Forbidden (Admin doesn't have permission)

---

## Module 10: Facilities (5 endpoints)

### ✅ GET /api/facility
Get all facilities with pagination.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/facility?pageNumber=1&pageSize=10" -Headers $headers
```

### ✅ GET /api/facility/{id}
Get facility by ID.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/facility/1" -Headers $headers
```

### ✅ POST /api/facility
Create a new facility.

**Request:**
```json
{
  "name": "Yoga Room A",
  "type": "Studio",
  "capacity": 30,
  "description": "Spacious yoga studio with mirrors"
}
```

**PowerShell:**
```powershell
$facilityBody = @{
    name = "Yoga Room A"
    type = "Studio"
    capacity = 30
    description = "Spacious yoga studio with mirrors"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5062/api/facility" -Method Post -Body $facilityBody -ContentType "application/json" -Headers $headers
```

### ✅ PUT /api/facility/{id}
Update an existing facility.

**Request:**
```json
{
  "name": "Updated Yoga Room",
  "type": "Studio",
  "capacity": 35,
  "description": "Updated description"
}
```

**PowerShell:**
```powershell
$updateFacilityBody = @{
    name = "Updated Yoga Room"
    type = "Studio"
    capacity = 35
    description = "Updated description"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5062/api/facility/1" -Method Put -Body $updateFacilityBody -ContentType "application/json" -Headers $headers
```

### ⚠️ DELETE /api/facility/{id}
Soft delete a facility (requires SuperAdmin role).

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/facility/1" -Method Delete -Headers $headers
```

**Expected:** 403 Forbidden (Admin doesn't have permission)

---

## Module 11: Reports (5 endpoints)

### ✅ GET /api/report/active-members
Get count of active members.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/report/active-members" -Headers $headers
```

**Expected Response:**
```json
{
  "activeMemberCount": 42
}
```

### ✅ GET /api/report/revenue
Get revenue summary for a specific month/year.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/report/revenue?month=1&year=2025" -Headers $headers
```

**Expected Response:**
```json
{
  "totalRevenue": 15000000,
  "invoiceCount": 30
}
```

### ✅ GET /api/report/revenue/detail
Get detailed revenue breakdown for a specific month/year.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/report/revenue/detail?month=1&year=2025" -Headers $headers
```

### ✅ GET /api/report/expiring-soon
Get memberships expiring soon.

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/report/expiring-soon?daysAhead=7" -Headers $headers
```

### ✅ GET /api/report/members (NEW)
Get member statistics (total, active, inactive counts).

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5062/api/report/members" -Headers $headers
```

**Expected Response:**
```json
{
  "totalMembers": 100,
  "activeMembers": 85,
  "inactiveMembers": 15
}
```

### ✅ GET /api/report/revenue/export
Export revenue report to Excel.

**PowerShell:**
```powershell
Invoke-WebRequest -Uri "http://localhost:5062/api/report/revenue/export?month=1&year=2025" -Headers $headers -OutFile "revenue_report.xlsx"
```

---

## Summary

### Total Endpoints: 59

| Module | Total | Working | Failed | Notes |
|--------|-------|---------|--------|-------|
| Auth | 1 | 1 | 0 | ✅ Fully functional |
| Members | 5 | 4 | 1 | ⚠️ DELETE requires SuperAdmin |
| Memberships | 7 | 6 | 1 | ⚠️ DELETE requires SuperAdmin |
| Trainers | 5 | 4 | 1 | ⚠️ DELETE requires SuperAdmin |
| Schedules | 5 | 5 | 0 | ✅ Fully functional |
| Sessions | 7 | 7 | 0 | ✅ Fully functional |
| Check-ins | 6 | 6 | 0 | ✅ Fully functional |
| Invoices | 7 | 6 | 1 | ⚠️ DELETE requires SuperAdmin |
| Payments | 6 | 5 | 1 | ⚠️ DELETE requires SuperAdmin |
| Facilities | 5 | 4 | 1 | ⚠️ DELETE requires SuperAdmin |
| Reports | 5 | 5 | 0 | ✅ Fully functional |

### Expected Pass Rate: 53/59 = 89.8% ✅

### Known Limitations:
- **6 DELETE endpoints return 403 Forbidden** - This is expected behavior. Admin role cannot delete resources; only SuperAdmin can. This is a security feature, not a bug.

### New Endpoints Implemented (8 total):
1. ✅ GET /api/membership/active
2. ✅ GET /api/membership/expiring
3. ✅ GET /api/schedule/date/{date}
4. ✅ GET /api/session/member/{id}
5. ✅ GET /api/checkin/date/{date}
6. ✅ GET /api/invoice/unpaid
7. ✅ GET /api/payment/member/{id}
8. ✅ GET /api/report/members

### Fixed Endpoints (2 total):
- POST /api/membership - Now works with correct DTO properties
- POST /api/session - Now works with correct DTO properties

---

## Testing Notes

1. **Start the server** before testing:
   ```powershell
   cd "d:\Workspace\Độ án 2\GymManegement\GymManegement"
   dotnet run
   ```

2. **Always get a fresh token** at the start of each testing session.

3. **Test in order**: Create resources (POST) before testing GET/PUT/DELETE operations.

4. **Check response status codes**:
   - 200 OK - Successful GET/PUT
   - 201 Created - Successful POST
   - 204 No Content - Successful DELETE
   - 400 Bad Request - Invalid input
   - 401 Unauthorized - Missing/invalid token
   - 403 Forbidden - Insufficient permissions
   - 404 Not Found - Resource doesn't exist
   - 500 Internal Server Error - Server-side error

5. **Common Issues**:
   - Ensure database is running and accessible
   - Check connection string in appsettings.json
   - Verify token hasn't expired (get a new one if needed)
   - Use correct property names in request bodies

---

## Quick Test Script

Run all core endpoints in sequence:

```powershell
# 1. Login
$loginBody = '{"username":"gymadmin","password":"Gym@2026"}'
$response = Invoke-RestMethod -Uri "http://localhost:5062/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$token = $response.token
$headers = @{ "Authorization" = "Bearer $token" }
Write-Host "✅ Logged in successfully" -ForegroundColor Green

# 2. Test new endpoints
Write-Host "`nTesting new endpoints..." -ForegroundColor Yellow

try {
    Invoke-RestMethod -Uri "http://localhost:5062/api/membership/active" -Headers $headers | Out-Null
    Write-Host "✅ GET /api/membership/active" -ForegroundColor Green
} catch {
    Write-Host "❌ GET /api/membership/active: $_" -ForegroundColor Red
}

try {
    Invoke-RestMethod -Uri "http://localhost:5062/api/membership/expiring?daysAhead=7" -Headers $headers | Out-Null
    Write-Host "✅ GET /api/membership/expiring" -ForegroundColor Green
} catch {
    Write-Host "❌ GET /api/membership/expiring: $_" -ForegroundColor Red
}

try {
    Invoke-RestMethod -Uri "http://localhost:5062/api/schedule/date/2025-08-01" -Headers $headers | Out-Null
    Write-Host "✅ GET /api/schedule/date/{date}" -ForegroundColor Green
} catch {
    Write-Host "❌ GET /api/schedule/date/{date}: $_" -ForegroundColor Red
}

try {
    Invoke-RestMethod -Uri "http://localhost:5062/api/session/member/1" -Headers $headers | Out-Null
    Write-Host "✅ GET /api/session/member/{id}" -ForegroundColor Green
} catch {
    Write-Host "❌ GET /api/session/member/{id}: $_" -ForegroundColor Red
}

try {
    Invoke-RestMethod -Uri "http://localhost:5062/api/checkin/date/2025-07-20" -Headers $headers | Out-Null
    Write-Host "✅ GET /api/checkin/date/{date}" -ForegroundColor Green
} catch {
    Write-Host "❌ GET /api/checkin/date/{date}: $_" -ForegroundColor Red
}

try {
    Invoke-RestMethod -Uri "http://localhost:5062/api/invoice/unpaid" -Headers $headers | Out-Null
    Write-Host "✅ GET /api/invoice/unpaid" -ForegroundColor Green
} catch {
    Write-Host "❌ GET /api/invoice/unpaid: $_" -ForegroundColor Red
}

try {
    Invoke-RestMethod -Uri "http://localhost:5062/api/payment/member/1" -Headers $headers | Out-Null
    Write-Host "✅ GET /api/payment/member/{id}" -ForegroundColor Green
} catch {
    Write-Host "❌ GET /api/payment/member/{id}: $_" -ForegroundColor Red
}

try {
    Invoke-RestMethod -Uri "http://localhost:5062/api/report/members" -Headers $headers | Out-Null
    Write-Host "✅ GET /api/report/members" -ForegroundColor Green
} catch {
    Write-Host "❌ GET /api/report/members: $_" -ForegroundColor Red
}

Write-Host "`n✅ All tests completed!" -ForegroundColor Green
```
