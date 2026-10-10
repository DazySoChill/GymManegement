# Hướng dẫn Test thủ công - Gym Management System

## Thông tin tài khoản test

### Tài khoản Admin
- **Username:** `admin`
- **Password:** `gym@2026`
- **Role:** SuperAdmin
- **Quyền:** Truy cập tất cả các chức năng, có quyền xóa dữ liệu

### Tài khoản Trainer
- **Username:** `trainer1`
- **Password:** `gym@2026`
- **Role:** Trainer
- **Quyền:** Dashboard, Lịch tập, Check-in

### Tài khoản Member
- **Username:** `member1`
- **Password:** `gym@2026`
- **Role:** Member
- **Quyền:** Dashboard (cá nhân), Lịch tập (chỉ xem), Gói tập (cá nhân), Check-in (QR)

---

## Kịch bản test theo Role

### 1. Test với Admin (SuperAdmin)

#### 1.1 Đăng nhập
- Truy cập: `http://localhost:5250/login.html`
- Nhập username: `admin`, password: `gym@2026`
- **Kỳ vọng:** Chuyển đến trang dashboard, hiển thị đầy đủ 9 menu (Tổng quan, Hội viên, Gói tập, HLV, Phòng/Thiết bị, Lịch tập, Check-in, Hóa đơn, Báo cáo)

#### 1.2 Dashboard
- **Kỳ vọng:** 
  - Hiển thị 4 thống kê: Hội viên hoạt động, Sắp hết hạn, Hóa đơn quá hạn, Doanh thu tháng
  - Danh sách hóa đơn quá hạn (nếu có)
  - Thông báo "Chức năng tạm thời không khả dụng" cho phần sắp hết hạn (API 404)

#### 1.3 Quản lý Hội viên
- **Tạo hội viên mới:**
  - Click "Thêm hội viên"
  - Nhập: Họ tên, Email, SĐT, Ngày tham gia
  - **Kỳ vọng:** Tạo thành công, hiển thị toast "Thêm thành công"
  
- **Sửa hội viên:**
  - Click icon ✏️ trên bất kỳ hội viên
  - Sửa thông tin
  - **Kỳ vọng:** Cập nhật thành công

- **Xóa hội viên:**
  - **Kỳ vọng:** Nút xóa 🗑️ hiển thị (chỉ SuperAdmin)
  - Click xóa, xác nhận
  - **Kỳ vọng:** Xóa thành công

#### 1.4 Quản lý Gói tập
- Chọn hội viên từ dropdown
- Click "Xem"
- **Kỳ vọng:** Hiển thị danh sách gói tập của hội viên đó
- **Lưu ý:** Nút "Đăng ký gói tập" bị ẩn với thông báo "Tạo gói tập tạm thời không khả dụng" (API 500)

#### 1.5 Quản lý Huấn luyện viên
- **Tạo HLV:** Nhập họ tên, email, chuyên môn → Thành công
- **Sửa HLV:** Click ✏️ → Sửa → Thành công
- **Xóa HLV:** Nút 🗑️ chỉ hiển thị cho SuperAdmin

#### 1.6 Quản lý Phòng/Thiết bị
- **Tạo phòng:** Nhập tên, mô tả, trạng thái → Thành công
- **Sửa/Xóa:** Tương tự như trên, xóa chỉ cho SuperAdmin

#### 1.7 Quản lý Lịch tập
- **Đặt lịch:** Click "Đặt lịch tập", chọn hội viên, HLV, phòng, thời gian → Thành công
- **Xóa lịch:** Nút xóa chỉ hiển thị cho SuperAdmin

#### 1.8 Check-in
- **Check-in thủ công:** Click "Check-in thủ công", chọn hội viên, session → Thành công
- **Check-in QR:** Click "Check-in QR", nhập mã QR, chọn session → Thành công
- **Kỳ vọng:** Hiển thị lịch sử check-in của tất cả hội viên

#### 1.9 Quản lý Hóa đơn
- **Tạo hóa đơn:** Chọn hội viên, nhập số tiền, hạn thanh toán → Thành công
- **Thanh toán:** Click 💰, nhập số tiền, phương thức → Thành công
- **Xóa hóa đơn:** Nút xóa chỉ hiển thị cho SuperAdmin

#### 1.10 Báo cáo
- Chọn tháng/năm, click "Xem báo cáo"
- **Kỳ vọng:** Hiển thị:
  - Tổng doanh thu, đã thu, chờ thanh toán, số hóa đơn
  - Chi tiết hóa đơn
  - Danh sách hội viên đang hoạt động

---

### 2. Test với Member

#### 2.1 Đăng nhập
- Username: `member1`, Password: `gym@2026`
- **Kỳ vọng:** Chuyển đến dashboard, chỉ hiển thị 4 menu: Tổng quan, Lịch tập, Gói tập, Check-in

#### 2.2 Dashboard (Member)
- **Kỳ vọng:**
  - Hiển thị gói tập của member
  - Hiển thị lịch sử check-in gần đây
  - Tiêu đề thay đổi: "🎫 Gói tập của bạn", "✅ Check-in gần đây"

#### 2.3 Lịch tập
- **Kỳ vọng:**
  - Tiêu đề: "📅 Lịch tập (Chỉ xem)"
  - Không có nút "Đặt lịch tập"
  - Chỉ xem danh sách lịch tập, không thể sửa/xóa

