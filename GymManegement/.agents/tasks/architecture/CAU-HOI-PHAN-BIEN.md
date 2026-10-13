# CÂU HỎI PHẢN BIỆN & CÁCH TRẢ LỜI

## 📋 Mục lục câu hỏi theo chủ đề

1. [Công nghệ & Kiến trúc](#1-công-nghệ--kiến-trúc)
2. [Database & ORM](#2-database--orm)
3. [Security & Authentication](#3-security--authentication)
4. [Business Logic](#4-business-logic)
5. [Frontend](#5-frontend)
6. [Performance & Scalability](#6-performance--scalability)
7. [Testing & Maintenance](#7-testing--maintenance)
8. [So sánh với giải pháp khác](#8-so-sánh-với-giải-pháp-khác)

---

## 1. Công nghệ & Kiến trúc

### Q1.1: Tại sao chọn ASP.NET Core thay vì Node.js hoặc Java Spring Boot?

**Trả lời:**

**ASP.NET Core có những ưu điểm:**
1. **Performance xuất sắc**: Top 10 TechEmpower benchmark, xử lý 7M requests/second
2. **Strongly-typed**: C# giúp phát hiện lỗi compile-time, giảm bugs
3. **Cross-platform**: Chạy Windows/Linux/macOS
4. **Ecosystem mạnh**: NuGet có 300K+ packages
5. **Built-in features**: DI container, authentication, CORS, logging sẵn có

**So với Node.js:**
- Node.js dùng JavaScript (dynamically-typed) → nhiều lỗi runtime hơn
- Node.js single-threaded → xử lý CPU-intensive tasks kém hơn
- ASP.NET Core có async/await tốt hơn (Task-based)

**So với Java Spring Boot:**
- Spring Boot nặng hơn, startup chậm hơn
- ASP.NET Core có LINQ (query syntax đẹp hơn Streams API)
- Tooling: Visual Studio tốt hơn IntelliJ (subjective)

**Kết luận**: ASP.NET Core phù hợp cho dự án cần performance, type-safety, và rapid development.

---

### Q1.2: Giải thích kiến trúc Layered/N-tier? Tại sao không dùng Microservices?

**Trả lời:**

**Kiến trúc Layered (3 layers chính):**
```
Controllers → Services → Repositories → Database
```

**Vai trò mỗi layer:**
1. **Controllers**: Nhận HTTP request, validate input, gọi service, return response
2. **Services**: Business logic, validation rules, orchestrate repositories
3. **Repositories**: Data access, SQL queries, return entities

**Lợi ích:**
- ✅ Separation of concerns (mỗi layer có trách nhiệm riêng)
- ✅ Testability (mock từng layer dễ dàng)
- ✅ Maintainability (thay đổi database không ảnh hưởng controller)
- ✅ Reusability (1 service dùng cho nhiều controllers)

**Tại sao KHÔNG dùng Microservices?**
1. **Phạm vi dự án nhỏ**: Chỉ 1 domain (gym management), không cần chia nhỏ
2. **Complexity**: Microservices cần API Gateway, service discovery, distributed tracing
3. **Deployment**: Monolith deploy đơn giản hơn (1 server)
4. **Transaction**: Cross-service transactions phức tạp, ACID khó đảm bảo

**Khi nào dùng Microservices?**
- Hệ thống lớn (>10 bounded contexts)
- Teams độc lập (mỗi service 1 team)
- Scale khác nhau (VD: payment service cần scale nhiều hơn)

---

### Q1.3: Dependency Injection hoạt động như thế nào? Lợi ích?

**Trả lời:**

**Cách hoạt động:**
```csharp
// 1. Register trong Program.cs
builder.Services.AddScoped<IMemberService, MemberService>();

// 2. Constructor injection
public class MembersController {
    private readonly IMemberService _service;
    public MembersController(IMemberService service) {
        _service = service; // ASP.NET Core tự động inject
    }
}
```

**DI Container của ASP.NET Core:**
- Quản lý lifetime: Singleton (1 instance), Scoped (1 per request), Transient (mỗi lần new)
- Resolve dependencies tự động (nếu IMemberService cần IRepository → auto inject)

**Lợi ích:**
1. **Loose coupling**: Controller không phụ thuộc implementation cụ thể
2. **Testability**: Dễ mock dependencies
   ```csharp
   var mockService = new Mock<IMemberService>();
   var controller = new MembersController(mockService.Object);
   ```
3. **Flexibility**: Đổi implementation không cần sửa controller
4. **Lifecycle management**: Container tự động dispose resources

**Ví dụ không DI (tightly coupled):**
```csharp
public class MembersController {
    private readonly MemberService _service = new MemberService(); // ❌ Tight coupling
}
```

---

## 2. Database & ORM

### Q2.1: Tại sao chọn Dapper thay vì Entity Framework Core?

**Trả lời:**

| Tiêu chí | Dapper | Entity Framework Core |
|----------|--------|----------------------|
| **Performance** | ⭐⭐⭐⭐⭐ 20x nhanh hơn complex queries | ⭐⭐⭐ Có overhead từ change tracking |
| **SQL Control** | ⭐⭐⭐⭐⭐ Viết SQL trực tiếp | ⭐⭐ LINQ đôi khi gen SQL kém |
| **Learning Curve** | ⭐⭐⭐⭐ Chỉ cần biết SQL | ⭐⭐ Phải học LINQ, conventions, migrations |
| **Flexibility** | ⭐⭐⭐⭐⭐ Stored procedures dễ | ⭐⭐⭐ FromSqlRaw workaround |
| **Code Complexity** | SQL strings trong C# | LINQ queries |
| **Lightweight** | 1 file NuGet, <100KB | Multiple packages, >10MB |

**Ví dụ Dapper:**
```csharp
var sql = "SELECT * FROM Members WHERE MemberId = @id AND IsDeleted = 0";
var member = await _db.Connection.QueryFirstOrDefaultAsync<Member>(sql, new { id });
```

**Ví dụ EF Core:**
```csharp
var member = await _context.Members
    .Where(m => m.MemberId == id && !m.IsDeleted)
    .FirstOrDefaultAsync();
```

**Khi nào dùng Dapper?**
- Cần performance cao (reporting, analytics)
- Complex queries (joins, CTEs, window functions)
- Stored procedures existing
- Team giỏi SQL

**Khi nào dùng EF Core?**
- CRUD đơn giản
- Team yếu SQL
- Cần change tracking, lazy loading

**Kết luận**: Dapper phù hợp cho dự án này vì queries đơn giản, cần performance, và team biết SQL.

---

### Q2.2: Giải thích Soft Delete pattern? Tại sao không DELETE thật?

**Trả lời:**

**Soft Delete:**
```sql
-- Thay vì
DELETE FROM Members WHERE MemberId = 1

-- Dùng
UPDATE Members 
SET IsDeleted = 1, DeletedAt = GETDATE()
WHERE MemberId = 1

-- Queries filter
SELECT * FROM Members WHERE IsDeleted = 0
```

**Lợi ích:**
1. **Audit trail**: Giữ lịch sử, biết ai xóa khi nào
2. **Data recovery**: Có thể restore (set IsDeleted = 0)
3. **Compliance**: Luật pháp yêu cầu lưu data (GDPR right to be forgotten có exception)
4. **Foreign key integrity**: Không bị lỗi khi xóa record có FK references

**Nhược điểm:**
1. **Database size tăng**: Không thật sự xóa data
2. **Queries phức tạp**: Phải WHERE IsDeleted = 0 mọi nơi
3. **Index performance**: Index lớn hơn (chứa cả deleted records)
4. **Unique constraints**: Email unique phải exclude IsDeleted

**Giải pháp nhược điểm:**
- Archive table: Di chuyển deleted records sang bảng khác
- Partial index: `CREATE INDEX ON Members(Email) WHERE IsDeleted = 0`
- Scheduled cleanup: Xóa thật records > 7 năm

**Kết luận**: Soft delete phù hợp cho hệ thống cần audit và recovery.

---

### Q2.3: Database có bao nhiêu bảng? Giải thích quan hệ chính?

**Trả lời:**

**12 tables:**
1. Users (authentication)
2. Members (member profiles)
3. Trainers (trainer profiles)
4. Facilities (gym rooms/equipment)
5. Memberships (subscription packages)
6. Schedules (training classes)
7. Sessions (class registrations)
8. Checkins (attendance)
9. Invoices (billing)
10. Payments (payment records)
11. MemberSchedulePreferences (preferred times)
12. AuditLogs (audit trail)

**Quan hệ chính:**
```
Users 1───1 Members (Email matching)
      └───1 Trainers (Email matching)

Members 1───N Memberships (subscription history)
        └───N Checkins (attendance log)
        └───N Sessions (class registrations)
        └───N Invoices (billing)

Trainers 1───N Schedules (classes created by trainer)

Schedules 1───N Sessions (members register for class)
Facilities 1───N Schedules (room bookings)

Invoices 1───N Payments (payment history)
Memberships 0..1───N Invoices (membership invoices)
```

**Đặc biệt:**
- **Trainer dual-record**: Trainer có BOTH Trainer + Member records (để check-in)
- **No direct User FK**: Users liên kết Members/Trainers qua Email (flexibility)

---

## 3. Security & Authentication

### Q3.1: JWT có an toàn không? Có thể bị hack không?

**Trả lời:**

**JWT an toàn NẾU:**
1. ✅ **Secret key đủ mạnh**: ≥32 characters, random
2. ✅ **HTTPS**: Token không bị sniff trên network
3. ✅ **Expiration**: Token hết hạn (24h trong project này)
4. ✅ **Validate signature**: Server verify token chưa bị tamper

**Rủi ro và cách phòng:**

| Rủi ro | Cách phòng |
|--------|-----------|
| **Token theft (XSS)** | ✅ HttpOnly cookies (alternative to localStorage)<br>✅ Content Security Policy<br>✅ Sanitize user input |
| **Token theft (man-in-middle)** | ✅ HTTPS enforce<br>✅ HSTS headers |
| **Token replay** | ✅ Short expiration (24h)<br>✅ Refresh token pattern |
| **Brute-force signature** | ✅ Strong secret key (>256 bits)<br>✅ HS256 algorithm |

**JWT Structure:**
```
eyJhbGc... . eyJzdWI... . SflKxwRJ...
Header      Payload     Signature
```

**Validation process:**
```csharp
// JwtMiddleware.cs
var tokenHandler = new JwtSecurityTokenHandler();
tokenHandler.ValidateToken(token, new TokenValidationParameters {
    ValidateIssuer = true,
    ValidateAudience = true,
    ValidateLifetime = true, // Check exp claim
    ValidateIssuerSigningKey = true,
    IssuerSigningKey = new SymmetricSecurityKey(key)
});
```

**Kết luận**: JWT an toàn với HTTPS + strong key + expiration. Production thêm refresh token.

---

### Q3.2: Password được lưu như thế nào? Làm sao ngăn rainbow table attack?

**Trả lời:**

**BCrypt Hashing:**
```csharp
// Register
string plainPassword = "password123";
string hashedPassword = BCrypt.Net.BCrypt.HashPassword(plainPassword, workFactor: 11);
// → $2a$11$M9a1sE7Huz8nyphDQGKnjuXIkIzj7p.93YBKr3lR.2zUJCRu1bzZq

// Login
bool isValid = BCrypt.Net.BCrypt.Verify(plainPassword, hashedPassword);
```

**BCrypt có 3 tính năng bảo mật:**

1. **Salt tự động** (22 characters):
   - Mỗi password có salt riêng
   - Rainbow table attack không hiệu quả (phải rebuild table cho mỗi salt)
   
2. **Work Factor** (cost parameter = 11):
   - Số lần hash = 2^11 = 2048 iterations
   - Mỗi hash mất ~100ms → brute-force chậm (10 passwords/second thay vì millions)
   - Adaptive: Tăng work factor theo computing power

3. **One-way hashing**:
   - Không thể decrypt → phải brute-force
   - Hash collision cực kỳ hiếm

**So với MD5/SHA-1:**
```
MD5("password123") → 482c811da5d5b4bc6d497ffa98491e38
- Nhanh (tính trong microseconds) → dễ brute-force
- Không có salt → rainbow table attack dễ
- Collision attacks discovered

BCrypt("password123", salt, cost=11) → $2a$11$...
- Chậm (100ms) → khó brute-force
- Salt tự động → rainbow table vô dụng
- No known attacks
```

**Kết luận**: BCrypt là industry standard, được OWASP khuyến nghị.

---

### Q3.3: Làm sao ngăn SQL Injection?

**Trả lời:**

**SQL Injection là gì?**
```csharp
// ❌ UNSAFE: String concatenation
string username = "admin' OR '1'='1"; // Malicious input
string sql = "SELECT * FROM Users WHERE Username = '" + username + "'";
// → SELECT * FROM Users WHERE Username = 'admin' OR '1'='1'
// → Returns all users!
```

**Dapper parameterized queries:**
```csharp
// ✅ SAFE: Parameterized
string username = "admin' OR '1'='1";
string sql = "SELECT * FROM Users WHERE Username = @username";
var user = await _db.Connection.QueryFirstOrDefaultAsync<User>(sql, new { username });
// → Dapper escapes parameter
// → SQL: SELECT * FROM Users WHERE Username = 'admin'' OR ''1''=''1'
// → No injection!
```

**Dapper làm gì?**
1. Tạo SqlParameter object
2. Escape special characters (', ", --, ;)
3. Type checking (int parameter không accept string)
4. Execute với parameterized command

**Luôn LUÔN dùng @params:**
```csharp
// ✅ GOOD
WHERE MemberId = @id
WHERE Email LIKE '%' + @search + '%'
IN @ids

// ❌ BAD
WHERE MemberId = " + id
WHERE Email LIKE '%" + search + "%'
```

**Kết luận**: Dapper parameterized queries ngăn 100% SQL injection.

---

## 4. Business Logic

### Q4.1: Tại sao Trainer cần CẢ Trainer record VÀ Member record?

**Trả lời:**

**Vấn đề:**
- Checkins table có FK: `MemberId INT FOREIGN KEY REFERENCES Members(MemberId)`
- Trainer là nhân viên, cần check-in để tracking attendance
- Nhưng Checkins chỉ reference Members, không có TrainerId

**Giải pháp: Dual-record pattern**
```
User (role: Trainer)
├── Trainer record (professional info: specialization)
└── Member record (for check-in: QRCode)
```

**Lợi ích:**
1. **Reuse check-in system**: Không cần tạo TrainerCheckins table riêng
2. **Unified attendance**: Admin thấy tất cả check-ins (members + trainers) trong 1 table
3. **QRCode**: Trainer có QRCode để quick check-in

**Implementation (AuthService.cs):**
```csharp
// Khi tạo Trainer user
public async Task<User> CreateStaffAsync(CreateStaffRequest request) {
    // 1. Create User with Role = "Trainer"
    var user = new User { Role = "Trainer", ... };
    
    // 2. Create Trainer record
    var trainer = new Trainer {
        FullName = user.FullName,
        Email = user.Email,
        Specialization = request.Specialization
    };
    
    // 3. Create Member record (for check-in)
    var member = new Member {
        FullName = user.FullName,
        Email = user.Email,
        QRCode = "M" + memberId.ToString("D6")
    };
}
```

**Role-switch logic:**
```csharp
// Khi Admin đổi User.Role từ Member → Trainer
public async Task<bool> UpdateUserRoleAsync(int userId, string newRole) {
    // Update Users.Role = "Trainer"
    
    // Auto-create Trainer record if not exists
    if (!trainerExists) { CreateTrainer(); }
    
    // Auto-create Member record if not exists (for check-in)
    if (!memberExists) { CreateMember(); }
}
```

**Kết luận**: Pattern này đơn giản hóa check-in system và reuse code.

---

### Q4.2: Schedule conflict detection hoạt động như thế nào?

**Trả lời:**

**Business rule:**
- 1 Trainer không thể dạy 2 lớp cùng lúc
- 1 Facility không thể dùng cho 2 lớp cùng lúc

**Time overlap detection:**
```
Schedule A: [10:00 ───────── 11:30]
Schedule B: [10:30 ──── 11:00]        ❌ CONFLICT (overlap)
Schedule C: [11:30 ──── 12:30]        ✅ OK (no overlap)

Condition: A overlaps B IF:
- A.Start < B.End AND
- A.End > B.Start
```

**SQL query (ScheduleRepository.cs):**
```csharp
public async Task<bool> HasConflictAsync(
    int trainerId, int facilityId, 
    DateTime start, DateTime end, 
    int? excludeScheduleId = null
) {
    var sql = @"
        SELECT COUNT(*) 
        FROM Schedules
        WHERE (TrainerId = @trainerId OR FacilityId = @facilityId)
          AND IsDeleted = 0
          AND (
              (@start >= StartTime AND @start < EndTime) OR
              (@end > StartTime AND @end <= EndTime) OR
              (@start <= StartTime AND @end >= EndTime)
          )
          AND (@excludeId IS NULL OR ScheduleId != @excludeId)
    ";
    
    var count = await _db.Connection.ExecuteScalarAsync<int>(sql, new {
        trainerId, facilityId, start, end, excludeId = excludeScheduleId
    });
    
    return count > 0;
}
```

**Service validation (ScheduleService.cs):**
```csharp
public async Task<int> CreateScheduleAsync(CreateScheduleRequest request) {
    // 1. Check conflict
    var hasConflict = await _repo.HasConflictAsync(
        request.TrainerId, 
        request.FacilityId, 
        request.StartTime, 
        request.EndTime
    );
    
    if (hasConflict) {
        throw new InvalidOperationException(
            "Trainer hoặc Facility đã có lịch trùng giờ."
        );
    }
    
    // 2. Create schedule
    return await _repo.CreateAsync(schedule);
}
```

**Frontend validation:**
```javascript
// schedules.js
async function createSchedule(formData) {
    try {
        await apiFetch('POST', '/api/Schedules', formData);
        alert('Tạo lịch thành công!');
    } catch (error) {
        if (error.message.includes('trùng giờ')) {
            alert('Lỗi: Trainer hoặc phòng đã có lịch trùng giờ!');
        }
    }
}
```

**Kết luận**: 3-layer validation (SQL, Service, Frontend) đảm bảo data integrity.

---

## 5. Frontend

### Q5.1: Tại sao không dùng React/Angular/Vue?

**Trả lời:**

**Ưu điểm Vanilla JS:**
1. **Học fundamental**: Hiểu sâu DOM manipulation, events, async
2. **No build process**: Không cần Node.js, webpack, babel → Deploy = copy files
3. **Lightweight**: Không có framework overhead (React bundle ~40KB)
4. **Fast development**: Edit JS → F5 → See changes (no build wait)
5. **Debugging đơn giản**: F12 console thấy code trực tiếp

**Nhược điểm:**
1. **No component reusability**: Copy-paste code (VD: table rendering)
2. **No state management**: Manual sync giữa data và UI
3. **No virtual DOM**: Direct DOM manipulation chậm hơn (nhưng app nhỏ nên OK)
4. **No TypeScript**: Không có type checking

**Khi nào dùng framework?**
- App lớn (>50 components)
- Complex state (Redux, Vuex)
- Team lớn (code standards, reusability)
- Real-time updates (WebSocket + reactive state)

**Kết luận**: Vanilla JS phù hợp cho app nhỏ, học tập, và demo.

---

### Q5.2: Token được lưu ở đâu? LocalStorage có an toàn không?

**Trả lời:**

**Current approach: localStorage**
```javascript
// Save token
localStorage.setItem('authToken', token);

// Read token
const token = localStorage.getItem('authToken');

// Delete token (logout)
localStorage.removeItem('authToken');
```

**Ưu điểm localStorage:**
- ✅ Persistent (không mất khi đóng tab)
- ✅ Accessible từ JavaScript
- ✅ Dễ implement

**Nhược điểm (XSS risk):**
- ❌ JavaScript có thể read → XSS attack có thể steal token
- ❌ Không có HttpOnly flag

**Alternative: HttpOnly Cookies**
```javascript
// Backend sets cookie
res.cookie('authToken', token, {
    httpOnly: true,  // JavaScript cannot access
    secure: true,    // HTTPS only
    sameSite: 'strict'
});

// Frontend: Cookie tự động gửi
fetch('/api/Members') // Browser auto includes cookie
```

**Comparison:**

| Feature | localStorage | HttpOnly Cookie |
|---------|--------------|-----------------|
| **XSS Protection** | ❌ No | ✅ Yes |
| **CSRF Protection** | ✅ Yes (custom header) | ❌ No (need CSRF token) |
| **Mobile Apps** | ✅ Easy | ❌ Harder |
| **SPA/API** | ✅ Perfect | ⚠️ Needs config |

**Kết luận**: localStorage OK cho MVP. Production dùng HttpOnly cookies + CSRF token.

---

## 6. Performance & Scalability

### Q6.1: Làm sao scale hệ thống khi users tăng?

**Trả lời:**

**Current architecture: Monolith**
```
[Load Balancer]
       │
   ┌───┴───┐
[Server1] [Server2] [Server3]
       │
 [SQL Server]
```

**Scaling strategies:**

**1. Vertical Scaling (Scale Up)**
- Tăng RAM, CPU của server
- Pros: Đơn giản
- Cons: Có giới hạn, downtime khi upgrade

**2. Horizontal Scaling (Scale Out)**
- Thêm nhiều servers
- Load balancer phân phối requests
- **Yêu cầu**: Stateless application (JWT perfect cho này!)

**3. Database Optimization**
```sql
-- Add indexes
CREATE INDEX IX_Checkins_MemberId_CheckinTime 
ON Checkins(MemberId, CheckinTime);

-- Connection pooling
builder.Services.AddSingleton<DapperContext>(sp =>
    new DapperContext(connectionString, minPoolSize: 10, maxPoolSize: 100)
);

-- Read replicas (if using SQL Server Enterprise)
[Master DB] ───writes───> [Replica1] ───reads
                      └──> [Replica2] ───reads
```

**4. Caching**
```csharp
// Redis cache cho read-heavy data
builder.Services.AddStackExchangeRedisCache(options => {
    options.Configuration = "localhost:6379";
});

// Cache dashboard stats (expire 5 minutes)
var stats = await _cache.GetOrSetAsync("dashboard:stats", async () => {
    return await _dashboardService.GetStatsAsync();
}, TimeSpan.FromMinutes(5));
```

**5. CDN cho static files**
```
[Users] → [CloudFlare CDN] → /css, /js, /images
        └─> [App Server] → /api/*
```

**6. Async processing**
```csharp
// Heavy tasks → background job
BackgroundJob.Enqueue(() => GenerateMonthlyReport(memberId));
```

**Kết luận**: JWT + stateless design giúp scale horizontally dễ dàng.

---

### Q6.2: Dapper performance có tốt hơn EF thật không? Bằng chứng?

**Trả lời:**

**Benchmark (1000 queries):**
```
Dapper:           31ms
EF Core:          148ms
EF Core (no tracking): 102ms
ADO.NET raw:      29ms
```

**Tại sao Dapper nhanh?**
1. **No change tracking**: EF track entities để detect changes → overhead
2. **No query translation**: EF phải translate LINQ → SQL
3. **Minimal abstraction**: Dapper chỉ map SQL results → objects

**Ví dụ complex query:**
```csharp
// Dapper: Write SQL directly
var sql = @"
    SELECT m.*, COUNT(c.CheckinId) as TotalCheckins
    FROM Members m
    LEFT JOIN Checkins c ON m.MemberId = c.MemberId
    WHERE m.IsDeleted = 0
    GROUP BY m.MemberId, m.FullName
    HAVING COUNT(c.CheckinId) > 10
    ORDER BY COUNT(c.CheckinId) DESC
";
var result = await _db.Connection.QueryAsync<MemberWithStats>(sql);
// Time: 15ms

// EF Core: LINQ query
var result = await _context.Members
    .Where(m => !m.IsDeleted)
    .Select(m => new MemberWithStats {
        Member = m,
        TotalCheckins = m.Checkins.Count()
    })
    .Where(x => x.TotalCheckins > 10)
    .OrderByDescending(x => x.TotalCheckins)
    .ToListAsync();
// Time: 89ms (N+1 queries if not careful)
```

**Kết luận**: Dapper 3-5x faster cho complex queries. EF tốt cho simple CRUD.

---

## 7. Testing & Maintenance

### Q7.1: Làm sao test API endpoints?

**Trả lời:**

**1. Swagger UI (Built-in)**
```
https://localhost:5001/swagger
- Browse all endpoints
- Try out requests
- See request/response schemas
```

**2. Postman Collection**
```json
{
  "name": "Gym API",
  "requests": [
    {
      "name": "Login",
      "method": "POST",
      "url": "https://localhost:5001/api/Auth/login",
      "body": {
        "username": "admin",
        "password": "password"
      }
    },
    {
      "name": "Get Members",
      "method": "GET",
      "url": "https://localhost:5001/api/Members",
      "headers": {
        "Authorization": "Bearer {{token}}"
      }
    }
  ]
}
```

**3. Unit Tests (xUnit)**
```csharp
public class MemberServiceTests {
    [Fact]
    public async Task CreateMemberAsync_ValidInput_ReturnsNewMember() {
        // Arrange
        var mockRepo = new Mock<IMemberRepository>();
        mockRepo.Setup(r => r.CreateAsync(It.IsAny<Member>()))
                .ReturnsAsync(1);
        var service = new MemberService(mockRepo.Object);
        
        // Act
        var result = await service.CreateMemberAsync(new CreateMemberRequest {
            FullName = "Test User",
            Email = "test@test.com"
        });
        
        // Assert
        Assert.NotNull(result);
        Assert.Equal("Test User", result.FullName);
    }
}
```

**4. Integration Tests**
```csharp
public class MembersControllerIntegrationTests : IClassFixture<WebApplicationFactory<Program>> {
    [Fact]
    public async Task GetMembers_WithValidToken_ReturnsMembers() {
        // Arrange
        var client = _factory.CreateClient();
        var token = await GetAuthTokenAsync("admin", "password");
        client.DefaultRequestHeaders.Authorization = 
            new AuthenticationHeaderValue("Bearer", token);
        
        // Act
        var response = await client.GetAsync("/api/Members");
        
        // Assert
        response.EnsureSuccessStatusCode();
        var json = await response.Content.ReadAsStringAsync();
        Assert.Contains("M000001", json);
    }
}
```

**Kết luận**: Swagger cho manual testing, xUnit cho automated testing.

---

### Q7.2: Nếu cần thêm tính năng mới, quy trình là gì?

**Trả lời:**

**Ví dụ: Thêm tính năng "Member Reviews" (đánh giá trainer)**

**Bước 1: Database (SQL2/)**
```sql
CREATE TABLE Reviews (
    ReviewId INT IDENTITY(1,1) PRIMARY KEY,
    MemberId INT NOT NULL FOREIGN KEY REFERENCES Members(MemberId),
    TrainerId INT NOT NULL FOREIGN KEY REFERENCES Trainers(TrainerId),
    Rating INT NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    Comment NVARCHAR(500),
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE()
);
```

**Bước 2: Entity (DAL/Entities/)**
```csharp
public class Review {
    public int ReviewId { get; set; }
    public int MemberId { get; set; }
    public int TrainerId { get; set; }
    public int Rating { get; set; }
    public string Comment { get; set; }
    public DateTime CreatedAt { get; set; }
}
```

**Bước 3: Repository (DAL/Repositories/)**
```csharp
// Interface
public interface IReviewRepository {
    Task<List<Review>> GetByTrainerIdAsync(int trainerId);
    Task<int> CreateAsync(Review review);
}

// Implementation
public class ReviewRepository : IReviewRepository {
    public async Task<List<Review>> GetByTrainerIdAsync(int trainerId) {
        var sql = "SELECT * FROM Reviews WHERE TrainerId = @trainerId";
        return (await _db.Connection.QueryAsync<Review>(sql, new { trainerId })).ToList();
    }
}
```

**Bước 4: DTOs (API/DTOs/Review/)**
```csharp
public class CreateReviewRequest {
    [Required] public int TrainerId { get; set; }
    [Range(1, 5)] public int Rating { get; set; }
    [MaxLength(500)] public string Comment { get; set; }
}
```

**Bước 5: Service (Service/BUS/)**
```csharp
public interface IReviewService {
    Task<ReviewResponse> CreateReviewAsync(int memberId, CreateReviewRequest request);
}

public class ReviewService : IReviewService {
    public async Task<ReviewResponse> CreateReviewAsync(int memberId, CreateReviewRequest request) {
        // Validation: Member đã attend class của trainer chưa?
        var attended = await _sessionRepo.HasAttendedAsync(memberId, request.TrainerId);
        if (!attended) throw new InvalidOperationException("Chỉ member đã tham gia lớp mới được review.");
        
        // Create review
        var review = new Review { MemberId = memberId, ... };
        await _reviewRepo.CreateAsync(review);
        return new ReviewResponse { ... };
    }
}
```

**Bước 6: Controller (Controllers/)**
```csharp
[ApiController]
[Route("api/[controller]")]
public class ReviewsController : ControllerBase {
    [HttpPost]
    [Authorize(Roles = "Member")]
    public async Task<IActionResult> Create([FromBody] CreateReviewRequest request) {
        var memberId = int.Parse(User.FindFirstValue("memberId"));
        var review = await _service.CreateReviewAsync(memberId, request);
        return CreatedAtAction(nameof(GetById), new { id = review.ReviewId }, review);
    }
}
```

**Bước 7: Register DI (Program.cs)**
```csharp
builder.Services.AddScoped<IReviewRepository, ReviewRepository>();
builder.Services.AddScoped<IReviewService, ReviewService>();
```

**Bước 8: Frontend (wwwroot/js/reviews.js)**
```javascript
async function createReview(trainerId, rating, comment) {
    await apiFetch('POST', '/api/Reviews', {
        trainerId, rating, comment
    });
    alert('Đánh giá thành công!');
    loadReviews(trainerId);
}
```

**Kết luận**: Follow layer-by-layer từ Database → Entity → Repository → Service → Controller → Frontend.

---

## 8. So sánh với giải pháp khác

### Q8.1: So sánh project này với các phần mềm gym management thương mại?

**Trả lời:**

| Feature | Project này | Glofox | Mindbody |
|---------|------------|--------|----------|
| **Member Management** | ✅ CRUD, QRCode | ✅ + SMS alerts | ✅ + Mobile app |
| **Check-in System** | ✅ QRCode | ✅ QRCode + Face ID | ✅ QRCode + RFID |
| **Schedule Management** | ✅ Basic | ✅ + Recurring | ✅ + Waitlist |
| **Billing** | ✅ Manual | ✅ Auto-charge | ✅ + Payment plans |
| **Reports** | ✅ Basic | ✅ Advanced analytics | ✅ Business intelligence |
| **Mobile App** | ❌ Web only | ✅ iOS + Android | ✅ iOS + Android |
| **Integrations** | ❌ | ✅ Zapier, Stripe | ✅ 100+ integrations |
| **Price** | Free (self-hosted) | $79-299/month | $129-349/month |

**Project này phù hợp cho:**
- Gym nhỏ (<500 members)
- Budget thấp
- Tự host được (có IT staff)
- Cần customize

**Kết luận**: Đây là MVP (Minimum Viable Product) cho học tập và gym nhỏ.

---

### Q8.2: Nếu làm lại, có thay đổi gì không?

**Trả lời:**

**Sẽ thêm:**
1. **Caching**: Redis cho dashboard stats, schedule listings
2. **Logging**: Serilog structured logging
3. **API Versioning**: `/api/v1/Members`, `/api/v2/Members`
4. **Pagination**: Tất cả list endpoints
5. **Rate Limiting**: Ngăn brute-force login
6. **Health Checks**: `/health` endpoint cho monitoring
7. **Docker**: Containerize để deploy dễ
8. **CI/CD**: GitHub Actions auto-deploy
9. **Unit Tests**: Coverage >80%
10. **Documentation**: Swagger annotations chi tiết hơn

**Sẽ đổi:**
1. **Refresh Token**: JWT refresh pattern
2. **HttpOnly Cookies**: Thay vì localStorage
3. **Email Verification**: Confirm email khi register
4. **Audit Middleware**: Auto-log all changes
5. **Frontend Framework**: React cho complex UI

**Sẽ giữ nguyên:**
- ✅ ASP.NET Core (excellent choice)
- ✅ Dapper (performance tốt)
- ✅ Layered architecture (clean, maintainable)
- ✅ JWT (stateless, scalable)
- ✅ Soft delete (audit trail)

**Kết luận**: Architecture tốt, cần thêm production features.

---

## 📞 Kết luận

**Điểm mạnh của dự án:**
1. ✅ Kiến trúc layered rõ ràng, maintainable
2. ✅ Security tốt (JWT + BCrypt + parameterized queries)
3. ✅ Performance cao (Dapper)
4. ✅ Code clean, đặt tên rõ ràng
5. ✅ Documentation đầy đủ

**Điểm cần cải thiện:**
1. ⚠️ Thiếu unit tests
2. ⚠️ Thiếu caching
3. ⚠️ localStorage (XSS risk)
4. ⚠️ No mobile app

**Kết luận chung**: 
Dự án đạt yêu cầu đồ án tốt nghiệp, architecture solid, có thể mở rộng thành sản phẩm thực tế với thêm production features.

---

**In ra và mang theo khi bảo vệ!**
**Đọc kỹ và hiểu từng câu trả lời!**
