# Hướng Dẫn Sửa Text Tiếng Việt Trong Admin JS

## Các Vấn Đề Tìm Thấy

### 1. STATUS VALUES (Giá trị trạng thái)
**File: payments.js, invoices.js, và nhiều files khác**

❌ **Sai:**
```javascript
<option value="Completed">Completed</option>
<option value="Pending">Pending</option>
<option value="Failed">Failed</option>
```

✅ **Đúng:**
```javascript
<option value="Completed">Hoàn thành</option>
<option value="Pending">Chờ xử lý</option>
<option value="Failed">Thất bại</option>
```

**LƯU Ý:** Giữ `value` là tiếng Anh (vì backend expect English), CHỈ sửa text hiển thị.

---

### 2. PAYMENT METHODS (Phương thức thanh toán)  
**File: payments.js**

❌ **Sai:**
```javascript
<option value="Cash">Cash</option>
<option value="QRCode">QRCode</option>
<option value="Card">Card</option>
<option value="BankTransfer">BankTransfer</option>
```

✅ **Đúng:**
```javascript
<option value="Cash">Tiền mặt</option>
<option value="QRCode">QR Code</option>
<option value="Card">Thẻ</option>
<option value="BankTransfer">Chuyển khoản</option>
```

---

### 3. EMPTY STATES & LOADING
**File: Tất cả JS files**

❌ **Sai:**
```javascript
console.error('Error loading payments:', error);
showError('Error occurred');
```

✅ **Đúng:**
```javascript
console.error('Lỗi tải danh sách thanh toán:', error);
showError('Đã xảy ra lỗi');
```

**Console.error có thể giữ tiếng Anh** (dev debug) HOẶC sửa thành tiếng Việt (user-facing errors).

---

## CÁC THAY ĐỔI CỤ THỂ CHO TỪNG FILE

### PAYMENTS.JS

#### Dòng ~228-229: Status badge
```javascript
// SỬA TỪ:
const statusBadge = payment.status === 'Completed' ? 'badge-success' :
                  payment.status === 'Failed' ? 'badge-danger' : 'badge-warning';

// THÀNH (giữ nguyên logic, CHỈ hiển thị text):
// Không cần sửa - đây là code logic, không phải display text
```

#### Dòng ~346-348: Status options
```javascript
// SỬA TỪ:
<option value="Completed">Completed</option>
<option value="Pending">Pending</option>
<option value="Failed">Failed</option>

// THÀNH:
<option value="Completed">Hoàn thành</option>
<option value="Pending">Chờ xử lý</option>
<option value="Failed">Thất bại</option>
```

#### Dòng ~324-329: Payment methods
```javascript
// SỬA TỪ:
<option value="Cash">Cash</option>
<option value="QRCode">QRCode</option>
<option value="Card">Card</option>
<option value="BankTransfer">BankTransfer</option>
<option value="MoMo">MoMo</option>
<option value="ZaloPay">ZaloPay</option>

// THÀNH:
<option value="Cash">Tiền mặt</option>
<option value="QRCode">QR Code</option>
<option value="Card">Thẻ</option>
<option value="BankTransfer">Chuyển khoản</option>
<option value="MoMo">MoMo</option>
<option value="ZaloPay">ZaloPay</option>
```

---

### INVOICES.JS

#### Status options (similar to payments)
```javascript
// Tìm và sửa:
<option value="Paid">Paid</option> → <option value="Paid">Đã thanh toán</option>
<option value="Unpaid">Unpaid</option> → <option value="Unpaid">Chưa thanh toán</option>
<option value="Overdue">Overdue</option> → <option value="Overdue">Quá hạn</option>
<option value="Cancelled">Cancelled</option> → <option value="Cancelled">Đã hủy</option>
```

---

### MEMBERSHIPS.JS, SCHEDULES.JS, SESSIONS.JS

#### Status options
```javascript
// Tìm các dạng:
<option value="Active">Active</option> → <option value="Active">Hoạt động</option>
<option value="Inactive">Inactive</option> → <option value="Inactive">Không hoạt động</option>
<option value="Expired">Expired</option> → <option value="Expired">Hết hạn</option>
<option value="Cancelled">Cancelled</option> → <option value="Cancelled">Đã hủy</option>
```

---

### CHECKINS.JS

#### Method options
```javascript
// Tìm:
<option value="QRCode">QRCode</option> → <option value="QRCode">QR Code</option>
<option value="Manual">Manual</option> → <option value="Manual">Thủ công</option>
<option value="Card">Card</option> → <option value="Card">Thẻ</option>
```

---

## CÁCH THỰC HIỆN

### Option 1: Manual Fix (Recommended)
1. Mở từng file JS
2. Dùng Find & Replace (Ctrl+H) với pattern cụ thể
3. Verify từng thay đổi trước khi save

### Option 2: Script Fix
Tôi có thể tạo script PowerShell hoặc Python để auto-replace.

---

## CHECKLIST

### ✅ Đã sửa:
- [x] payments.js - amount validation (step=1)
- [x] invoices.js - amount validation (step=1)

### ⏳ Cần sửa:
- [ ] payments.js - status options (Completed, Pending, Failed)
- [ ] payments.js - payment methods (Cash, Card, etc.)
- [ ] invoices.js - status options (Paid, Unpaid, etc.)
- [ ] memberships.js - status options (Active, Inactive, etc.)
- [ ] schedules.js - status options
- [ ] sessions.js - status options
- [ ] checkins.js - method options
- [ ] All files - console.error messages (optional)

---

## LƯU Ý QUAN TRỌNG

1. **KHÔNG sửa `value` attribute** - chỉ sửa text giữa tags:
   ```html
   <option value="Completed">Hoàn thành</option>
             ^^^^^^^^^^^^^^^   ^^^^^^^^^^^^^
             GIỮ NGUYÊN        SỬA CÁI NÀY
   ```

2. **Test sau mỗi file sửa** - đảm bảo không break functionality

3. **Backup trước khi sửa** - commit git trước khi bắt đầu

4. **Consistency** - dùng cùng terminology trong tất cả files

---

## QUY TẮC TERMINOLOGY

| English | Vietnamese | Notes |
|---------|------------|-------|
| Completed | Hoàn thành | Status |
| Pending | Chờ xử lý | Status |
| Failed | Thất bại | Status |
| Active | Hoạt động | Status |
| Inactive | Không hoạt động | Status |
| Paid | Đã thanh toán | Invoice status |
| Unpaid | Chưa thanh toán | Invoice status |
| Overdue | Quá hạn | Invoice status |
| Cancelled | Đã hủy | Status |
| Expired | Hết hạn | Membership status |
| Cash | Tiền mặt | Payment method |
| Card | Thẻ | Payment method |
| QRCode | QR Code | Payment method |
| BankTransfer | Chuyển khoản | Payment method |
| Manual | Thủ công | Check-in method |

