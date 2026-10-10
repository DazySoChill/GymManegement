# 🔍 PHASE 5 PREPARATION - RÀ SOÁT

> Chuẩn bị refactor 11 Controllers

---

## ✅ RÀ SOÁT PHASE 1-4

### ✅ Phase 1: Entities - VERIFIED
- ✅ User.Role is string
- ✅ User has FullName, Email
- ✅ Member.Phone, DateOfBirth nullable
- ✅ All entities have audit fields
- ✅ Deleted: EmailVerificationOTP, PasswordResetToken

### ✅ Phase 2: DTOs - VERIFIED
- ✅ RegisterRequest: 4 fields only
- ✅ LoginResponse: has FullName, Email
- ✅ CreateStaffRequest: NEW
- ✅ Member DTOs: nullable
- ✅ All Response DTOs: have audit fields
- ✅ Deleted: OTP, PasswordReset DTOs

### ✅ Phase 3: Repositories - VERIFIED
- ✅ UserRepository: No RoleId, has GetByEmail/UsernameExists/EmailExists
- ✅ MemberRepository: Inline SQL, soft delete, audit
- ✅ IInvoiceRepository: ✅ REGISTERED in DI (Program.cs line 23)

### ✅ Phase 4: Services - VERIFIED
- ✅ AuthService.RegisterAsync: Auto-create Member
- ✅ AuthService.LoginAsync: Find MemberId via Email
- ✅ AuthService.CreateStaffAsync: NEW method
- ✅ MembershipService: Auto-create Invoice (uses IInvoiceRepository ✅)
- ✅ PaymentService: Auto-update Invoice.Status (uses IInvoiceRepository ✅)

---

## 📋 PHASE 5: CONTROLLERS TO REFACTOR

### Total: 11 Controllers

| # | Controller | Priority | Changes Needed |
|---|------------|----------|----------------|
| 1 | **AuthController.cs** | ⭐⭐⭐ HIGH | Remove OTP endpoints, add CreateStaff, update responses |
| 2 | MemberController.cs | ⭐⭐ MEDIUM | Update DTOs (nullable) |
| 3 | MembershipController.cs | ⭐⭐ MEDIUM | No changes (auto-invoice in service) |
| 4 | PaymentController.cs | ⭐⭐ MEDIUM | No changes (auto-update in service) |
| 5 | TrainerController.cs | ⭐ LOW | Update DTOs (audit fields) |
| 6 | FacilityController.cs | ⭐ LOW | Update DTOs (audit fields) |
| 7 | ScheduleController.cs | ⭐ LOW | Update DTOs (audit fields) |
| 8 | SessionController.cs | ⭐ LOW | Update DTOs (audit fields) |
| 9 | CheckinController.cs | ⭐ LOW | Update DTOs (audit fields) |
| 10 | InvoiceController.cs | ⭐ LOW | Update DTOs (audit fields) |
| 11 | ReportController.cs | ⭐ LOW | No changes likely |

---

## 🎯 AUTHCONTROLLER - MAIN FOCUS

### Current State (OLD):
```csharp
[HttpPost("register")]
public async Task<IActionResult> Register([FromBody] RegisterRequest request)
{
    var result = await _service.RegisterAsync(request);
    return Ok(new { 
        message = "Đăng ký thành công! Vui lòng kiểm tra email để nhận mã OTP xác nhận.", 
        user = result 
    });
}

[HttpPost("verify-email")]  // ❌ REMOVE
[HttpPost("resend-otp")]    // ❌ REMOVE

[HttpGet("users")]
[Authorize(Roles = "SuperAdmin")]  // ❌ Change to "Admin"

[HttpGet("User")]
public IActionResult Me() {
    trainerId = User.FindFirstValue("trainerId"),  // ❌ REMOVE
}
```

### Target State (NEW):
```csharp
[HttpPost("register")]
public async Task<IActionResult> Register([FromBody] RegisterRequest request)
{
    var result = await _service.RegisterAsync(request);
    return Ok(new { 
        message = "Đăng ký thành công! Tài khoản đã được kích hoạt.",  // ✅ No OTP
        user = result,
        memberId = // Get from Members table via Email  // ✅ NEW
    });
}

[HttpPost("create-staff")]  // ✅ NEW
[Authorize(Roles = "Admin")]
public async Task<IActionResult> CreateStaff([FromBody] CreateStaffRequest request)
{
    var result = await _service.CreateStaffAsync(request);
    return Ok(new { message = "Tạo tài khoản thành công.", user = result });
}

// ❌ REMOVE: verify-email, resend-otp

[HttpGet("users")]
[Authorize(Roles = "Admin")]  // ✅ Changed from "SuperAdmin"

[HttpGet("me")]  // ✅ Changed from "User"
public IActionResult Me() {
    memberId = User.FindFirstValue("memberId"),  // Only memberId
    // ❌ NO trainerId
}
```

