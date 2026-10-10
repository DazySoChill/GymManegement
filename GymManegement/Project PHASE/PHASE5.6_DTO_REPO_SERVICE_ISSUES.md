# Phase 5.6 - DTOs, Repositories, Services Issues Found

**Date**: 2026-10-09  
**Status**: CRITICAL - Many files using removed/renamed entity properties

---

## 🚨 Issues Summary

After fixing entities in Phase 5.5, found **20+ files** still using old property names that no longer exist in entities.

---

## Category 1: Member-related Issues

### ✅ Already Fixed (Morning)
- Member Entity: JoinDate, Status, QRCodeValue → Fixed
- MemberRepository: Fixed
- MemberService: Fixed
- MemberResponse DTO: Fixed
- MemberController: Fixed

---

## Category 2: Membership Issues

### ❌ Files Using `MembershipType` (renamed to `PackageName`)

**Entity Change**:
```csharp
// OLD
public string MembershipType { get; set; }

// NEW
public string PackageName { get; set; }
```

**Affected Files** (6 files):
1. `API/DTOs/Membership/CreateMembershipRequest.cs`
2. `API/DTOs/Membership/UpdateMembershipRequest.cs`
3. `API/DTOs/Membership/MembershipResponse.cs`
4. `DAL/Repositories/Implementations/MembershipRepository.cs`
5. `Service/BUS/Implementations/MembershipService.cs`
6. `Service/BUS/Implementations/ExportService.cs`

---

### ❌ Files Using `Membership.IsActive` (REMOVED)

**Entity Change**:
```csharp
// OLD
public bool IsActive { get; set; } = true;

// NEW
// REMOVED - not in SQL2 schema
```

**Affected Files** (3 files):
1. `API/DTOs/Membership/MembershipResponse.cs` - Has `IsActive` and `DaysRemaining` computed property
2. `Service/BUS/Implementations/MembershipService.cs` - Sets/reads `IsActive`
3. `DAL/Repositories/Implementations/MembershipRepository.cs` - Passes `IsActive` to stored proc

---

## Category 3: Checkin Issues

### ❌ Files Using `Checkin.SessionId` (REMOVED)

**Entity Change**:
```csharp
// OLD
public int SessionId { get; set; }

// NEW
// REMOVED - Checkins link directly to Members, not Sessions
```

**Affected Files** (5 files):
1. `API/DTOs/Checkin/CheckinResponse.cs`
2. `API/DTOs/Checkin/CreateCheckinRequest.cs` (likely)
3. `API/DTOs/Checkin/QRCheckinRequest.cs` - Has `SessionId`
4. `Controllers/CheckinController.cs` - GET endpoint by SessionId
5. `Service/BUS/Interfaces/ICheckinService.cs` - `GetBySessionIdAsync`
6. `Service/BUS/Implementations/CheckinService.cs` - Uses `SessionId`
7. `DAL/Repositories/Interfaces/ICheckinRepository.cs` - `GetBySessionIdAsync`
8. `DAL/Repositories/Implementations/CheckinRepository.cs` - Queries by `SessionId`

---

### ❌ Files Using `Checkin.CheckinMethod` (REMOVED)

**Entity Change**:
```csharp
// OLD
public string CheckinMethod { get; set; } = string.Empty;

// NEW
// REMOVED - not in SQL2 schema
```

**Affected Files** (4 files):
1. `API/DTOs/Checkin/CheckinResponse.cs`
2. `API/DTOs/Checkin/CreateCheckinRequest.cs` (likely)
3. `Service/BUS/Implementations/CheckinService.cs`
4. `DAL/Repositories/Implementations/CheckinRepository.cs`

---

### ❌ Files Using `QRCodeValue` (renamed to `QRCode`)

**Affected Files** (2 files):
1. `API/DTOs/Checkin/QRCheckinRequest.cs`
2. `Service/BUS/Implementations/CheckinService.cs`

---

## Category 4: Schedule Issues

### ❌ Files Using `Schedule.MemberId` (REMOVED)

**Entity Change**:
```csharp
// OLD
public int MemberId { get; set; }

// NEW
// REMOVED - Schedules are classes, not member-specific
```

