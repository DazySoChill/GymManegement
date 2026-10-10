## 🔧 HƯỚNG DẪN SỬA CODE - BUS/DAL/DTOs

> **Sau khi chạy SQL2, cần update code để khớp với database mới**

---

## 📋 CHECKLIST TỔNG QUAN

- [ ] **Step 1**: Update Connection String
- [ ] **Step 2**: Update Entities (DAL/Entities)
- [ ] **Step 3**: Update DTOs (API/DTOs)
- [ ] **Step 4**: Update Repositories (DAL/Repositories)
- [ ] **Step 5**: Update Services (Service/BUS)
- [ ] **Step 6**: Update Controllers (Controllers)
- [ ] **Step 7**: Test tất cả APIs

---

## STEP 1: UPDATE CONNECTION STRING

### File: `appsettings.json`

```json
{
  "ConnectionStrings": {
    "GymDb": "Server=localhost;Database=GymDb;User Id=sa;Password=yourpassword;TrustServerCertificate=true;"
  }
}
```

---

## STEP 2: UPDATE ENTITIES

### 📁 File: `DAL/Entities/User.cs`

**❌ TRƯỚC (cũ)**:
```csharp
public class User
{
    public int UserId { get; set; }
    public string Username { get; set; }
    public string PasswordHash { get; set; }
    public string PasswordSalt { get; set; }        // ❌ BỎ
    public int RoleId { get; set; }                 // ❌ BỎ FK
    public int? MemberId { get; set; }              // ❌ BỎ FK
    public int? TrainerId { get; set; }             // ❌ BỎ FK
    public bool IsActive { get; set; }
    public bool EmailConfirmed { get; set; }        // ❌ BỎ
    public int FailedLoginCount { get; set; }       // ❌ BỎ
    public DateTime? LockedUntil { get; set; }      // ❌ BỎ
    public DateTime? LastLoginAt { get; set; }      // ❌ BỎ
    public DateTime CreatedAt { get; set; }
    
    // Navigation properties
    public Role Role { get; set; }                  // ❌ BỎ
    public Member Member { get; set; }              // ❌ BỎ
    public Trainer Trainer { get; set; }            // ❌ BỎ
}
```

**✅ SAU (mới)**:
```csharp
public class User
{
    public int UserId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;  // BCrypt hash (có salt)
    public string FullName { get; set; } = string.Empty;      // ✅ THÊM
    public string Email { get; set; } = string.Empty;         // ✅ THÊM
    public string Role { get; set; } = "Member";              // ✅ THÊM (string)
    public bool IsActive { get; set; } = true;
    
    // Basic audit
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    
    // Soft delete
    public bool IsDeleted { get; set; } = false;
    public DateTime? DeletedAt { get; set; }
}
```

**📝 NOTES**:
- ❌ Bỏ `PasswordSalt` (BCrypt đã có salt trong hash)
- ❌ Bỏ `RoleId` FK → Thay bằng `Role` string
- ❌ Bỏ `MemberId`, `TrainerId` FK → Tìm bằng Email
- ❌ Bỏ `EmailConfirmed`, `FailedLoginCount`, `LockedUntil`, `LastLoginAt`
- ✅ Thêm `FullName`, `Email`
- ✅ Role là enum string: "Admin", "Trainer", "Member"

---

### 📁 File: `DAL/Entities/Member.cs`

**Chỉ cần sửa nhỏ**:
```csharp
public class Member
{
    public int MemberId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? Phone { get; set; }               // Nullable
    public string Email { get; set; } = string.Empty;
    public DateTime? DateOfBirth { get; set; }       // Nullable
    public DateTime JoinDate { get; set; } = DateTime.UtcNow;
    public string Status { get; set; } = "Active";   // Active/Inactive/Expired
    public string QRCodeValue { get; set; } = string.Empty;
    
    // Basic audit
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    
    // Soft delete
    public bool IsDeleted { get; set; } = false;
    public DateTime? DeletedAt { get; set; }
}
```

**📝 NOTES**:
- ✅ Giữ nguyên hầu hết
- ⚠️ Phone, DateOfBirth là nullable

---

### 📁 Các Entities khác (Trainer, Facility, etc.)

