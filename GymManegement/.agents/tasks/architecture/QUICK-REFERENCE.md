# QUICK REFERENCE - Tham khảo nhanh cho bảo vệ đồ án

## 🎯 Thông tin chính (THUỘC LÒNG!)

### Technology Stack
```
Backend:    ASP.NET Core 6.0 (LTS)
ORM:        Dapper (micro-ORM)
Database:   SQL Server 2019+
Frontend:   Vanilla JavaScript (no framework)
Auth:       JWT (JSON Web Tokens)
Password:   BCrypt (workFactor 11)
IDE:        Visual Studio 2022
```

### Project Statistics
```
Controllers:        12 controllers
API Endpoints:      ~60 endpoints
Database Tables:    12 tables
Stored Procedures:  97 procedures
Roles:              3 (Admin, Trainer, Member)
Layers:             4 (Controllers → Services → Repositories → Database)
```

---

## 📊 12 Database Tables

| # | Tên bảng | Mục đích | Key columns |
|---|----------|----------|-------------|
| 1 | Users | Tài khoản đăng nhập | UserId, Username, PasswordHash, Role |
| 2 | Members | Thông tin thành viên | MemberId, QRCode, Email |
| 3 | Trainers | Thông tin huấn luyện viên | TrainerId, Specialization |
| 4 | Facilities | Phòng tập, thiết bị | FacilityId, Name, Status |
| 5 | Memberships | Gói tập của member | MembershipId, MemberId, StartDate, EndDate |
| 6 | Schedules | Lịch tập do trainer tạo | ScheduleId, TrainerId, FacilityId, StartTime |
| 7 | Sessions | Member đăng ký vào lịch | SessionId, ScheduleId, MemberId |
| 8 | Checkins | Check-in/out attendance | CheckinId, MemberId, CheckinTime |
| 9 | Invoices | Hóa đơn | InvoiceId, MemberId, TotalAmount, Status |
| 10 | Payments | Thanh toán | PaymentId, InvoiceId, Amount, PaymentMethod |
| 11 | MemberSchedulePreferences | Giờ tập ưa thích | PreferenceId, MemberId, DayOfWeek |
| 12 | AuditLogs | Audit trail | AuditLogId, TableName, Action |

---

## 🔐 3 Roles & Permissions

| Role | Permissions | Special notes |
|------|-------------|---------------|
| **Admin** | ✅ Full access<br>✅ CRUD all entities<br>✅ View all reports<br>✅ Manage users | Không thể đổi role chính mình |
| **Trainer** | ✅ Create/edit own schedules<br>✅ View all schedules<br>✅ Check-in (as employee)<br>✅ View own stats | Có BOTH Trainer + Member records |
| **Member** | ✅ View schedules<br>✅ Register for sessions<br>✅ Check-in/out<br>✅ View own info | Auto-created when register |

---

## 🚀 Key Flows (Nắm vững!)

### 1. Login Flow
```
1. User nhập username/password
2. Frontend: POST /api/Auth/login
3. Backend: Verify BCrypt
4. Generate JWT (claims: userId, role, memberId)
5. Return token
6. Frontend: Save to localStorage
7. Subsequent requests: Header "Authorization: Bearer <token>"
```

### 2. Check-in Flow
```
1. Member clicks "Check In"
2. Frontend: POST /api/Checkins (empty body)
3. JwtMiddleware: Extract memberId from token
4. Controller: Pass to service
5. Service: Validate member exists
6. Repository: INSERT INTO Checkins
7. Return success
8. Frontend: Update UI
```

### 3. Create Schedule Flow
```
1. Trainer fills form (class, time, facility)
2. Frontend: POST /api/Schedules
3. JwtMiddleware: Validate token + extract trainerId
4. Controller: Ownership check (trainerId == current user?)
5. Service: Conflict detection (trainer/facility time overlap?)
6. Repository: INSERT INTO Schedules
7. Return success
```

---

