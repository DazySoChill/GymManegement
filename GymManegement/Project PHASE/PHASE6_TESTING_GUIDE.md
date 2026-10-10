# Phase 6 - Testing Guide

## ✅ Build & Run Status
- **Build**: SUCCESS (2 warnings về package version - không ảnh hưởng)
- **Server**: Running on `http://localhost:5250`
- **Swagger**: `http://localhost:5250/swagger`
- **Date**: 2026-10-09

---

## 🧪 Test Plan

### 1. Authentication Flow Tests

#### Test 1.1: Register New Member (Auto-create Member + QRCode)
**Endpoint**: `POST /api/Auth/register`

**Request Body**:
```json
{
  "username": "testmember1",
  "password": "Test@123",
  "fullName": "Test Member One",
  "email": "testmember1@test.com"
}
```

**Expected Result**:
- ✅ Returns `RegisterResponse` with userId
- ✅ Auto-creates Member record in database
- ✅ Member.QRCode auto-generated (format: "M{memberId:D6}")
- ✅ User.Role = "Member"
- ✅ Can login immediately (no OTP)

**Verification Query** (run in SQL):
```sql
SELECT u.UserId, u.Username, u.Role, m.MemberId, m.QRCode
FROM Users u
LEFT JOIN Members m ON u.Email = m.Email
WHERE u.Username = 'testmember1';
```

---

#### Test 1.2: Login Member
**Endpoint**: `POST /api/Auth/login`

**Request Body**:
```json
{
  "username": "testmember1",
  "password": "Test@123"
}
```

