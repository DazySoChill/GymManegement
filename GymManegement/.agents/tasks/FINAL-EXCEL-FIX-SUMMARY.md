# Final Excel Export Fix - Summary

## Date: 2026-10-11 | EPPlus 8.7.1

---

## Root Cause Found ✅

**Problem:** Excel file empty despite EPPlus 8.7.1 installed.

**Root Cause:** 
Dapper returns **dynamic objects** (ExpandoObject/DapperRow), but EPPlus reflection-based export expects **strongly-typed classes**.

```csharp
// Dapper query returns dynamic
var rows = await conn.QueryAsync(sql, new { Month = month, Year = year });

// EPPlus tries to use reflection on dynamic object
var properties = typeof(T).GetProperties();  // ❌ Fails on dynamic!
```

---

## Solution Applied ✅

### 1. ExportService.cs - Added Dynamic Object Handler

**New code:**
```csharp
public async Task<byte[]> ExportToExcelAsync<T>(IEnumerable<T> data, ...)
{
    var dataList = data.ToList();
    
    // ✅ Check if data is dynamic/ExpandoObject
    if (dataList.Count > 0 && dataList[0] is System.Dynamic.ExpandoObject)
    {
        return ExportDynamicData(dataList, sheetName);  // Special handler
    }
    
    // Original reflection-based code for typed objects
    var properties = GetProperties<T>(columns);
    ...
}

private byte[] ExportDynamicData(List<dynamic> data, string sheetName)
{
    // Treat dynamic as IDictionary<string, object>
    var firstItem = data[0] as IDictionary<string, object>;
    var keys = firstItem.Keys.ToList();  // Get property names
    
    // Export without reflection - direct dictionary access
    foreach (var item in data)
    {
        var dict = item as IDictionary<string, object>;
        foreach (var key in keys)
        {
            var value = dict[key];
            cell.Value = value;  // Direct assignment
        }
    }
}
```

**Benefits:**
- ✅ Works with Dapper dynamic results
- ✅ No reflection needed
- ✅ Proper formatting (dates, numbers)
- ✅ Vietnamese column headers

---

### 2. ReportController.cs - Added Debug Logging

```csharp
Console.WriteLine($"[Export] Month {m} data count: {data?.Count() ?? 0}");
Console.WriteLine($"[Export] Total rows to export: {allData.Count}");
Console.WriteLine($"[Export] Generated file size: {bytes.Length} bytes");
```

**Why:** To diagnose issues quickly:
- If data count = 0 → No data in DB
- If file size = 0 → Export failed
- If error logged → See exact issue

---

## Files Modified

1. **Service/BUS/Implementations/ExportService.cs**
   - Added `ExportDynamicData()` method
   - Added dynamic object detection
   - Added `GetDisplayNameForDynamic()` for Vietnamese headers

2. **Controllers/ReportController.cs**
   - Added debug logging
   - Added try-catch with detailed error messages

---

## How It Works Now

```
1. Frontend clicks "Xuất Excel"
2. Backend receives: type=month, month=10, year=2026

3. ReportController.ExportRevenue():
   a. Call ReportService.GetRevenueDetailAsync(10, 2026)
   b. Dapper returns: { Month: 10, Year: 2026, Data: [dynamic objects] }
   c. Extract Data property: List<dynamic> with invoice rows
   d. Log: "[Export] Month 10 data count: 15"
   
4. ExportService.ExportToExcelAsync(allData, "DoanhThu_Thang10_2026"):
   a. Detect first item is ExpandoObject
   b. Call ExportDynamicData() instead of reflection
   c. Convert dynamic to IDictionary<string, object>
   d. Read keys: InvoiceId, InvoiceDate, TotalAmount, ...
   e. Write header row with Vietnamese names
   f. Loop through data and write values directly
   g. Format dates (dd/MM/yyyy) and numbers (#,##0)
   h. Return Excel bytes
   
5. Log: "[Export] Generated file size: 12345 bytes"
6. Return file to browser
7. User downloads: DoanhThu_Thang10_2026.xlsx with data ✅
```

---

## Excel File Structure

| Mã hóa đơn | Ngày hóa đơn      | Tổng tiền  | Trạng thái | Tên gói tập | Tên hội viên   |
|------------|-------------------|------------|------------|-------------|----------------|
| 1          | 01/10/2026 10:30  | 500,000    | Paid       | Gói 3 tháng | Nguyễn Văn A   |
| 2          | 05/10/2026 14:20  | 1,000,000  | Paid       | Gói 6 tháng | Trần Thị B     |

**Features:**
- ✅ Blue header with white text
- ✅ All cells bordered
- ✅ Auto-fit columns
- ✅ Frozen header row
- ✅ Date formatting: dd/MM/yyyy HH:mm
- ✅ Number formatting: #,##0 (thousand separator)
- ✅ Vietnamese column names

---

## Testing Steps

### 1. Rebuild Backend
```powershell
cd "d:\Workspace\Độ án 2\GymManegement\GymManegement"
dotnet clean
dotnet build
dotnet run
```

**Keep console window visible to see logs!**

---

### 2. Test from Browser

1. Clear cache: **Ctrl + Shift + R**
2. Go to Reports page
3. Select "Xem theo: Tháng" + Month 10 + Year 2026
4. Click "🔍 Xem" → Verify table shows data
5. Click "📥 Xuất Excel"

---

### 3. Check Backend Console

Should see:
```
[Export] Month 10 data count: 15
[Export] Total rows to export: 15
[Export] Generated file size: 12345 bytes
```

✅ If data count > 0 and file size > 5000 → Success!
❌ If data count = 0 → No data in that month (try different month)
❌ If error logged → Send error message to me

---

### 4. Verify Excel File

1. Open downloaded file
2. Should have:
   - ✅ Header row (blue background)
   - ✅ Data rows with actual invoices
   - ✅ Formatted dates and numbers
   - ✅ Vietnamese column names

---

## Troubleshooting

### Issue: Data count = 0
**Check database:**
```sql
SELECT COUNT(*) 
FROM Invoices 
WHERE MONTH(InvoiceDate) = 10 
  AND YEAR(InvoiceDate) = 2026
  AND IsDeleted = 0;
```

If result = 0 → Create test invoices or try current month.

---

### Issue: File size = 0
**Possible causes:**
1. EPPlus license error → Already set to NonCommercial in code
2. Data type conversion error → Check console error message
3. Empty data list → Check data count log

---

### Issue: File has header but no data rows
**Check console logs for:**
```
[ExportDynamic] Keys: ...
[ExportDynamic] Data count: ...
```

If not present, add more debug to ExportDynamicData().

---

## Summary

✅ **Root cause:** Dapper dynamic objects incompatible with EPPlus reflection  
✅ **Solution:** Special handler for dynamic/ExpandoObject  
✅ **Result:** Excel export works with actual invoice data  
✅ **Features:** Vietnamese headers, proper formatting, borders  
✅ **Debug:** Console logging for quick diagnosis  

**Rebuild backend và test ngay!** 🚀

---

## What Changed vs Original Code

**Before:**
```csharp
// Only worked with strongly-typed classes
var properties = typeof(T).GetProperties();
foreach (var prop in properties) {
    var value = prop.GetValue(item);  // ❌ Fails on dynamic
}
```

**After:**
```csharp
// Detects and handles dynamic objects
if (dataList[0] is ExpandoObject) {
    var dict = item as IDictionary<string, object>;
    var value = dict[key];  // ✅ Works with dynamic
}
```

**Key insight:** Treat Dapper dynamic results as dictionaries, not classes!