## 🔑 Authentication & Security

### JWT Claims Structure
```json
{
  "sub": "1",                    // userId
  "unique_name": "admin",        // username
  "email": "admin@gym.vn",       // email
  "role": "Admin",               // role
  "memberId": "null",            // memberId (if Member/Trainer)
  "trainerId": "1",              // trainerId (if Trainer)
  "exp": 1705661234              // expiration
}
```

### BCrypt Password Example
```
Plain:  "password"
Hash:   "$2a$11$M9a1sE7Huz8nyphDQGKnjuXIkIzj7p.93YBKr3lR.2zUJCRu1bzZq"
        ^^^ ^^   ^^^^^^^^^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        |   |    Salt (22 chars)          Hash (31 chars)
        |   WorkFactor (11 = ~100ms/hash)
        Algorithm (2a = BCrypt)
```

### Security Measures
- ✅ BCrypt password hashing (workFactor 11)
- ✅ JWT token authentication (24h expiration)
- ✅ Role-based authorization ([Authorize(Roles = "Admin")])
- ✅ SQL injection prevention (Dapper parameterized queries)
- ✅ CORS policy
- ✅ Input validation (DTO validation attributes)
- ✅ Soft delete (data retention)

---

## 📁 Layered Architecture

```
┌──────────────────────────────────────┐
│  FRONTEND (wwwroot/)                 │  - HTML/CSS/JS
│  - app.js (routing, auth, API)      │  - apiFetch() helper
│  - entity.js (CRUD per entity)      │  - localStorage for token
└────────────┬─────────────────────────┘
             │ HTTP/JSON + JWT Token
             ▼
┌──────────────────────────────────────┐
│  CONTROLLERS (API endpoints)         │  - AuthController
│  - Extract DTO from request          │  - MembersController
│  - Call Service layer                │  - 12 controllers total
│  - Return JSON response              │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│  SERVICES (Business logic)           │  - AuthService
│  - Validation rules                  │  - MemberService
│  - Business logic                    │  - 12 services
│  - Call Repository layer             │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│  REPOSITORIES (Data access)          │  - UserRepository
│  - SQL queries with Dapper           │  - MemberRepository
│  - Parameterized queries             │  - 12 repositories
│  - Return entities                   │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│  DATABASE (SQL Server)               │  - 12 tables
│  - Tables with relationships         │  - 97 stored procedures
│  - Indexes for performance           │  - Soft delete pattern
└──────────────────────────────────────┘
```

---

## 💡 Design Patterns

### 1. Repository Pattern
```csharp
// Interface
public interface IMemberRepository {
    Task<Member> GetByIdAsync(int id);
    Task<int> CreateAsync(Member member);
}

// Implementation
public class MemberRepository : IMemberRepository {
    public async Task<Member> GetByIdAsync(int id) {
        var sql = "SELECT * FROM Members WHERE MemberId = @id AND IsDeleted = 0";
        return await _db.Connection.QueryFirstOrDefaultAsync<Member>(sql, new { id });
    }
}

// Usage in Service
private readonly IMemberRepository _repo;
public MemberService(IMemberRepository repo) { _repo = repo; }
```

### 2. DTO Pattern
```csharp
// Request DTO (from client)
public class CreateMemberRequest {
    [Required] public string FullName { get; set; }
    [EmailAddress] public string Email { get; set; }
}

// Response DTO (to client)
public class MemberResponse {
    public int MemberId { get; set; }
    public string FullName { get; set; }
    public string QRCode { get; set; }
}
```

### 3. Dependency Injection
```csharp
// Program.cs
builder.Services.AddScoped<IMemberRepository, MemberRepository>();
builder.Services.AddScoped<IMemberService, MemberService>();

// Controller
public class MembersController {
    private readonly IMemberService _service;
    public MembersController(IMemberService service) { _service = service; }
}
```

---

## 🔍 Dapper vs Entity Framework

