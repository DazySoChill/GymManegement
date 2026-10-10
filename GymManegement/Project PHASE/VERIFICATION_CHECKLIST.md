# Verification Checklist - Gym Management API vs SQL2 Database

**Purpose**: Verify ALL entities, DTOs, and code match SQL2 database schema  
**Date**: 2026-10-09  
**Status**: IN PROGRESS

---

## SQL2 Database Schema (10 Tables)

1. ✅ Users
2. ✅ Members (FIXED 2026-10-09)
3. ⏳ Trainers
4. ⏳ Facilities
5. ⏳ Memberships
6. ⏳ Schedules
7. ⏳ Sessions
8. ⏳ Checkins
9. ⏳ Invoices
10. ⏳ Payments

---

## Table 1: Users ✅

### SQL2 Schema:
```sql
CREATE TABLE Users (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(MAX) NOT NULL,
    FullName NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200) NOT NULL UNIQUE,
    Role NVARCHAR(50) NOT NULL CHECK (Role IN ('Admin', 'Trainer', 'Member')),
    IsActive BIT NOT NULL DEFAULT 1,
    LastLoginAt DATETIME NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);
```

### Entity Match: ✅ VERIFIED (Phase 1)
- [x] No RoleId FK
- [x] Role is string
- [x] LastLoginAt exists
- [x] Audit fields present

---

## Table 2: Members ✅ FIXED

### SQL2 Schema:
```sql
CREATE TABLE Members (
    MemberId INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200) NOT NULL UNIQUE,
    Phone NVARCHAR(20) NULL,
    DateOfBirth DATE NULL,
    QRCode NVARCHAR(50) NOT NULL UNIQUE,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);
```

### Entity Match: ✅ FIXED (2026-10-09)
- [x] No JoinDate
- [x] No Status
- [x] QRCode (not QRCodeValue)
- [x] UpdatedAt is NOT NULL
- [x] Audit fields present

### Files Updated:
- [x] DAL/Entities/Member.cs
- [x] DAL/Repositories/Interfaces/IMemberRepository.cs
- [x] DAL/Repositories/Implementations/MemberRepository.cs
- [x] API/DTOs/Member/MemberResponse.cs
- [x] API/DTOs/Member/CreateMemberRequest.cs
- [x] API/DTOs/Member/UpdateMemberRequest.cs
- [x] Service/BUS/Interfaces/IMemberService.cs
- [x] Service/BUS/Implementations/MemberService.cs
- [x] Controllers/MemberController.cs
- [x] Service/BUS/Implementations/AuthService.cs (RegisterAsync)

---

## Table 3: Trainers ⏳ TO BE VERIFIED

### SQL2 Schema:
```sql
CREATE TABLE Trainers (
    TrainerId INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200) NOT NULL UNIQUE,
    Phone NVARCHAR(20) NULL,
    Specialization NVARCHAR(200) NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);
```

### Entity Check: ⏳ PENDING
- [ ] Check DAL/Entities/Trainer.cs
- [ ] Check TrainerRepository
- [ ] Check TrainerService
- [ ] Check TrainerController
- [ ] Check Trainer DTOs

---

## Table 4: Facilities ⏳ TO BE VERIFIED

### SQL2 Schema:
```sql
CREATE TABLE Facilities (
    FacilityId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    Status NVARCHAR(50) NOT NULL DEFAULT 'Available' 
        CHECK (Status IN ('Available', 'Maintenance', 'OutOfService')),
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);
```

### Entity Check: ⏳ PENDING
- [ ] Check DAL/Entities/Facility.cs
- [ ] Facility HAS Status (not removed like Member)

---

## Table 5: Memberships ⏳ TO BE VERIFIED

### SQL2 Schema:
```sql
CREATE TABLE Memberships (
    MembershipId INT IDENTITY(1,1) PRIMARY KEY,
    MemberId INT NOT NULL FOREIGN KEY REFERENCES Members(MemberId),
    PackageName NVARCHAR(200) NOT NULL,
    Price DECIMAL(18,2) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);
```

### Entity Check: ⏳ PENDING
- [ ] Check DAL/Entities/Membership.cs
- [ ] Check auto-create Invoice behavior in MembershipService

---

## Table 6: Schedules ⏳ TO BE VERIFIED

