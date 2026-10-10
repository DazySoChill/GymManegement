# 🔧 CODE REFACTORING CHECKLIST
## Sửa code theo thứ tự, từng bước một

> **Follow this checklist step by step. Don't skip!**

---

## 📋 OVERVIEW

```
Progress: [    ] 0% → [████] 100%

Phase 1: Entities      [    ] → 20%
Phase 2: DTOs          [    ] → 40%
Phase 3: Repositories  [    ] → 60%
Phase 4: Services      [    ] → 80%
Phase 5: Controllers   [    ] → 100%
```

---

## ⭐ PHASE 1: ENTITIES (Start Here!)

### 1.1 Xóa các Entities không dùng

- [ ] **XÓA FILE**: `DAL/Entities/Role.cs`
- [ ] **XÓA FILE**: `DAL/Entities/Permission.cs`
- [ ] **XÓA FILE**: `DAL/Entities/RolePermission.cs`
- [ ] **XÓA FILE**: `DAL/Entities/EmailVerificationOTP.cs`
- [ ] **XÓA FILE**: `DAL/Entities/PasswordResetToken.cs`
- [ ] **XÓA FILE**: `DAL/Entities/RefreshToken.cs` (nếu có)
- [ ] **XÓA FILE**: `DAL/Entities/AuditLog.cs` (nếu có)

---

### 1.2 ⭐ SỬA: `DAL/Entities/User.cs` (CRITICAL)

**File path**: `DAL/Entities/User.cs`

**Replace toàn bộ file với**:
```csharp
namespace GymManegement.DAL.Entities
{
    public class User
    {
        public int UserId { get; set; }
        public string Username { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Role { get; set; } = "Member";  // Admin/Trainer/Member
        public bool IsActive { get; set; } = true;
        
        // Basic audit
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
        
        // Soft delete
        public bool IsDeleted { get; set; } = false;
        public DateTime? DeletedAt { get; set; }
    }
}
```

**Checklist**:
- [ ] Bỏ `PasswordSalt` (BCrypt có salt)
- [ ] Bỏ `RoleId`, thêm `Role` string
- [ ] Bỏ `MemberId`, `TrainerId` FK
- [ ] Bỏ `EmailConfirmed`, `FailedLoginCount`, `LockedUntil`, `LastLoginAt`
- [ ] Thêm `FullName`, `Email`
- [ ] Giữ `IsDeleted`, `DeletedAt`
- [ ] Bỏ `CreatedBy`, `UpdatedBy`, `DeletedBy`
- [ ] Bỏ `RowVersion`

---

### 1.3 SỬA: `DAL/Entities/Member.cs`

**Minor changes only**:
```csharp
public class Member
{
    public int MemberId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? Phone { get; set; }  // ✅ Nullable
    public string Email { get; set; } = string.Empty;
    public DateTime? DateOfBirth { get; set; }  // ✅ Nullable
    public DateTime JoinDate { get; set; } = DateTime.UtcNow;
    public string Status { get; set; } = "Active";
    public string QRCodeValue { get; set; } = string.Empty;
    
    // Basic audit
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    
    // Soft delete
    public bool IsDeleted { get; set; } = false;
    public DateTime? DeletedAt { get; set; }
}
```

**Checklist**:
- [ ] Phone nullable
- [ ] DateOfBirth nullable
- [ ] Bỏ CreatedBy, UpdatedBy, DeletedBy
- [ ] Bỏ RowVersion

---

### 1.4 SỬA: Các Entities khác (Pattern tương tự)

**Apply cho tất cả**: Trainer, Facility, Membership, Schedule, Session, Checkin, Invoice, Payment

**Pattern**:
```csharp
// ✅ GIỮ
public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
public DateTime? UpdatedAt { get; set; }
public bool IsDeleted { get; set; } = false;
public DateTime? DeletedAt { get; set; }

// ❌ BỎ
// public int? CreatedBy { get; set; }
// public int? UpdatedBy { get; set; }
// public int? DeletedBy { get; set; }
// public byte[] RowVersion { get; set; }
```

**Files**:
- [ ] `DAL/Entities/Trainer.cs`
- [ ] `DAL/Entities/Facility.cs`
- [ ] `DAL/Entities/Membership.cs`
- [ ] `DAL/Entities/Schedule.cs`
- [ ] `DAL/Entities/Session.cs`
- [ ] `DAL/Entities/Checkin.cs`
- [ ] `DAL/Entities/Invoice.cs`
- [ ] `DAL/Entities/Payment.cs`

---

### 1.5 BUILD & TEST

```bash
dotnet build
```

**Expected**: Nhiều lỗi compile (OK, fix ở phase sau)

---

## ⭐ PHASE 2: DTOs

