# 🏋️ GYM MANAGEMENT API - ĐƠN GIẢN HÓA
## Specification Document - Phiên bản dễ hiểu & dễ làm

> **Triết lý**: Làm đơn giản nhất có thể. Bỏ những thứ phức tạp không cần thiết.

---

## 📚 TABLE OF CONTENTS

1. [Auth APIs](#1-auth-apis) - Đăng nhập/Đăng ký
2. [Member APIs](#2-member-apis) - Quản lý hội viên  
3. [Membership APIs](#3-membership-apis) - Gói tập
4. [Trainer APIs](#4-trainer-apis) - Huấn luyện viên
5. [Facility APIs](#5-facility-apis) - Phòng/Thiết bị
6. [Schedule APIs](#6-schedule-apis) - Lịch tập
7. [Session APIs](#7-session-apis) - Buổi tập
8. [Checkin APIs](#8-checkin-apis) - Check-in
9. [Invoice & Payment APIs](#9-invoice--payment-apis) - Hóa đơn & Thanh toán
10. [Report APIs](#10-report-apis) - Báo cáo

---

## 🎯 GLOBAL RULES

### Authorization
- JWT Token trong header: `Authorization: Bearer {token}`
- Public APIs (không cần token): Login, Register
- Các API còn lại đều cần token

### Roles (3 roles duy nhất)
- **Admin**: Quản lý gym (CRUD tất cả)
- **Trainer**: HLV (xem lịch, checkin, tạo session)
- **Member**: Hội viên (xem info cá nhân)

### Pagination cho tất cả GET list
```
?pageNumber=1&pageSize=10&searchTerm=keyword
```

Response:
```json
{
  "items": [],
  "totalCount": 100,
  "pageNumber": 1,
  "pageSize": 10
}
```

### Error Response (thống nhất)
```json
{
  "message": "Mô tả lỗi cụ thể"
}
```

---

## 1. AUTH APIs

### 🔥 ĐĂNG KÝ SIÊU ĐƠN GIẢN

#### POST /api/Auth/register
**Người dùng tự đăng ký → auto thành Member**

**Input** (4 fields thôi):
```json
{
  "username": "john_doe",
  "password": "123456",
  "fullName": "Nguyễn Văn A",
  "email": "user@example.com"
}
```

**Output**:
```json
{
  "message": "Đăng ký thành công! Bạn có thể đăng nhập ngay.",
  "userId": 1,
  "username": "john_doe",
  "role": "Member"
}
```

**Logic**:
1. Validate: username unique, email unique, password >= 6 chars
2. Hash password (BCrypt)
3. Tạo User: Role = "Member", IsActive = true
4. **TỰ ĐỘNG tạo Member record**:
   - FullName = fullName
   - Email = email
   - Phone = "" (để trống, update sau)
   - JoinDate = now
   - Status = "Active"
   - QRCodeValue = "MEMBER-{id:00000}-{GUID}"
5. Save database
6. **Có thể login ngay** (không cần verify email)

**📝 NOTES**:
- ❌ Không cần OTP
- ❌ Không cần verify email
- ✅ Đăng ký xong login luôn
- ✅ Auto tạo Member
- ✅ Role mặc định = Member

---

#### POST /api/Auth/login

**Input**:
```json
{
  "username": "john_doe",
  "password": "123456"
}
```

**Output**:
```json
{
  "token": "jwt_token_here",
  "userId": 1,
  "username": "john_doe",
  "fullName": "Nguyễn Văn A",
  "role": "Member",
  "memberId": 5
}
```

**Logic**:
1. Tìm User by username
2. Verify password (BCrypt)
3. Check IsActive = true
4. Tạo JWT token (expire 7 days):
   - Claims: userId, username, role, email, memberId (nếu Member)
5. Return token + user info

---

#### POST /api/Auth/change-password
**Đổi mật khẩu (cần login)**

**Input**:
```json
{
  "oldPassword": "123456",
  "newPassword": "newpass123"
}
```

**Output**:
```json
{
  "message": "Đổi mật khẩu thành công"
}
```

**Logic**:
1. Lấy userId từ token
2. Verify oldPassword
3. Update PasswordHash

---

#### GET /api/Auth/me
**Xem profile hiện tại**

**Output**:
```json
{
  "userId": 1,
  "username": "john_doe",
  "fullName": "Nguyễn Văn A",
  "role": "Member",
  "memberId": 5
}
```

---

### 👮 ADMIN QUẢN LÝ USERS

#### GET /api/Auth/users
**Xem danh sách users [Admin only]**

Query: `?pageNumber=1&pageSize=10&searchTerm=john`

**Output**:
```json
{
  "items": [
    {
      "userId": 1,
      "username": "john_doe",
      "fullName": "Nguyễn Văn A",
      "role": "Member",
      "isActive": true
    }
  ],
  "totalCount": 50
}
```

---

#### POST /api/Auth/create-staff
**Admin tạo tài khoản Admin/Trainer [Admin only]**

**Input**:
```json
{
  "username": "trainer_john",
  "password": "123456",
  "fullName": "HLV Nguyễn B",
  "email": "trainer@gym.com",
  "role": "Trainer"  // hoặc "Admin"
}
```

**Output**:
```json
{
  "message": "Tạo tài khoản Trainer thành công",
  "userId": 10
}
```

**Logic**:
- Nếu role = "Trainer" → tạo User + tạo Trainer record
- Nếu role = "Admin" → chỉ tạo User

---

#### PUT /api/Auth/users/{id}/toggle-active
**Khóa/Mở tài khoản [Admin only]**

**Output**:
```json
{
  "message": "Đã khóa tài khoản"
}
```

---

## 2. MEMBER APIs

### GET /api/Member
**Danh sách hội viên**

Query: `?pageNumber=1&pageSize=10&searchTerm=john&status=Active`

**Output**:
```json
{
  "items": [
    {
      "memberId": 1,
      "fullName": "Nguyễn Văn A",
      "phone": "0901234567",
      "email": "user@example.com",
      "dateOfBirth": "1990-01-01",
      "joinDate": "2024-01-01",
      "status": "Active",
      "qrCodeValue": "MEMBER-00001-ABC"
    }
  ],
  "totalCount": 100
}
```

**Filters**:
- `searchTerm`: tìm trong FullName, Phone, Email
- `status`: Active | Inactive | Expired

---

### GET /api/Member/{id}
**Chi tiết hội viên**

**Output**: Single MemberResponse

---

### POST /api/Member
**Tạo hội viên mới [Admin only]**

**Input**:
```json
{
  "fullName": "Trần Văn B",
  "phone": "0912345678",
  "email": "member2@example.com",
  "dateOfBirth": "1995-05-15"
}
```

**Output**: MemberResponse (201 Created)

**Logic**:
1. Validate email unique, phone format
2. Tạo QRCodeValue = "MEMBER-{id:00000}-{GUID}"
3. Status = "Active"
4. JoinDate = today
5. Save

---

### PUT /api/Member/{id}
**Cập nhật hội viên [Admin only]**

**Input**:
```json
{
  "fullName": "Trần Văn B Updated",
  "phone": "0912345679",
  "email": "updated@example.com",
  "dateOfBirth": "1995-05-15",
  "status": "Active"
}
```

---

### DELETE /api/Member/{id}
**Xóa hội viên [Admin only]**

**Output**: 204 No Content

**Logic**: Soft delete (IsDeleted = true)

---

## 3. MEMBERSHIP APIs

### GET /api/Membership
**Danh sách gói tập**

**Output**:
```json
{
  "items": [
    {
      "membershipId": 1,
      "memberId": 1,
      "memberName": "Nguyễn Văn A",
      "membershipType": "Monthly",
      "price": 500000,
      "startDate": "2024-01-01",
      "endDate": "2024-02-01",
      "status": "Active"
    }
  ]
}
```

**Types**: Monthly | Quarterly | Annual
**Status**: Active | Expired | Cancelled

---

### GET /api/Membership/{id}
**Chi tiết gói tập**

---

### GET /api/Membership/member/{memberId}
**Lịch sử gói tập của 1 hội viên**

---

### GET /api/Membership/member/{memberId}/active
**Gói tập đang active của hội viên**

**Output**: Single MembershipResponse hoặc null

**Logic**: 
- EndDate >= today
- Status = "Active"

---

### POST /api/Membership
**Đăng ký gói tập mới [Admin only]**

**Input**:
```json
{
  "memberId": 1,
  "membershipType": "Monthly",
  "price": 500000,
  "startDate": "2024-01-01",
  "endDate": "2024-02-01"
}
```

**Output**: MembershipResponse (201)

**Logic**:
1. Validate Member exists
2. Validate startDate < endDate
3. Tạo Membership, Status = "Active"
4. Update Member.Status = "Active"
5. **Auto tạo Invoice tương ứng**

---

### PUT /api/Membership/{id}
**Cập nhật/Gia hạn gói tập [Admin only]**

**Input**:
```json
{
  "membershipType": "Quarterly",
  "price": 1200000,
  "endDate": "2024-04-01",
  "status": "Active"
}
```

---

### DELETE /api/Membership/{id}
**Xóa gói tập [Admin only]**

Soft delete

---

## 4. TRAINER APIs

### GET /api/Trainer
**Danh sách HLV**

**Output**:
```json
{
  "items": [
    {
      "trainerId": 1,
      "fullName": "HLV Nguyễn B",
      "phone": "0987654321",
      "email": "trainer@gym.com",
      "specialization": "Yoga, Boxing",
      "status": "Active"
    }
  ]
}
```

---

### GET /api/Trainer/{id}
**Chi tiết HLV**

---

### POST /api/Trainer
**Tạo HLV [Admin only]**

**Input**:
```json
{
  "fullName": "HLV Nguyễn C",
  "phone": "0998877665",
  "email": "trainer2@gym.com",
  "specialization": "Gym, Cardio"
}
```

**Logic**:
- Option: Tạo User tương ứng với role = "Trainer"

---

### PUT /api/Trainer/{id}
**Cập nhật HLV [Admin only]**

---

### DELETE /api/Trainer/{id}
**Xóa HLV [Admin only]**

---

## 5. FACILITY APIs

### GET /api/Facility
**Danh sách phòng/thiết bị**

**Output**:
```json
{
  "items": [
    {
      "facilityId": 1,
      "facilityName": "Phòng Yoga",
      "facilityType": "Room",
      "capacity": 20,
      "status": "Available"
    }
  ]
}
```

**Types**: Room | Equipment
**Status**: Available | Maintenance | Unavailable

---

### GET /api/Facility/{id}

---

### POST /api/Facility [Admin only]

**Input**:
```json
{
  "facilityName": "Phòng Boxing",
  "facilityType": "Room",
  "capacity": 15,
  "status": "Available"
}
```

---

### PUT /api/Facility/{id} [Admin only]

---

### DELETE /api/Facility/{id} [Admin only]

---

## 6. SCHEDULE APIs

### GET /api/Schedule
**Danh sách lịch tập**

**Output**:
```json
{
  "items": [
    {
      "scheduleId": 1,
      "memberId": 1,
      "memberName": "Nguyễn Văn A",
      "trainerId": 1,
      "trainerName": "HLV Nguyễn B",
      "facilityId": 1,
      "facilityName": "Phòng Yoga",
      "scheduledDate": "2024-01-15",
      "startTime": "09:00",
      "endTime": "10:00",
      "status": "Scheduled"
    }
  ]
}
```

**Status**: Scheduled | Completed | Cancelled

---

### GET /api/Schedule/{id}

---

### GET /api/Schedule/trainer/{trainerId}
**Lịch tập của HLV**

---

### GET /api/Schedule/member/{memberId}
**Lịch tập của hội viên**

---

### POST /api/Schedule
**Đặt lịch tập [Admin/Trainer]**

**Input**:
```json
{
  "memberId": 1,
  "trainerId": 1,
  "facilityId": 1,
  "scheduledDate": "2024-01-15",
  "startTime": "09:00",
  "endTime": "10:00",
  "notes": "Tập Yoga buổi sáng"
}
```

**Logic**:
1. Validate Member có active membership
2. Check Trainer không trùng lịch
3. Check Facility available
4. Tạo Schedule, Status = "Scheduled"

---

### PUT /api/Schedule/{id} [Admin/Trainer]
**Cập nhật lịch**

---

### DELETE /api/Schedule/{id} [Admin]
**Hủy lịch**

Soft delete, status = "Cancelled"

---

## 7. SESSION APIs

> **Session** = Buổi tập thực tế (tạo từ Schedule khi đến giờ tập)

### GET /api/Session
**Danh sách buổi tập**

**Output**:
```json
{
  "items": [
    {
      "sessionId": 1,
      "scheduleId": 1,
      "memberId": 1,
      "trainerId": 1,
      "actualStartTime": "09:05",
      "actualEndTime": "10:00",
      "notes": "Buổi tập tốt",
      "createdAt": "2024-01-15"
    }
  ]
}
```

---

### GET /api/Session/{id}

---

### GET /api/Session/schedule/{scheduleId}
**Sessions của 1 schedule**

---

### POST /api/Session
**Tạo buổi tập [Admin/Trainer]**

**Input**:
```json
{
  "scheduleId": 1,
  "actualStartTime": "09:05",
  "actualEndTime": "10:00",
  "notes": "Completed"
}
```

**Logic**:
1. Validate Schedule exists
2. Tạo Session
3. Update Schedule.Status = "Completed"

---

### PUT /api/Session/{id} [Admin/Trainer]

---

### DELETE /api/Session/{id} [Admin]

---

## 8. CHECKIN APIs

### GET /api/Checkin
**Danh sách check-in**

**Output**:
```json
{
  "items": [
    {
      "checkinId": 1,
      "memberId": 1,
      "memberName": "Nguyễn Văn A",
      "sessionId": 1,
      "checkinTime": "2024-01-15T09:05:00",
      "checkinMethod": "QR"
    }
  ]
}
```

---

### GET /api/Checkin/{id}

---

### GET /api/Checkin/member/{memberId}
**Lịch sử check-in của hội viên**

---

### GET /api/Checkin/date-range
**Check-in theo khoảng thời gian**

Query: `?from=2024-01-01&to=2024-01-31`

---

### POST /api/Checkin/manual
**Check-in thủ công [Admin/Trainer]**

**Input**:
```json
{
  "memberId": 1,
  "sessionId": 1
}
```

**Logic**:
1. Validate Member có active membership
2. Validate Session exists (optional)
3. Tạo Checkin, CheckinMethod = "Manual"

---

### POST /api/Checkin/qr
**Check-in bằng QR Code [Public - NFR Feature]**

**Input**:
```json
{
  "qrCodeValue": "MEMBER-00001-ABC",
  "sessionId": 1
}
```

**Output**:
```json
{
  "checkinId": 1,
  "memberName": "Nguyễn Văn A",
  "message": "Check-in thành công! Chào mừng bạn."
}
```

**Logic**:
1. Tìm Member by QRCodeValue
2. Check active membership
3. Check không duplicate trong ngày
4. Tạo Checkin, Method = "QR"
5. Return success message

**Security**: Rate limiting (tránh spam)

---

## 9. INVOICE & PAYMENT APIs

### 💰 INVOICE (HÓA ĐƠN)

#### GET /api/Invoice
**Danh sách hóa đơn**

**Output**:
```json
{
  "items": [
    {
      "invoiceId": 1,
      "memberId": 1,
      "memberName": "Nguyễn Văn A",
      "membershipId": 1,
      "amount": 500000,
      "issueDate": "2024-01-01",
      "dueDate": "2024-01-15",
      "status": "Pending",
      "description": "Phí tập tháng 1"
    }
  ]
}
```

**Status**: Pending | Paid | Overdue | Cancelled

---

#### GET /api/Invoice/{id}

---

#### GET /api/Invoice/member/{memberId}
**Hóa đơn của hội viên**

---

#### GET /api/Invoice/overdue
**Hóa đơn quá hạn**

**Logic**:
- Status = "Pending"
- DueDate < today
- Auto update Status = "Overdue"

---

#### POST /api/Invoice [Admin only]

**Input**:
```json
{
  "memberId": 1,
  "membershipId": 1,
  "amount": 500000,
  "issueDate": "2024-01-01",
  "dueDate": "2024-01-15",
  "description": "Phí membership tháng 1"
}
```

**Logic**: Tạo invoice, Status = "Pending"

**NOTE**: Thường được tạo tự động khi tạo Membership

---

#### PUT /api/Invoice/{id} [Admin only]

---

#### DELETE /api/Invoice/{id} [Admin only]

---

### 💳 PAYMENT (THANH TOÁN)

#### GET /api/Payment
**Danh sách thanh toán**

**Output**:
```json
{
  "items": [
    {
      "paymentId": 1,
      "invoiceId": 1,
      "amount": 500000,
      "paymentMethod": "Cash",
      "paymentDate": "2024-01-10",
      "notes": "Thanh toán đầy đủ"
    }
  ]
}
```

**Methods**: Cash | Card | Transfer

---

#### GET /api/Payment/{id}

---

#### GET /api/Payment/invoice/{invoiceId}
**Payments của 1 invoice**

---

#### POST /api/Payment [Admin only]
**Ghi nhận thanh toán**

**Input**:
```json
{
  "invoiceId": 1,
  "amount": 500000,
  "paymentMethod": "Cash",
  "paymentDate": "2024-01-10",
  "notes": "Thanh toán full"
}
```

**Logic**:
1. Validate Invoice exists, Status = "Pending"
2. Tạo Payment
3. Nếu sum(payments) >= invoice.amount:
   - Update Invoice.Status = "Paid"
4. Else: giữ Status = "Pending"

---

#### PUT /api/Payment/{id} [Admin only]

---

#### DELETE /api/Payment/{id} [Admin only]

**Logic**: 
- Soft delete
- Recalculate Invoice status

---

## 10. REPORT APIs

### GET /api/Report/active-members
**Báo cáo hội viên đang hoạt động [Admin only]**

**Output**:
```json
{
  "totalActiveMembers": 150,
  "newMembersThisMonth": 10,
  "expiringThisMonth": 5,
  "members": [
    {
      "memberId": 1,
      "fullName": "Nguyễn Văn A",
      "endDate": "2024-02-01",
      "daysRemaining": 15
    }
  ]
}
```

---

### GET /api/Report/revenue
**Báo cáo doanh thu [Admin only]**

Query: `?month=1&year=2024`

**Output**:
```json
{
  "month": 1,
  "year": 2024,
  "totalRevenue": 50000000,
  "totalInvoices": 100,
  "totalPaid": 45000000,
  "totalPending": 5000000
}
```

---

### GET /api/Report/expiring-soon
**Membership sắp hết hạn [Admin only]**

Query: `?daysAhead=7`

**Output**:
```json
{
  "totalExpiring": 10,
  "members": [
    {
      "memberId": 1,
      "fullName": "Nguyễn Văn A",
      "email": "user@example.com",
      "endDate": "2024-01-20",
      "daysRemaining": 5
    }
  ]
}
```

**Logic**:
- EndDate BETWEEN today AND (today + 7 days)
- Status = "Active"
- Option: Gửi email nhắc gia hạn

---

### GET /api/Report/revenue/export
**Export Excel doanh thu [Admin only]**

Query: `?month=1&year=2024`

**Output**: File Excel

**Filename**: `Revenue_01_2024.xlsx`

---

## 📝 IMPLEMENTATION NOTES

### 1. DATABASE SIMPLIFICATIONS

#### Users Table (đơn giản hóa)
```sql
CREATE TABLE Users (
    UserId INT PRIMARY KEY IDENTITY,
    Username NVARCHAR(50) UNIQUE NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    Role NVARCHAR(20) NOT NULL,  -- Admin/Trainer/Member
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE()
)
```

**❌ BỎ**:
- EmailConfirmed (không cần verify email)
- EmailVerificationOTP table
- PasswordResetToken table
- LastLogin, FailedLoginAttempts (làm sau nếu cần)

---

#### Members Table (đơn giản)
```sql
CREATE TABLE Members (
    MemberId INT PRIMARY KEY IDENTITY,
    FullName NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(20),
    Email NVARCHAR(100) UNIQUE NOT NULL,
    DateOfBirth DATE,
    JoinDate DATE DEFAULT GETDATE(),
    Status NVARCHAR(20) DEFAULT 'Active',  -- Active/Inactive/Expired
    QRCodeValue NVARCHAR(100) UNIQUE,
    IsDeleted BIT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETDATE()
)
```

**📝 NOTE**: Không link trực tiếp UserId → MemberId. Tìm bằng Email khi cần.

---

#### Memberships Table
```sql
CREATE TABLE Memberships (
    MembershipId INT PRIMARY KEY IDENTITY,
    MemberId INT FOREIGN KEY REFERENCES Members(MemberId),
    MembershipType NVARCHAR(20),  -- Monthly/Quarterly/Annual
    Price DECIMAL(18,2),
    StartDate DATE,
    EndDate DATE,
    Status NVARCHAR(20) DEFAULT 'Active',  -- Active/Expired/Cancelled
    IsDeleted BIT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETDATE()
)
```

---

#### Invoices Table (đơn giản)
```sql
CREATE TABLE Invoices (
    InvoiceId INT PRIMARY KEY IDENTITY,
    MemberId INT FOREIGN KEY REFERENCES Members(MemberId),
    MembershipId INT FOREIGN KEY REFERENCES Memberships(MembershipId),
    Amount DECIMAL(18,2),
    IssueDate DATE,
    DueDate DATE,
    Status NVARCHAR(20) DEFAULT 'Pending',  -- Pending/Paid/Overdue/Cancelled
    Description NVARCHAR(255),
    IsDeleted BIT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETDATE()
)
```

---

#### Payments Table (đơn giản)
```sql
CREATE TABLE Payments (
    PaymentId INT PRIMARY KEY IDENTITY,
    InvoiceId INT FOREIGN KEY REFERENCES Invoices(InvoiceId),
    Amount DECIMAL(18,2),
    PaymentMethod NVARCHAR(20),  -- Cash/Card/Transfer
    PaymentDate DATE,
    Notes NVARCHAR(255),
    IsDeleted BIT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETDATE()
)
```

---

### 2. BUS/SERVICE SIMPLIFICATIONS

#### AuthService - ĐỒNG BỘ hóa logic

**RegisterAsync()** - Đơn giản hóa:
```csharp
public async Task<UserResponse> RegisterAsync(RegisterRequest request)
{
    // 1. Validate
    if (await _userRepo.UsernameExistsAsync(request.Username))
        throw new InvalidOperationException("Username đã tồn tại");
    
    if (await _userRepo.EmailExistsAsync(request.Email))
        throw new InvalidOperationException("Email đã tồn tại");
    
    // 2. Hash password
    string passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);
    
    // 3. Tạo User - AUTO ROLE = MEMBER
    var user = new User
    {
        Username = request.Username,
        PasswordHash = passwordHash,
        FullName = request.FullName,
        Email = request.Email,
        Role = "Member",  // AUTO
        IsActive = true   // LUÔN TRUE
    };
    
    await _userRepo.CreateAsync(user);
    
    // 4. TỰ ĐỘNG tạo Member
    var member = new Member
    {
        FullName = request.FullName,
        Email = request.Email,
        Phone = "",  // Update sau
        JoinDate = DateTime.Now,
        Status = "Active",
        QRCodeValue = $"MEMBER-{user.UserId:D5}-{Guid.NewGuid().ToString("N").Substring(0, 8)}"
    };
    
    await _memberRepo.CreateAsync(member);
    
    return new UserResponse
    {
        UserId = user.UserId,
        Username = user.Username,
        FullName = user.FullName,
        Role = user.Role
    };
}
```

**❌ BỎ**:
- OTP generation
- Email verification
- EmailConfirmed logic
- Tất cả OTP-related code

---

#### MembershipService - Auto create Invoice

**CreateAsync()** - Tự động tạo invoice:
```csharp
public async Task<MembershipResponse> CreateAsync(CreateMembershipRequest request)
{
    // 1. Validate Member
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
    
    // 3. AUTO CREATE INVOICE
    var invoice = new Invoice
    {
        MemberId = request.MemberId,
        MembershipId = membership.MembershipId,
        Amount = request.Price,
        IssueDate = DateTime.Now,
        DueDate = request.StartDate.AddDays(7),  // 7 days to pay
        Status = "Pending",
        Description = $"Phí {request.MembershipType} membership"
    };
    
    await _invoiceRepo.CreateAsync(invoice);
    
    // 4. Update Member Status
    member.Status = "Active";
    await _memberRepo.UpdateAsync(member);
    
    return MapToResponse(membership);
}
```

---

#### PaymentService - Auto update Invoice status

**CreateAsync()** - Tự động cập nhật invoice:
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
        PaymentMethod = request.PaymentMethod,
        PaymentDate = request.PaymentDate,
        Notes = request.Notes
    };
    
    await _paymentRepo.CreateAsync(payment);
    
    // 3. AUTO UPDATE INVOICE STATUS
    var totalPaid = await _paymentRepo.GetTotalPaidAsync(request.InvoiceId);
    
    if (totalPaid >= invoice.Amount)
    {
        invoice.Status = "Paid";
        await _invoiceRepo.UpdateAsync(invoice);
    }
    
    return MapToResponse(payment);
}
```

---

### 3. BỎ CÁC FEATURES PHỨC TẠP

#### ❌ BỎ:
1. **Email Verification / OTP System**
   - Bảng EmailVerificationOTP
   - Bảng PasswordResetToken
   - Email service cho OTP
   - Verify/Resend OTP endpoints

2. **SuperAdmin Role**
   - Chỉ còn 3 roles: Admin, Trainer, Member
   - Admin có full quyền

3. **Audit Log với Versioning**
   - Làm sau nếu thực sự cần
   - Hiện tại: chỉ log CreatedAt

4. **Background Jobs phức tạp**
   - Làm sau: Email notifications, Auto-expire membership
   - Hiện tại: Manual operations

5. **Advanced Search/Filters**
   - Chỉ giữ: searchTerm, pagination
   - Bỏ: sortBy, sortDir, multi-field filters

---

### 4. ƯU TIÊN IMPLEMENTATION (THEO YÊU CẦU DỰ ÁN)

> **Nguyên tắc**: Ưu tiên "Gym Management" trước, "Yêu cầu chung" sau

#### 🏋️ PHASE 1: GYM CORE FEATURES (Tuần 1-2)
**Mục tiêu**: Đủ để quản lý gym cơ bản

```
Priority 1: Member & Membership Management
✅ 1.1. Đăng ký hội viên (Member CRUD)
✅ 1.2. Thẻ tập - Membership CRUD
✅ 1.3. Quản lý gói dịch vụ (Monthly/Quarterly/Annual)
✅ 1.4. Check-in Manual (ghi nhận buổi tập cơ bản)

Priority 2: Trainer & Facility
✅ 2.1. Quản lý Trainer CRUD
✅ 2.2. Quản lý Facility (phòng/thiết bị) CRUD

Priority 3: Scheduling
✅ 3.1. Đặt lịch tập với PT (Schedule CRUD)
✅ 3.2. Quản lý Session (buổi tập thực tế)

Priority 4: Financial
✅ 4.1. Thu phí - Invoice & Payment
✅ 4.2. Cảnh báo sắp hết hạn (Expiring Soon Report)
```

#### 📊 PHASE 2: REPORTING & NFR (Tuần 3)
**Mục tiêu**: Báo cáo & tính năng đặc biệt

```
Priority 5: Basic Reports
✅ 5.1. Báo cáo hội viên đang hoạt động
✅ 5.2. Báo cáo doanh thu theo tháng
✅ 5.3. Danh sách sắp hết hạn (với email nhắc - optional)

Priority 6: NFR Features
✅ 6.1. Check-in QR Code (tích hợp đặc biệt)
✅ 6.2. Export Excel (Invoice, Revenue)
✅ 6.3. Export PDF (Hóa đơn)
```

#### 🔐 PHASE 3: AUTH & SECURITY (Tuần 4)
**Mục tiêu**: Hoàn thiện authentication & authorization

```
Priority 7: Auth System
✅ 7.1. Đăng ký/Đăng nhập JWT (đã đơn giản hóa)
✅ 7.2. Role-based Access Control (3 roles: Admin/Trainer/Member)
✅ 7.3. Phân quyền theo màn hình & hành động

Priority 8: Security & Quality (KHÔNG ƯU TIÊN CAO)
⚠️ 8.1. Chống SQL Injection (dùng parameterized queries)
⚠️ 8.2. CORS configuration
⚠️ 8.3. Input validation
⏸️ 8.4. Rate limiting (LÀM SAU - không cần ngay)
⏸️ 8.5. CSRF token (LÀM SAU)
```

#### 📝 PHASE 4: DOCUMENTATION & TESTING (Tuần 5)
**Mục tiêu**: Tài liệu & kiểm thử

```
Priority 9: Documentation
✅ 9.1. OpenAPI/Swagger đầy đủ
✅ 9.2. Postman collection
✅ 9.3. API documentation

Priority 10: Testing (30-40% coverage)
✅ 10.1. Unit tests (Service layer)
✅ 10.2. Integration tests (API endpoints)
✅ 10.3. Test basic scenarios
```

#### 🚫 KHÔNG LÀM NGAY (Phase 5+)
```
⏸️ Docker & docker-compose (không cần thiết lúc đầu)
⏸️ CI/CD pipeline (làm sau khi stable)
⏸️ Redis cache (optimize sau)
⏸️ Rate limiting (security advanced)
⏸️ Audit log versioning (nâng cao)
⏸️ Background jobs/Queue (notification sau)
⏸️ Health check endpoint (monitoring sau)
⏸️ 2FA/OAuth2 (quá phức tạp)
```

---

### 5. YÊU CẦU DỰ ÁN - CHECKLIST

> Dựa trên "Yêu cầu của dự án.txt"

#### ✅ GYM MANAGEMENT - CHỨC NĂNG BẮT BUỘC (6 ĐIỂM)

##### 1. Đăng ký hội viên, thẻ tập, hạn sử dụng ✅
```
✅ Member CRUD APIs
✅ QRCode tự động khi tạo member
✅ Membership với StartDate/EndDate
✅ Status tracking: Active/Inactive/Expired
```

##### 2. Quản lý gói dịch vụ (theo tháng/năm) ✅
```
✅ Membership types: Monthly/Quarterly/Annual
✅ Price management
✅ Auto calculate EndDate
✅ Status: Active/Expired/Cancelled
```

##### 3. Đặt lịch tập với PT, quản lý phòng/thiết bị ✅
```
✅ Schedule CRUD (member book với trainer)
✅ Facility CRUD (rooms & equipment)
✅ Check trainer availability
✅ Check facility availability
✅ Session management (actual workout)
```

##### 4. Quản lý check-in, ghi nhận buổi tập ✅
```
✅ Manual checkin (by admin/trainer)
✅ QR Code checkin (NFR feature)
✅ Validate active membership
✅ Prevent duplicate checkin same day
✅ Link to Session (optional)
```

##### 5. Thu phí, hoá đơn; cảnh báo sắp hết hạn ✅
```
✅ Invoice management (auto create from membership)
✅ Payment management (auto update invoice status)
✅ Payment methods: Cash/Card/Transfer
✅ Expiring soon report (membership sắp hết hạn)
✅ Email nhắc gia hạn (optional - background job)
```

##### 6. Báo cáo: hội viên đang hoạt động, doanh thu ✅
```
✅ Active members report
✅ Revenue report (by month/year)
✅ Revenue detail (transactions)
✅ Export Excel revenue
```

---

#### ✅ YÊU CẦU CHUNG - TÍNH NĂNG NỀN TẢNG

##### 🔐 Đăng ký/Đăng nhập (SIMPLIFIED)
```
✅ Register: username, password, fullName, email
✅ Login: JWT token (expire 7 days)
✅ Change password
✅ Role: Admin/Trainer/Member
❌ KHÔNG: OAuth2, 2FA (quá phức tạp cho project này)
```

##### 👥 RBAC - 3 vai trò
```
✅ Admin: Full CRUD quyền
✅ Trainer: Xem lịch, checkin, tạo session
✅ Member: Xem thông tin cá nhân, lịch tập
✅ Phân quyền theo controller (Authorize attributes)
✅ Phân quyền theo action (role-based)
```

##### 📊 CRUD có tìm kiếm, lọc, sắp xếp, phân trang
```
✅ Pagination: pageNumber, pageSize
✅ Search: searchTerm (tìm trong multiple fields)
⚠️ Sort: sortBy, sortDir (OPTIONAL - không bắt buộc)
⚠️ Filter: status, date range (theo từng entity)
```

##### 📄 Nhập/Xuất Excel/CSV, Xuất PDF
```
✅ Export Excel: Revenue report
✅ Export PDF: Invoice (hóa đơn)
⏸️ Import Excel: Bulk members upload (LÀM SAU)
⏸️ Export CSV: Alternative format (LÀM SAU)
```

##### 📜 Audit log (ai làm gì, lúc nào)
```
⚠️ Basic: CreatedAt timestamp trên mọi entity
⚠️ Soft delete: IsDeleted flag
⏸️ Advanced: Audit log table (ai, làm gì, khi nào) - LÀM SAU
⏸️ Versioning: Record history - LÀM SAU NẾU CẦN
```

##### 📧 Thông báo (email và/hoặc in-app)
```
⏸️ Email: Send via SMTP (làm sau)
⏸️ In-app notification: WebSocket/SignalR (làm sau)
⚠️ Priority: Email cho expiring membership (nếu có thời gian)
```

##### ⏳ Hàng đợi tác vụ (job) cho tác vụ lâu
```
⏸️ Background jobs: Hangfire/Quartz (LÀM SAU)
⏸️ Email queue (LÀM SAU)
⏸️ Report generation queue (LÀM SAU)
```

---

#### ✅ CHẤT LƯỢNG & VẬN HÀNH

##### 📖 OpenAPI/Swagger đầy đủ, Postman collection
```
✅ Swagger UI: Tích hợp sẵn trong ASP.NET
✅ XML comments: Document mọi endpoint
✅ Example requests/responses
✅ Postman collection: Export từ Swagger
```

##### 🧪 Unit test & Integration test (30-40% coverage)
```
✅ Unit tests: Service layer logic
✅ Integration tests: API endpoints
✅ Test scenarios:
  - Happy paths
  - Validation errors
  - Authorization errors
  - Business logic errors
⚠️ Coverage: Aim for 30-40% (không cần 100%)
```

##### 🐳 Docker & CI/CD
```
⏸️ Docker: docker-compose (LÀM SAU - không priority)
⏸️ CI/CD: GitHub Actions/Azure DevOps (LÀM SAU)
⏸️ Deployment guide: Manual deployment trước
```

##### 🔒 Bảo mật & Hiệu năng
```
✅ SQL Injection: Parameterized queries (Dapper/EF)
✅ XSS: Input validation, encode output
✅ CORS: Configure cho frontend
⚠️ CSRF: Token-based (nếu có form-based actions)
⏸️ Rate limiting: Middleware (LÀM SAU)
⏸️ Redis cache: Cho danh mục (LÀM SAU)
```

##### 📊 Dữ liệu mẫu (seed data)
```
✅ Seed script: ≥ 2,000 records
  - 100 Members
  - 500 Memberships
  - 10 Trainers
  - 20 Facilities
  - 1000 Checkins
  - 200 Invoices
  - 200 Payments
```

##### 📈 Giám sát: Logging & Health check
```
⚠️ Logging: Serilog/NLog (structured logs)
⏸️ Health check endpoint: /health (LÀM SAU)
⏸️ Application Insights: Monitoring (LÀM SAU)
```

---

#### 📚 TÀI LIỆU & BÀN GIAO

##### Tài liệu yêu cầu
```
✅ SRS: Software Requirements Specification
✅ ERD: Database schema diagram
✅ Use case: Các luồng chính
✅ Architecture: Layered architecture (API/BLL/DAL)
✅ API Documentation: Swagger/Postman
```

##### Hướng dẫn & Demo
```
✅ Installation guide: Cài đặt database, run API
✅ User guide: Sử dụng các chức năng
✅ Video demo: 5-10 phút (record screen)
```

---

### 6. WHAT TO FOCUS NOW

#### ✅ LÀM NGAY (Tuần 1-3)
1. **Gym Core Features**: Member, Membership, Checkin, Schedule
2. **Financial**: Invoice, Payment
3. **Basic Reports**: Active members, Revenue, Expiring
4. **Auth**: Simple register/login (no OTP)
5. **RBAC**: 3 roles với authorization
6. **CRUD**: Pagination, search cơ bản
7. **NFR**: QR Code checkin
8. **Export**: Excel (revenue), PDF (invoice)

#### ⚠️ LÀM SAU NẾU CÓ THỜI GIAN (Tuần 4-5)
1. Soft delete + audit CreatedAt
2. Email notifications (expiring membership)
3. Unit tests (aim 30% coverage)
4. Swagger documentation đầy đủ
5. Seed data ≥ 2000 records
6. Basic logging

#### ⏸️ KHÔNG LÀM NGAY (Phase 2 project)
1. Docker & docker-compose
2. CI/CD pipeline
3. Rate limiting
4. Redis cache
5. Background jobs/Queue
6. OAuth2/2FA
7. Advanced audit log with versioning
8. Health check endpoint
9. In-app notifications (WebSocket)

---

#### Auth Tests
- [ ] Register → auto create Member
- [ ] Login → get token
- [ ] Token contains correct claims
- [ ] Change password works
- [ ] Admin can create Trainer/Admin accounts

#### Member Tests
- [ ] CRUD operations
- [ ] QRCode auto generated

#### Membership Tests
- [ ] Create membership → auto create invoice
- [ ] Update endDate → recalculate status

#### Payment Tests
- [ ] Create payment → auto update invoice status
- [ ] Partial payment → status still Pending
- [ ] Full payment → status = Paid

#### Checkin Tests
- [ ] Manual checkin works
- [ ] QR checkin with valid QRCode works
- [ ] QR checkin validates active membership
- [ ] Cannot checkin twice in same day

---

## 🎯 SUMMARY - WHAT CHANGED

### ✅ SIMPLIFIED
1. **Register**: 4 fields, no OTP, auto Member, login ngay
2. **Roles**: 3 roles thay vì 4 (bỏ SuperAdmin)
3. **Membership**: Auto create Invoice khi tạo
4. **Payment**: Auto update Invoice status
5. **Database**: Bỏ OTP tables, bỏ audit versioning

### ❌ REMOVED
1. Email verification / OTP system
2. Password reset tokens
3. Complex audit logging
4. Background jobs (làm sau)
5. Advanced search filters

### 🎯 FOCUS
- **Đơn giản**: Dễ hiểu, dễ code
- **Thực tế**: Đủ dùng cho gym nhỏ/vừa
- **Có thể mở rộng**: Thêm features sau nếu cần

---

**END OF SIMPLIFIED SPECIFICATION**

🎉 Giờ code thôi!

### 7. TESTING SCENARIOS (30-40% COVERAGE)

#### Auth Tests
- [ ] Register → auto create Member record
- [ ] Register với username đã tồn tại → error
- [ ] Login thành công → return token
- [ ] Login sai password → 401
- [ ] Token contains correct claims (userId, role, memberId)
- [ ] Change password with correct oldPassword → success
- [ ] Admin can create Trainer/Admin accounts

#### Member Tests
- [ ] Create member → auto generate QRCode
- [ ] Get all members with pagination
- [ ] Search members by name/email/phone
- [ ] Update member info
- [ ] Delete member (soft delete)

#### Membership Tests
- [ ] Create membership → auto create invoice
- [ ] Create membership → update member status = Active
- [ ] Get active membership of member
- [ ] Update endDate → recalculate status
- [ ] Expired membership → status = Expired

#### Invoice & Payment Tests
- [ ] Create payment → auto update invoice status
- [ ] Partial payment → invoice status = Pending
- [ ] Full payment → invoice status = Paid
- [ ] Get overdue invoices

#### Schedule Tests
- [ ] Create schedule → validate member has active membership
- [ ] Create schedule → check trainer availability
- [ ] Create schedule → check facility availability
- [ ] Trainer cannot have overlapping schedules

#### Checkin Tests
- [ ] Manual checkin validates active membership
- [ ] QR checkin with valid QRCode → success
- [ ] QR checkin with expired membership → error
- [ ] Cannot checkin twice in same day
- [ ] QR checkin without sessionId → success (general checkin)

#### Report Tests
- [ ] Active members count correct
- [ ] Revenue calculation correct
- [ ] Expiring soon list correct (7 days ahead)

---

## 🎯 SUMMARY - KEY DECISIONS

### ✅ KEPT SIMPLE
1. **Auth**: 4-field register, no OTP, auto Member, login ngay
2. **Roles**: 3 roles (Admin/Trainer/Member)
3. **Auto Logic**: 
   - Register → Create Member
   - Create Membership → Create Invoice
   - Create Payment → Update Invoice
4. **Database**: Bỏ OTP tables, simple audit (CreatedAt only)

### ✅ PRIORITIZED (Gym Core)
1. Member & Membership management
2. Trainer & Facility management
3. Schedule & Session
4. Checkin (manual + QR)
5. Invoice & Payment
6. Basic reports

### ⏸️ DEFERRED (Làm sau)
1. Docker & CI/CD
2. Rate limiting
3. Redis cache
4. Advanced audit log
5. Background jobs
6. OAuth2/2FA
7. In-app notifications

### 🎯 FOCUS ORDER
```
Week 1-2: Gym Core (Member, Membership, Checkin, Schedule)
Week 3:   Reports + NFR (QR, Export)
Week 4:   Testing + Documentation
Week 5:   Polish + Seed data + Video demo
```

---

**🏁 END OF SPECIFICATION**

✨ File này là blueprint hoàn chỉnh theo đúng yêu cầu dự án!
✨ Ưu tiên Gym Management core trước, yêu cầu chung sau!
✨ Bỏ những thứ không cần thiết (Docker, Rate limit, OAuth2)!

