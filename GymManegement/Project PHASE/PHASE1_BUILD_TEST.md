# 🔨 PHASE 1 BUILD TEST

> Test build sau khi hoàn thành Phase 1: DAL/Entities Refactoring

---

## ✅ Phase 1 Changes Summary

### Files Deleted (2):
- `DAL/Entities/EmailVerificationOTP.cs`
- `DAL/Entities/PasswordResetToken.cs`

### Files Modified (11):
1. `DAL/Entities/User.cs` - Major simplification
2. `DAL/Entities/Member.cs` - Nullable fields + audit
3. `DAL/Entities/Trainer.cs` - Added audit fields
4. `DAL/Entities/Membership.cs` - Added audit fields
5. `DAL/Entities/Schedule.cs` - Added audit fields
6. `DAL/Entities/Session.cs` - Added audit fields
7. `DAL/Entities/Checkin.cs` - Added audit fields
8. `DAL/Entities/Invoice.cs` - Added audit fields
9. `DAL/Entities/Payment.cs` - Added audit fields
10. `DAL/Entities/Facility.cs` - Added audit fields
11. `DAL/Entities/AuditLog.cs` - Added audit fields

---

## 🧪 How to Test Phase 1

### Option 1: Visual Studio Code Terminal
```powershell
cd "d:\Workspace\Độ án 2\GymManegement\GymManegement"
dotnet clean
dotnet build
```

### Option 2: Visual Studio
1. Open `GymManegement.sln` in Visual Studio
2. Menu: Build → Rebuild Solution
3. View errors in Error List window

### Option 3: Command Line
```cmd
cd "d:\Workspace\Độ án 2\GymManegement\GymManegement"
dotnet build --verbosity detailed > build_output.txt 2>&1
notepad build_output.txt
```

---

## ❌ Expected Build Errors (NORMAL - Will fix in Phase 2-5)

### 1. **DAL/Repositories/** - Repository Errors

#### UserRepository.cs:
```
CS1061: 'User' does not contain a definition for 'RoleId'
CS1061: 'User' does not contain a definition for 'PasswordSalt'
CS1061: 'User' does not contain a definition for 'MemberId'
CS1061: 'User' does not contain a definition for 'TrainerId'
CS1061: 'User' does not contain a definition for 'CreatedBy'
CS1061: 'User' does not contain a definition for 'UpdatedBy'
CS1061: 'User' does not contain a definition for 'RowVersion'
```

#### RoleRepository.cs / PermissionRepository.cs (if exists):
```
CS0246: The type or namespace name 'Role' could not be found
CS0246: The type or namespace name 'Permission' could not be found
```

#### EmailOTPRepository.cs / PasswordResetRepository.cs (if exists):
```
CS0246: The type or namespace name 'EmailVerificationOTP' could not be found
CS0246: The type or namespace name 'PasswordResetToken' could not be found
```

### 2. **Service/BUS/** - Service Errors

#### AuthService.cs:
```
CS1061: 'User' does not contain a definition for 'RoleId'
CS1061: 'User' does not contain a definition for 'PasswordSalt'
CS1061: 'User' does not contain a definition for 'MemberId'
```

#### UserService.cs:
```
CS1061: 'User' does not contain a definition for 'RowVersion'
CS1061: 'User' does not contain a definition for 'CreatedBy'
```

### 3. **Controllers/** - Controller Errors

#### AuthController.cs:
```
CS0246: The type or namespace name 'OTPVerificationRequest' could not be found
CS0246: The type or namespace name 'PasswordResetRequest' could not be found
```

#### MemberController.cs:
```
CS0029: Cannot implicitly convert type 'string?' to 'string'
(Phone and DateOfBirth nullable mismatch)
```

### 4. **API/DTOs/** - DTO Mapping Errors
```
CS1061: 'User' does not contain a definition for 'RoleId'
CS1061: 'Member' does not contain a definition for 'Phone' (nullability issue)
```

