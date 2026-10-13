# Manual Fix for memberships.js UTF-8 Encoding

## Problem
The file `wwwroot/js/memberships.js` contains UTF-8 mojibake (double-encoded Vietnamese text). Automated replacement via PowerShell is failing due to encoding mismatches during string replacement operations.

## Solution: Manual Fix in VS Code

### Step 1: Open the file
Open `wwwroot/js/memberships.js` in VS Code

### Step 2: Fix line 11 (AVAILABLE_PACKAGES array)
Find line 11:
```javascript
  { id: 'advanced', name: 'Gói Nâng Cao', price: 1200000, durationDays: 90, description: '3 thÃ¡ng - Bao gá»"m 2 buá»•i PT/thÃ¡ng' },
```

**Replace with:**
```javascript
  { id: 'advanced', name: 'Gói Nâng Cao', price: 1200000, durationDays: 90, description: '3 tháng - Bao gồm 2 buổi PT/tháng' },
```

### Step 3: Save with UTF-8 encoding
1. File > Save (or Ctrl+S)
2. Check bottom-right of VS Code status bar - should say "UTF-8"
3. If not UTF-8, click the encoding name and select "Save with Encoding" > "UTF-8"

## Verification
After saving, refresh the memberships page in your browser. The package descriptions should now display correctly:
- "Gói Cơ Bản" - "1 tháng - Sử dụng tất cả thiết bị"
- "Gói Nâng Cao" - "3 tháng - Bao gồm 2 buổi PT/tháng" ← This should be fixed
- "Gói VIP" - "6 tháng - Không giới hạn PT + dinh dưỡng"
- "Gói Năm" - "12 tháng - Tất cả dịch vụ cao cấp"

## Why PowerShell Failed
PowerShell's `Get-Content` and string replacement methods were reading/writing with incorrect encodings, causing the UTF-8 bytes to be misinterpreted. VS Code's built-in UTF-8 handling is more reliable for this type of fix.

## Other Files to Check
If you see similar encoding issues elsewhere, check these files:
- `wwwroot/js/payments.js`
- `wwwroot/js/invoices.js`
- `wwwroot/js/schedules.js`
- `wwwroot/js/sessions.js`
- `wwwroot/js/checkins.js`

Follow the same manual fix process if needed.