### SQL2 Schema:
```sql
CREATE TABLE Schedules (
    ScheduleId INT IDENTITY(1,1) PRIMARY KEY,
    TrainerId INT NOT NULL FOREIGN KEY REFERENCES Trainers(TrainerId),
    FacilityId INT NOT NULL FOREIGN KEY REFERENCES Facilities(FacilityId),
    ClassName NVARCHAR(200) NOT NULL,
    StartTime DATETIME NOT NULL,
    EndTime DATETIME NOT NULL,
    MaxCapacity INT NOT NULL DEFAULT 20,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);
```

### Entity Check: ⏳ PENDING
- [ ] Check DAL/Entities/Schedule.cs

---

## Table 7: Sessions ⏳ TO BE VERIFIED

### SQL2 Schema:
```sql
CREATE TABLE Sessions (
    SessionId INT IDENTITY(1,1) PRIMARY KEY,
    ScheduleId INT NOT NULL FOREIGN KEY REFERENCES Schedules(ScheduleId),
    MemberId INT NOT NULL FOREIGN KEY REFERENCES Members(MemberId),
    RegistrationDate DATETIME NOT NULL DEFAULT GETDATE(),
    Status NVARCHAR(50) NOT NULL DEFAULT 'Registered' 
        CHECK (Status IN ('Registered', 'Attended', 'Cancelled')),
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);
```

### Entity Check: ⏳ PENDING
- [ ] Check DAL/Entities/Session.cs
- [ ] Session HAS Status (not removed)

---

## Table 8: Checkins ⏳ TO BE VERIFIED

### SQL2 Schema:
```sql
CREATE TABLE Checkins (
    CheckinId INT IDENTITY(1,1) PRIMARY KEY,
    MemberId INT NOT NULL FOREIGN KEY REFERENCES Members(MemberId),
    CheckinTime DATETIME NOT NULL DEFAULT GETDATE(),
    CheckoutTime DATETIME NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);
```

### Entity Check: ⏳ PENDING
- [ ] Check DAL/Entities/Checkin.cs

---

## Table 9: Invoices ⏳ TO BE VERIFIED

### SQL2 Schema:
```sql
CREATE TABLE Invoices (
    InvoiceId INT IDENTITY(1,1) PRIMARY KEY,
    MembershipId INT NOT NULL FOREIGN KEY REFERENCES Memberships(MembershipId),
    InvoiceDate DATE NOT NULL,
    DueDate DATE NOT NULL,
    TotalAmount DECIMAL(18,2) NOT NULL,
    Status NVARCHAR(50) NOT NULL DEFAULT 'Pending' 
        CHECK (Status IN ('Pending', 'Paid', 'PartiallyPaid', 'Overdue', 'Cancelled')),
    Description NVARCHAR(MAX) NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);
```

### Entity Check: ⏳ PENDING
- [ ] Check DAL/Entities/Invoice.cs

---

## Table 10: Payments ⏳ TO BE VERIFIED

### SQL2 Schema:
```sql
CREATE TABLE Payments (
    PaymentId INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceId INT NOT NULL FOREIGN KEY REFERENCES Invoices(InvoiceId),
    Amount DECIMAL(18,2) NOT NULL,
    PaymentMethod NVARCHAR(50) NOT NULL 
        CHECK (PaymentMethod IN ('Cash', 'Card', 'BankTransfer', 'Momo', 'ZaloPay')),
    PaymentDate DATETIME NOT NULL DEFAULT GETDATE(),
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);
```

### Entity Check: ⏳ PENDING
- [ ] Check DAL/Entities/Payment.cs
- [ ] Check auto-update Invoice.Status in PaymentService

---

## Testing Priority

### 🔥 CRITICAL (Test Now):
1. [ ] POST /api/Auth/register → auto-create Member with QRCode
2. [ ] POST /api/Auth/login → returns token + member info
3. [ ] GET /api/Auth/me → user info correct

### 🔴 HIGH:
4. [ ] GET /api/Member → pagination works
5. [ ] POST /api/Member → create member with QRCode
6. [ ] POST /api/Membership → auto-create Invoice
7. [ ] POST /api/Payment → auto-update Invoice.Status

### 🟡 MEDIUM:
8. [ ] All other CRUD endpoints work
9. [ ] Soft delete works
10. [ ] Export endpoints work

---

## Next Steps

1. **Test Register endpoint first** (most critical)
2. **If Register works** → Continue testing other endpoints
3. **If Register fails** → Check logs and fix

---

**Status**: Member entity FIXED. Ready for testing.  
**Server**: Running on http://localhost:5250  
**Swagger**: http://localhost:5250/swagger
