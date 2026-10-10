# 📁 PROJECT FILES OVERVIEW

> Danh sách tất cả files quan trọng trong dự án Gym Management  
> Dùng để định hướng build và refactoring

---

## 📚 Documentation Files (Đọc trước khi refactor)

### Core Documentation:
1. **`PROJECT_ROADMAP.md`** ⭐⭐⭐
   - Master plan với 6 phases
   - Acceptance criteria từng phase
   - Mapping Yêu cầu dự án → Implementation
   - **Đọc đầu tiên**

2. **`PHASE_TRACKER.md`** ⭐⭐⭐
   - Theo dõi tiến độ real-time
   - Danh sách files đã sửa từng phase
   - Progress bar và checklist
   - **Cập nhật liên tục**

3. **`PHASE1_BUILD_TEST.md`** ⭐⭐
   - Hướng dẫn test Phase 1
   - Expected errors
   - Success criteria
   - **Đọc sau khi hoàn thành Phase 1**

4. **`PROJECT_FILES_OVERVIEW.md`** (file này)
   - Danh sách tất cả files
   - Mô tả chức năng từng file
   - Dependency map

### SQL2 Documentation:
5. **`SQL2/README.md`**
   - Tổng quan SQL2 folder
   - Schema description
   - Test data info

6. **`SQL2/CHANGES_FOR_CODE.md`** ⭐⭐
   - Chi tiết thay đổi code cần làm
   - Entity/DTO/Repository changes
   - Code examples

7. **`SQL2/CODE_REFACTORING_CHECKLIST.md`** ⭐⭐⭐
   - Step-by-step checklist Phase 1-6
   - Code snippets cho từng step
   - **Dùng khi refactor**

8. **`SQL2/MIGRATION_GUIDE.md`**
   - Optional: Migrate data from old DB to SQL2
   - Ignore if starting fresh

### API Documentation:
9. **`API_SPECIFICATION_SIMPLIFIED.md`** ⭐
   - Simplified API spec
   - Endpoints description
   - Request/Response examples

### Requirements:
10. **`Yêu cầu dự án.txt`**
    - Original project requirements (Vietnamese)
    - 6 core gym functions
    - RBAC requirements

---

## 🗂️ Source Code Structure

### 1️⃣ DAL/Entities/ (Data Layer - Domain Models)

**Status Phase 1:** ✅ ALL COMPLETED

| File | Status | Description | Phase 1 Changes |
|------|--------|-------------|-----------------|
| `User.cs` | ✅ Modified | User accounts (Admin/Trainer/Member) | Major: Removed RoleId/PasswordSalt/MemberId/TrainerId, added FullName/Email |
| `Member.cs` | ✅ Modified | Gym members | Nullable Phone/DOB, added audit fields |
| `Trainer.cs` | ✅ Modified | Personal trainers | Added audit fields |
| `Membership.cs` | ✅ Modified | Member subscription packages | Added audit fields |
| `Schedule.cs` | ✅ Modified | Training schedules | Added audit fields |
| `Session.cs` | ✅ Modified | Individual training sessions | Added audit fields |
| `Checkin.cs` | ✅ Modified | Member check-ins | Added audit fields |
| `Invoice.cs` | ✅ Modified | Payment invoices | Added audit fields |
| `Payment.cs` | ✅ Modified | Payment records | Added audit fields |
| `Facility.cs` | ✅ Modified | Gym facilities/equipment | Added audit fields |
| `AuditLog.cs` | ✅ Modified | System audit logs | Added audit fields |
| ~~`Role.cs`~~ | ❌ Deleted | (Old RBAC) | N/A |
| ~~`Permission.cs`~~ | ❌ Deleted | (Old RBAC) | N/A |
| ~~`EmailVerificationOTP.cs`~~ | ❌ Deleted | (Old OTP system) | Deleted Phase 1 |
| ~~`PasswordResetToken.cs`~~ | ❌ Deleted | (Old password reset) | Deleted Phase 1 |

---

### 2️⃣ API/DTOs/ (Data Transfer Objects)

**Status Phase 2:** 🔜 NOT STARTED

#### Auth DTOs (`API/DTOs/Auth/`):
| File | Status | Phase 2 Action | Description |
|------|--------|----------------|-------------|
| `AuthDTOs.cs` | 🔜 To Modify | Register: 4 fields only, Login: no change | Request/Response for auth |
| `RegisterRequest.cs` | 🔜 To Modify | username, password, fullName, email | User registration |
| `LoginRequest.cs` | ✅ Keep | No changes | User login |
| `LoginResponse.cs` | 🔜 To Modify | Add FullName, Email | JWT token response |
| ~~`OTPVerificationDTOs.cs`~~ | 🔜 To Delete | Remove OTP flow | OTP verification |
| ~~`PasswordResetDTOs.cs`~~ | 🔜 To Delete | Defer to Phase 6 | Password reset |
| **NEW** `CreateStaffRequest.cs` | ➕ To Create | Admin creates Admin/Trainer | Staff creation |