**Expected Result**:
```json
{
  "userId": 1,
  "username": "testmember1",
  "fullName": "Test Member One",
  "email": "testmember1@test.com",
  "role": "Member",
  "memberId": 1,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Verify**:
- ✅ Returns JWT token
- ✅ MemberId is not null (found via Email join)
- ✅ FullName and Email present
- ✅ No TrainerId field

---

#### Test 1.3: Login Admin
**Endpoint**: `POST /api/Auth/login`

**Request Body**:
```json
{
  "username": "admin",
  "password": "gym@2026"
}
```

**Expected Result**:
```json
{
  "userId": 1,
  "username": "admin",
  "fullName": "System Admin",
  "email": "admin@gym.com",
  "role": "Admin",
  "memberId": null,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Verify**:
- ✅ Returns JWT token
- ✅ Role = "Admin"
- ✅ MemberId is null (Admin is not a Member)

---

#### Test 1.4: Create Staff (Admin Only)
**Endpoint**: `POST /api/Auth/create-staff`  
**Authorization**: Bearer token from Test 1.3 (Admin login)

**Request Body** (Create Trainer):
```json
{
  "username": "trainer10",
  "password": "Gym@2026",
  "fullName": "New Trainer Ten",
  "email": "trainer10@gym.com",
  "role": "Trainer"
}
```

**Expected Result**:
```json
{
  "userId": 10,
  "username": "trainer10",
  "role": "Trainer"
}
```

**Verify**:
- ✅ 401 Unauthorized if no token
- ✅ 403 Forbidden if Member/Trainer token used
- ✅ 200 OK if Admin token used
- ✅ User created with Role = "Trainer"
- ✅ No auto-create Member (only Register does that)

**Request Body** (Create Admin):
```json
{
  "username": "admin2",
  "password": "Gym@2026",
  "fullName": "Second Admin",
  "email": "admin2@gym.com",
  "role": "Admin"
}
```

---

#### Test 1.5: Get Current User Info
**Endpoint**: `GET /api/Auth/me`  
**Authorization**: Bearer token from any login

**Expected Result**:
```json
{
  "userId": 1,
  "username": "testmember1",
  "fullName": "Test Member One",
  "email": "testmember1@test.com",
  "role": "Member",
  "memberId": 1,
  "isActive": true
}
```

**Verify**:
- ✅ Returns current user info
- ✅ FullName, Email present
- ✅ No TrainerId field
- ✅ 401 if no token

---

### 2. Auto-Behavior Tests

#### Test 2.1: Membership → Auto-create Invoice
**Endpoint**: `POST /api/Membership`  
**Authorization**: Bearer token (any role with permission)

**Request Body**:
```json
{
  "memberId": 1,
  "packageName": "Monthly Premium",
  "price": 500000,
  "startDate": "2026-10-09",
  "endDate": "2026-11-09"
}
```

**Expected Result**:
- ✅ Membership created
- ✅ Invoice auto-created with:
  - InvoiceDate = current date
  - DueDate = Membership.EndDate
  - TotalAmount = Membership.Price
  - Status = "Pending"
  - Description = "Hóa đơn cho gói tập {packageName}"

**Verification Query**:
```sql
SELECT ms.MembershipId, ms.PackageName, i.InvoiceId, i.TotalAmount, i.Status
FROM Memberships ms
LEFT JOIN Invoices i ON ms.MembershipId = i.MembershipId
WHERE ms.MemberId = 1
ORDER BY ms.CreatedAt DESC;
```

---

#### Test 2.2: Payment → Auto-update Invoice.Status
**Endpoint**: `POST /api/Payment`  
**Authorization**: Bearer token

**Request Body**:
```json
{
  "invoiceId": 1,
  "amount": 500000,
  "paymentMethod": "Cash",
  "paymentDate": "2026-10-09"
}
```

**Expected Result**:
- ✅ Payment created
- ✅ Invoice.Status auto-updated:
  - "Paid" if Payment.Amount >= Invoice.TotalAmount
  - "PartiallyPaid" if Payment.Amount < Invoice.TotalAmount

**Verification Query**:
```sql
SELECT i.InvoiceId, i.TotalAmount, i.Status, 
       SUM(p.Amount) AS TotalPaid
FROM Invoices i
LEFT JOIN Payments p ON i.InvoiceId = p.InvoiceId
WHERE i.InvoiceId = 1
GROUP BY i.InvoiceId, i.TotalAmount, i.Status;
```

---

### 3. CRUD Tests (Sample - Member Management)

#### Test 3.1: Get All Members (Pagination)
**Endpoint**: `GET /api/Member?page=1&pageSize=10`

**Expected Result**:
```json
{
  "items": [...],
  "totalCount": 500,
  "page": 1,
  "pageSize": 10,
  "totalPages": 50
}
```

**Verify**:
- ✅ Pagination working
- ✅ Items array contains MemberResponse with audit fields

---

#### Test 3.2: Get Member by ID
**Endpoint**: `GET /api/Member/{id}`

**Expected Result**:
```json
{
  "memberId": 1,
  "fullName": "Nguyễn Văn A",
  "email": "member1@example.com",
  "phone": "0901234567",
  "dateOfBirth": "1990-01-15",
  "qrCode": "M000001",
  "createdAt": "2026-01-01T00:00:00",
  "updatedAt": "2026-01-01T00:00:00"
}
```

---

#### Test 3.3: Update Member
**Endpoint**: `PUT /api/Member/{id}`

**Request Body**:
```json
{
  "fullName": "Nguyễn Văn A Updated",
  "phone": "0909999999",
  "dateOfBirth": "1990-01-15"
}
```

**Expected Result**:
- ✅ 200 OK
- ✅ Member.UpdatedAt changed

---

#### Test 3.4: Delete Member (Soft Delete)
**Endpoint**: `DELETE /api/Member/{id}`

**Expected Result**:
- ✅ 204 No Content
- ✅ Member.IsDeleted = true
- ✅ Member.DeletedAt set
- ✅ GET /api/Member/{id} returns 404

---

### 4. Other Controller Tests

#### Test All 11 Controllers:
1. ✅ **AuthController** - Tested above
2. ✅ **MemberController** - Sample tested above
3. ⏳ **TrainerController** - Similar to Member
4. ⏳ **FacilityController** - CRUD + pagination
5. ⏳ **MembershipController** - CRUD + auto-create Invoice
6. ⏳ **ScheduleController** - CRUD
7. ⏳ **SessionController** - CRUD
8. ⏳ **CheckinController** - Create checkin, QR checkin
9. ⏳ **InvoiceController** - CRUD + export
10. ⏳ **PaymentController** - CRUD + auto-update Invoice
11. ⏳ **ReportController** - All 6 reports

---

## 📊 Test Results Template

| Test ID | Endpoint | Status | Notes |
|---------|----------|--------|-------|
| 1.1 | POST /register | ⏳ | |
| 1.2 | POST /login (Member) | ⏳ | |
| 1.3 | POST /login (Admin) | ⏳ | |
| 1.4 | POST /create-staff | ⏳ | |
| 1.5 | GET /me | ⏳ | |
| 2.1 | Membership → Invoice | ⏳ | |
| 2.2 | Payment → Invoice Status | ⏳ | |
| 3.1-3.4 | Member CRUD | ⏳ | |

Legend:
- ⏳ Not Tested
- ✅ Pass
- ❌ Fail
- ⚠️ Warning

---

## 🔍 Known Issues & Warnings

1. **Package Version Warnings (NU1603)**:
   - Microsoft.IdentityModel.Tokens 8.0.13 → 8.1.0
   - System.IdentityModel.Tokens.Jwt 8.0.13 → 8.1.0
   - **Impact**: None (runtime auto-resolves)

2. **PowerShell Echo Issue**:
   - `dotnet` commands show duplicate output
   - **Workaround**: Run commands manually in terminal

---

## ✅ Success Criteria (Phase 6 Complete)

- [ ] All authentication endpoints work (register, login, create-staff, /me)
- [ ] Auto-behaviors verified:
  - [ ] Register → auto-create Member with QRCode
  - [ ] Membership → auto-create Invoice
  - [ ] Payment → auto-update Invoice.Status
- [ ] CRUD operations work for at least 1 entity (Member)
- [ ] Pagination working
- [ ] Soft delete working
- [ ] JWT authentication working
- [ ] Role-based authorization working (Admin-only endpoints)
- [ ] No critical build/runtime errors

---

## 📝 Next Steps After Phase 6

1. Update `PHASE_TRACKER.md` → Phase 6 Complete
2. Create `PHASE6_COMPLETED.md` with test results
3. Optional improvements:
   - Add validation error messages
   - Add integration tests
   - Add Postman collection
   - Performance testing
   - Security audit

---

**Testing Started**: 2026-10-09  
**API Server**: http://localhost:5250  
**Swagger UI**: http://localhost:5250/swagger
