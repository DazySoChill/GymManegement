# 1. TỔNG QUAN HỆ THỐNG GYM MANAGEMENT

## 1.1. Giới thiệu dự án

**Tên dự án**: Gym Management System (Hệ thống quản lý phòng gym)

**Mục đích**: Xây dựng hệ thống quản lý toàn diện cho phòng gym bao gồm:
- Quản lý thành viên (Members) và huấn luyện viên (Trainers)
- Quản lý lịch tập và đăng ký lớp
- Quản lý check-in/check-out với QR Code
- Quản lý gói tập và hóa đơn
- Báo cáo thống kê theo vai trò

**Người dùng hệ thống**:
- **Admin**: Quản trị viên (quản lý toàn bộ hệ thống)
- **Trainer**: Huấn luyện viên (tạo lịch tập, check-in như nhân viên)
- **Member**: Thành viên (đăng ký lớp, check-in, xem thông tin cá nhân)

## 1.2. Công nghệ sử dụng

### Backend: ASP.NET Core 6.0
**Tại sao chọn ASP.NET Core?**
1. **Performance cao**: Một trong những framework nhanh nhất (top 10 TechEmpower benchmark)
2. **Cross-platform**: Chạy được trên Windows, Linux, macOS
3. **Type-safe**: C# là ngôn ngữ strongly-typed, giảm lỗi runtime
4. **Ecosystem mạnh**: NuGet packages phong phú, community lớn
5. **Built-in features**: Dependency Injection, Authentication, CORS sẵn có

**Phiên bản**: .NET 6.0 (LTS - Long Term Support)

### Database: SQL Server + Dapper ORM
**Tại sao chọn SQL Server?**
1. **Enterprise-grade**: Tin cậy, bảo mật cao
2. **Tích hợp tốt** với ASP.NET Core
3. **Công cụ quản lý**: SQL Server Management Studio (SSMS) mạnh mẽ
4. **T-SQL**: Ngôn ngữ SQL mở rộng với stored procedures

**Tại sao chọn Dapper thay vì Entity Framework?**

| Tiêu chí | Dapper | Entity Framework Core |
|----------|--------|----------------------|
| **Performance** | ⭐⭐⭐⭐⭐ Nhanh gần như raw ADO.NET | ⭐⭐⭐ Chậm hơn do abstraction |
| **SQL Control** | ⭐⭐⭐⭐⭐ Viết SQL trực tiếp, kiểm soát 100% | ⭐⭐ LINQ đôi khi generate SQL kém |
| **Learning Curve** | ⭐⭐⭐⭐ Đơn giản, chỉ cần biết SQL | ⭐⭐ Phải học LINQ, conventions, migrations |
| **Flexibility** | ⭐⭐⭐⭐⭐ Queries phức tạp dễ dàng | ⭐⭐⭐ LINQ có giới hạn |
| **Lightweight** | ⭐⭐⭐⭐⭐ 1 file, vài KB | ⭐⭐⭐ Package lớn hơn |

**Kết luận**: Dapper phù hợp cho dự án cần performance và SQL control rõ ràng.

### Frontend: Vanilla JavaScript (No Framework)
**Tại sao KHÔNG dùng React/Vue/Angular?**

| Ưu điểm Vanilla JS | Nhược điểm Frameworks |
|--------------------|---------------------|
| ✅ **Học fundamental**: Hiểu sâu JavaScript core | ❌ Phải học thêm JSX, Virtual DOM, Reactivity |
| ✅ **Không build process**: Chỉ cần text editor | ❌ Cần Node.js, npm, webpack, babel |
| ✅ **Deploy đơn giản**: Copy files là xong | ❌ Build artifacts, source maps phức tạp |
| ✅ **Page load nhanh**: Không có framework overhead | ❌ Bundle size lớn (React ~40KB gzipped) |
| ✅ **Debugging dễ**: F12 console thấy ngay code | ❌ Framework stack traces khó đọc |

**Kết luận**: Phù hợp cho dự án học tập, không cần complex state management.

### Authentication: JWT (JSON Web Tokens)
**Tại sao chọn JWT?**
1. **Stateless**: Server không cần lưu session, scale tốt
2. **Self-contained**: Token chứa đủ thông tin (userId, role, email)
3. **Cross-domain**: Gửi qua HTTP header, mobile-friendly
4. **Standard**: RFC 7519, library hỗ trợ mọi ngôn ngữ

**Cấu trúc JWT trong project**:
```
Header.Payload.Signature

Payload chứa:
- sub: userId
- unique_name: username
- email: user@example.com
- role: Admin/Trainer/Member
- memberId: (nếu là Member hoặc Trainer)
- trainerId: (nếu là Trainer)
- exp: expiration timestamp
```