**Áp dụng pattern tương tự**:
```csharp
// Basic audit (giữ lại)
public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
public DateTime? UpdatedAt { get; set; }

// Soft delete (giữ lại)
public bool IsDeleted { get; set; } = false;
public DateTime? DeletedAt { get; set; }

// ❌ BỎ: CreatedBy, UpdatedBy, DeletedBy (columns ID)
// ❌ BỎ: RowVersion (byte[] concurrency)
```

---

## STEP 3: UPDATE DTOs

### 📁 File: `API/DTOs/Auth/RegisterRequest.cs`

**✅ MỚI (đơn giản)**:
```csharp
public class RegisterRequest
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
    [StringLength(150)]
    public string Email { get; set; } = string.Empty;
    
    // ❌ BỎ: Role field (auto = Member)
}
```

**📝 NOTES**:
- Chỉ 4 fields
- Role tự động = "Member"

---

### 📁 File: `API/DTOs/Auth/LoginResponse.cs`

**❌ TRƯỚC**:
```csharp
public class LoginResponse
{
    public string Token { get; set; }
    public int UserId { get; set; }
    public string Username { get; set; }
    public string Role { get; set; }
    public int? MemberId { get; set; }
    public int? TrainerId { get; set; }
    public DateTime ExpiresAt { get; set; }
}
```

**✅ SAU**:
```csharp
public class LoginResponse
{
    public string Token { get; set; } = string.Empty;
    public int UserId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;  // ✅ THÊM
    public string Email { get; set; } = string.Empty;     // ✅ THÊM
    public string Role { get; set; } = string.Empty;
    public int? MemberId { get; set; }                    // ✅ GIỮ (tìm bằng email)
    
    // ❌ BỎ: TrainerId (không cần thiết)
    // ❌ BỎ: ExpiresAt (client không cần)
}
```

---

### 📁 File: `API/DTOs/Auth/CreateStaffRequest.cs` (MỚI)

**✅ THÊM MỚI** (để Admin tạo Trainer/Admin):
```csharp
public class CreateStaffRequest
{
    [Required]
    [StringLength(50)]
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
    [RegularExpression("^(Admin|Trainer)$")]
    public string Role { get; set; } = "Trainer";  // Admin hoặc Trainer
}
```

---

### 📁 File: `API/DTOs/Member/CreateMemberRequest.cs`

**✅ SỬA NHỎ**:
```csharp
public class CreateMemberRequest
{
    [Required]
    [StringLength(100)]
    public string FullName { get; set; } = string.Empty;
    
    [Phone]
    public string? Phone { get; set; }  // Nullable
    
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;
    
    public DateTime? DateOfBirth { get; set; }  // Nullable
}
```

---

## STEP 4: UPDATE REPOSITORIES

### 📁 File: `DAL/Repositories/Interfaces/IUserRepository.cs`

**✅ MỚI**:
```csharp
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
    
    // ❌ BỎ: GetByRoleIdAsync (không có RoleId)
    // ❌ BỎ: GetByMemberIdAsync (không có FK)
}
```

---

### 📁 File: `DAL/Repositories/Implementations/UserRepository.cs`

**✅ Ví dụ implementation**:
```csharp
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
            SELECT UserId, Username, PasswordHash, FullName, Email, Role, IsActive, 
                   CreatedAt, UpdatedAt, IsDeleted
            FROM Users
            WHERE Username = @Username AND IsDeleted = 0";
        
        using var conn = _context.CreateConnection();
        return await conn.QueryFirstOrDefaultAsync<User>(sql, new { Username = username });
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
```

**📝 NOTES**:
- Query chỉ cần Username, PasswordHash, FullName, Email, Role
- ❌ Không query RoleId, MemberId, TrainerId
- ❌ Không query PasswordSalt, EmailConfirmed, etc.

---

### 📁 File: `DAL/Repositories/Interfaces/IMemberRepository.cs`

**✅ THÊM METHOD**:
```csharp
public interface IMemberRepository
{
    // ... existing methods
    
    Task<Member?> GetByEmailAsync(string email);  // ✅ THÊM
    Task<Member?> GetByQRCodeAsync(string qrCode);
}
```

---

## STEP 5: UPDATE SERVICES

### 📁 File: `Service/BUS/Implementations/AuthService.cs`