### 2.1 ⭐ SỬA: `API/DTOs/Auth/RegisterRequest.cs`

**Replace với**:
```csharp
using System.ComponentModel.DataAnnotations;

namespace GymManegement.API.DTOs.Auth
{
    public class RegisterRequest
    {
        [Required(ErrorMessage = "Username là bắt buộc")]
        [StringLength(50, MinimumLength = 3)]
        public string Username { get; set; } = string.Empty;
        
        [Required(ErrorMessage = "Password là bắt buộc")]
        [StringLength(100, MinimumLength = 6)]
        public string Password { get; set; } = string.Empty;
        
        [Required(ErrorMessage = "Họ tên là bắt buộc")]
        [StringLength(100)]
        public string FullName { get; set; } = string.Empty;
        
        [Required(ErrorMessage = "Email là bắt buộc")]
        [EmailAddress]
        [StringLength(150)]
        public string Email { get; set; } = string.Empty;
    }
}
```

**Checklist**:
- [ ] Chỉ 4 fields
- [ ] Bỏ Role field (auto = Member)

---

### 2.2 SỬA: `API/DTOs/Auth/LoginResponse.cs`

**Replace với**:
```csharp
namespace GymManegement.API.DTOs.Auth
{
    public class LoginResponse
    {
        public string Token { get; set; } = string.Empty;
        public int UserId { get; set; }
        public string Username { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;
        public int? MemberId { get; set; }
    }
}
```

**Checklist**:
- [ ] Thêm FullName, Email
- [ ] Bỏ TrainerId, ExpiresAt

---

### 2.3 ⭐ TẠO MỚI: `API/DTOs/Auth/CreateStaffRequest.cs`

**Tạo file mới**:
```csharp
using System.ComponentModel.DataAnnotations;

namespace GymManegement.API.DTOs.Auth
{
    public class CreateStaffRequest
    {
        [Required]
        [StringLength(50, MinimumLength = 3)]
        public string Username { get; set; } = string.Empty;
        
        [Required]
        [StringLength(100, MinimumLength = 6)]
        public string Password { get; set; } = string.Empty;
        
        [Required]
        [StringLength(100)]
        public string FullName { get; set; } = string.Empty;
        
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
        
        [Required]
        [RegularExpression("^(Admin|Trainer)$", ErrorMessage = "Role phải là Admin hoặc Trainer")]
        public string Role { get; set; } = "Trainer";
    }
}
```

---

### 2.4 XÓA DTOs không dùng

- [ ] **XÓA FOLDER**: `API/DTOs/Auth/OTPVerificationDTOs.cs` (hoặc tương tự)
- [ ] **XÓA FILE**: `API/DTOs/Auth/PasswordResetDTOs.cs` (nếu có)

---

### 2.5 TẠO: `API/DTOs/Auth/UserResponse.cs` (nếu chưa có)

```csharp
namespace GymManegement.API.DTOs.Auth
{
    public class UserResponse
    {
        public int UserId { get; set; }
        public string Username { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;
    }
}
```

---

## ⭐ PHASE 3: REPOSITORIES

### 3.1 ⭐ SỬA: `DAL/Repositories/Interfaces/IUserRepository.cs`

**Replace interface**:
```csharp
using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface IUserRepository
    {
        Task<User?> GetByIdAsync(int userId);
        Task<User?> GetByUsernameAsync(string username);
        Task<User?> GetByEmailAsync(string email);
        Task<bool> UsernameExistsAsync(string username);
        Task<bool> EmailExistsAsync(string email);
        Task<User> CreateAsync(User user);
        Task<bool> UpdateAsync(User user);
        Task<bool> DeleteAsync(int userId);
        Task<IEnumerable<User>> GetAllAsync(int pageNumber, int pageSize);
    }
}
```

**Checklist**:
- [ ] Bỏ methods liên quan RoleId, MemberId FK
- [ ] Thêm GetByEmailAsync, UsernameExistsAsync, EmailExistsAsync

---

### 3.2 ⭐ SỬA: `DAL/Repositories/Implementations/UserRepository.cs`

**Key methods** (example với Dapper):