**Need to check**:
- ScheduleResponse DTO
- ScheduleRepository
- ScheduleService

---

### ❌ Missing `Schedule.ClassName` and `Schedule.MaxCapacity`

**Entity Change**:
```csharp
// NEW in SQL2
public string ClassName { get; set; } = string.Empty;
public int MaxCapacity { get; set; } = 20;
```

**Need to check**:
- Schedule DTOs (Create/Update/Response)
- ScheduleRepository (INSERT/UPDATE queries)
- ScheduleService

---

## Category 5: Session Issues

### ❌ Files Using `Session.SessionDate` (renamed to `RegistrationDate`)

**Entity Change**:
```csharp
// OLD
public DateTime SessionDate { get; set; }

// NEW
public DateTime RegistrationDate { get; set; }
```

**Need to check**:
- Session DTOs
- SessionRepository
- SessionService

---

### ❌ Missing `Session.MemberId`

**Entity Change**:
```csharp
// NEW in SQL2
public int MemberId { get; set; }
```

**Need to check**:
- Session DTOs (must add MemberId)
- SessionRepository (must handle MemberId FK)
- SessionService

---

## Category 6: Invoice Issues

### ❌ Files Using `Invoice.MemberId` (changed to `MembershipId`)

**Entity Change**:
```csharp
// OLD
public int MemberId { get; set; }

// NEW
public int MembershipId { get; set; }
```

**Need to check**:
- Invoice DTOs
- InvoiceRepository
- InvoiceService

---

### ❌ Missing `Invoice.Description`

**Entity Change**:
```csharp
// NEW in SQL2
public string? Description { get; set; }
```

**Need to check**:
- Invoice DTOs
- InvoiceRepository
- InvoiceService

---

## Category 7: Payment Issues

### ❌ Files Using `Payment.Status` (REMOVED)

**Entity Change**:
```csharp
// OLD
public string Status { get; set; } = string.Empty;

// NEW
// REMOVED - Payments don't have status, only Invoices do
```

**Need to check**:
- Payment DTOs
- PaymentRepository
- PaymentService

---

## Category 8: Facility Issues

### ❌ Files Using `Facility.IsActive` (changed to `Status`)

**Entity Change**:
```csharp
// OLD
public bool IsActive { get; set; } = true;

// NEW
public string Status { get; set; } = "Available"; // Available | Maintenance | OutOfService
```

**Need to check**:
- Facility DTOs
- FacilityRepository
- FacilityService

---

## Category 9: Trainer Issues

### ❌ `Phone` and `Specialization` nullability

**Entity Change**:
```csharp
// OLD
public string Phone { get; set; } = string.Empty;
public string Specialization { get; set; } = string.Empty;

// NEW
public string? Phone { get; set; }
public string? Specialization { get; set; }
```

**Need to check**:
- Trainer DTOs (if they enforce NOT NULL)
- TrainerRepository
- TrainerService

---

## 📊 Estimated Fixes Required

| Category | Files to Fix | Severity |
|----------|--------------|----------|
| Membership | 6-9 files | HIGH |
| Checkin | 8-10 files | CRITICAL |
| Schedule | 3-6 files | MEDIUM |
| Session | 3-6 files | MEDIUM |
| Invoice | 3-6 files | MEDIUM |
| Payment | 3 files | LOW |
| Facility | 3 files | MEDIUM |
| Trainer | 3 files | LOW |
| **TOTAL** | **32-49 files** | **CRITICAL** |

---

## 🎯 Fix Strategy

### Priority Order:
1. **CRITICAL: Checkin** (8-10 files) - Most complex, affects check-in feature
2. **HIGH: Membership** (6-9 files) - Core business logic
3. **MEDIUM: Schedule, Session, Invoice, Facility** (12-18 files)
4. **LOW: Payment, Trainer** (6 files)

### Approach:
For each entity:
1. Fix DTOs (Request/Response)
2. Fix Repository (queries)
3. Fix Service (business logic)
4. Fix Controller (if needed)

---

## ✅ Next Steps

1. Start with Checkin (most critical)
2. Then Membership
3. Then others in priority order
4. Rebuild and test after each category

---

**Status**: Issues identified, ready to fix systematically
