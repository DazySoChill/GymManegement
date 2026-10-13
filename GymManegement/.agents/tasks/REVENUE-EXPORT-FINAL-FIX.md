# Revenue Export & Display - Final Fix ✅

## Date: 2026-10-11

---

## Problems Found & Fixed

### 1. Excel File Empty ❌ → ✅ Fixed
**Root Cause:** Backend was passing wrapped data `new[] { data }` to ExportService, causing reflection to fail.

**Fix:** Pass the actual data list directly:
```csharp
// OLD (WRONG):
var bytes = await _export.ExportToExcelAsync(new[] { data }, fileName);

// NEW (CORRECT):
var bytes = await _export.ExportToExcelAsync(allData, fileName);
```

Also fixed dynamic casting:
```csharp
// Extract Data property properly
var resultObj = (dynamic)result;
var data = resultObj.Data as IEnumerable<dynamic>;
if (data != null) allData.AddRange(data);
```

---

### 2. Revenue Label Shows "NaN ₫" ❌ → ✅ Fixed
**Root Cause:** 
- Label was static HTML "Doanh Thu Tháng 10/2026" - never updated
- API response format was `{ totalRevenue: 123, invoiceCount: 5 }` but code expected just a number

**Fix:**

**A. Made label dynamic:**
```html
<!-- OLD: -->
<div class="stat-label">Doanh Thu Tháng ${currentMonth}/${currentYear}</div>

<!-- NEW: -->
<div class="stat-label" id="revenueLabel">Doanh Thu Tháng ${currentMonth}/${currentYear}</div>
```

**B. Extract totalRevenue correctly:**
```javascript
// OLD:
const revenue = await apiFetch(`/api/Report/revenue?month=${month}&year=${year}`);
totalRevenue = revenue || 0;  // WRONG: revenue is object, not number

// NEW:
const revenue = await apiFetch(`/api/Report/revenue?month=${month}&year=${year}`);
totalRevenue = revenue?.totalRevenue || revenue?.TotalRevenue || 0;  // Extract from object
```

**C. Update label when filter changes:**
```javascript
if (type === 'month') {
    label = `Doanh Thu Tháng ${month}/${year}`;
} else if (type === 'quarter') {
    label = `Doanh Thu Quý ${quarter}/${year}`;
} else if (type === 'year') {
    label = `Doanh Thu Năm ${year}`;
}

document.getElementById('revenueLabel').textContent = label;
```

---

## Files Modified

### 1. Backend - `Controllers/ReportController.cs`
**Changes:**
- Fixed dynamic casting to extract `Data` property correctly
- Pass actual data list to ExportService (not wrapped)
- Better error handling

**Lines changed:**
```csharp
// Extract data from wrapper object
var resultObj = (dynamic)result;
var data = resultObj.Data as IEnumerable<dynamic>;

// Pass data directly
var bytes = await _export.ExportToExcelAsync(allData, fileName);
```

---

### 2. Frontend - `wwwroot/js/reports.js`

**Changes:**

#### A. Dynamic Label (line ~23)
```html
<div class="stat-label" id="revenueLabel">Doanh Thu Tháng ${currentMonth}/${currentYear}</div>
```

#### B. Extract Revenue Correctly (line ~110+)
```javascript
const revenue = await apiFetch(`/api/Report/revenue?month=${month}&year=${year}`);
totalRevenue = revenue?.totalRevenue || revenue?.TotalRevenue || 0;
```

#### C. Update Label When Filter Changes
```javascript
let label = '';
if (type === 'month') {
    label = `Doanh Thu Tháng ${month}/${year}`;
} else if (type === 'quarter') {
    label = `Doanh Thu Quý ${quarter}/${year}`;
} else if (type === 'year') {
    label = `Doanh Thu Năm ${year}`;
}
document.getElementById('revenueLabel').textContent = label;
```

---

## How It Works Now