```csharp
using Dapper;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Helper;
using GymManegement.DAL.Repositories.Interfaces;

namespace GymManegement.DAL.Repositories.Implementations
{
    public class UserRepository : IUserRepository
    {
        private readonly DapperContext _context;
        
        public UserRepository(DapperContext context)
        {
            _context = context;
        }
        
        public async Task<User?> GetByUsernameAsync(string username)
        {
            const string sql = @"
                SELECT UserId, Username, PasswordHash, FullName, Email, Role, 
                       IsActive, CreatedAt, UpdatedAt, IsDeleted, DeletedAt
                FROM Users
                WHERE Username = @Username AND IsDeleted = 0";
            
            using var conn = _context.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<User>(sql, new { Username = username });
        }
        
        public async Task<User?> GetByEmailAsync(string email)
        {
            const string sql = @"
                SELECT UserId, Username, PasswordHash, FullName, Email, Role, 
                       IsActive, CreatedAt, UpdatedAt, IsDeleted, DeletedAt
                FROM Users
                WHERE Email = @Email AND IsDeleted = 0";
            
            using var conn = _context.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<User>(sql, new { Email = email });
        }
        
        public async Task<bool> UsernameExistsAsync(string username)
        {
            const string sql = "SELECT COUNT(1) FROM Users WHERE Username = @Username AND IsDeleted = 0";
            using var conn = _context.CreateConnection();
            return await conn.ExecuteScalarAsync<int>(sql, new { Username = username }) > 0;
        }
        
        public async Task<bool> EmailExistsAsync(string email)
        {
            const string sql = "SELECT COUNT(1) FROM Users WHERE Email = @Email AND IsDeleted = 0";
            using var conn = _context.CreateConnection();
            return await conn.ExecuteScalarAsync<int>(sql, new { Email = email }) > 0;
        }
        
        public async Task<User> CreateAsync(User user)
        {
            const string sql = @"
                INSERT INTO Users (Username, PasswordHash, FullName, Email, Role, IsActive)
                VALUES (@Username, @PasswordHash, @FullName, @Email, @Role, @IsActive);
                SELECT CAST(SCOPE_IDENTITY() as int);";
            
            using var conn = _context.CreateConnection();
            user.UserId = await conn.ExecuteScalarAsync<int>(sql, user);
            return user;
        }
        
        // ... other methods
    }
}
```

**Checklist**:
- [ ] Query chỉ select columns tồn tại trong DB mới
- [ ] Filter `IsDeleted = 0` mọi query
- [ ] Bỏ queries liên quan RoleId, MemberId FK

---

### 3.3 SỬA: `DAL/Repositories/Interfaces/IMemberRepository.cs`

**Thêm methods**:
```csharp
Task<Member?> GetByEmailAsync(string email);
Task<Member?> GetByQRCodeAsync(string qrCodeValue);
```

---

### 3.4 SỬA: `DAL/Repositories/Implementations/MemberRepository.cs`

**Thêm implementations**:
```csharp
public async Task<Member?> GetByEmailAsync(string email)
{
    const string sql = "SELECT * FROM Members WHERE Email = @Email AND IsDeleted = 0";
    using var conn = _context.CreateConnection();
    return await conn.QueryFirstOrDefaultAsync<Member>(sql, new { Email = email });
}

public async Task<Member?> GetByQRCodeAsync(string qrCodeValue)
{
    const string sql = "SELECT * FROM Members WHERE QRCodeValue = @QRCodeValue AND IsDeleted = 0";
    using var conn = _context.CreateConnection();
    return await conn.QueryFirstOrDefaultAsync<Member>(sql, new { QRCodeValue = qrCodeValue });
}
```

---

### 3.5 BUILD & TEST Repositories

```bash
dotnet build
```

**Test**: Write simple unit tests hoặc integration tests

---

## ⭐ PHASE 4: SERVICES (QUAN TRỌNG NHẤT)

### 4.1 ⭐ SỬA: `Service/BUS/Interfaces/IAuthService.cs`

**Update interface**:
```csharp
using GymManegement.API.DTOs.Auth;

namespace GymManegement.Service.BUS.Interfaces
{
    public interface IAuthService
    {
        Task<LoginResponse?> LoginAsync(LoginRequest request);
        Task<UserResponse> RegisterAsync(RegisterRequest request);
        Task<UserResponse> CreateStaffAsync(CreateStaffRequest request);
        Task<bool> ChangePasswordAsync(int userId, ChangePasswordRequest request);
        Task<IEnumerable<UserResponse>> GetAllUsersAsync();
        Task<bool> SetActiveAsync(int userId, bool isActive);
    }
}
```

**Checklist**:
- [ ] Bỏ VerifyEmailAsync, ResendOTPAsync, ForgotPasswordAsync
- [ ] Thêm CreateStaffAsync
- [ ] RegisterAsync return UserResponse (không cần OTP)

---

### 4.2 ⭐ SỬA: `Service/BUS/Implementations/AuthService.cs`

Tôi sẽ tạo file mẫu hoàn chỉnh...

---

**TO BE CONTINUED** (file quá dài, tiếp tục ở phần sau...)

---

## 📞 NEXT STEPS

Bạn bắt đầu với **PHASE 1** trước:
1. Xóa entities không dùng
2. Sửa User.cs
3. Sửa các entities khác
4. Build để xem errors

Sau khi xong PHASE 1, ping tôi để tôi guide PHASE tiếp theo! 🚀
