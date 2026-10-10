# Quick Test Checklist - Admin vs Member RBAC

## ⚡ Quick Reference Guide

### Pre-Test Setup
```bash
# Start server
dotnet run --project "GymManegement.csproj"

# Open browser to:
http://localhost:5250/login.html
```

---

## 🔴 ADMIN TEST (5 minutes)

### Login: `gymadmin` / `Gym@2026`

**✓ Checklist:**
- [ ] Login successful → redirects to dashboard
- [ ] **9 menu items** visible (count them!)
- [ ] Dashboard shows system-wide stats (multiple members)
- [ ] Click "👤 Hội viên" → **"+ Thêm hội viên" button visible**
- [ ] Click "✅ Check-in" → **TWO buttons visible** (Manual + QR)
- [ ] Click "🧾 Hóa đơn" → **"+ Tạo hóa đơn" button visible**
- [ ] Click "📈 Báo cáo" → Reports page loads
- [ ] User menu shows: **Role = Admin/SuperAdmin**

**DevTools Check (F12 → Console):**
```javascript
JSON.parse(localStorage.getItem('user')).role
// Result: "Admin" or "SuperAdmin"
```

---

## 🟢 MEMBER TEST (5 minutes)

### Step 1: Create Account
1. Logout from admin
2. Click "Tạo tài khoản" tab
3. Fill: `testmember` / `testmember@gym.com` / `Test@2026`
4. Submit → Success message
5. Auto-switches to login tab

### Step 2: Login: `testmember` / `Test@2026`

**✓ Checklist:**
- [ ] Login successful → redirects to dashboard
- [ ] **ONLY 4 menu items** visible (count them!)
  - [ ] 📊 Tổng quan
  - [ ] 📅 Lịch tập
  - [ ] 🎫 Gói tập
  - [ ] ✅ Check-in
- [ ] **Hidden items (should NOT see):**
  - [ ] ❌ Hội viên (Members)
  - [ ] ❌ Huấn luyện viên (Trainers)
  - [ ] ❌ Phòng / Thiết bị (Facilities)
  - [ ] ❌ Hóa đơn (Invoices)
  - [ ] ❌ Báo cáo (Reports)
- [ ] Dashboard shows **personal data only** (not system-wide)
- [ ] Click "✅ Check-in" → **ONLY QR button visible** (no manual button)
- [ ] User menu shows: **Role = Member**

**DevTools Check:**
```javascript
JSON.parse(localStorage.getItem('user')).role
// Result: "Member"
```

---

## 🔒 ACCESS CONTROL TEST (Critical!)

**While logged in as Member**, try to access admin pages by URL:

### Type in address bar:
```
http://localhost:5250/index.html#members
```

**Expected Result:**
- [ ] Error toast: "Bạn không có quyền truy cập trang này"
- [ ] Auto-redirects to dashboard
- [ ] Page does NOT load

### Repeat for:
- [ ] `#trainers` → blocked ✓
- [ ] `#facilities` → blocked ✓
- [ ] `#invoices` → blocked ✓
- [ ] `#reports` → blocked ✓

---

## 📊 COMPARISON QUICK VIEW

| What to Check | Admin | Member |
|---------------|-------|--------|
| Menu items | **9** | **4** |
| Can see "Hội viên" page | ✅ YES | ❌ NO |
| Can see "Hóa đơn" page | ✅ YES | ❌ NO |
| Can see "Báo cáo" page | ✅ YES | ❌ NO |
| Checkin buttons | 2 (Manual + QR) | 1 (QR only) |
| Dashboard data | All members | Own data only |
| Create member button | ✅ YES | ❌ NO |
| Create invoice button | ✅ YES | ❌ NO |

---

## 🎯 PASS/FAIL CRITERIA

### ✅ PASS if:
- Admin sees 9 menu items
- Member sees 4 menu items
- Member CANNOT access admin pages (blocks with error)
- Both roles can login and logout successfully
- DevTools shows correct role in localStorage

### ❌ FAIL if:
- Member can see or access admin pages
- Menu items count is wrong
- No error when member tries admin URL
- Role in localStorage is incorrect
- Pages don't load or show errors

---

## 🐛 Common Issues

### Issue: Member can access admin pages
**Fix:** Check `app.js` → `isAllowedPage()` function

### Issue: Menu items not hiding
**Fix:** Check `app.js` → `initNavigation()` function

### Issue: Login fails with 401
**Fix:** Check server is running, database connection OK

### Issue: Token not saved
**Fix:** Check browser localStorage not disabled, no CORS errors

---

## 📸 Screenshots to Take

### Admin View:
1. Navigation sidebar (showing all 9 items)
2. Members page with "+ Thêm hội viên" button
3. Checkins page with BOTH buttons
4. DevTools → localStorage showing role

### Member View:
1. Navigation sidebar (showing only 4 items)
2. Checkins page with ONLY QR button
3. Error toast when trying to access admin page
4. DevTools → localStorage showing role

---

## ⏱️ Expected Time

- Admin test: **5 minutes**
- Create member + test: **5 minutes**
- Access control test: **3 minutes**
- Screenshots: **2 minutes**
- **Total: ~15 minutes**

---

## ✍️ Test Results

**Date:** ________________  
**Tester:** ________________  
**Browser:** ________________

**Admin Test:** [ ✓ PASS / ✗ FAIL ]  
**Member Test:** [ ✓ PASS / ✗ FAIL ]  
**Access Control:** [ ✓ PASS / ✗ FAIL ]

**Overall:** [ ✓ PASS / ✗ FAIL ]

**Notes:**
_____________________________________________________________
_____________________________________________________________
_____________________________________________________________

---

## 🚀 Next Steps

**If PASS:**
- ✅ RBAC implementation working correctly
- ✅ Ready for production
- Document and train users

**If FAIL:**
- ❌ Review failed tests
- Fix issues in code
- Re-test until pass

---

**End of Quick Checklist**