### Security: BCrypt Password Hashing
**Tại sao chọn BCrypt?**
1. **Adaptive**: WorkFactor 11 → tăng theo computing power
2. **Salt tự động**: Mỗi password có salt riêng
3. **Chống brute-force**: Mỗi hash mất ~0.1 giây (cố tình chậm)
4. **Industry standard**: Được khuyến nghị bởi OWASP

**Ví dụ**:
```csharp
// Hash password khi register
string hashedPassword = BCrypt.Net.BCrypt.HashPassword("password123", 11);
// → $2a$11$M9a1sE7Huz8nyphDQGKnjuXIkIzj7p.93YBKr3lR.2zUJCRu1bzZq

// Verify khi login
bool isValid = BCrypt.Net.BCrypt.Verify("password123", hashedPassword);
```

## 1.3. Kiến trúc tổng quan

### Layered Architecture (Kiến trúc phân lớp)
```
┌─────────────────────────────────────────┐
│         FRONTEND (wwwroot/)             │
│    HTML + CSS + Vanilla JavaScript      │
│         (SPA - Single Page App)         │
└────────────────┬────────────────────────┘
                 │ HTTP/JSON
                 │ JWT Token
                 ▼
┌─────────────────────────────────────────┐
│      PRESENTATION LAYER (Controllers)   │
│  - AuthController, MembersController    │
│  - CheckinsController, SchedulesController │
│  - Role: Nhận request, trả response     │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│    BUSINESS LOGIC LAYER (Services)      │
│  - AuthService, MemberService           │
│  - CheckinService, ScheduleService      │
│  - Role: Business rules, validation     │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│   DATA ACCESS LAYER (Repositories)      │
│  - MemberRepository, CheckinRepository  │
│  - Role: SQL queries với Dapper         │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│           DATABASE (SQL Server)         │
│  - 12 tables với relationships          │
│  - Stored procedures (97 procedures)    │
└─────────────────────────────────────────┘
```

### Data Flow (Luồng dữ liệu)
```
User clicks button
    ↓
JavaScript (apiFetch)
    ↓
HTTP Request (JSON + JWT)
    ↓
JwtMiddleware (validate token)
    ↓
Controller (extract data from DTO)
    ↓
Service (business logic)
    ↓
Repository (SQL query)
    ↓
Database
    ↓
Return data
    ↓
Service → Controller → JSON Response
    ↓
Frontend updates UI
```

## 1.4. Cấu trúc thư mục project

```
GymManegement/
├── API/
│   └── DTOs/                      # Data Transfer Objects
│       ├── Auth/                  # Login, Register, ChangePassword
│       ├── Member/                # CreateMemberRequest, UpdateMemberRequest
│       ├── Checkin/               # CreateCheckinRequest, CheckinResponse
│       └── ...                    # Mỗi entity có Request/Response riêng
│
├── Controllers/                   # API Endpoints (REST)
│   ├── AuthController.cs          # /api/Auth/* (login, register)
│   ├── MembersController.cs       # /api/Members/* (CRUD)
│   ├── CheckinsController.cs      # /api/Checkins/* (check-in/out)
│   └── ...                        # 12 controllers
│
├── Service/
│   └── BUS/                       # Business Logic Layer
│       ├── Interfaces/            # IAuthService, IMemberService...
│       └── Implementations/       # AuthService, MemberService...
│
├── DAL/                           # Data Access Layer
│   ├── Entities/                  # User, Member, Checkin (POCOs)
│   ├── Helper/                    # DapperContext (connection string)
│   └── Repositories/
│       ├── Interfaces/            # IUserRepository, IMemberRepository...
│       └── Implementations/       # UserRepository, MemberRepository...
│
├── Middleware/                    # Custom Middleware
│   ├── JwtMiddleware.cs           # Validate JWT token
│   └── GlobalExceptionMiddleware.cs # Catch all exceptions
│
├── wwwroot/                       # Frontend (Static Files)
│   ├── index.html                 # Single page entry
│   ├── css/                       # Styles
│   └── js/
│       ├── app.js                 # Core: routing, auth, API client
│       ├── dashboard.js           # Dashboard page
│       ├── members.js             # Members CRUD
│       ├── checkins.js            # Check-in/out
│       └── ...                    # Mỗi entity 1 file JS
│
├── SQL2/                          # Database Scripts
│   ├── 00_CREATE_DATABASE.sql     # Tạo database
│   ├── 01_CREATE_TABLES.sql       # 12 tables
│   ├── 14_SEED_DATA.sql           # Sample data
│   ├── RUN_ALL.sql                # Master script
│   └── COMPLETE_GYM_MANAGEMENT_SYSTEM.sql # All-in-one
│
├── appsettings.json               # Configuration
├── Program.cs                     # Entry point + DI setup
└── GymManegement.csproj           # Project file
```