---

## ✅ What Should NOT Have Errors

### DAL/Entities/ - All entity files should compile cleanly:
- ✅ User.cs
- ✅ Member.cs
- ✅ Trainer.cs
- ✅ Membership.cs
- ✅ Schedule.cs
- ✅ Session.cs
- ✅ Checkin.cs
- ✅ Invoice.cs
- ✅ Payment.cs
- ✅ Facility.cs
- ✅ AuditLog.cs

---

## 📊 Expected Error Count by Category

| Category | Error Type | Estimated Count | Phase to Fix |
|----------|-----------|-----------------|--------------|
| Repositories | Property not found (User) | 15-20 errors | Phase 3 |
| Repositories | Type not found (Role/OTP) | 5-10 errors | Phase 3 |
| Services | Property not found | 10-15 errors | Phase 4 |
| Controllers | DTO not found | 5-10 errors | Phase 2 & 5 |
| DTOs | Nullability mismatch | 5-10 errors | Phase 2 |
| **TOTAL** | | **40-65 errors** | Phase 2-5 |

---

## ✅ Success Criteria for Phase 1

Even with 40-65 errors, Phase 1 is **SUCCESSFUL** if:

1. ✅ **All entity files compile** (DAL/Entities/*.cs)
2. ✅ **Errors are ONLY in dependent files**:
   - Repositories referencing old properties
   - Services using deleted entities
   - Controllers with DTO mismatches
3. ✅ **No errors in entity definitions themselves**
4. ✅ **Entity properties match SQL2 schema exactly**

---

## 🚦 Next Steps After Build Test

### If build shows 40-65 errors (Expected):
✅ **Phase 1 SUCCESS** - Proceed to Phase 2 (DTOs)

### If build shows 0-5 errors (Unexpected but good):
✅ **Excellent!** Some files may already be compatible - still review Phase 2-5

### If build shows >100 errors (Unexpected):
❌ Review entity changes - may have introduced syntax errors

### If build shows entity-level errors:
❌ Fix entity definitions first before proceeding

---

## 📝 Build Test Checklist

Before proceeding to Phase 2, verify:

- [ ] Run `dotnet clean`
- [ ] Run `dotnet build`
- [ ] Count total errors
- [ ] Verify errors are ONLY in:
  - [ ] `DAL/Repositories/` 
  - [ ] `Service/BUS/`
  - [ ] `Controllers/`
  - [ ] `API/DTOs/`
- [ ] Verify NO errors in:
  - [ ] `DAL/Entities/User.cs`
  - [ ] `DAL/Entities/Member.cs`
  - [ ] `DAL/Entities/*.cs` (all entities)
- [ ] Document error count in this file
- [ ] Proceed to Phase 2 if checklist passes

---

## 📋 Build Results (Fill after testing)

**Date:** __________  
**Build Command:** `dotnet build`  
**Result:** ⬜ Success (0 errors) / ⬜ Expected Errors (40-65) / ⬜ Unexpected Errors (>100)

**Total Errors:** __________  
**Total Warnings:** __________

**Error Breakdown:**
- Repositories: ______ errors
- Services: ______ errors
- Controllers: ______ errors
- DTOs: ______ errors
- Entities: ______ errors (should be 0)

**Conclusion:** ⬜ Phase 1 PASS / ⬜ Phase 1 FAIL

**Notes:**
```
(Bạn điền vào đây sau khi test)
```

---

## 🔧 Manual Build Instructions (If PowerShell Fails)

1. Mở **Visual Studio Code**
2. Open Terminal (Ctrl + `)
3. Run:
   ```powershell
   cd "d:\Workspace\Độ án 2\GymManegement\GymManegement"
   dotnet build
   ```
4. Screenshot errors
5. Fill in "Build Results" section above
6. Report back to continue Phase 2

---

**File Created:** 2026-10-09  
**Purpose:** Test Phase 1 completion before proceeding to Phase 2
