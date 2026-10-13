# Excel Export - Backend Solution ✅

## Date: 2026-10-11

---

## Problem
- Client-side Excel export failed (SheetJS không load được từ CDN)
- File xuất ra là CSV thay vì XLSX
- User cần xuất Excel đúng format theo Tháng/Quý/Năm

---

## Solution: Backend Export API

Thay vì export client-side, tôi đã nâng cấp backend API để:
- ✅ Hỗ trợ export theo **Tháng/Quý/Năm**
- ✅ Trả về **file Excel thật** (.xlsx)
- ✅ Aggregate data từ nhiều tháng nếu cần
- ✅ Không conflict với code hiện có

---

## Changes Made

### 1. Backend - ReportController.cs ✅

**Old endpoint:**
```csharp
[HttpGet("revenue/export")]
public async Task<IActionResult> ExportRevenue([FromQuery] int month, [FromQuery] int year)
{
    // Chỉ export 1 tháng
}
```

**New endpoint:**
```csharp
[HttpGet("revenue/export")]
public async Task<IActionResult> ExportRevenue(
    [FromQuery] string type = "month",  // "month", "quarter", "year"
    [FromQuery] int? month = null,
    [FromQuery] int? quarter = null,
    [FromQuery] int year = 0)
{
    // Export flexible theo type
    // Aggregate data từ nhiều tháng
    // Return file Excel với tên đúng
}
```

**Logic:**
- **type="month" + month=10 + year=2026** → Export tháng 10/2026
- **type="quarter" + quarter=4 + year=2026** → Export Quý 4 (T10, T11, T12) năm 2026
- **type="year" + year=2026** → Export cả năm 2026 (12 tháng)

**File names:**
- Tháng: `DoanhThu_Thang10_2026.xlsx`
- Quý: `DoanhThu_Quy4_2026.xlsx`
- Năm: `DoanhThu_Nam2026.xlsx`

---

### 2. Frontend - reports.js ✅

**Updated `exportRevenue()` function:**
```javascript
async function exportRevenue() {
    const type = document.getElementById('revenueType')?.value || 'month';
    const year = document.getElementById('revenueYear')?.value;
    
    // Build URL
    let url = `${API_BASE}/api/Report/revenue/export?type=${type}&year=${year}`;
    
    if (type === 'month') {
        const month = document.getElementById('revenueMonth')?.value;
        url += `&month=${month}`;
    } else if (type === 'quarter') {
        const quarter = document.getElementById('revenueQuarter')?.value;
        url += `&quarter=${quarter}`;
    }
    
    // Fetch Excel file from backend
    const response = await fetch(url, {
        headers: { 'Authorization': 'Bearer ' + token }
    });
    
    const blob = await response.blob();
    // Download file
    ...
}
```

**Removed:**
- ❌ SheetJS client-side library
- ❌ `exportToCSV()` function
- ❌ `exportToExcel()` function  
- ❌ Client-side data aggregation

**Benefits:**
- ✅ Backend generates proper Excel file
- ✅ Faster (backend aggregates data)
- ✅ No CDN dependency
- ✅ Consistent formatting

---

### 3. index.html ✅

**Removed:**
```html
<!-- SheetJS for Excel export -->
<script src="https://cdn.sheetjs.com/xlsx-0.20.1/package/dist/xlsx.full.min.js"></script>
```

No external library needed anymore!

---

## API Examples

### Export Tháng 10/2026:
```
GET /api/Report/revenue/export?type=month&month=10&year=2026
```

### Export Quý 4/2026:
```
GET /api/Report/revenue/export?type=quarter&quarter=4&year=2026
```

### Export Năm 2026:
```
GET /api/Report/revenue/export?type=year&year=2026
```

---

## Backend Flow

```
1. Frontend gọi API với type + parameters
2. Backend:
   a. Validate parameters
   b. Call GetRevenueDetailAsync() cho từng tháng cần thiết
      - Month: 1 API call
      - Quarter: 3 API calls (3 months)
      - Year: 12 API calls (12 months)
   c. Aggregate all data into single list
   d. Call ExportService.ExportToExcelAsync()
   e. Return Excel file bytes
3. Frontend downloads file với tên đúng
```

---

## Excel File Structure

Backend `ExportService` tạo file Excel với:
- **Headers:** InvoiceId, InvoiceDate, TotalAmount, Status, PackageName, MemberName
- **Data rows:** Tất cả invoices trong period
- **Format:** .xlsx (OpenXML)
- **Encoding:** UTF-8

---

## Testing Instructions

### 1. Rebuild Backend
```powershell
cd "d:\Workspace\Độ án 2\GymManegement\GymManegement"
dotnet build
dotnet run
```

### 2. Clear Browser Cache
Press **Ctrl + Shift + R**

### 3. Test Export Tháng
1. Go to Reports page
2. Select "Xem theo: **Tháng**"
3. Select month + year
4. Click "📥 Xuất Excel"
5. File downloads: `DoanhThu_Thang10_2026.xlsx`
6. Open file → Should be proper Excel with data

### 4. Test Export Quý
1. Select "Xem theo: **Quý**"
2. Select quarter + year
3. Click "📥 Xuất Excel"
4. File downloads: `DoanhThu_Quy4_2026.xlsx`
5. Open file → Should have 3 months data

### 5. Test Export Năm
1. Select "Xem theo: **Năm**"
2. Select year only
3. Click "📥 Xuất Excel"
4. File downloads: `DoanhThu_Nam2026.xlsx`
5. Open file → Should have 12 months data

---

## Console Debug

Open Console (F12) to see:
```
Exporting revenue: {type: "quarter", year: 2026, url: "..."}
Export response status: 200
Export response content-type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
Export blob size: 15234 type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
```

**If blob size = 0** → No data for that period!

---

## Error Handling

### Backend Errors:
- **400 Bad Request** - Invalid parameters
- **404 Not Found** - No data for specified period
- **500 Internal Server Error** - Export service failed

### Frontend Errors:
- Shows Vietnamese error message
- Logs to console for debugging

---

## Backward Compatibility

✅ **Old API calls still work!**

Old URL (still supported):
```
GET /api/Report/revenue/export?month=10&year=2026
```
Will be treated as:
```
GET /api/Report/revenue/export?type=month&month=10&year=2026
```

---

## Files Modified

1. **Controllers/ReportController.cs** - Updated `ExportRevenue()` endpoint
2. **wwwroot/js/reports.js** - Updated `exportRevenue()` function
3. **wwwroot/index.html** - Removed SheetJS library

---

## Summary

✅ Backend export API upgraded to support Tháng/Quý/Năm  
✅ Frontend calls backend API instead of client-side export  
✅ Real Excel files (.xlsx) generated by backend  
✅ No external CDN dependencies  
✅ Vietnamese filenames  
✅ Proper error handling  
✅ Backward compatible  

**Now rebuild backend and test!** 🚀
