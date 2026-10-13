# 🚀 Quick Test Guide - 2026-10-11

**QUAN TRỌNG:** Refresh browser trước khi test: `Ctrl + Shift + R`

---

## ✅ 7 Features Cần Test

### 1️⃣ Members Edit
```
📍 Quản lý Member → Click ✏️ Sửa → Đổi thông tin → Click "Cập Nhật"
✅ Expect: Success toast + data updated
```

### 2️⃣ Trainers Edit
```
📍 Huấn luyện viên → Click ✏️ Sửa → Đổi thông tin → Click "Cập Nhật"
✅ Expect: Success toast + data updated
```

### 3️⃣ Schedules Facility
```
📍 Lịch Class → Click "Thêm Lịch" → Check Phòng Tập dropdown
✅ Expect: Dropdown có facilities (Available/Active only)
```

### 4️⃣ Invoice Filter by Member ID
```
📍 Hóa Đơn → Nhập Member ID: 1 → Click 🔍 Tìm
✅ Expect: Chỉ hiện invoices của member 1
```

### 5️⃣ Invoice Filter by Status
```
📍 Hóa Đơn → Chọn "Pending" → Click 🔍 Tìm
✅ Expect: Chỉ hiện invoices Pending
```

### 6️⃣ Invoice Custom Package
```
📍 Hóa Đơn → Tạo Hóa Đơn → Chọn "✏️ Gói Tự Chọn"
→ Nhập tên: "Gói test"
→ Nhập giá: 1500000
→ Click "Tạo Hóa Đơn"
✅ Expect: Success! Description có "Gói tự chọn: Gói test"
```

### 7️⃣ Payment from Pending Invoice
```
📍 Thanh Toán → Check section "⏳ Hóa Đơn Chưa Thanh Toán"
✅ Expect: Thấy pending invoices

→ Click "💵 Thanh toán" on any invoice
→ Chọn Cash → Click "✅ Xác Nhận Thanh Toán"
✅ Expect: 
   - Invoice biến mất từ section "Chưa Thanh Toán"
   - Payment hiện trong section "Lịch Sử Thanh Toán"
```

---

## 🐛 Nếu Có Lỗi

1. **F12 → Console tab**
2. Copy error message
3. Copy network request (F12 → Network → XHR)
4. Screenshot màn hình
5. Báo lại cho tôi!

---

## 📋 Expected Console Logs

### Members/Trainers Edit:
```
✅ Edit membership form event listener attached
🔥 FORM SUBMITTED! Starting validation...
=== EDIT MEMBERSHIP VALIDATION ===
✅ All validation passed
📤 PUT request payload: {...}
```

### Schedules:
```
Facilities loaded: [...]
Selected facility: {...}
```

### Invoices:
```
Loading invoices with filters: {...}
Package selected: custom
=== INVOICE FORM VALIDATION ===
✅ All validation passed
```

### Payments:
```
=== PAY INVOICE ===
Invoice ID: 1
Payment data: {...}
```

---

## ✅ Final Checklist

- [ ] Hard refresh: `Ctrl + Shift + R`
- [ ] Test Members edit
- [ ] Test Trainers edit
- [ ] Test Schedules facility
- [ ] Test Invoice filter (Member ID)
- [ ] Test Invoice filter (Status)
- [ ] Test Invoice custom package
- [ ] Test Payment from pending invoice
- [ ] Check console logs (no red errors)
- [ ] All features working? ✅

---

**Nếu tất cả OK → DONE! 🎉**

**Nếu có lỗi → Copy console logs và báo lại!**