#### Member DTOs (`API/DTOs/Member/`):
| File | Status | Phase 2 Action | Description |
|------|--------|----------------|-------------|
| `CreateMemberRequest.cs` | 🔜 To Modify | Phone/DOB nullable | Create member |
| `UpdateMemberRequest.cs` | 🔜 To Modify | Phone/DOB nullable | Update member |
| `MemberResponse.cs` | 🔜 To Modify | Add audit fields | Member data response |

#### Other DTOs (similar pattern):
- `API/DTOs/Trainer/` (3 files)
- `API/DTOs/Membership/` (3 files)
- `API/DTOs/Schedule/` (3 files)
- `API/DTOs/Session/` (3 files)
- `API/DTOs/Checkin/` (3 files)
- `API/DTOs/Invoice/` (3 files)
- `API/DTOs/Payment/` (3 files)
- `API/DTOs/Facility/` (3 files)
- `API/DTOs/Common/` (PagedResult.cs, ExportRequest.cs)

**Total DTOs:** ~30 files

---

### 3️⃣ DAL/Repositories/ (Data Access Layer)

**Status Phase 3:** 🔜 NOT STARTED

| File | Status | Phase 3 Action | Description |
|------|--------|----------------|-------------|
| `UserRepository.cs` | 🔜 To Modify | Major: Remove RoleId, add GetByEmail/UsernameExists/EmailExists | User CRUD |
| `MemberRepository.cs` | 🔜 To Modify | Nullable Phone/DOB, add GetByEmail | Member CRUD |
| `TrainerRepository.cs` | 🔜 To Modify | Update audit fields | Trainer CRUD |
| `MembershipRepository.cs` | 🔜 To Modify | Update audit fields | Membership CRUD |
| `ScheduleRepository.cs` | 🔜 To Modify | Update audit fields | Schedule CRUD |
| `SessionRepository.cs` | 🔜 To Modify | Update audit fields | Session CRUD |
| `CheckinRepository.cs` | 🔜 To Modify | Update audit fields | Check-in CRUD |
| `InvoiceRepository.cs` | 🔜 To Modify | Update audit fields | Invoice CRUD |
| `PaymentRepository.cs` | 🔜 To Modify | Update audit fields | Payment CRUD |
| `FacilityRepository.cs` | 🔜 To Modify | Update audit fields | Facility CRUD |
| ~~`RoleRepository.cs`~~ | 🔜 To Delete | Remove RBAC | (Old) |
| ~~`PermissionRepository.cs`~~ | 🔜 To Delete | Remove RBAC | (Old) |
| ~~`EmailOTPRepository.cs`~~ | 🔜 To Delete | Remove OTP | (Old) |
| ~~`PasswordResetRepository.cs`~~ | 🔜 To Delete | Remove reset | (Old) |

**Total Repositories:** ~10 active, ~4 to delete

---

### 4️⃣ Service/BUS/ (Business Logic Layer)

**Status Phase 4:** 🔜 NOT STARTED

| File | Status | Phase 4 Action | Description |
|------|--------|----------------|-------------|
| `AuthService.cs` | 🔜 To Modify | Major: RegisterAsync auto-create Member, CreateStaffAsync new | Authentication logic |
| `UserService.cs` | 🔜 To Modify | Update User properties | User management |
| `MemberService.cs` | 🔜 To Modify | Update nullable handling | Member management |
| `MembershipService.cs` | 🔜 To Modify | CreateAsync auto-create Invoice | Membership management |
| `PaymentService.cs` | 🔜 To Modify | CreateAsync auto-update Invoice.Status | Payment processing |
| `TrainerService.cs` | 🔜 To Modify | Update audit | Trainer management |
| `ScheduleService.cs` | 🔜 To Modify | Update audit | Schedule management |
| `SessionService.cs` | 🔜 To Modify | Update audit | Session management |
| `CheckinService.cs` | 🔜 To Modify | Update audit | Check-in logic |
| `InvoiceService.cs` | 🔜 To Modify | Update audit | Invoice management |
| `FacilityService.cs` | 🔜 To Modify | Update audit | Facility management |
| `ReportService.cs` | 🔜 To Modify | Update queries | Reporting logic |

**Total Services:** ~12 files

---

### 5️⃣ Controllers/ (API Endpoints)

**Status Phase 5:** 🔜 NOT STARTED

| File | Status | Phase 5 Action | Description |
|------|--------|----------------|-------------|
| `AuthController.cs` | 🔜 To Modify | Major: Add /create-staff, remove OTP endpoints | Auth endpoints |
| `MemberController.cs` | 🔜 To Modify | Update DTOs | Member CRUD API |
| `TrainerController.cs` | 🔜 To Modify | Update DTOs | Trainer CRUD API |
| `MembershipController.cs` | 🔜 To Modify | Update DTOs | Membership CRUD API |
| `ScheduleController.cs` | 🔜 To Modify | Update DTOs | Schedule CRUD API |
| `SessionController.cs` | 🔜 To Modify | Update DTOs | Session CRUD API |
| `CheckinController.cs` | 🔜 To Modify | Update DTOs | Check-in API |
| `InvoiceController.cs` | 🔜 To Modify | Update DTOs | Invoice CRUD API |
| `PaymentController.cs` | 🔜 To Modify | Update DTOs | Payment CRUD API |
| `FacilityController.cs` | 🔜 To Modify | Update DTOs | Facility CRUD API |
| `ReportController.cs` | 🔜 To Modify | Update DTOs | Reporting API |

