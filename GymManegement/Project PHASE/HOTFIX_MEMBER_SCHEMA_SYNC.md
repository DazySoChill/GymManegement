# HOTFIX: Member Schema Synchronization with SQL2

**Date**: 2026-10-09  
**Issue**: Member entity and related code were NOT synchronized with SQL2 database schema  
**Severity**: CRITICAL - Blocked all Register/Member operations (500 errors)

---

## Root Cause

Phase 1 (Entities) was **INCOMPLETE**. The `Member` entity still had old schema columns that don't exist in SQL2 database:

| Old Entity Property | SQL2 Database Column | Issue |
|--------------------|---------------------|-------|
| `JoinDate` | ❌ Not exist | Runtime error |
| `Status` | ❌ Not exist | Runtime error |
| `QRCodeValue` | ❌ Not exist | Runtime error |
| ✅ Should be | `QRCode` | Column name mismatch |

---

## Errors Before Fix

### Error 1: Register endpoint (500)
```
Invalid column name 'JoinDate'.
Invalid column name 'Status'.
Invalid column name 'QRCodeValue'.
```

### Error 2: Login endpoint (401)
Password hash in seed data was wrong/fake.

---

## Files Fixed

### 1. DAL/Entities/Member.cs ✅
**Changes**:
- ❌ Removed: `JoinDate`, `Status`, `QRCodeValue`
- ✅ Added: `QRCode` (matches database column name)
- ✅ Changed: `UpdatedAt` from nullable to NOT NULL

**Before**:
```csharp
public DateTime JoinDate { get; set; }
public string Status { get; set; } = "Active";
public string QRCodeValue { get; set; } = string.Empty;
public DateTime? UpdatedAt { get; set; }
```

**After**:
```csharp
public string QRCode { get; set; } = string.Empty;
public DateTime UpdatedAt { get; set; }
```

---

### 2. DAL/Repositories/Interfaces/IMemberRepository.cs ✅
**Changes**:
- ❌ Removed `status` parameter from `GetAllAsync()`
- ✅ Changed `GetByQRCodeAsync(string qrCodeValue)` → `GetByQRCodeAsync(string qrCode)`

---

### 3. DAL/Repositories/Implementations/MemberRepository.cs ✅
**Changes**:
- ✅ `GetAllAsync()`: Changed `ORDER BY JoinDate DESC` → `ORDER BY CreatedAt DESC`
- ✅ `GetAllAsync(paged)`: Removed `status` parameter and filter logic
- ✅ `GetByQRCodeAsync()`: Changed `QRCodeValue` → `QRCode`
- ✅ `GetByStatusAsync()`: Throws `NotSupportedException` (Status column removed in SQL2)
- ✅ `CreateAsync()`: 
  - Changed SQL: `JoinDate, Status, QRCodeValue` → `QRCode`
  - Added `UpdatedAt` to INSERT
- ✅ `UpdateAsync()`: Removed `Status` from UPDATE

---

### 4. API/DTOs/Member/MemberResponse.cs ✅
**Changes**:
- ❌ Removed: `JoinDate`, `Status`, `QRCodeValue`
- ✅ Added: `QRCode`
- ✅ Changed: `UpdatedAt` from nullable to NOT NULL

---

### 5. API/DTOs/Member/CreateMemberRequest.cs ✅
**Changes**:
- ❌ Removed: `JoinDate`
- No other changes needed (FullName, Email, Phone, DateOfBirth match database)

---

### 6. API/DTOs/Member/UpdateMemberRequest.cs ✅
**Changes**:
- ❌ Removed: `Status`

---

### 7. Service/BUS/Interfaces/IMemberService.cs ✅
**Changes**:
- ❌ Removed `status` parameter from `GetAllAsync()`

---

### 8. Service/BUS/Implementations/MemberService.cs ✅
**Changes**:
- ✅ `GetAllAsync()`: Removed `status` parameter
- ✅ `CreateAsync()`: 
  - Generate QRCode format `M000001` (not GUID)
  - Removed `JoinDate`, `Status` assignment
  - Changed `QRCodeValue` → `QRCode`
- ✅ `UpdateAsync()`: Removed `Status` update logic
- ✅ `ToResponse()`: Changed mapping to use `QRCode`, `CreatedAt`, `UpdatedAt`

---

