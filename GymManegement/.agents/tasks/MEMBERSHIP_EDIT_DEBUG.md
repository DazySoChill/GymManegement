# Membership Edit - Debug Guide

**Date:** 2026-10-11  
**Issue:** Form "Cập Nhật" không hoạt động

---

## 🔍 Debug Steps

### Step 1: Hard Refresh Browser
```
Ctrl + Shift + R (hoặc Ctrl + F5)
```
Clear cache hoàn toàn!

---

### Step 2: Open Developer Console
```
F12 → Console tab
```

---

### Step 3: Click "Sửa" (Edit) Button
**Expected console output:**
```
✅ Edit membership form event listener attached for membership: <ID>
```

Nếu KHÔNG thấy message này → File JS chưa được load!

---

### Step 4: Click "Cập Nhật" Button
**Expected console output sequence:**
```
🔥 FORM SUBMITTED! Starting validation...
=== EDIT MEMBERSHIP VALIDATION ===
Form data: { packageName: "...", price: "...", startDate: "...", endDate: "..." }
✅ All validation passed
📤 PUT request payload: { ... }
📍 API endpoint: /api/Membership/<ID>
🔍 Token: Present
⏳ Calling API...
✅ API response: { ... }
🚪 Closing modal and reloading...
✅ Done!
```

---

## ❌ Possible Error Scenarios

### Scenario A: KHÔNG thấy log gì cả
**Nguyên nhân:** Form submit event chưa được attach

**Giải pháp:**
1. Hard refresh: `Ctrl + Shift + R`
2. Check file có load không: Console → Sources → `wwwroot/js/memberships.js`
3. Kiểm tra có error nào khi load page không

---

### Scenario B: Thấy "🔥 FORM SUBMITTED" nhưng dừng ở giữa
**Nguyên nhân:** Validation fail hoặc có exception

**Check:**
- Có thấy validation error message không? (màu đỏ phía dưới field)
- Console có error màu đỏ không?

---

### Scenario C: Validation pass nhưng API fail
**Console output:**
```
✅ All validation passed
📤 PUT request payload: { ... }
⏳ Calling API...
❌ API Error: <error message>
```

**Possible reasons:**
- Token expired → Re-login
- Backend error (500) → Check backend logs
- Unauthorized (401/403) → Check role permissions
- Bad request (400) → Check payload format

---

### Scenario D: Token missing
**Console output:**
```
🔍 Token: Missing
```

**Solution:** 
```javascript
// Re-login để lấy token mới
```

---

## 🧪 Manual API Test (Console)

Nếu form không work, test trực tiếp API:

```javascript
// 1. Get membership ID
const membershipId = 1; // Thay bằng ID thực tế

// 2. Prepare data
const testData = {
    packageName: "Test Package",
    price: 500000,
    startDate: "2026-10-11T00:00:00Z",
    endDate: "2026-11-11T23:59:59Z"
};

// 3. Call API directly
fetch(`/api/Membership/${membershipId}`, {
    method: 'PUT',
    headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + localStorage.getItem('gym_token')
    },
    body: JSON.stringify(testData)
})
.then(r => r.json())
.then(data => console.log('✅ Success:', data))
.catch(err => console.error('❌ Error:', err));
```

---

## 🛠️ Backend Check

### Check Controller có chạy không:

**File:** `Controllers/MembershipController.cs`

**Endpoint:**
```csharp
[HttpPut("{id:int}")]
[Authorize(Roles = "SuperAdmin,Admin")]
public async Task<IActionResult> Update(int id, [FromBody] UpdateMembershipRequest request)
```

**Required:**
- Role: `SuperAdmin` hoặc `Admin`
- Request body: `{ packageName, price, startDate, endDate }`

---

## 📋 Checklist

- [ ] Hard refresh (Ctrl + Shift + R)
- [ ] Open F12 Console
- [ ] Click "Sửa" → See "✅ Edit membership form event listener attached"
- [ ] Change some data
- [ ] Click "Cập Nhật" → See full log sequence
- [ ] If error → Copy exact error message
- [ ] Check Network tab (F12 → Network) for PUT request
- [ ] Check request payload
- [ ] Check response status (200 = OK, 400 = Bad Request, 401 = Unauthorized, 500 = Server Error)

---

## 🚨 Common Issues

### Issue 1: "showError is not defined"
**Fix:** Check `api.js` loaded trước `memberships.js`

### Issue 2: "apiFetch is not defined"
**Fix:** Check `api.js` loaded trước `memberships.js`

### Issue 3: 401 Unauthorized
**Fix:** Re-login hoặc check role (cần Admin/SuperAdmin)

### Issue 4: 400 Bad Request
**Fix:** Check payload format:
```json
{
  "packageName": "string",
  "price": number,
  "startDate": "ISO datetime string",
  "endDate": "ISO datetime string"
}
```

---

## 📞 Report Back

Sau khi test, báo lại cho tôi:

1. **Có thấy log nào trong Console không?**
   - Nếu có, copy toàn bộ log
   - Nếu không, báo "Không có log gì cả"

2. **Có error message màu đỏ không?**
   - Nếu có, copy exact message

3. **Network tab:**
   - F12 → Network → Filter: XHR
   - Click "Cập Nhật"
   - Có thấy request `PUT /api/Membership/<ID>` không?
   - Status code là gì? (200, 400, 401, 500?)
   - Click vào request → Preview tab → Copy response

---

**Với thông tin đó, tôi sẽ biết chính xác vấn đề ở đâu!** 🔧
