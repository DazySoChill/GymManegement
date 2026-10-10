# 🎯 BẮT ĐẦU TEST NGAY TẠI ĐÂY

## 📋 Bạn cần làm gì?

Test hệ thống với **2 vai trò** để xem **sự khác biệt** giữa Admin và Member:

---

## 🚀 BƯỚC 1: Khởi động server

```bash
dotnet run
```

Chờ thông báo: `Now listening on: http://localhost:5250`

---

## 🔴 BƯỚC 2: Test với ADMIN (5 phút)

### 2.1. Mở browser
```
http://localhost:5250/login.html
```

### 2.2. Login với Admin
- Username: `gymadmin`
- Password: `Gym@2026`
- Click "Đăng nhập"

### 2.3. Kiểm tra điều này:

| ✓ | Kiểm tra | Kết quả mong đợi |
|---|----------|------------------|
| [ ] | Đếm số mục menu bên trái | **Phải có 9 mục** |
| [ ] | Click "👤 Hội viên" | Có nút **"+ Thêm hội viên"** |
| [ ] | Click "✅ Check-in" | Có **2 nút** (Manual + QR) |
| [ ] | Click "📈 Báo cáo" | Trang hiển thị bình thường |
| [ ] | Click "🧾 Hóa đơn" | Trang hiển thị bình thường |

**Nếu tất cả đúng → Admin PASS ✅**

---

## 🟢 BƯỚC 3: Test với MEMBER (5 phút)

### 3.1. Đăng xuất khỏi Admin
- Click avatar góc trên bên phải
- Click "Đăng xuất"

### 3.2. Tạo tài khoản Member mới
- Click tab **"Tạo tài khoản"**
- Điền thông tin:
  - Username: `testmember`
  - Email: `testmember@gym.com`
  - Password: `Test@2026`
- Click "Đăng ký"
- Chờ thông báo thành công

### 3.3. Login với Member mới
- Tab "Đăng nhập" tự động được chọn
- Username: `testmember`
- Password: `Test@2026`
- Click "Đăng nhập"

### 3.4. Kiểm tra điều này:

| ✓ | Kiểm tra | Kết quả mong đợi |
|---|----------|------------------|
| [ ] | Đếm số mục menu bên trái | **Chỉ có 4 mục** (Tổng quan, Lịch tập, Gói tập, Check-in) |
| [ ] | Tìm mục "👤 Hội viên" | **KHÔNG CÓ** (đã bị ẩn) |
| [ ] | Tìm mục "📈 Báo cáo" | **KHÔNG CÓ** (đã bị ẩn) |
| [ ] | Tìm mục "🧾 Hóa đơn" | **KHÔNG CÓ** (đã bị ẩn) |
| [ ] | Click "✅ Check-in" | **Chỉ có 1 nút** (QR) |

**Nếu tất cả đúng → Member PASS ✅**

---

## 🔒 BƯỚC 4: Test bảo mật (3 phút) - QUAN TRỌNG!

### 4.1. Vẫn đang login với Member
### 4.2. Thử truy cập trang admin bằng URL trực tiếp:

Copy-paste URL này vào thanh địa chỉ:
```
http://localhost:5250/index.html#members
```

### 4.3. Kết quả mong đợi:

| ✓ | Kiểm tra | Kết quả mong đợi |
|---|----------|------------------|
| [ ] | Hiển thị thông báo lỗi đỏ | "Bạn không có quyền truy cập trang này" |
| [ ] | Trang tự động chuyển về | Dashboard (Tổng quan) |
| [ ] | Trang "Hội viên" KHÔNG load | Phải bị chặn |

### 4.4. Thử thêm các URL này (phải đều bị chặn):
- `http://localhost:5250/index.html#invoices`
- `http://localhost:5250/index.html#reports`
- `http://localhost:5250/index.html#trainers`

**Nếu tất cả đều bị chặn → Security PASS ✅**

---

## 📊 KẾT QUẢ SO SÁNH

### Bảng so sánh Admin vs Member:

| Tính năng | Admin | Member |
|-----------|-------|--------|
| **Số menu items** | 9 | 4 |
| **Xem trang "Hội viên"** | ✅ Có | ❌ Không |
| **Xem trang "Hóa đơn"** | ✅ Có | ❌ Không |
| **Xem trang "Báo cáo"** | ✅ Có | ❌ Không |
| **Nút Check-in** | 2 nút | 1 nút |
| **Tạo hội viên mới** | ✅ Có | ❌ Không |
| **Dashboard** | Toàn bộ hệ thống | Chỉ dữ liệu cá nhân |

---

## ✅ PASS / ❌ FAIL?