### 9. Service/BUS/Implementations/AuthService.cs ✅
**Changes in `RegisterAsync()`**:
- ✅ Generate QRCode with format `M{nextId:D6}` (M000001, M000002, ...)
- ❌ Removed: `JoinDate`, `Status` assignment
- ✅ Changed: `QRCodeValue` → `QRCode`

---

### 10. Controllers/MemberController.cs ✅
**Changes**:
- ❌ Removed `status` query parameter from `GetAll()` endpoint

---

## SQL2 Database Schema (Reference)

```sql
CREATE TABLE Members (
    MemberId INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200) NOT NULL UNIQUE,
    Phone NVARCHAR(20) NULL,
    DateOfBirth DATE NULL,
    QRCode NVARCHAR(50) NOT NULL UNIQUE,  -- Format: M000001
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME NULL
);
```

**Key Points**:
- ❌ No `JoinDate` column
- ❌ No `Status` column
- ✅ `QRCode` (NOT `QRCodeValue`)
- ✅ `UpdatedAt` is NOT NULL

---

## Testing Instructions

### Test 1: Register (Auto-create Member with QRCode)
**Endpoint**: `POST /api/Auth/register`

**Request**:
```json
{
  "username": "testuser1",
  "password": "Test@123",
  "fullName": "Test User One",
  "email": "testuser1@test.com"
}
```

**Expected**:
- ✅ User created with Role="Member"
- ✅ Member auto-created with QRCode="M000501" (next available ID)
- ✅ No error 500

---

### Test 2: Login with Registered User
**Endpoint**: `POST /api/Auth/login`

**Request**:
```json
{
  "username": "testuser1",
  "password": "Test@123"
}
```

**Expected**:
- ✅ Returns JWT token
- ✅ MemberId is not null
- ✅ FullName, Email present

---

### Test 3: Get All Members
**Endpoint**: `GET /api/Member?pageNumber=1&pageSize=10`

**Expected**:
- ✅ Returns paginated list
- ✅ Each member has QRCode (format: M000001)
- ✅ No JoinDate, Status fields in response

---

### Test 4: Create Member (Admin)
**Endpoint**: `POST /api/Member`

**Request**:
```json
{
  "fullName": "Manual Member",
  "email": "manual@test.com",
  "phone": "0909999999",
  "dateOfBirth": "1995-05-15"
}
```

**Expected**:
- ✅ Member created with auto-generated QRCode
- ✅ No error about JoinDate/Status

---

## Verification

### ✅ Build Status
- Build: SUCCESS (0 errors)
- Warnings: 2 package version warnings (non-critical)

### ✅ Server Status
- Server running on: http://localhost:5250
- Swagger UI: http://localhost:5250/swagger
- No startup errors

### ⏳ API Testing
- [ ] Register endpoint works
- [ ] Login with registered user works
- [ ] Get all members works
- [ ] Create member works
- [ ] Update member works

---

## Lessons Learned

### ❌ What Went Wrong:
1. **Phase 1 was marked "Complete" but was INCOMPLETE**
   - Member entity still had old schema columns
   - No verification was done against actual database

2. **No schema validation between Entity and Database**
   - Code changes didn't match SQL2 schema
   - Column name mismatches (QRCodeValue vs QRCode)

3. **Cascading errors**
   - One wrong entity → Repository errors → Service errors → Controller errors
   - 10 files needed fixes (entity + 3 DTOs + 2 interfaces + 4 implementations)

### ✅ How to Prevent:
1. **Verify against DATABASE first, not assumptions**
   - Always check actual SQL schema
   - Compare column names exactly

2. **Test immediately after each phase**
   - Don't wait until Phase 6 to test
   - Build and run after Phase 1, 2, 3, 4, 5

3. **Follow the principle: "Đơn giản mà đúng"**
   - If SQL2 removes columns → Remove from code
   - If SQL2 renames columns → Rename in code
   - No assumptions, no old code left behind

---

## Status After Fix

- ✅ Member entity matches SQL2 schema 100%
- ✅ All Member DTOs updated
- ✅ All Member repositories updated
- ✅ All Member services updated
- ✅ MemberController updated
- ✅ AuthService.RegisterAsync() updated
- ✅ Build successful
- ✅ Server running without errors
- ⏳ Waiting for API testing confirmation

---

**Next Step**: Test Register endpoint in Swagger to confirm fix works end-to-end.
