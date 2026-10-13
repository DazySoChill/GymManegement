# Fix Lỗi Encoding Trong memberships.js

## ❌ VẤN ĐỀ:
File `wwwroot/js/memberships.js` có lỗi encoding UTF-8 ở dòng 9-13:

```javascript
// HIỆN TẠI (SAI):
const AVAILABLE_PACKAGES = [
  { id: 'basic', name: 'GÃ³i CÆ¡ Báº£n', ...
  { id: 'advanced', name: 'GÃ³i NÃ¢ng Cao', ...
  { id: 'vip', name: 'GÃ³i VIP', ...
  { id: 'annual', name: 'GÃ³i NÄƒm', ...
];
```

## ✅ CÁCH SỬA:

### Option 1: Sửa thủ công (NHANH NHẤT)
1. Mở file: `wwwroot/js/memberships.js`
2. Tìm dòng 9-13 (const AVAILABLE_PACKAGES)
3. **XÓA** toàn bộ đoạn code lỗi
4. **DÁN** code mới:

```javascript
const AVAILABLE_PACKAGES = [
  { id: 'basic', name: 'Gói Cơ Bản', price: 500000, durationDays: 30, description: '1 tháng - Sử dụng tất cả thiết bị' },
  { id: 'advanced', name: 'Gói Nâng Cao', price: 1200000, durationDays: 90, description: '3 tháng - Bao gồm 2 buổi PT/tháng' },
  { id: 'vip', name: 'Gói VIP', price: 2000000, durationDays: 180, description: '6 tháng - Không giới hạn PT + dinh dưỡng' },
  { id: 'annual', name: 'Gói Năm', price: 3500000, durationDays: 365, description: '12 tháng - Tất cả dịch vụ cao cấp' }
];
```

5. **LƯU** file với encoding UTF-8

### Option 2: PowerShell Script
Chạy lệnh:
```powershell
$file = "wwwroot/js/memberships.js"
$content = Get-Content $file -Raw -Encoding UTF8

# Replace broken text
$content = $content -replace "GÃ³i CÆ¡ Báº£n", "Gói Cơ Bản"
$content = $content -replace "GÃ³i NÃ¢ng Cao", "Gói Nâng Cao"
$content = $content -replace "GÃ³i VIP", "Gói VIP"  
$content = $content -replace "GÃ³i NÄƒm", "Gói Năm"
$content = $content -replace "thÃ¡ng", "tháng"
$content = $content -replace "Sá»­ dá»¥ng", "Sử dụng"
$content = $content -replace "táº¥t cáº£", "tất cả"
$content = $content -replace "thiáº¿t bá»‹", "thiết bị"
$content = $content -replace "Bao gá»"m", "Bao gồm"
$content = $content -replace "buá»•i", "buổi"
$content = $content -replace "KhÃ´ng", "Không"
$content = $content -replace "giá»›i háº¡n", "giới hạn"
$content = $content -replace "dinh dÆ°á»¡ng", "dinh dưỡng"
$content = $content -replace "Táº¥t cáº£", "Tất cả"
$content = $content -replace "dá»‹ch vá»¥", "dịch vụ"

# Save file
$content | Out-File $file -Encoding UTF8 -NoNewline
Write-Host "✅ Fixed encoding in memberships.js"
```

## CÁC CHỖ KHÁC CÓ THỂ BỊ LỖI TƯƠNG TỰ:

Sau khi fix AVAILABLE_PACKAGES, quét tiếp:

### Dòng 173: (Có thể bị lỗi)
```javascript
// SAI:
<label for="startDatePicker">NgÃ y báº¯t Ä'áº§u:</label>

// ĐÚNG:
<label for="startDatePicker">Ngày bắt đầu:</label>
```

### Dòng 312-313:
```javascript
// SAI:
error.message.toLowerCase().includes('Ä'Ã£ cÃ³ gÃ³i táº­p')
errorMessage = 'Báº¡n Ä'Ã£ cÃ³ gÃ³i táº­p Ä'ang hoáº¡t Ä'á»™ng...'

// ĐÚNG:
error.message.toLowerCase().includes('đã có gói tập')
errorMessage = 'Bạn đã có gói tập đang hoạt động...'
```

### Dòng 371:
```javascript
// SAI:
${m.daysRemaining} ngÃ y

// ĐÚNG:
${m.daysRemaining} ngày
```

### Dòng 372:
```javascript
// SAI:
Há»§y GÃ³i

// ĐÚNG:
Hủy Gói
```

### Dòng 526:
```javascript
// SAI:
-- Chá»n thÃ nh viÃªn --

// ĐÚNG:
-- Chọn thành viên --
```

### Dòng 629:
```javascript
// SAI:
TÃªn gÃ³i

// ĐÚNG:
Tên gói
```

### Dòng 634:
```javascript
// SAI:
GiÃ¡ (VNÄ)

// ĐÚNG:
Giá (VNĐ)
```

### Dòng 639:
```javascript
// SAI:
NgÃ y báº¯t Ä'áº§u

// ĐÚNG:
Ngày bắt đầu
```

### Dòng 644:
```javascript
// SAI:
NgÃ y káº¿t thÃºc

// ĐÚNG:
Ngày kết thúc
```

---

## NGUYÊN NHÂN:

File được lưu với encoding sai (có thể là Windows-1252 hay Latin-1) thay vì UTF-8.

## GIẢI PHÁP DÀI HẠN:

1. VS Code: File → Preferences → Settings → Search "encoding"
2. Set "Files: Encoding" = "utf8"
3. Reopen file và chọn "Reopen with Encoding" → UTF-8
4. Save lại

---

## TEST SAU KHI SỬA:

1. Mở trang Gói Tập trong browser
2. Kiểm tra dropdown chọn gói:
   - ✅ "Gói Cơ Bản" (không phải "GÃ³i CÆ¡ Báº£n")
   - ✅ "Gói Nâng Cao"
   - ✅ "Gói VIP"
   - ✅ "Gói Năm"
3. Tất cả text hiển thị tiếng Việt đúng

---

**ƯU TIÊN:** Fix dòng 9-13 trước (AVAILABLE_PACKAGES) vì đây là nơi user nhìn thấy nhiều nhất!