**✅ RegisterAsync() - LOGIC MỚI**:
```csharp
public async Task<UserResponse> RegisterAsync(RegisterRequest request)
{
    // 1. Validate
    if (await _userRepo.UsernameExistsAsync(request.Username))
        throw new InvalidOperationException("Username đã tồn tại");
    
    if (await _userRepo.EmailExistsAsync(request.Email))
        throw new InvalidOperationException("Email đã được sử dụng");
    
    // 2. Hash password (BCrypt tự động generate salt)
    string passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);
    
    // 3. Tạo User với Role = "Member" (AUTO)
    var user = new User
    {
        Username = request.Username,
        PasswordHash = passwordHash,
        FullName = request.FullName,
        Email = request.Email,
        Role = "Member",  // ✅ AUTO
        IsActive = true   // ✅ LUÔN TRUE
    };
    
    await _userRepo.CreateAsync(user);
    
    // 4. ✅ TỰ ĐỘNG tạo Member record
    var member = new Member
    {
        FullName = request.FullName,
        Email = request.Email,
        Phone = "",  // Để trống, update sau
        JoinDate = DateTime.UtcNow,
        Status = "Active",
        QRCodeValue = $"MEMBER-{user.UserId:D5}-{Guid.NewGuid().ToString("N")[..8]}"
    };
    
    await _memberRepo.CreateAsync(member);
    
    // 5. Trả về response (có thể login ngay)
    return new UserResponse
    {
        UserId = user.UserId,
        Username = user.Username,
        FullName = user.FullName,
        Email = user.Email,
        Role = user.Role
    };
}
```

**📝 KEY CHANGES**:
- ❌ KHÔNG tạo OTP
- ❌ KHÔNG gửi email
- ❌ KHÔNG set EmailConfirmed, IsActive auto = true
- ✅ TỰ ĐỘNG tạo Member record
- ✅ Role auto = "Member"

---

**✅ LoginAsync() - LOGIC MỚI**:
```csharp
public async Task<LoginResponse?> LoginAsync(LoginRequest request)
{
    // 1. Tìm user by username
    var user = await _userRepo.GetByUsernameAsync(request.Username);
    if (user == null || !user.IsActive)
        return null;
    
    // 2. Verify password (BCrypt)
    if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
        return null;
    
    // 3. Nếu role = Member, tìm MemberId bằng Email
    int? memberId = null;
    if (user.Role == "Member")
    {
        var member = await _memberRepo.GetByEmailAsync(user.Email);
        memberId = member?.MemberId;
    }
    
    // 4. Tạo JWT token
    var token = GenerateJwtToken(user, memberId);
    
    // 5. Trả về response
    return new LoginResponse
    {
        Token = token,
        UserId = user.UserId,
        Username = user.Username,
        FullName = user.FullName,
        Email = user.Email,
        Role = user.Role,
        MemberId = memberId
    };
}
```

**📝 KEY CHANGES**:
- ❌ KHÔNG check EmailConfirmed
- ❌ KHÔNG increment FailedLoginCount
- ❌ KHÔNG check LockedUntil
- ✅ Tìm MemberId bằng Email (không FK)

---

**✅ GenerateJwtToken() - CLAIMS MỚI**:
```csharp
private string GenerateJwtToken(User user, int? memberId)
{
    var claims = new List<Claim>
    {
        new Claim(JwtRegisteredClaimNames.Sub, user.UserId.ToString()),
        new Claim(JwtRegisteredClaimNames.UniqueName, user.Username),
        new Claim(JwtRegisteredClaimNames.Email, user.Email),
        new Claim(ClaimTypes.Role, user.Role),  // ✅ Role string
        new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
    };
    
    // Add MemberId claim nếu có
    if (memberId.HasValue)
        claims.Add(new Claim("memberId", memberId.Value.ToString()));
    
    var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Secret"]));
    var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
    
    var token = new JwtSecurityToken(
        issuer: _config["Jwt:Issuer"],
        audience: _config["Jwt:Audience"],
        claims: claims,
        expires: DateTime.UtcNow.AddDays(7),  // 7 days
        signingCredentials: creds
    );
    
    return new JwtSecurityTokenHandler().WriteToken(token);
}
```

**📝 KEY CHANGES**:
- ✅ Claims: sub, unique_name, email, role, memberId
- ❌ KHÔNG có trainerIds claim

---