---

## 📝 DETAILED CHANGES PER CONTROLLER

### 1. AuthController ⭐⭐⭐ MAJOR

**Remove:**
- ❌ `POST /verify-email` endpoint
- ❌ `POST /resend-otp` endpoint
- ❌ `trainerId` from `/me` response

**Add:**
- ✅ `POST /create-staff` endpoint (NEW)

**Update:**
- ✅ `POST /register` - Change success message (no OTP)
- ✅ `GET /users` - Change `[Authorize(Roles = "SuperAdmin")]` to `"Admin"`
- ✅ `PUT /users/{id}/active` - Change to `"Admin"`
- ✅ `GET /me` - Rename from `/User` to `/me`, remove trainerId

---

### 2. MemberController ⭐⭐

**Update:**
- ✅ Accept nullable Phone/DateOfBirth in POST/PUT
- ✅ Return audit fields (CreatedAt/UpdatedAt) in responses

**Example:**
```csharp
[HttpPost]
public async Task<IActionResult> Create([FromBody] CreateMemberRequest request)
{
    // request.Phone is nullable ✅
    // request.DateOfBirth is nullable ✅
    var result = await _service.CreateAsync(request);
    return Ok(result);  // result has CreatedAt/UpdatedAt ✅
}
```

---

### 3. MembershipController ⭐⭐

**No changes needed!** ✅
- Auto-create Invoice logic is in MembershipService
- Controller just calls service

**But verify:**
```csharp
[HttpPost]
public async Task<IActionResult> Create([FromBody] CreateMembershipRequest request)
{
    var result = await _service.CreateAsync(request);
    // Service auto-creates Invoice ✅
    return Ok(result);
}
```

---

### 4. PaymentController ⭐⭐

**No changes needed!** ✅
- Auto-update Invoice.Status logic is in PaymentService
- Controller just calls service

**But verify:**
```csharp
[HttpPost]
public async Task<IActionResult> Create([FromBody] CreatePaymentRequest request)
{
    var result = await _service.CreateAsync(request);
    // Service auto-updates Invoice.Status ✅
    return Ok(result);
}
```

---

### 5-11. Other Controllers ⭐ LOW PRIORITY

**Minor changes:**
- ✅ Response DTOs now include `CreatedAt`, `UpdatedAt`
- ✅ No other logic changes

---

## 🎯 AUTHORIZATION CHANGES

### OLD:
```csharp
[Authorize(Roles = "SuperAdmin")]  // ❌ No "SuperAdmin" role
```

### NEW:
```csharp
[Authorize(Roles = "Admin")]  // ✅ Only 3 roles: Admin, Trainer, Member
```

### ALL ROLES:
- ✅ `"Admin"` - Full access
- ✅ `"Trainer"` - Manage schedules, sessions, checkins
- ✅ `"Member"` - View own data, checkin

---

## ✅ PRE-PHASE 5 CHECKLIST

- [x] **IInvoiceRepository registered** in DI (Program.cs line 23)
- [x] **AuthService.CreateStaffAsync** implemented
- [x] **CreateStaffRequest DTO** created
- [x] **Phase 1-4** all verified
- [ ] **Ready to refactor** AuthController
- [ ] **Ready to refactor** other 10 controllers

---

## 🚀 PHASE 5 EXECUTION ORDER

### Step 1: AuthController (30 min) ⭐⭐⭐
- Remove OTP endpoints
- Add CreateStaff endpoint
- Update roles to "Admin"
- Update /me response

### Step 2: MemberController (10 min) ⭐⭐
- Verify nullable handling
- Verify response DTOs

### Step 3: Membership + Payment (10 min) ⭐⭐
- Verify no changes needed
- Test auto-behaviors

### Step 4: Other 7 Controllers (20 min) ⭐
- Update response DTOs
- Update authorization

### Step 5: Build Test (5 min)
- `dotnet build` → Expect 0 errors ✅

**Total Time:** ~1.5 hours

---

## 📊 SUCCESS CRITERIA - PHASE 5

### After Phase 5 Done:
- ✅ Build success (0 errors)
- ✅ No OTP endpoints
- ✅ CreateStaff endpoint exists
- ✅ All roles use "Admin" (not "SuperAdmin")
- ✅ /me returns memberId only (no trainerId)
- ✅ All DTOs match Phase 2
- ✅ Ready for API testing

---

**Date:** 2026-10-09  
**Status:** READY TO START PHASE 5  
**Next:** Refactor AuthController