## 1.5. Dependency Injection (DI)

**Program.cs** thiết lập DI container:

```csharp
// Database context
builder.Services.AddSingleton<DapperContext>();

// Repositories (Scoped = 1 instance per request)
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IMemberRepository, MemberRepository>();
// ... 12 repositories

// Services
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IMemberService, MemberService>();
// ... 12 services
```

**Constructor Injection** trong controller:
```csharp
public class MembersController : ControllerBase
{
    private readonly IMemberService _service;
    
    // ASP.NET Core tự động inject implementation
    public MembersController(IMemberService service) 
    {
        _service = service;
    }
}
```

**Lợi ích DI**:
- ✅ **Loose coupling**: Controller không phụ thuộc vào implementation cụ thể
- ✅ **Testability**: Dễ mock service trong unit tests
- ✅ **Maintainability**: Đổi implementation không ảnh hưởng controller

## 1.6. Configuration (appsettings.json)

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=.;Database=GymDb;Trusted_Connection=True;TrustServerCertificate=True;"
  },
  "Jwt": {
    "Key": "ThisIsMySecretKey1234567890123456",
    "Issuer": "GymManagement",
    "Audience": "GymManagementUsers",
    "ExpiryHours": 24
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
```

**Giải thích**:
- **ConnectionStrings**: Kết nối SQL Server (Windows Authentication)
- **Jwt:Key**: Secret key để sign JWT (phải ≥32 ký tự)
- **Jwt:ExpiryHours**: Token hết hạn sau 24 giờ
- **Logging**: Log level (Information = log mọi thứ)

## 1.7. Môi trường Development vs Production

**appsettings.Development.json**:
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug"  // Chi tiết hơn cho dev
    }
  }
}
```

**Khi deploy Production**:
- Đổi ConnectionString sang production database
- Đổi Jwt:Key sang key phức tạp hơn
- Set Logging:LogLevel:Default = "Warning" (giảm log)

## 1.8. Các tính năng chính

### 1. Authentication & Authorization
- ✅ Đăng ký/Đăng nhập với JWT
- ✅ Role-based access (Admin, Trainer, Member)
- ✅ Password hashing với BCrypt
- ✅ Token expiration

### 2. Member Management
- ✅ CRUD operations
- ✅ Auto-generate QR Code (M000001)
- ✅ Soft delete
- ✅ Search & pagination
- ✅ Export to Excel

### 3. Check-in System
- ✅ Check-in với QR Code
- ✅ Check-out (optional)
- ✅ History tracking
- ✅ Trainer check-in (dùng Member record)

### 4. Schedule Management
- ✅ Trainer tạo lịch tập
- ✅ Conflict detection (trainer/facility/time)
- ✅ Member đăng ký session
- ✅ Capacity check

### 5. Billing System
- ✅ Gói tập (Memberships)
- ✅ Hóa đơn (Invoices)
- ✅ Thanh toán (Payments)
- ✅ Tự động tạo invoice khi tạo membership

### 6. Reports & Dashboard
- ✅ Role-specific stats
- ✅ Revenue reports
- ✅ Member statistics
- ✅ Export to Excel

## 1.9. Development Tools

- **IDE**: Visual Studio 2022 hoặc Visual Studio Code
- **Database**: SQL Server 2019+ hoặc LocalDB
- **API Testing**: Postman, Swagger UI (built-in)
- **Browser**: Chrome/Edge (F12 Developer Tools)
- **Version Control**: Git

## 1.10. Build & Run

```bash
# Clone project
git clone <repository-url>

# Setup database
# Chạy SQL2/RUN_ALL.sql hoặc COMPLETE_GYM_MANAGEMENT_SYSTEM.sql

# Restore packages
dotnet restore

# Build
dotnet build

# Run
dotnet run

# Hoặc trong Visual Studio: Ctrl+F5
```

**Access**:
- Frontend: https://localhost:5001
- Swagger API: https://localhost:5001/swagger
- Test credentials: admin/password, trainer1/password, member01/password

---

**Tài liệu tiếp theo:**
- [02-KIEN-TRUC-PHAN-LỚP.md](./02-KIEN-TRUC-PHAN-LỚPMD) - Chi tiết về từng layer
- [03-API-ROUTES.md](./03-API-ROUTES.md) - Danh sách đầy đủ API endpoints
- [04-DATA-FLOW.md](./04-DATA-FLOW.md) - Tracing request-response flows