| Feature | Dapper | Entity Framework |
|---------|--------|------------------|
| **Performance** | ⭐⭐⭐⭐⭐ Gần ADO.NET | ⭐⭐⭐ Chậm hơn |
| **SQL Control** | ⭐⭐⭐⭐⭐ Viết SQL trực tiếp | ⭐⭐ LINQ abstraction |
| **Learning** | ⭐⭐⭐⭐ Chỉ cần SQL | ⭐⭐ Học LINQ + conventions |
| **Code** | SQL strings in C# | LINQ queries |
| **Migrations** | Manual SQL scripts | Auto-generate |

**Why Dapper?**
- Performance critical (20x faster cho complex queries)
- Full SQL control (stored procedures, custom queries)
- Lightweight (1 file, <100KB)
- Dễ debug (SQL rõ ràng)

---

## 🎨 Frontend Architecture

### app.js Core Functions
```javascript
// API Client
async function apiFetch(method, url, body = null) {
    const token = localStorage.getItem('authToken');
    const response = await fetch(API_BASE_URL + url, {
        method,
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
        },
        body: body ? JSON.stringify(body) : null
    });
    return response.json();
}

// Routing
function loadPage(page) {
    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
    document.getElementById(page + 'Page').classList.add('active');
}

// Role-based navigation
const allowedPagesByRole = {
    'Admin': ['dashboard', 'members', 'trainers', ...],
    'Trainer': ['dashboard', 'schedules', 'checkins', 'profile'],
    'Member': ['dashboard', 'schedules', 'sessions', 'checkins', 'profile']
};
```

---

## ❓ Câu hỏi thường gặp (FAQs)

### Q1: Tại sao chọn ASP.NET Core?
**A**: Performance cao, cross-platform, strongly-typed (C#), ecosystem mạnh, DI built-in.

### Q2: Tại sao Dapper thay vì EF?
**A**: Performance tốt hơn (20x faster), SQL control đầy đủ, lightweight, dễ học.

### Q3: Tại sao không dùng React/Vue?
**A**: Học fundamental JS, không build process, deploy đơn giản, phù hợp học tập.

### Q4: JWT có an toàn không?
**A**: Có. Token signed với secret key, expire sau 24h, HTTPS transport. Production thêm refresh token.

### Q5: Làm sao ngăn SQL injection?
**A**: Dapper parameterized queries: `@param` thay vì string concatenation.

### Q6: Soft delete là gì? Tại sao dùng?
**A**: IsDeleted=1 thay vì DELETE. Giữ audit trail, có thể recover, compliance.

### Q7: Trainer check-in như thế nào?
**A**: Trainer có BOTH Trainer record + Member record. Check-in dùng Member record.

### Q8: Role-switch logic là gì?
**A**: Khi đổi role User → auto-create Trainer/Member record tương ứng. Tránh lỗi "Không tìm thấy trainer/member".

### Q9: QRCode format?
**A**: M + MemberId (6 digits), VD: M000001. Unique per member, dùng cho check-in.

### Q10: Làm sao scale hệ thống?
**A**: Load balancer, database replication, caching (Redis), CDN cho static files, connection pooling.

---

## 🧪 Testing Guide

### Postman Test Script
```
POST https://localhost:5001/api/Auth/login
Body:
{
    "username": "admin",
    "password": "password"
}

→ Copy token từ response
→ Dùng cho requests khác:
Header: Authorization: Bearer <token>
```

### Browser DevTools
```
F12 → Network tab → Xem requests/responses
F12 → Application → Local Storage → Xem authToken
F12 → Console → Test apiFetch()
```

---

## 📞 Contacts

**Demo credentials:**
- Admin: admin / password
- Trainer: trainer1 / password
- Member: member01 / password

**URL:**
- Frontend: https://localhost:5001
- Swagger: https://localhost:5001/swagger

---

**Cập nhật**: 2025-01-18  
**In ra và mang theo khi bảo vệ!**
