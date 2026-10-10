# Phase 6 - Manual Testing Guide

**Testing Platform:** Swagger UI  
**URL:** http://localhost:5250/swagger  
**Date:** 2026-10-09

---

## 🎯 Testing Checklist

### Pre-requisites
- ✅ Server running on port 5250
- ✅ Database SQL2 with seed data
- ✅ Swagger UI accessible

---

## 📋 Test Scenarios

### ✅ Scenario 1: Member Registration & Login

#### Step 1.1: Register New Member
```http
POST /api/Auth/register
```

**Request Body:**
```json
{
  "username": "testuser1",
  "password": "Test@123",
  "fullName": "Test User One",
  "email": "testuser1@test.com"
}
```

**Expected Response:** 200 OK
```json
{
  "userId": {number},
  "username": "testuser1",
  "fullName": "Test User One",
  "email": "testuser1@test.com",
  "role": "Member"
}
```

**Verify:**
- [ ] Response 200 OK
- [ ] UserId returned
- [ ] Role = "Member" (auto-assigned)
- [ ] Can login with these credentials

---

#### Step 1.2: Login
```http
POST /api/Auth/login
```

**Request Body:**
```json
{
  "username": "testuser1",
  "password": "Test@123"
}
```

**Expected Response:** 200 OK
```json
{
  "token": "eyJhbGci...",
  "username": "testuser1",
  "fullName": "Test User One",
  "role": "Member",
  "memberId": {number}
}
```

**Verify:**
- [ ] Response 200 OK
- [ ] Token received (JWT format)
- [ ] MemberId present (proves auto Member creation)
- [ ] Copy token for next requests

---

#### Step 1.3: Get Profile
```http
GET /api/Auth/me
```

**Authorization:** Bearer {token from step 1.2}

**Expected Response:** 200 OK
```json
{
  "userId": {number},
  "username": "testuser1",
  "fullName": "Test User One",
  "email": "testuser1@test.com",
  "role": "Member"
}
```

**Verify:**
- [ ] Response 200 OK
- [ ] Profile data matches registration

---

### ⚠️ Scenario 2: Admin Login (If seed data works)

#### Step 2.1: Admin Login
```http
POST /api/Auth/login
```

**Request Body:**
```json
{
  "username": "admin",
  "password": "gym@2026"
}
```

**If Success:** Copy admin token for CRUD operations

**If Failed:** 
- Check database Users table for admin record
- Verify password hash
- May need to register new admin via SQL or create-staff endpoint

---

### ✅ Scenario 3: Membership → Invoice Auto-Creation (Requires Admin Token)

#### Step 3.1: Create Membership
```http
POST /api/Membership
Authorization: Bearer {admin_token}
```

**Request Body:**
```json
{
  "memberId": {memberId from step 1.2},
  "packageName": "Monthly Basic",
  "price": 500000,
  "startDate": "2026-10-09",
  "endDate": "2026-11-09"
}
```

**Expected Response:** 201 Created
```json
{
  "membershipId": {number},
  "memberId": {number},
  "packageName": "Monthly Basic",
  "price": 500000,
  "startDate": "2026-10-09",
  "endDate": "2026-11-09"
}
```

**Verify:**
- [ ] Response 201 Created
- [ ] MembershipId returned

---

#### Step 3.2: Check Invoice Auto-Created
```http
GET /api/Invoice/member/{memberId}
Authorization: Bearer {admin_token}
```

**Expected Response:** 200 OK with array containing invoice
```json
[
  {
    "invoiceId": {number},
    "membershipId": {from step 3.1},
    "totalAmount": 500000,
    "status": "Pending",
    "invoiceDate": "2026-10-09",
    "dueDate": "2026-11-09",
    "description": "Hóa đơn cho gói tập Monthly Basic"
  }
]
```

**Verify:**
- [ ] Invoice exists (auto-created)
- [ ] Status = "Pending"
- [ ] TotalAmount matches membership price
- [ ] Description auto-generated

---

### ✅ Scenario 4: Payment → Invoice Status Auto-Update

#### Step 4.1: Create Payment
```http
POST /api/Payment
Authorization: Bearer {admin_token}
```

**Request Body:**
```json
{
  "invoiceId": {from step 3.2},
  "amount": 500000,
  "paymentDate": "2026-10-09",
  "paymentMethod": "Cash"
}
```

**Expected Response:** 201 Created
```json
{
  "paymentId": {number},
  "invoiceId": {number},
  "amount": 500000,
  "paymentDate": "2026-10-09",
  "paymentMethod": "Cash"
}
```

**Verify:**
- [ ] Response 201 Created
- [ ] PaymentId returned

---

#### Step 4.2: Verify Invoice Status Updated
```http
GET /api/Invoice/{invoiceId}
Authorization: Bearer {admin_token}
```

**Expected Response:** 200 OK
```json
{
  "invoiceId": {number},
  "status": "Paid",  ← CHANGED from "Pending"
  ...
}
```

