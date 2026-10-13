# Excel Export Debug Guide - EPPlus 8.7.1

## Date: 2026-10-11

---

## Changes Made

### 1. ExportService.cs - Added Dynamic Object Support

**Problem:** EPPlus reflection cannot read `dynamic` object properties from Dapper queries.

**Solution:** Added special handling for dynamic/ExpandoObject:

```csharp
// Check if data is dynamic
if (dataList[0] is System.Dynamic.ExpandoObject)
{
    return ExportDynamicData(dataList, sheetName);
}
```

**New method `ExportDynamicData()`:**
- Treats dynamic object as `IDictionary<string, object>`
- Reads keys and values directly (no reflection needed)
- Formats DateTime and numeric values
- Vietnamese column headers

**Columns exported:**
- Mã hóa đơn (InvoiceId)
- Ngày hóa đơn (InvoiceDate)
- Tổng tiền (TotalAmount) - formatted with thousand separator
- Trạng thái (Status)
- Tên gói tập (PackageName)
- Tên hội viên (MemberName)

---

### 2. ReportController.cs - Added Debug Logging

**Added Console.WriteLine logs:**
```csharp
Console.WriteLine($"[Export] Month data count: {data?.Count() ?? 0}");
Console.WriteLine($"[Export] Total rows to export: {allData.Count}");
Console.WriteLine($"[Export] Generated file size: {bytes.Length} bytes");
```

**Added try-catch:**
```csharp
catch (Exception ex)
{
    Console.WriteLine($"[Export] ERROR: {ex.Message}");
    return StatusCode(500, $"Export failed: {ex.Message}");
}
```

---

## How to Test & Debug

### Step 1: Rebuild Backend
```powershell
cd "d:\Workspace\Độ án 2\GymManegement\GymManegement"
dotnet clean
dotnet build
dotnet run
```

### Step 2: Watch Backend Console Output

When backend starts, you should see:
```
Now listening on: http://localhost:5000
...
```

**Keep this terminal window open and visible!**

---

### Step 3: Test Export from Frontend

1. Open browser (clear cache: Ctrl+Shift+R)
2. Go to Reports page
3. Select filter (e.g., Tháng 10/2026)
4. Click "🔍 Xem" to load data (verify table shows data)
5. Click "📥 Xuất Excel"

---

### Step 4: Check Backend Console

You should see logs like:
```
[Export] Month 10 data count: 15
[Export] Total rows to export: 15
[Export] Generated file size: 12345 bytes
```

**Interpretation:**

✅ **If you see:**
```
[Export] Month 10 data count: 15
[Export] Total rows to export: 15
[Export] Generated file size: 12345 bytes
```
→ Backend is working! Excel should have data.

❌ **If you see:**
```
[Export] Month 10 data count: 0
[Export] Total rows to export: 0
```
→ No data in database for that month. Try different month/year.

❌ **If you see:**
```
[Export] ERROR: Cannot convert ...
[Export] Stack: ...
```
→ Data type conversion error. Copy error message and send to me.

---

### Step 5: Open Excel File

**If file has data:**
✅ Success! Export is working.

**If file is still empty:**
Check console logs. Possible issues:
1. Data count = 0 → No data in DB
2. Error in logs → Type conversion issue
3. File size < 5000 bytes → EPPlus generated empty sheet

---

## Troubleshooting

### Issue: "Month data count: 0"
**Cause:** No invoices in that month/year.
**Solution:** 
1. Check database has invoices: `SELECT * FROM Invoices WHERE MONTH(InvoiceDate) = 10 AND YEAR(InvoiceDate) = 2026`
2. Try current month instead
3. Create test invoice if needed

---

### Issue: "ERROR: Cannot convert object to IDictionary"
**Cause:** Data type from Dapper is not ExpandoObject.
**Solution:** Update ReportService to return proper type:

```csharp
// In ReportService.GetRevenueDetailAsync()
var rows = await conn.QueryAsync<dynamic>(sql, new { Month = month, Year = year });
// Change to:
var rows = (await conn.QueryAsync(sql, new { Month = month, Year = year })).ToList();
```

---

### Issue: File size > 0 but Excel shows empty
**Cause:** EPPlus generated file structure but no data rows.
**Solution:** Add more debug in ExportDynamicData:

```csharp
Console.WriteLine($"[ExportDynamic] Keys: {string.Join(", ", keys)}");
Console.WriteLine($"[ExportDynamic] Data count: {data.Count}");
Console.WriteLine($"[ExportDynamic] First item type: {data[0].GetType().Name}");
```

---

## Manual Testing via API

Test export endpoint directly:

```powershell
# Get auth token first (from browser DevTools → Application → Local Storage)
$token = "your_jwt_token_here"

# Test export
Invoke-WebRequest -Uri "http://localhost:5000/api/Report/revenue/export?type=month&month=10&year=2026" `
    -Headers @{"Authorization"="Bearer $token"} `
    -OutFile "test_export.xlsx"

# Check file size
(Get-Item "test_export.xlsx").Length
```

**Expected:** File size > 5000 bytes

---

## SQL Query to Check Data

```sql
-- Check if there are invoices in October 2026
SELECT 
    i.InvoiceId,
    i.InvoiceDate,
    i.TotalAmount,
    i.Status,
    ms.PackageName,
    m.FullName AS MemberName
FROM Invoices i
INNER JOIN Memberships ms ON i.MembershipId = ms.MembershipId
INNER JOIN Members m ON ms.MemberId = m.MemberId
WHERE MONTH(i.InvoiceDate) = 10 
    AND YEAR(i.InvoiceDate) = 2026
    AND i.IsDeleted = 0
ORDER BY i.InvoiceDate DESC;
```

**If query returns 0 rows → No data to export!**

---

## Expected Excel Output

| Mã hóa đơn | Ngày hóa đơn      | Tổng tiền  | Trạng thái | Tên gói tập | Tên hội viên   |
|------------|-------------------|------------|------------|-------------|----------------|
| 1          | 01/10/2026 10:30  | 500,000    | Paid       | Gói 3 tháng | Nguyễn Văn A   |
| 2          | 05/10/2026 14:20  | 1,000,000  | Paid       | Gói 6 tháng | Trần Thị B     |

**Formatting:**
- Dates: dd/MM/yyyy HH:mm
- Numbers: #,##0 (thousand separator)
- Header: Blue background, white text, bold
- Borders: All cells
- Auto-fit columns

---

## Next Steps

1. **Rebuild backend** with new code
2. **Run backend** and keep console visible
3. **Test export** from frontend
4. **Check console logs** for data count and file size
5. **Send me the logs** if there are errors

**Important:** Chụp màn hình console logs và gửi cho tôi nếu vẫn bị lỗi!
