# 2. API ROUTES - DANH SÁCH ĐẦY ĐỦ

## Mục lục
- [AuthController](#authcontroller) - Authentication & User Management
- [MembersController](#memberscontroller) - Member CRUD
- [TrainersController](#trainerscontroller) - Trainer CRUD  
- [SchedulesController](#schedulescontroller) - Schedule Management
- [CheckinsController](#checkinscontroller) - Check-in/out System
- [MembershipsController](#membershipscontroller) - Membership Packages
- [InvoicesController](#invoicescontroller) - Billing & Invoices
- [PaymentsController](#paymentscontroller) - Payment Processing
- [FacilitiesController](#facilitiescontroller) - Facility Management
- [SessionsController](#sessionscontroller) - Class Registration
- [DashboardController](#dashboardcontroller) - Statistics & Reports

---

## AuthController

**Base Route**: `/api/Auth`

### 1. POST /api/Auth/login
**Đăng nhập - Trả về JWT token**

```
Authorization: AllowAnonymous (không cần token)
Request Body: LoginRequest
{
  "username": "admin",
  "password": "password"
}

Response: AuthResponse (200 OK)
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "username": "admin",
  "fullName": "Quản Trị Viên",
  "email": "admin@gymmanagement.vn",
  "role": "Admin",
  "memberId": null,
  "expiresAt": "2025-01-19T10:00:00Z"
}

Logic Flow:
1. Tìm user by username: _userRepository.GetByUsernameAsync()
2. Verify password: BCrypt.Net.BCrypt.Verify(password, user.PasswordHash)
3. Check IsActive = true
4. Nếu role = Member/Trainer → lấy memberId từ Members table
5. Generate JWT token với claims (userId, role, memberId, email)
6. Update LastLoginAt
7. Return token + user info

Error Responses:
- 401 Unauthorized: Sai username/password
- 400 BadRequest: Tài khoản chưa kích hoạt
```

### 2. POST /api/Auth/register
**Đăng ký tài khoản mới - Auto tạo Member**

```
Authorization: AllowAnonymous
Request Body: RegisterRequest
{
  "username": "newuser",
  "password": "password123",
  "fullName": "Nguyễn Văn A",
  "email": "nguyenvana@gmail.com"
}

Response: 200 OK
{
  "message": "Đăng ký thành công! Tài khoản đã được kích hoạt và Member được tạo tự động.",
  "user": {
    "userId": 27,
    "username": "newuser",
    "fullName": "Nguyễn Văn A",
    "email": "nguyenvana@gmail.com",
    "role": "Member"
  }
}

Logic Flow:
1. Validate: Check username/email tồn tại chưa
2. Create User với Role = "Member", IsActive = true
3. Hash password: BCrypt.HashPassword(password, workFactor: 11)
4. Insert vào Users table
5. Auto create Member record:
   - FullName, Email từ User
   - Generate QRCode = "M" + MemberId.ToString("D6") (VD: M000027)
6. Return user info

Error Responses:
- 400 BadRequest: Username/Email đã tồn tại
- 400 BadRequest: ModelState invalid (password quá ngắn, email sai format)
```

### 3. POST /api/Auth/create-staff
**Tạo tài khoản Admin hoặc Trainer - Chỉ Admin**

```
Authorization: Authorize(Roles = "Admin")
Request Body: CreateStaffRequest
{
  "username": "trainer6",
  "password": "password123",
  "fullName": "Nguyễn Văn F",
  "email": "nvf@gymmanagement.vn",
  "role": "Trainer",  // "Admin" hoặc "Trainer"
  "specialization": "CrossFit & Strength"  // Chỉ cho Trainer
}

Response: 200 OK
{
  "message": "Tạo tài khoản thành công!",
  "user": { ... }
}

Logic Flow:
1. Check role = "Admin" hoặc "Trainer" (không được "Member")
2. Validate username/email uniqueness
3. Create User với Role = request.Role
4. Nếu Role = "Trainer":
   - Auto create Trainer record (FullName, Email, Specialization)
   - Auto create Member record (để trainer có thể check-in)
   - Generate QRCode cho Member record
5. Return user info

Error Responses:
- 401 Unauthorized: Không phải Admin
- 400 BadRequest: Role không hợp lệ (phải Admin/Trainer)
```

### 4. POST /api/Auth/change-password
**Đổi mật khẩu - Yêu cầu đăng nhập**

```
Authorization: Authorize (phải có token)
Request Body: ChangePasswordRequest
{
  "oldPassword": "password123",
  "newPassword": "newpassword456"
}

Response: 200 OK
{
  "message": "Đổi mật khẩu thành công."
}

Logic Flow:
1. Extract userId from JWT claims (sub claim)
2. Get user from database
3. Verify oldPassword với BCrypt
4. Hash newPassword
5. Update Users.PasswordHash
6. Return success

Error Responses:
- 401 Unauthorized: Token invalid/expired
- 400 BadRequest: Mật khẩu cũ không đúng
```

### 5. GET /api/Auth/users
**Xem danh sách Users - Chỉ Admin**

```
Authorization: Authorize(Roles = "Admin")

Response: 200 OK
[
  {
    "userId": 1,
    "username": "admin",
    "fullName": "Quản Trị Viên",
    "email": "admin@gymmanagement.vn",
    "role": "Admin",
    "isActive": true,
    "lastLoginAt": "2025-01-18T10:00:00",
    "createdAt": "2025-01-01T00:00:00"
  },
  ...
]

Logic Flow:
1. Check role = "Admin"
2. Get all users: _userRepository.GetAllAsync()
3. Filter IsDeleted = 0
4. Order by CreatedAt DESC
5. Return list

Error Responses:
- 401 Unauthorized: Không phải Admin
```

### 6. PUT /api/Auth/users/{id}/active?isActive=true
**Khóa/mở tài khoản - Chỉ Admin**

```
Authorization: Authorize(Roles = "Admin")
Parameters: 
- id: userId (path parameter)
- isActive: true/false (query parameter)

Response: 200 OK
{
  "message": "Đã kích hoạt tài khoản."  // hoặc "Đã khóa tài khoản."
}

Logic Flow:
1. Check role = "Admin"
2. Update Users.IsActive = @isActive WHERE UserId = @id
3. Return success

Error Responses:
- 404 NotFound: User không tồn tại
```

### 7. PUT /api/Auth/users/{id}/role
**Thay đổi vai trò user - Chỉ Admin**

```
Authorization: Authorize(Roles = "Admin")
Request Body: UpdateUserRoleRequest
{
  "role": "Trainer"  // "Admin", "Trainer", hoặc "Member"
}

Response: 200 OK
{
  "message": "Đã thay đổi vai trò thành công."
}

Logic Flow (QUAN TRỌNG - Role-Switch Logic):
1. Check current user != target user (không đổi role chính mình)
2. Update Users.Role = @role
3. **Auto-create missing records**:
   - Nếu newRole = "Trainer" → check Trainer record tồn tại chưa
     - Nếu chưa: create Trainer record
     - Create thêm Member record (để trainer check-in được)
   - Nếu newRole = "Member" → check Member record tồn tại chưa
     - Nếu chưa: create Member record + generate QRCode
4. Return success

Error Responses:
- 400 BadRequest: Không thể đổi role chính mình
- 404 NotFound: User không tồn tại
```

### 8. GET /api/Auth/me
**Lấy thông tin user đang đăng nhập**

```
Authorization: Authorize

Response: 200 OK
{
  "userId": "1",
  "username": "admin",
  "fullName": "Quản Trị Viên",
  "email": "admin@gymmanagement.vn",
  "role": "Admin",
  "memberId": null
}

Logic Flow:
1. Extract claims từ JWT token
2. Return claims as JSON

Không query database!
```

---

## MembersController

**Base Route**: `/api/Members`

### 1. GET /api/Members
**Lấy danh sách members (pagination + search)**

```
Authorization: Authorize
Query Parameters:
- page: 1 (default)
- pageSize: 10 (default)
- search: "" (optional - tìm theo FullName, Email, Phone)

Response: PagedResult<MemberResponse>
{
  "data": [
    {
      "memberId": 1,
      "fullName": "Nguyễn Thị Mai",
      "email": "mai.nguyen@gmail.com",
      "phone": "0912345601",
      "dateOfBirth": "1995-03-15",
      "qrCode": "M000001",
      "createdAt": "2025-01-01T00:00:00"
    },
    ...
  ],
  "pageNumber": 1,
  "pageSize": 10,
  "totalCount": 25,
  "totalPages": 3
}

SQL Query:
SELECT * FROM Members 
WHERE IsDeleted = 0 
  AND (@search IS NULL OR 
       FullName LIKE '%' + @search + '%' OR
       Email LIKE '%' + @search + '%' OR
       Phone LIKE '%' + @search + '%')
ORDER BY CreatedAt DESC
OFFSET (@page - 1) * @pageSize ROWS
FETCH NEXT @pageSize ROWS ONLY
```

### 2. GET /api/Members/{id}
**Lấy member theo ID**

```
Authorization: Authorize
Path Parameter: id (memberId)

Response: MemberResponse (200 OK)

Error Responses:
- 404 NotFound: Member không tồn tại hoặc đã xóa
```

### 3. POST /api/Members
**Tạo member mới - Chỉ Admin**

```
Authorization: Authorize(Roles = "Admin")
Request Body: CreateMemberRequest
{
  "fullName": "Nguyễn Văn B",
  "email": "nvb@gmail.com",
  "phone": "0901234567",
  "dateOfBirth": "1990-01-01"  // optional
}

Response: MemberResponse (201 Created)

Logic Flow:
1. Validate email uniqueness
2. Insert Member record
3. Get newly inserted MemberId
4. Generate QRCode = "M" + MemberId.ToString("D6")
5. Update Member.QRCode
6. Return member

SQL:
INSERT INTO Members (FullName, Email, Phone, DateOfBirth, QRCode, CreatedAt, UpdatedAt, IsDeleted)
OUTPUT INSERTED.MemberId
VALUES (@FullName, @Email, @Phone, @DateOfBirth, 'TEMP', GETDATE(), GETDATE(), 0)

UPDATE Members SET QRCode = 'M' + RIGHT('000000' + CAST(@MemberId AS VARCHAR), 6)
WHERE MemberId = @MemberId
```

### 4. PUT /api/Members/{id}
**Cập nhật member - Chỉ Admin**

```
Authorization: Authorize(Roles = "Admin")
Request Body: UpdateMemberRequest
{
  "fullName": "Nguyễn Văn B Updated",
  "email": "nvb_new@gmail.com",
  "phone": "0909999999",
  "dateOfBirth": "1990-01-01"
}

Response: 200 OK hoặc 204 NoContent

Error Responses:
- 404 NotFound: Member không tồn tại
- 400 BadRequest: Email đã được dùng bởi member khác
```

### 5. DELETE /api/Members/{id}
**Xóa member (soft delete) - Chỉ Admin**

```
Authorization: Authorize(Roles = "Admin")

Response: 200 OK hoặc 204 NoContent

Logic: Soft delete
UPDATE Members 
SET IsDeleted = 1, DeletedAt = GETDATE()
WHERE MemberId = @id
```

### 6. GET /api/Members/export
**Export Excel - Chỉ Admin**

```
Authorization: Authorize(Roles = "Admin")

Response: File (application/octet-stream)
Headers:
- Content-Disposition: attachment; filename=Members_20250118.xlsx

Logic Flow:
1. Get all members (không phân trang)
2. Generate Excel với EPPlus library
3. Return file stream
```

---

## CheckinsController

**Base Route**: `/api/Checkins`

### 1. POST /api/Checkins
**Tạo check-in mới - Member/Trainer**

```
Authorization: Authorize
Request Body: {} (empty - memberId lấy từ token)

Response: CheckinResponse (201 Created)
{
  "checkinId": 30,
  "memberId": 1,
  "checkinTime": "2025-01-18T14:30:00",
  "checkoutTime": null
}

Logic Flow:
1. Extract memberId từ JWT claims
2. Validate member tồn tại
3. Insert Checkin record
4. Return checkin info

SQL:
INSERT INTO Checkins (MemberId, CheckinTime, CreatedAt, UpdatedAt, IsDeleted)
OUTPUT INSERTED.CheckinId
VALUES (@MemberId, GETDATE(), GETDATE(), GETDATE(), 0)

Lưu ý: Trainer cũng check-in được vì có Member record
```

### 2. GET /api/Checkins
**Lấy danh sách check-ins (pagination) - Admin**

```
Authorization: Authorize(Roles = "Admin")
Query: ?page=1&pageSize=10

Response: PagedResult<CheckinResponse>

Order: CheckinTime ASC (sớm nhất lên trước - cho attendance tracking)
```

### 3. GET /api/Checkins/my
**Lấy check-in history của chính mình - Member/Trainer**

```
Authorization: Authorize
Query: ?page=1&pageSize=10

Response: PagedResult<CheckinResponse>

Logic:
1. Extract memberId từ token
2. Get checkins WHERE MemberId = @memberId
3. Order by CheckinTime ASC
```

---

## SchedulesController

**Base Route**: `/api/Schedules`

### 1. GET /api/Schedules
**Lấy tất cả lịch tập**

```
Authorization: Authorize
Query: ?page=1&pageSize=10

Response: PagedResult<ScheduleResponse>
{
  "data": [
    {
      "scheduleId": 1,
      "trainerId": 1,
      "trainerName": "Nguyễn Văn An",
      "facilityId": 1,
      "facilityName": "Phòng Gym Tầng 1",
      "className": "Cardio Buổi Sáng",
      "startTime": "2025-01-20T06:00:00",
      "endTime": "2025-01-20T07:00:00",
      "maxCapacity": 20
    },
    ...
  ]
}

Lưu ý:
- Member: Xem tất cả schedules (để đăng ký)
- Trainer: Xem tất cả nhưng chỉ edit/delete của mình
- Admin: Xem và quản lý tất cả
```

### 2. POST /api/Schedules
**Tạo lịch tập mới - Trainer/Admin**

```
Authorization: Authorize(Roles = "Trainer,Admin")
Request Body: CreateScheduleRequest
{
  "trainerId": 1,     // Nếu Trainer tạo → phải là trainerId của chính mình
  "facilityId": 1,
  "className": "Yoga Buổi Chiều",
  "startTime": "2025-01-20T14:00:00",
  "endTime": "2025-01-20T15:30:00",
  "maxCapacity": 15
}

Response: ScheduleResponse (201 Created)

Logic Flow:
1. Nếu role = Trainer:
   - Extract trainerId từ token
   - Validate request.trainerId == current trainerId
2. Check conflict (trainer hoặc facility bị trùng thời gian):
   - SQL: Check overlap với schedules khác
3. Insert Schedule
4. Return schedule

Conflict Detection SQL:
SELECT COUNT(*) FROM Schedules
WHERE (TrainerId = @trainerId OR FacilityId = @facilityId)
  AND IsDeleted = 0
  AND (
    (@startTime >= StartTime AND @startTime < EndTime) OR
    (@endTime > StartTime AND @endTime <= EndTime) OR
    (@startTime <= StartTime AND @endTime >= EndTime)
  )
  AND (@excludeScheduleId IS NULL OR ScheduleId != @excludeScheduleId)

Error:
- 400 BadRequest: Trainer/Facility đã có lịch trùng giờ
- 403 Forbidden: Trainer tạo lịch cho trainer khác
```

### 3. PUT /api/Schedules/{id}
**Cập nhật lịch tập - Chỉ trainer sở hữu hoặc Admin**

```
Authorization: Authorize
Path: id (scheduleId)
Request Body: UpdateScheduleRequest

Logic:
1. Get schedule from database
2. Nếu role = Trainer:
   - Validate schedule.TrainerId == current trainerId
3. Check conflict (exclude current schedule)
4. Update schedule

Error:
- 403 Forbidden: Trainer sửa lịch của trainer khác
- 400 BadRequest: Conflict với lịch khác
```

### 4. DELETE /api/Schedules/{id}
**Xóa lịch tập - Chỉ trainer sở hữu hoặc Admin**

```
Authorization: Authorize

Logic giống PUT (ownership check)
Soft delete: IsDeleted = 1
```

---

## DashboardController

**Base Route**: `/api/Dashboard`

### 1. GET /api/Dashboard/stats
**Lấy thống kê dashboard - Role-specific**

```
Authorization: Authorize

Response (Admin):
{
  "totalMembers": 25,
  "totalTrainers": 5,
  "totalFacilities": 10,
  "todayCheckins": 15,
  "activeSchedules": 12,
  "pendingInvoices": 8,
  "monthlyRevenue": 45000000
}

Response (Trainer):
{
  "mySchedules": 8,
  "totalSessions": 45,
  "todayCheckins": 3,
  "upcomingClasses": 2
}

Response (Member):
{
  "myMemberships": 1,
  "myCheckins": 12,
  "registeredSessions": 3,
  "activeMembership": {
    "packageName": "Gói 6 Tháng",
    "endDate": "2025-06-30"
  }
}

Logic:
1. Extract role từ token
2. Query data dựa trên role
3. Return role-specific stats
```

---

**Các controller còn lại (Trainers, Facilities, Invoices, Payments, Sessions, Memberships) đều follow pattern tương tự:**
- GET (list + pagination)
- GET /{id} (single)
- POST (create - Admin/Trainer)
- PUT /{id} (update - Admin/Trainer)
- DELETE /{id} (soft delete - Admin)
- Export Excel (Admin)

---

## HTTP Status Codes sử dụng

| Code | Ý nghĩa | Khi nào dùng |
|------|---------|--------------|
| 200 OK | Success | GET, PUT, DELETE thành công |
| 201 Created | Resource created | POST thành công |
| 204 No Content | Success, no body | PUT/DELETE thành công (alternative) |
| 400 Bad Request | Invalid input | Validation fail, business rule vi phạm |
| 401 Unauthorized | Not authenticated | Token missing/invalid/expired |
| 403 Forbidden | Not authorized | Không đủ quyền (VD: Trainer sửa lịch của trainer khác) |
| 404 Not Found | Resource not found | ID không tồn tại hoặc đã xóa |
| 500 Internal Server Error | Server error | Exception chưa handle |

---

**Tài liệu tiếp theo**: 
- [03-DATA-FLOW-CHI-TIET.md](./03-DATA-FLOW-CHI-TIET.md) - Tracing request từ frontend đến database