**✅ CreateStaffAsync() - METHOD MỚI**:
```csharp
public async Task<UserResponse> CreateStaffAsync(CreateStaffRequest request)
{
    // Admin only method - validate in controller
    
    // Validate
    if (await _userRepo.UsernameExistsAsync(request.Username))
        throw new InvalidOperationException("Username đã tồn tại");
    
    if (await _userRepo.EmailExistsAsync(request.Email))
        throw new InvalidOperationException("Email đã được sử dụng");
    
    // Hash password
    string passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);
    
    // Create User
    var user = new User
    {
        Username = request.Username,
        PasswordHash = passwordHash,
        FullName = request.FullName,
        Email = request.Email,
        Role = request.Role,  // Admin hoặc Trainer
        IsActive = true
    };
    
    await _userRepo.CreateAsync(user);
    
    // Nếu role = Trainer, tạo Trainer record
    if (request.Role == "Trainer")
    {
        var trainer = new Trainer
        {
            FullName = request.FullName,
            Email = request.Email,
            Phone = "",
            Specialization = ""
        };
        await _trainerRepo.CreateAsync(trainer);
    }
    
    return new UserResponse
    {
        UserId = user.UserId,
        Username = user.Username,
        FullName = user.FullName,
        Role = user.Role
    };
}
```

---

### 📁 File: `Service/BUS/Implementations/MembershipService.cs`

**✅ CreateAsync() - AUTO CREATE INVOICE**:
```csharp
public async Task<MembershipResponse> CreateAsync(CreateMembershipRequest request)
{
    // 1. Validate Member exists
    var member = await _memberRepo.GetByIdAsync(request.MemberId);
    if (member == null)
        throw new NotFoundException("Member not found");
    
    // 2. Create Membership
    var membership = new Membership
    {
        MemberId = request.MemberId,
        MembershipType = request.MembershipType,
        Price = request.Price,
        StartDate = request.StartDate,
        EndDate = request.EndDate,
        Status = "Active"
    };
    
    await _membershipRepo.CreateAsync(membership);
    
    // 3. ✅ AUTO CREATE INVOICE
    var invoice = new Invoice
    {
        MemberId = request.MemberId,
        MembershipId = membership.MembershipId,
        Amount = request.Price,
        IssueDate = DateTime.UtcNow,
        DueDate = request.StartDate.AddDays(7),  // 7 days to pay
        Status = "Pending",
        Description = $"Phí {request.MembershipType} membership"
    };
    
    await _invoiceRepo.CreateAsync(invoice);
    
    // 4. Update Member status
    member.Status = "Active";
    await _memberRepo.UpdateAsync(member);
    
    return MapToResponse(membership);
}
```

**📝 KEY CHANGE**:
- ✅ AUTO tạo Invoice khi tạo Membership

---

### 📁 File: `Service/BUS/Implementations/PaymentService.cs`

**✅ CreateAsync() - AUTO UPDATE INVOICE STATUS**:
```csharp
public async Task<PaymentResponse> CreateAsync(CreatePaymentRequest request)
{
    // 1. Validate Invoice
    var invoice = await _invoiceRepo.GetByIdAsync(request.InvoiceId);
    if (invoice == null || invoice.Status != "Pending")
        throw new InvalidOperationException("Invoice không hợp lệ");
    
    // 2. Create Payment
    var payment = new Payment
    {
        InvoiceId = request.InvoiceId,
        Amount = request.Amount,
        PaymentDate = request.PaymentDate,
        PaymentMethod = request.PaymentMethod,
        Notes = request.Notes
    };
    
    await _paymentRepo.CreateAsync(payment);
    
    // 3. ✅ AUTO UPDATE INVOICE STATUS
    var totalPaid = await _paymentRepo.GetTotalPaidAsync(request.InvoiceId);
    
    if (totalPaid >= invoice.Amount)
    {
        invoice.Status = "Paid";
        invoice.UpdatedAt = DateTime.UtcNow;
        await _invoiceRepo.UpdateAsync(invoice);
    }
    
    return MapToResponse(payment);
}
```

**📝 KEY CHANGE**:
- ✅ AUTO update Invoice.Status = "Paid" khi trả đủ

---

## STEP 6: UPDATE CONTROLLERS

### 📁 File: `Controllers/AuthController.cs`

**✅ THÊM ENDPOINT MỚI**:
```csharp
/// <summary>Admin tạo tài khoản Admin/Trainer</summary>
[HttpPost("create-staff")]
[Authorize(Roles = "Admin")]
public async Task<IActionResult> CreateStaff([FromBody] CreateStaffRequest request)
{
    if (!ModelState.IsValid) return BadRequest(ModelState);
    
    try
    {
        var result = await _authService.CreateStaffAsync(request);
        return Ok(new { 
            message = $"Tạo tài khoản {request.Role} thành công", 
            user = result 
        });
    }
    catch (InvalidOperationException ex)
    {
        return BadRequest(new { message = ex.Message });
    }
}
```

