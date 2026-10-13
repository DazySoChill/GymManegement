# TÀI LIỆU KIẾN TRÚC HỆ THỐNG - GYM MANAGEMENT

## 📚 Danh sách tài liệu

Đây là bộ tài liệu phân tích chi tiết kiến trúc và cách vận hành của hệ thống Gym Management System, được chuẩn bị cho việc bảo vệ đồ án tốt nghiệp.

### 📖 Tài liệu hiện có

1. **[01-TONG-QUAN-HE-THONG.md](./01-TONG-QUAN-HE-THONG.md)** ✅
   - Giới thiệu dự án
   - Công nghệ sử dụng (ASP.NET Core, Dapper, Vanilla JS, JWT, BCrypt)
   - Tại sao chọn mỗi công nghệ?
   - Kiến trúc tổng quan (Layered Architecture)
   - Cấu trúc thư mục project
   - Dependency Injection
   - Configuration & Build

2. **[02-API-ROUTES-DAY-DU.md](./02-API-ROUTES-DAY-DU.md)** ✅  
   - Danh sách đầy đủ **TẤT CẢ** API endpoints
   - Từng controller chi tiết:
     - AuthController (8 endpoints)
     - MembersController  
     - CheckinsController
     - SchedulesController
     - DashboardController
     - Và 6 controllers còn lại
   - Request/Response DTOs
   - Logic flow từng endpoint
   - SQL queries minh họa
   - HTTP status codes

3. **[03-DATA-FLOW-CHI-TIET.md](./03-DATA-FLOW-CHI-TIET.md)** ✅
   - Tracing request-response flow chi tiết
   - 5 ví dụ cụ thể với step-by-step:
     - **Login flow** (11 steps từ click button đến dashboard)
     - **Check-in flow** (8 steps với JWT validation)
     - **Create schedule flow** (7 steps với conflict detection)
     - Register for session flow
     - Generate report flow
   - Performance analysis (timing breakdown)
   - Common patterns

4. **[CAU-HOI-PHAN-BIEN.md](./CAU-HOI-PHAN-BIEN.md)** ✅
   - **20+ câu hỏi thường gặp** khi bảo vệ
   - 8 chủ đề:
     - Công nghệ & Kiến trúc
     - Database & ORM
     - Security & Authentication
     - Business Logic
     - Frontend
     - Performance & Scalability
     - Testing & Maintenance
     - So sánh với giải pháp khác
   - Câu trả lời chi tiết với code examples
   - So sánh Dapper vs EF, ASP.NET vs Node.js

5. **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** ✅
   - **Tham khảo nhanh** cho bảo vệ
   - Statistics (thuộc lòng!)
   - 12 tables summary
   - 3 roles & permissions
   - Key flows (Login, Check-in, Schedule)
   - JWT structure, BCrypt example
   - Layered architecture diagram
   - Design patterns
   - FAQs ngắn gọn
   - **In ra mang theo khi bảo vệ!**

### 📝 Tài liệu bổ sung (Có thể thêm nếu cần)

6. **04-DATABASE-SCHEMA.md** (Tùy chọn)
   - Chi tiết 12 tables với tất cả columns
   - ER diagram (ASCII art)
   - Relationships diagram
   - Indexes và foreign keys
   - Soft delete pattern chi tiết

7. **05-FRONTEND-DEEP-DIVE.md** (Tùy chọn)
   - SPA architecture chi tiết
   - apiFetch() implementation
   - Role-based navigation
   - Excel export với SheetJS

---

## 🎯 Cách sử dụng tài liệu này

### Cho việc bảo vệ đồ án

**Đọc theo thứ tự:**
1. File 01 (Tổng quan) → Hiểu toàn cảnh hệ thống
2. File 02 (API Routes) → Nắm rõ từng endpoint
3. File 03 (Data Flow) → Hiểu luồng dữ liệu
4. File 04 (Database) → Hiểu schema và quan hệ
5. File 05 (Security) → Hiểu authentication/authorization
6. File 06 (Frontend) → Hiểu cách frontend gọi API
7. File 07 (Q&A) → Chuẩn bị trả lời câu hỏi

**Tập trung vào:**
- ✅ File 01: Technology choices - tại sao chọn mỗi công nghệ?
- ✅ File 02: API routes - phải thuộc tất cả endpoints
- ✅ File 03: Data flow - tracing từ click button đến database
- ✅ File 04: Database schema - giải thích relationships
- ✅ File 05: Security - JWT, BCrypt, authorization
- ✅ File 07: Q&A - câu trả lời cho mọi câu hỏi có thể gặp

