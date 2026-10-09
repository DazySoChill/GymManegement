# 🏋️ SQL2 - SIMPLIFIED DATABASE SCHEMA

> **Database mới đơn giản hóa theo API_SPECIFICATION_SIMPLIFIED.md**

---

## 📂 CẤU TRÚC FILES

```
SQL2/
├── README.md                    - File này
├── 00_DROP_AND_CREATE_DB.sql   - Drop/Create database
├── 01_SCHEMA_SIMPLIFIED.sql    - Schema đơn giản (core tables only)
├── 02_SEED_DATA.sql            - Seed data 2000+ records
├── 03_STORED_PROCEDURES.sql    - Basic stored procedures
├── CHANGES_FOR_CODE.md         - Hướng dẫn sửa BUS/DAL/DTOs
└── MIGRATION_GUIDE.md          - Hướng dẫn migrate từ SQL cũ
```

---

## 🎯 TRIẾT LÝ THIẾT KẾ

### ✅ GIẢN ĐƠN HÓA
1. **Bỏ RBAC phức tạp**: Không có Roles, Permissions, RolePermissions tables
2. **Bỏ OTP system**: Không có EmailVerificationOTP, PasswordResetToken
3. **Bỏ RefreshTokens**: JWT đơn giản, không rotation
4. **Users table đơn giản**: Role là string (Admin/Trainer/Member)
5. **Không FK từ Users**: Tìm Member/Trainer bằng Email

### ✅ GIỮ LẠI
1. **Core business tables**: Members, Trainers, Facilities, Memberships, Schedules, Sessions, Checkins, Invoices, Payments
2. **Soft delete**: IsDeleted, DeletedAt
3. **Basic audit**: CreatedAt, UpdatedAt (không có triggers phức tạp)
4. **Seed data**: 2000+ records

### ❌ BỎ
1. ❌ Roles, Permissions, RolePermissions tables
2. ❌ EmailVerificationOTP table
3. ❌ PasswordResetToken table
4. ❌ RefreshTokens table
5. ❌ AuditLogs table (phức tạp)
6. ❌ Audit triggers
7. ❌ RowVersion (concurrency - làm sau nếu cần)
8. ❌ Users.PasswordSalt (BCrypt đã có salt)
9. ❌ Users.FailedLoginCount, LockedUntil (security nâng cao - làm sau)

---

## 🚀 CÁCH SỬ DỤNG

### STEP 1: Chạy SQL scripts theo thứ tự

```bash
# 1. Tạo database mới (hoặc drop + recreate)
sqlcmd -S localhost -U sa -P yourpassword -i 00_DROP_AND_CREATE_DB.sql

# 2. Tạo schema
sqlcmd -S localhost -U sa -P yourpassword -d GymDb -i 01_SCHEMA_SIMPLIFIED.sql

# 3. Seed data
sqlcmd -S localhost -U sa -P yourpassword -d GymDb -i 02_SEED_DATA.sql

# 4. Stored procedures
sqlcmd -S localhost -U sa -P yourpassword -d GymDb -i 03_STORED_PROCEDURES.sql
```

Hoặc chạy trong SSMS/Azure Data Studio:
1. Mở từng file .sql
2. Chạy theo thứ tự 00 → 01 → 02 → 03

---

### STEP 2: Update connection string

```json
"ConnectionStrings": {
  "GymDb": "Server=localhost;Database=GymDb;User Id=sa;Password=yourpassword;TrustServerCertificate=true;"
}
```

---

### STEP 3: Sửa code (xem CHANGES_FOR_CODE.md)

1. **Entities**: Sửa Users entity (bỏ RoleId FK, thêm Role string)
2. **DTOs**: Sửa RegisterRequest, LoginResponse
3. **Repositories**: Sửa UserRepository (query by email, không FK)
4. **Services**: Sửa AuthService (register logic, login logic)

---

## 📊 SO SÁNH VỚI SQL CŨ

| Feature | SQL Cũ | SQL2 Mới | Lý do |
|---------|--------|----------|-------|
| **Tables** | 15+ tables | 10 tables | Bỏ RBAC, OTP, RefreshTokens |
| **Users.Role** | FK → Roles table | String (Admin/Trainer/Member) | Đơn giản |
| **OTP** | EmailVerificationOTP table | ❌ Không có | Không cần verify email |
| **Audit** | AuditLogs + Triggers | Chỉ CreatedAt/UpdatedAt | Đơn giản |
| **Soft Delete** | ✅ Có | ✅ Có | Giữ lại |
| **Seed Data** | 2000+ records | 2000+ records | Giữ lại |

---

## ⚠️ LƯU Ý

### 1. Không tương thích ngược
- Database mới **KHÔNG TƯƠNG THÍCH** với code cũ
- Phải update BUS/DAL/DTOs (xem CHANGES_FOR_CODE.md)

### 2. Migration data
- Nếu có data production cũ, xem MIGRATION_GUIDE.md
- Nếu dev/test: Drop DB cũ, tạo mới

### 3. Testing
- Sau khi chạy SQL, test tất cả APIs
- Verify Register → Login flow
- Verify Member auto-creation

---

## 🎯 PRIORITIES

### ✅ Đã làm (trong SQL2)
1. Schema đơn giản (10 core tables)
2. Seed data 2000+ records
3. Basic stored procedures (CRUD)

### ⏸️ Chưa làm (làm sau nếu cần)
1. Advanced stored procedures (reports)
2. Views (dashboard, analytics)
3. Indexes optimization
4. Stored procedures for exports

---

## 📞 HỖ TRỢ

- Xem API specification: `../API_SPECIFICATION_SIMPLIFIED.md`
- Xem code changes: `CHANGES_FOR_CODE.md`
- Xem migration guide: `MIGRATION_GUIDE.md`

---

**Created**: 2026-10-09
**Version**: 1.0 - Simplified Schema