**✅ SỬA ENDPOINT**: Bỏ OTP-related endpoints
```csharp
// ❌ BỎ: POST /verify-email
// ❌ BỎ: POST /resend-otp
```

---

## STEP 7: UPDATE PROGRAM.CS

### 📁 File: `Program.cs`

**✅ JWT Configuration (giữ nguyên, nhưng check claims)**:
```csharp
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Secret"]))
        };
    });
```

**✅ Authorization (giữ nguyên)**:
```csharp
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
    options.AddPolicy("TrainerOrAdmin", policy => policy.RequireRole("Admin", "Trainer"));
});
```

---

## STEP 8: TESTING CHECKLIST

### ✅ Test Register Flow
```bash
POST /api/Auth/register
{
  "username": "testuser",
  "password": "123456",
  "fullName": "Test User",
  "email": "test@example.com"
}

Expected:
- 200 OK
- User created với Role = "Member"
- Member record tự động tạo
- QRCode tự động generate
- Có thể login ngay (không cần verify)
```

### ✅ Test Login Flow
```bash
POST /api/Auth/login
{
  "username": "testuser",
  "password": "123456"
}

Expected:
- 200 OK
- Token hợp lệ
- Response có: userId, username, fullName, email, role, memberId
```

### ✅ Test Get Current User
```bash
GET /api/Auth/me
Authorization: Bearer <token>

Expected:
- 200 OK
- User info với role, memberId
```

### ✅ Test Create Membership → Auto Invoice
```bash
POST /api/Membership
Authorization: Bearer <admin-token>
{
  "memberId": 1,
  "membershipType": "Monthly",
  "price": 500000,
  "startDate": "2026-10-10",
  "endDate": "2026-11-10"
}

Expected:
- 201 Created
- Membership created
- Invoice tự động tạo với MembershipId
- Member.Status = "Active"
```

### ✅ Test Create Payment → Auto Update Invoice
```bash
POST /api/Payment
Authorization: Bearer <admin-token>
{
  "invoiceId": 1,
  "amount": 500000,
  "paymentDate": "2026-10-10",
  "paymentMethod": "Cash"
}

Expected:
- 201 Created
- Payment created
- Invoice.Status tự động = "Paid" (nếu trả đủ)
```

### ✅ Test QR Checkin
```bash
POST /api/Checkin/qr
{
  "qrCodeValue": "MEMBER-00001-ABC123",
  "sessionId": null
}

Expected:
- 200 OK
- Checkin created
- Validate active membership
- Cannot duplicate checkin same day
```

---

## 🎯 SUMMARY OF CHANGES

### ✅ ENTITIES
- **User**: Bỏ FK, thêm FullName/Email, Role string
- **Other entities**: Giữ nguyên structure, chỉ bỏ CreatedBy/UpdatedBy/RowVersion

### ✅ DTOs
- **RegisterRequest**: 4 fields only
- **LoginResponse**: Thêm FullName, Email
- **CreateStaffRequest**: New DTO

### ✅ REPOSITORIES
- **UserRepository**: Query theo username/email, không FK
- **MemberRepository**: Thêm GetByEmailAsync()

### ✅ SERVICES
- **AuthService.Register**: Auto tạo Member, không OTP
- **AuthService.Login**: Tìm MemberId bằng email
- **AuthService.CreateStaff**: New method cho Admin
- **MembershipService.Create**: Auto tạo Invoice
- **PaymentService.Create**: Auto update Invoice status

### ✅ CONTROLLERS
- **AuthController**: Thêm POST /create-staff, bỏ OTP endpoints

---

## ⚠️ BREAKING CHANGES

1. **Database không tương thích** với code cũ
2. **Phải update tất cả layers** (Entities, DTOs, Repos, Services)
3. **Không thể migrate data** từ SQL cũ (schema khác hoàn toàn)

---

## 📞 SUPPORT

- Có lỗi? Check console logs và database connection
- Test fail? Verify JWT token claims
- 401 Unauthorized? Check Role string trong token

**Good luck! 🚀**