### Các câu hỏi thường gặp khi bảo vệ

**1. Công nghệ**
- "Tại sao chọn ASP.NET Core?" → File 01
- "Tại sao dùng Dapper thay vì Entity Framework?" → File 01
- "Tại sao không dùng React/Vue?" → File 01

**2. Kiến trúc**
- "Giải thích kiến trúc layered?" → File 01
- "Dependency Injection hoạt động như thế nào?" → File 01

**3. API**
- "Có bao nhiêu endpoints?" → File 02 (đếm được!)
- "Giải thích login flow?" → File 02 + File 03
- "Authorization hoạt động như thế nào?" → File 02 + File 05

**4. Database**
- "Có bao nhiêu bảng?" → File 04 (12 tables)
- "Giải thích quan hệ giữa Trainer và Member?" → File 04
- "Soft delete là gì?" → File 04

**5. Security**
- "JWT có an toàn không?" → File 05
- "Làm sao ngăn SQL injection?" → File 05
- "Password được lưu như thế nào?" → File 05 (BCrypt)

**6. Frontend**
- "Frontend gọi API như thế nào?" → File 06
- "Token được lưu ở đâu?" → File 06 (localStorage)
- "Role-based UI hoạt động sao?" → File 06

---

## 📊 Quick Facts (Thuộc lòng!)

**Technology Stack:**
- Backend: ASP.NET Core 6.0
- ORM: Dapper (micro-ORM)
- Database: SQL Server
- Frontend: Vanilla JavaScript
- Auth: JWT (JSON Web Tokens)
- Password: BCrypt (workFactor 11)

**Architecture:**
- Layered/N-tier: Controllers → Services → Repositories → Database
- Pattern: Repository pattern, DTO pattern, Dependency Injection

**Statistics:**
- Controllers: 12 controllers
- API Endpoints: ~60 endpoints
- Tables: 12 tables
- Stored Procedures: 97 procedures
- Roles: 3 roles (Admin, Trainer, Member)

**Key Features:**
- Authentication & Authorization (JWT + Role-based)
- Member Management (CRUD + QR Code)
- Check-in System (QR Code based)
- Schedule Management (Conflict detection)
- Billing System (Memberships, Invoices, Payments)
- Reports & Dashboard (Role-specific stats)
- Export to Excel

---

## 🔑 Test Credentials

```
Admin:
- Username: admin
- Password: password
- Role: Admin (full access)

Trainer:
- Username: trainer1
- Password: password
- Role: Trainer (create schedules, check-in)

Member:
- Username: member01
- Password: password
- Role: Member (register sessions, check-in)
```

---

## 🚀 Demo Flow (Cho bảo vệ)

### 1. Login Demo
```
1. Mở https://localhost:5001
2. Login admin/password
3. F12 → Network tab: Xem POST /api/Auth/login
4. Application tab → Local Storage: Xem authToken
5. Giải thích JWT structure (Header.Payload.Signature)
```

### 2. Member CRUD Demo
```
1. Navigate: Members page
2. Create new member → F12 Network: POST /api/Members
3. Edit member → PUT /api/Members/{id}
4. Show validation (email uniqueness)
5. Show soft delete (IsDeleted = 1)
```

### 3. Check-in Demo
```
1. Login member01/password
2. Navigate: Check-ins
3. Click "Check In" → POST /api/Checkins
4. Show memberId from JWT token
5. Switch to Admin → show check-in list (sorted ASC)
```

### 4. Schedule Demo
```
1. Login trainer1/password
2. Create schedule → Show conflict detection
3. Try creating schedule for another trainer → Show 403 Forbidden
4. Login member01 → Show all schedules but can't edit
```

### 5. Report Demo
```
1. Login admin/password
2. Dashboard → Show statistics
3. Members → Export Excel
4. Show EPPlus library usage
```

---

## 📱 Contacts & Support

Nếu có thắc mắc về tài liệu này, tham khảo thêm:
- Source code: Controllers/, Service/, DAL/
- SQL scripts: SQL2/
- Frontend: wwwroot/js/
- Configuration: appsettings.json

---

**Cập nhật**: 2025-01-18  
**Phiên bản**: 1.0  
**Trạng thái**: ✅ HOÀN THÀNH - 5 files core done (100KB documentation)

### 📊 Thống kê tài liệu:
- **Tổng pages**: ~100 trang A4
- **Tổng words**: ~25,000 từ
- **Tổng size**: ~100 KB
- **Topics covered**: 60+ topics
- **Code examples**: 80+ examples
- **Questions answered**: 20+ Q&A