**Total Controllers:** ~11 files

---

### 6️⃣ Configuration Files

| File | Status | Description |
|------|--------|-------------|
| `appsettings.json` | ✅ Keep | App configuration (JWT, DB connection) |
| `appsettings.Development.json` | ✅ Keep | Dev environment config |
| `Program.cs` | 🔜 Review Phase 5 | App startup, middleware |
| `App.config` | ✅ Keep | Legacy config |
| `GymManegement.csproj` | ✅ Keep | Project file |

---

### 7️⃣ Helper/Utility Files

| Folder | Files | Status | Description |
|--------|-------|--------|-------------|
| `DAL/Helper/` | `DapperContext.cs` | ✅ Keep | Dapper DB context |
| `Service/Helper/` | Various | 🔜 Review Phase 4 | Service utilities |
| `Middleware/` | Auth, Error handling | 🔜 Review Phase 5 | Middleware |

---

## 🗄️ Database Files (SQL2/)

| File | Status | Description |
|------|--------|-------------|
| `00_DROP_AND_CREATE_DB.sql` | ✅ Complete | Create GymDb database |
| `01_SCHEMA_SIMPLIFIED.sql` | ✅ Complete | 10 tables schema |
| `02_SEED_DATA.sql` | ✅ Complete | 2000+ test records |
| `03_STORED_PROCEDURES.sql` | ✅ Complete | Optional procedures |

---

## 📊 File Count Summary

| Category | Total Files | Modified Phase 1 | To Modify Phase 2-5 | Status |
|----------|-------------|------------------|---------------------|--------|
| **Documentation** | 10 | 2 new | - | ✅ Complete |
| **Entities** | 11 | 11 | 0 | ✅ Complete |
| **DTOs** | ~30 | 0 | ~25 | 🔜 Phase 2 |
| **Repositories** | ~14 | 0 | ~10 | 🔜 Phase 3 |
| **Services** | ~12 | 0 | ~12 | 🔜 Phase 4 |
| **Controllers** | ~11 | 0 | ~11 | 🔜 Phase 5 |
| **Config/Helper** | ~5 | 0 | ~2 | 🔜 Phase 5 |
| **SQL Files** | 4 | 4 | 0 | ✅ Complete |
| **TOTAL** | **~97** | **17** | **~60** | **18% Done** |

---

## 🔄 Dependency Map (Build Order)

```
SQL2 Database (✅ Done)
    ↓
DAL/Entities (✅ Phase 1 Done)
    ↓
API/DTOs (🔜 Phase 2)
    ↓
DAL/Repositories (🔜 Phase 3)
    ↓
Service/BUS (🔜 Phase 4)
    ↓
Controllers (🔜 Phase 5)
    ↓
Testing (🔜 Phase 6)
```

---

## 🎯 Quick Navigation

### Đọc trước khi bắt đầu:
1. `PROJECT_ROADMAP.md` - Master plan
2. `PHASE_TRACKER.md` - Current status
3. `SQL2/CODE_REFACTORING_CHECKLIST.md` - Step-by-step guide

### Khi refactor từng phase:
- **Phase 1:** `PHASE_TRACKER.md` → DAL/Entities/*.cs
- **Phase 2:** `SQL2/CHANGES_FOR_CODE.md` → API/DTOs/*/*.cs
- **Phase 3:** `SQL2/CHANGES_FOR_CODE.md` → DAL/Repositories/*.cs
- **Phase 4:** `SQL2/CHANGES_FOR_CODE.md` → Service/BUS/*.cs
- **Phase 5:** `API_SPECIFICATION_SIMPLIFIED.md` → Controllers/*.cs
- **Phase 6:** `PROJECT_ROADMAP.md` → Testing checklist

### Khi build:
1. `PHASE1_BUILD_TEST.md` - Build instructions
2. `PHASE_TRACKER.md` - Update progress
3. Fix errors theo phase

---

## 📝 Notes

### Files không cần sửa (giữ nguyên):
- `appsettings.json`, `appsettings.Development.json`
- `DapperContext.cs`
- `PagedResult.cs`, `ExportRequest.cs`
- Navigation properties trong entities (giữ cho EF-like compatibility)

### Files cần xóa hoàn toàn:
- `EmailVerificationOTP.cs` ✅ Done Phase 1
- `PasswordResetToken.cs` ✅ Done Phase 1
- `Role.cs`, `Permission.cs` (if exist)
- `*OTP*.cs`, `*PasswordReset*.cs` trong DTOs/Repos/Services

### Files cần tạo mới:
- `API/DTOs/Auth/CreateStaffRequest.cs` (Phase 2)

---

**Last Updated:** 2026-10-09  
**Current Phase:** Phase 1 Complete  
**Next Phase:** Phase 2 (DTOs)