#### 2.4 Gói tập
- **Kỳ vọng:**
  - Tiêu đề: "🎫 Gói tập của bạn"
  - Dropdown chọn hội viên bị ẩn
  - Tự động hiển thị gói tập của member hiện tại
  - Không có nút "Đăng ký gói tập"

#### 2.5 Check-in
- **Kỳ vọng:**
  - Tiêu đề: "✅ Lịch sử Check-in của bạn"
  - Chỉ hiển thị check-in của member hiện tại
  - Chỉ có nút "📷 Check-in QR", không có nút "Check-in thủ công"

#### 2.6 Truy cập trang không được phép
- Thử truy cập URL trực tiếp: `/index.html#invoices` hoặc `/index.html#members`
- **Kỳ vọng:** Hiển thị toast "Bạn không có quyền truy cập trang này", chuyển về Dashboard

---

### 3. Test với Admin (không phải SuperAdmin)

Nếu có tài khoản Admin (role = "Admin", không phải "SuperAdmin"):
- **Kỳ vọng:**
  - Truy cập tất cả các menu như SuperAdmin
  - **NHƯNG:** Tất cả nút xóa (🗑️) đều bị ẩn
  - Chỉ có quyền xem, tạo, sửa - không có quyền xóa

---

## Input test cần thiết

### Tạo Member mới
```
Họ tên: Nguyễn Văn Test
Email: test@example.com
SĐT: 0901234567
Ngày sinh: 1995-01-15
Ngày tham gia: 2026-01-01
Trạng thái: Active
```

### Tạo Trainer mới
```
Họ tên: Trần Thị HLV
Email: hlv@gym.com
SĐT: 0912345678
Chuyên môn: Yoga & Cardio
```

### Tạo Phòng mới
```
Tên: Phòng Yoga
Mô tả: Phòng tập yoga với sức chứa 20 người
Trạng thái: Hoạt động
```

### Đặt lịch tập
```
Hội viên: [Chọn từ dropdown]
HLV: [Chọn từ dropdown]
Phòng: [Chọn từ dropdown]
Bắt đầu: [Ngày giờ hiện tại + 1 giờ]
Kết thúc: [Bắt đầu + 1 giờ]
```

### Tạo Hóa đơn
```
Hội viên: [Chọn từ dropdown]
Tổng tiền: 1500000 (VNĐ)
Hạn thanh toán: [Ngày hiện tại + 7 ngày]
```

### Check-in QR
```
Giá trị QR Code: QR-MEMBER-001 (hoặc bất kỳ chuỗi nào)
Session: [Chọn từ dropdown session có sẵn]
```

---

## Checklist tổng quan

### Chức năng Admin
- [x] Đăng nhập thành công
- [x] Hiển thị đầy đủ 9 menu
- [x] Dashboard hiển thị thống kê
- [x] CRUD Member (SuperAdmin có nút xóa)
- [x] CRUD Trainer (SuperAdmin có nút xóa)
- [x] CRUD Facility (SuperAdmin có nút xóa)
- [x] CRUD Schedule (SuperAdmin có nút xóa)
- [x] CRUD Invoice (SuperAdmin có nút xóa)
- [x] Xem gói tập theo hội viên
- [x] Check-in thủ công và QR
- [x] Xem báo cáo doanh thu

### Chức năng Member
- [x] Đăng nhập thành công
- [x] Chỉ hiển thị 4 menu (Dashboard, Lịch tập, Gói tập, Check-in)
- [x] Dashboard hiển thị gói tập và check-in cá nhân
- [x] Lịch tập chỉ xem (không có nút tạo/sửa/xóa)
- [x] Gói tập chỉ xem của mình
- [x] Check-in chỉ có QR (không có thủ công)
- [x] Bảo vệ route: không truy cập được trang không được phép

### Xử lý API lỗi
- [x] POST /api/membership → Ẩn nút "Đăng ký gói tập", hiển thị thông báo
- [x] GET /api/membership/active, /expiring → Skip, hiển thị "Chức năng tạm thời không khả dụng"
- [x] DELETE operations → Chỉ hiển thị cho SuperAdmin

---

## Kết luận

**Pass rate mục tiêu:** 85-90% các chức năng chính hoạt động

**Các chức năng chính:**
1. ✅ Đăng nhập/Đăng xuất
2. ✅ Phân quyền theo role (Admin/Member)
3. ✅ CRUD Members, Trainers, Facilities, Schedules, Invoices
4. ✅ Xem gói tập
5. ✅ Check-in (Manual + QR)
6. ✅ Thanh toán hóa đơn
7. ✅ Báo cáo doanh thu

**Các chức năng tạm thời không khả dụng (API lỗi):**
1. ❌ Tạo gói tập mới (POST /api/membership → 500)
2. ❌ Xem gói tập sắp hết hạn (GET /api/membership/expiring → 404)
3. ❌ Đăng ký session (POST /api/session → 500)

**Giới hạn quyền:**
- Admin: Xem, tạo, sửa (không xóa)
- SuperAdmin: Xem, tạo, sửa, xóa
- Member: Chỉ xem dữ liệu cá nhân, check-in QR

---

**Cập nhật:** 2026-01-10