### ✅ HỆ THỐNG PASS NẾU:
- ✅ Admin thấy đầy đủ 9 menu items
- ✅ Member chỉ thấy 4 menu items
- ✅ Member KHÔNG thể truy cập các trang admin (bị chặn + hiện lỗi)
- ✅ Cả 2 role đều login/logout được bình thường

### ❌ HỆ THỐNG FAIL NẾU:
- ❌ Member thấy được hoặc truy cập được trang admin
- ❌ Số lượng menu items không đúng
- ❌ Không có thông báo lỗi khi Member cố truy cập trang admin
- ❌ Trang bị crash hoặc lỗi

---

## 📸 SCREENSHOTS QUAN TRỌNG

### Chụp màn hình những thứ này để làm bằng chứng:

**Admin:**
1. Menu sidebar (9 items)
2. Trang Members với nút "+ Thêm hội viên"
3. Trang Check-in với 2 nút

**Member:**
1. Menu sidebar (4 items)
2. Trang Check-in với 1 nút
3. Thông báo lỗi khi cố truy cập trang admin

---

## 🎓 KIỂM TRA KỸ THUẬT (Optional - Dành cho dev)

### Mở DevTools (F12) → Console, gõ:

**Kiểm tra role hiện tại:**
```javascript
JSON.parse(localStorage.getItem('user')).role
```

**Kết quả:**
- Admin login → `"Admin"` hoặc `"SuperAdmin"`
- Member login → `"Member"`

**Kiểm tra token:**
```javascript
localStorage.getItem('accessToken')
```

**Kết quả:** Phải có chuỗi JWT dài (bắt đầu bằng `eyJ...`)

---

## ⏱️ THỜI GIAN DỰ KIẾN

- ✅ Admin test: **5 phút**
- ✅ Tạo + test Member: **5 phút**
- ✅ Test bảo mật: **3 phút**
- 📸 Chụp screenshots: **2 phút**
- **⏰ Tổng cộng: ~15 phút**

---

## 🐛 NẾU GẶP LỖI

### Lỗi: "Cannot connect to server"
**Giải pháp:** Kiểm tra server có chạy không (phải thấy `Now listening on: http://localhost:5250`)

### Lỗi: "Login failed - 401"
**Giải pháp:** 
- Kiểm tra username/password đúng chưa
- Kiểm tra database có connect được không

### Lỗi: Member vẫn thấy menu admin
**Giải pháp:**
- Hard refresh browser (Ctrl + Shift + R)
- Clear cache và thử lại
- Kiểm tra file `wwwroot/js/app.js`

---

## 📚 TÀI LIỆU CHI TIẾT HƠN

Nếu cần test chi tiết hơn, xem các file này:

1. **QUICK_TEST_CHECKLIST.md** ← Bạn đang ở đây
2. **VISUAL_TEST_GUIDE.md** ← Có hướng dẫn screenshots chi tiết
3. **STEP_BY_STEP_TEST_GUIDE.md** ← Test từng bước với bảng chi tiết
4. **MANUAL_TEST_RESULTS.md** ← Template ghi kết quả đầy đủ
5. **TESTING_DOCUMENTATION_INDEX.md** ← Index tất cả documents

---

## 🎯 SAU KHI TEST XONG

### Nếu PASS:
1. ✅ Chụp screenshots quan trọng
2. ✅ Điền kết quả vào phần dưới
3. ✅ Hệ thống sẵn sàng demo/production

### Nếu FAIL:
1. ❌ Ghi lại lỗi cụ thể
2. ❌ Chụp screenshot lỗi
3. ❌ Báo với developer để fix

---

## ✍️ GHI KẾT QUẢ TEST CỦA BẠN

**Ngày test:** ________________  
**Người test:** ________________  
**Browser:** ________________

### Kết quả:

| Test | Kết quả |
|------|---------|
| Admin (9 menu items) | [ ✓ PASS / ✗ FAIL ] |
| Member (4 menu items) | [ ✓ PASS / ✗ FAIL ] |
| Bảo mật (chặn truy cập) | [ ✓ PASS / ✗ FAIL ] |
| **TỔNG KẾT** | [ ✓ PASS / ✗ FAIL ] |

### Ghi chú:
```
________________________________________________________
________________________________________________________
________________________________________________________
```

---

## 🎉 CHÚC BẠN TEST THÀNH CÔNG!

**Câu hỏi?** Đọc file `TESTING_DOCUMENTATION_INDEX.md` để tìm thêm hướng dẫn.

---

**📍 BẮT ĐẦU NGAY:**
1. Mở terminal → `dotnet run`
2. Mở browser → `http://localhost:5250/login.html`
3. Làm theo bảng checklist ở trên ⬆️

**LET'S GO! 🚀**