### User Flow:
```
1. User selects "Xem theo: Quý" + "Quý 4" + "2026"
2. Click "🔍 Xem"
3. Frontend:
   a. Load revenue for Oct, Nov, Dec (3 API calls)
   b. Calculate total: totalRevenue = oct + nov + dec
   c. Update label: "Doanh Thu Quý 4/2026"
   d. Update value: "15,000,000 ₫" (formatted)
   e. Show table with all invoices
4. Click "📥 Xuất Excel"
5. Backend:
   a. Receive: type=quarter, quarter=4, year=2026
   b. Load data for Oct, Nov, Dec
   c. Aggregate into single list
   d. Generate Excel with all rows
   e. Return file: DoanhThu_Quy4_2026.xlsx
6. User downloads file with actual data
```

---

## API Response Format

### `/api/Report/revenue?month=10&year=2026`
```json
{
  "totalRevenue": 15000000,
  "invoiceCount": 25
}
```

### `/api/Report/revenue/detail?month=10&year=2026`
```json
{
  "month": 10,
  "year": 2026,
  "data": [
    {
      "invoiceId": 1,
      "invoiceDate": "2026-10-01T10:30:00",
      "totalAmount": 500000,
      "status": "Paid",
      "packageName": "Gói 3 tháng",
      "memberName": "Nguyễn Văn A"
    },
    ...
  ]
}
```

---

## Excel File Content

After fix, Excel file will have:

| InvoiceId | InvoiceDate         | TotalAmount | Status | PackageName  | MemberName     |
|-----------|---------------------|-------------|--------|--------------|----------------|
| 1         | 01/10/2026 10:30    | 500,000     | Paid   | Gói 3 tháng  | Nguyễn Văn A   |
| 2         | 05/10/2026 14:20    | 1,000,000   | Paid   | Gói 6 tháng  | Trần Thị B     |
| ...       | ...                 | ...         | ...    | ...          | ...            |

**Column headers** (from ExportService):
- InvoiceId → "Mã hóa đơn"
- InvoiceDate → "InvoiceDate" (can add to mapping)
- TotalAmount → "Tổng tiền"
- PackageName → "Tên gói tập"
- MemberName → "MemberName" (can add to mapping)

---

## Testing

### Step 1: Rebuild Backend
```powershell
cd "d:\Workspace\Độ án 2\GymManegement\GymManegement"
dotnet build
dotnet run
```

### Step 2: Clear Browser Cache
Press **Ctrl + Shift + R**

### Step 3: Test Revenue Display
1. Go to Reports page
2. Select "Xem theo: **Quý**"
3. Select "Quý 4" + year
4. Click "🔍 Xem"
5. Check top card:
   - Label should say: **"Doanh Thu Quý 4/2026"**
   - Value should show number: **"15,000,000 ₫"** (not NaN ₫)

### Step 4: Test Excel Export
1. With same filter (Quý 4)
2. Click "📥 Xuất Excel"
3. File downloads: `DoanhThu_Quy4_2026.xlsx`
4. Open file in Excel
5. Should have rows with invoice data (not empty!)

---

## Debug Console Logs

After fix, you should see:

```
Revenue Summary - API Response: {totalRevenue: 15000000, invoiceCount: 25}
Revenue Details - API Response: {month: 10, year: 2026, data: Array(25)}
Revenue Details - Details array: [{...}, {...}, ...]
Revenue Details - Total: 15000000

Exporting revenue: {type: "quarter", year: 2026, url: "..."}
Export response status: 200
Export blob size: 12345 type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
```

**If you see:**
- ❌ `totalRevenue: NaN` → Revenue extraction failed (check API response format)
- ❌ `blob size: 0` → Backend export failed (check backend logs)
- ❌ `Details array: []` → No data in that period

---

## Summary

✅ Fixed Excel export - file now contains actual invoice data  
✅ Fixed revenue label - updates to "Tháng X/Y", "Quý X/Y", or "Năm Y"  
✅ Fixed NaN display - extracts totalRevenue from API response correctly  
✅ Backend properly aggregates data for quarter/year exports  
✅ Frontend properly extracts and displays revenue totals  

**Rebuild backend, clear cache, and test!** 🚀