**Verify:**
- [ ] Status changed to "Paid" (auto-updated)
- [ ] No manual update needed

---

### ✅ Scenario 5: QR Check-in (Public Endpoint)

#### Step 5.1: Get Member QRCode
```http
GET /api/Member/{memberId}
Authorization: Bearer {admin_token}
```

**Expected Response:** 200 OK
```json
{
  "memberId": {number},
  "qrCode": "M000502",  ← Note this value
  ...
}
```

**Verify:**
- [ ] QRCode format: M{6-digit-number}
- [ ] Copy QRCode value

---

#### Step 5.2: Check-in via QR
```http
POST /api/Checkin/qr
```

**NO AUTHORIZATION NEEDED** (Public endpoint for scanners)

**Request Body:**
```json
{
  "qrCode": "M000502"
}
```

**Expected Response:** 200 OK
```json
{
  "checkinId": {number},
  "memberId": {number},
  "checkinTime": "2026-10-09T10:30:00",
  "checkoutTime": null
}
```

**Verify:**
- [ ] Response 200 OK without auth
- [ ] CheckinId returned
- [ ] CheckinTime set
- [ ] CheckoutTime null (not checked out yet)

---

### ✅ Scenario 6: Reports

#### Step 6.1: Active Members Report
```http
GET /api/Report/active-members
Authorization: Bearer {admin_token}
```

**Expected Response:** 200 OK
```json
{
  "activeMemberCount": {number >= 1}
}
```

**Verify:**
- [ ] Count includes our test member

---

#### Step 6.2: Revenue Report
```http
GET /api/Report/revenue?month=10&year=2026
Authorization: Bearer {admin_token}
```

**Expected Response:** 200 OK
```json
{
  "totalRevenue": 500000,  ← From our payment
  "invoiceCount": 1
}
```

**Verify:**
- [ ] TotalRevenue includes test payment
- [ ] InvoiceCount correct

---

#### Step 6.3: Revenue Detail
```http
GET /api/Report/revenue/detail?month=10&year=2026
Authorization: Bearer {admin_token}
```

**Expected Response:** 200 OK
```json
{
  "month": 10,
  "year": 2026,
  "data": [
    {
      "invoiceId": {number},
      "invoiceDate": "2026-10-09",
      "totalAmount": 500000,
      "status": "Paid",
      "packageName": "Monthly Basic",
      "memberName": "Test User One"
    }
  ]
}
```

**Verify:**
- [ ] Detail data includes test invoice
- [ ] Member name resolved correctly

---

## ✅ Final Checklist - 6 Core Features

After completing all scenarios above:

### Feature #1: Đăng ký hội viên, thẻ tập, hạn sử dụng
- [ ] Register creates User + Member automatically
- [ ] QRCode auto-generated (format M{ID:D6})
- [ ] Membership CRUD works
- [ ] StartDate/EndDate tracked

### Feature #2: Quản lý gói dịch vụ
- [ ] Membership packages (Monthly/etc.) work
- [ ] Price tracked
- [ ] Status tracking works

### Feature #3: Đặt lịch tập với PT
- [ ] Schedule endpoints accessible
- [ ] (Full schedule test optional in Phase 6)

### Feature #4: Quản lý check-in
- [ ] QR check-in works without auth
- [ ] CheckinTime recorded
- [ ] Can retrieve checkin history

### Feature #5: Thu phí, hoá đơn
- [ ] Membership auto-creates Invoice
- [ ] Payment auto-updates Invoice status
- [ ] Status flow: Pending → Paid

### Feature #6: Báo cáo
- [ ] Active members count works
- [ ] Revenue calculation correct
- [ ] Revenue detail shows transactions

---

## 📊 Test Results Template

After testing, fill in:

```
Test Date: 2026-10-09
Tester: [Your Name]

Scenario 1 (Register/Login): ✅ PASS / ❌ FAIL
Scenario 2 (Admin): ✅ PASS / ❌ FAIL  
Scenario 3 (Membership→Invoice): ✅ PASS / ❌ FAIL
Scenario 4 (Payment→Status): ✅ PASS / ❌ FAIL
Scenario 5 (QR Checkin): ✅ PASS / ❌ FAIL
Scenario 6 (Reports): ✅ PASS / ❌ FAIL

Overall Status: ✅ READY FOR PRODUCTION / ⚠️ NEEDS FIXES
```

---

## 🐛 Known Issues to Watch

1. **Password Hash:** Seed data uses same hash for all users - may need regeneration
2. **Admin Login:** If fails, use registered member's token or create new admin
3. **QRCode Sequence:** Should be M000501, M000502, M000503... (sequential)

---

## 📝 Notes

- Use Swagger's "Authorize" button to set Bearer token once
- All admin/trainer operations require valid JWT token
- QR check-in is PUBLIC endpoint - no auth needed
- Member operations can use member's own token

---

**Guide Version:** 1.0  
**For:** Phase 6 Manual Testing via Swagger UI
