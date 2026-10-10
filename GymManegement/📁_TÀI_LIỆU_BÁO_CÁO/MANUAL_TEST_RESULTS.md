# Manual Test Results - Admin vs Member View

## Test Environment
- **Date**: 2026-10-09
- **Server**: http://localhost:5250
- **Frontend**: wwwroot/index.html, wwwroot/login.html
- **Test Status**: ⚠️ **REQUIRES MANUAL EXECUTION**

---

## ⚠️ IMPORTANT NOTE

This document provides a **comprehensive test plan** for manual UI testing. As an automated agent, I cannot physically interact with a browser to perform these tests. 

**The user must execute these tests manually** following the steps below and record the results.

---

## Test Accounts

### Admin Account (Pre-configured)
- **Username**: `gymadmin` (or use demo button: `admin`)
- **Password**: `Gym@2026` (or `gym@2026` for demo)
- **Expected Role**: SuperAdmin or Admin
- **Expected Access**: Full system access (9 menu items)

### Member Account (To be created)
- **Username**: `testmember`
- **Password**: `Test@2026`
- **Email**: `testmember@gym.com`
- **Expected Role**: Member
- **Expected Access**: Limited to 4 menu items

---

## PRE-TEST CHECKLIST

- [ ] Server is running: `dotnet run --project "GymManegement.csproj"`
- [ ] Can access: http://localhost:5250
- [ ] Login page loads: http://localhost:5250/login.html
- [ ] Browser DevTools is open (F12)
- [ ] Network tab is recording
- [ ] Console tab is visible (check for errors)

---

## TEST 1: ADMIN ROLE (gymadmin / Gym@2026)

### 1.1 Login Process
**Steps:**
1. Open browser to http://localhost:5250/login.html
2. Enter username: `gymadmin`
3. Enter password: `Gym@2026`
4. Click "Đăng nhập" button

**Expected Results:**
- [ ] Login successful (no error message)
- [ ] Redirected to `/` or `/index.html`
- [ ] Token saved in localStorage (check DevTools > Application > Local Storage)
- [ ] User object saved with correct role

**DevTools Checks:**
```javascript
// Console commands to verify:
localStorage.getItem('accessToken')  // Should return JWT token
JSON.parse(localStorage.getItem('user'))  // Should show: {userId, username: "gymadmin", role: "Admin" or "SuperAdmin"}
```

**Results:**
- Status: [ ✓ PASS / ✗ FAIL ]
- Token present: [ YES / NO ]
- User role: _______________
- Notes: _______________________________________________

---

### 1.2 Navigation Menu (Admin)
**Expected Menu Items (9 total):**
- [ ] 📊 Tổng quan (Dashboard)
- [ ] 👤 Hội viên (Members)
- [ ] 🎫 Gói tập (Memberships)
- [ ] 💪 Huấn luyện viên (Trainers)
- [ ] 🏠 Phòng / Thiết bị (Facilities)
- [ ] 📅 Lịch tập (Schedules)
- [ ] ✅ Check-in (Checkins)
- [ ] 🧾 Hóa đơn (Invoices)
- [ ] 📈 Báo cáo (Reports)

**Verification:**
- Count visible menu items: _____
- All items clickable: [ YES / NO ]
- No hidden items: [ YES / NO ]

**Results:**
- Status: [ ✓ PASS / ✗ FAIL ]
- Notes: _______________________________________________

---

### 1.3 Dashboard Page (Admin View)
**Steps:**
1. Click on "📊 Tổng quan" or ensure you're on dashboard

**Expected Elements:**
- [ ] 4 stat cards visible:
  - [ ] Hội viên hoạt động (blue card)
  - [ ] Sắp hết hạn (warning card)
  - [ ] Hóa đơn quá hạn (red card)
  - [ ] Doanh thu tháng này (green card)
- [ ] Stats show numbers (not just "—")
- [ ] Two tables below stats:
  - [ ] ⚠️ Hội viên sắp hết hạn
  - [ ] 🧾 Hóa đơn quá hạn

**API Calls (Network Tab):**
- [ ] GET /api/dashboard/stats
- [ ] GET /api/dashboard/expiring
- [ ] GET /api/dashboard/overdue
- [ ] All return 200 status
- [ ] Bearer token in Authorization header

**Results:**
- Status: [ ✓ PASS / ✗ FAIL ]
- Stats loaded: [ YES / NO ]
- Data displayed correctly: [ YES / NO ]
- Notes: _______________________________________________

---

### 1.4 Members Page (Admin)
**Steps:**
1. Click "👤 Hội viên"

**Expected Elements:**
- [ ] Page title: "👤 Danh sách hội viên"
- [ ] Search box visible: "🔍 Tìm kiếm hội viên..."
- [ ] "+ Thêm hội viên" button visible (PRIMARY BUTTON)
- [ ] Table with columns: ID, Họ tên, SĐT, Email, Ngày tham gia, Trạng thái, Thao tác
- [ ] Member rows load (or "Không có dữ liệu")
- [ ] Action buttons per row: ✏️ Sửa, 🗑️ Xóa
- [ ] Pagination controls (if >10 members)

**Test Create Member:**
1. Click "+ Thêm hội viên"
2. Modal opens: "Thêm hội viên"
3. Fill required fields (Họ tên, Email, Ngày tham gia)
4. Click "💾 Lưu"
5. [ ] Success message appears
6. [ ] Modal closes
7. [ ] Table refreshes with new member

**Results:**
- Status: [ ✓ PASS / ✗ FAIL ]
- Create button visible: [ YES / NO ]
- Create function works: [ YES / NO ]
- Notes: _______________________________________________

---

### 1.5 Schedules Page (Admin)
**Expected:**
- [ ] "+ Đặt lịch tập" button visible and enabled
- [ ] Table shows all schedules (not just own)
- [ ] Can edit/delete any schedule
- [ ] Create modal has dropdowns for: Member, Trainer, Facility

**Results:**
- Status: [ ✓ PASS / ✗ FAIL ]
- Notes: _______________________________________________

---

### 1.6 Checkins Page (Admin)
**Expected:**
- [ ] TWO buttons visible:
  - [ ] "📝 Check-in thủ công" (Manual checkin)
  - [ ] "📷 Check-in QR" (QR checkin)
- [ ] Table shows ALL checkins (system-wide)
- [ ] Both checkin methods accessible

**Results:**
- Status: [ ✓ PASS / ✗ FAIL ]
- Both buttons visible: [ YES / NO ]
- Notes: _______________________________________________

---

### 1.7 Invoices Page (Admin)
**Expected:**
- [ ] "+ Tạo hóa đơn" button visible
- [ ] Tab filters: Tất cả, Chờ TT, Đã TT, Quá hạn
- [ ] Shows ALL invoices (all members)
- [ ] Action buttons: 💰 Thanh toán, 🗑️ Xóa

**Results:**
- Status: [ ✓ PASS / ✗ FAIL ]
- Notes: _______________________________________________

---

### 1.8 Reports Page (Admin)
**Expected:**
- [ ] "📈 Báo cáo doanh thu" section visible
- [ ] Month/Year selectors
- [ ] "Xem báo cáo" button
- [ ] Stats: Tổng doanh thu, Đã thu, Chờ thanh toán, Số hóa đơn
- [ ] Detailed invoice table
- [ ] "👤 Hội viên đang hoạt động" table

**Results:**
- Status: [ ✓ PASS / ✗ FAIL ]
- Notes: _______________________________________________

---

### 1.9 Logout (Admin)
**Steps:**
1. Click on user avatar/menu in top-right
2. Click "🚪 Đăng xuất"

**Expected:**
- [ ] Redirects to /login.html
- [ ] localStorage cleared (no accessToken, no user)
- [ ] Cannot access /index.html without login

**Results:**
- Status: [ ✓ PASS / ✗ FAIL ]
- Notes: _______________________________________________

---

## TEST 2: CREATE MEMBER ACCOUNT

### 2.1 Registration Process
**Steps:**
1. Go to http://localhost:5250/login.html
2. Click "Tạo tài khoản" tab
3. Fill form:
   - Tên đăng nhập: `testmember`
   - Họ và tên: `Test Member` (optional)
   - Email: `testmember@gym.com`
   - Mật khẩu: `Test@2026`
   - Xác nhận mật khẩu: `Test@2026`
4. Click "Tạo tài khoản"

**Expected:**
- [ ] Success message: "✓ Tạo tài khoản thành công! Bạn có thể đăng nhập ngay."
- [ ] Form resets
- [ ] Auto-switch to "Đăng nhập" tab after ~2 seconds
- [ ] Username pre-filled: `testmember`

**API Call:**
- [ ] POST /api/auth/register
- [ ] Body: {username, email, password}
- [ ] Response 200/201
- [ ] Response includes: {userId, token, role: "Member"}

**Results:**
- Status: [ ✓ PASS / ✗ FAIL ]
- Account created: [ YES / NO ]
- Notes: _______________________________________________

---

## TEST 3: MEMBER ROLE (testmember / Test@2026)

### 3.1 Login Process (Member)
**Steps:**
1. On login page
2. Enter username: `testmember`
3. Enter password: `Test@2026`
4. Click "Đăng nhập"

**Expected:**
- [ ] Login successful
- [ ] Token saved in localStorage
- [ ] User object: {username: "testmember", role: "Member"}

**DevTools Check:**
```javascript
JSON.parse(localStorage.getItem('user')).role  // Should be "Member"
```

**Results:**
- Status: [ ✓ PASS / ✗ FAIL ]
- Role confirmed as Member: [ YES / NO ]
- Notes: _______________________________________________

---

### 3.2 Navigation Menu (Member) - CRITICAL TEST
**Expected Menu Items (4 ONLY):**
- [ ] 📊 Tổng quan (Dashboard)
- [ ] 📅 Lịch tập (Schedules)
- [ ] 🎫 Gói tập (Memberships)
- [ ] ✅ Check-in (Checkins)

**Items that MUST BE HIDDEN:**
- [ ] 👤 Hội viên (Members) - HIDDEN
- [ ] 💪 Huấn luyện viên (Trainers) - HIDDEN
- [ ] 🏠 Phòng / Thiết bị (Facilities) - HIDDEN
- [ ] 🧾 Hóa đơn (Invoices) - HIDDEN
- [ ] 📈 Báo cáo (Reports) - HIDDEN

**Verification:**
- Count visible menu items: _____ (must be 4)
- Verify hidden items: [ CONFIRMED / FAILED ]

**Results:**
- Status: [ ✓ PASS / ✗ FAIL ]
- Menu items correct: [ YES / NO ]
- Notes: _______________________________________________

---

### 3.3 Dashboard (Member View)
**Expected:**
- [ ] Stats show PERSONAL data only (not system-wide)
- [ ] "Hội viên hoạt động" = 1 (self) or personal metric
- [ ] NO admin-level stats
- [ ] Shows own memberships
- [ ] Shows own recent checkins

**Compare with Admin:**
- Admin dashboard shows system-wide stats
- Member dashboard shows personal view only

**Results:**
- Status: [ ✓ PASS / ✗ FAIL ]
- Personal view confirmed: [ YES / NO ]
- Notes: _______________________________________________

---

### 3.4 Schedules Page (Member)
**Expected:**
- [ ] Table shows ONLY own schedules (where MemberId = current user's memberId)
- [ ] "+ Đặt lịch tập" button visible (members CAN book sessions)
- [ ] Can create new schedule for self
- [ ] CANNOT edit/delete other members' schedules
- [ ] Edit/Delete buttons only on own schedules

**Results:**
- Status: [ ✓ PASS / ✗ FAIL ]
- Only own schedules shown: [ YES / NO ]
- Notes: _______________________________________________

---

### 3.5 Memberships Page (Member)
**Expected:**
- [ ] Shows ONLY own memberships
- [ ] "+ Đăng ký gói tập" button may be HIDDEN or DISABLED for members
  - (Admin typically creates memberships)
- [ ] Table columns: ID, Loại gói, Giá, Từ ngày, Đến ngày, Còn lại, Trạng thái
- [ ] NO access to other members' memberships

**Results:**
- Status: [ ✓ PASS / ✗ FAIL ]
- Only own data shown: [ YES / NO ]
- Notes: _______________________________________________

---

### 3.6 Checkins Page (Member)
**Expected:**
- [ ] "📷 Check-in QR" button visible (members can self-checkin)
- [ ] "📝 Check-in thủ công" button HIDDEN or DISABLED
  - (Manual checkin typically admin-only)
- [ ] Table shows ONLY own checkins
- [ ] NO access to other members' checkin history

**Results:**
- Status: [ ✓ PASS / ✗ FAIL ]
- QR button visible: [ YES / NO ]
- Manual button hidden: [ YES / NO ]
- Only own data: [ YES / NO ]
- Notes: _______________________________________________

---

### 3.7 Access Control Test (Member) - CRITICAL
**Steps:**
1. Try to access admin pages by typing URL directly:
   - http://localhost:5250/index.html#members
   - http://localhost:5250/index.html#invoices
   - http://localhost:5250/index.html#reports

**Expected Behavior:**
- [ ] Page does NOT load
- [ ] Error toast: "Bạn không có quyền truy cập trang này"
- [ ] Auto-redirect to dashboard
- [ ] Console shows: navigateTo() blocked by isAllowedPage() check

**Code Check (from app.js):**
```javascript
// This function should BLOCK member access
function isAllowedPage(pageId, role) {
  const allowedPages = {
    'Member': ['dashboard', 'schedules', 'memberships', 'checkins']
  };
  return allowedPages[role].includes(pageId);
}
```

**Test Each Blocked Page:**
- [ ] /members → redirects to dashboard
- [ ] /trainers → redirects to dashboard
- [ ] /facilities → redirects to dashboard
- [ ] /invoices → redirects to dashboard
- [ ] /reports → redirects to dashboard

**Results:**
- Status: [ ✓ PASS / ✗ FAIL ]
- Access properly restricted: [ YES / NO ]
- Notes: _______________________________________________

---

### 3.8 Logout (Member)
**Steps:**
1. Click user menu
2. Click "🚪 Đăng xuất"

**Expected:**
- [ ] Redirects to /login.html
- [ ] localStorage cleared

**Results:**
- Status: [ ✓ PASS / ✗ FAIL ]
- Notes: _______________________________________________

---

## COMPARISON TABLE

| Feature | Admin/SuperAdmin | Member | Notes |
|---------|-----------------|--------|-------|
| **Navigation Items** | 9 items | 4 items | Member sees 56% fewer menu items |
| **Dashboard** | System-wide stats | Personal stats | Admin sees all, Member sees own |
| **Members Page** | ✅ Full access | ❌ NO ACCESS | Admin only |
| **Trainers Page** | ✅ Full access | ❌ NO ACCESS | Admin only |
| **Facilities Page** | ✅ Full access | ❌ NO ACCESS | Admin only |
| **Schedules Page** | ✅ All schedules | ✅ Own only | Both can create, Member limited view |
| **Memberships Page** | ✅ All members | ✅ Own only | Member can view own subscriptions |
| **Checkins Page** | ✅ Manual + QR | ✅ QR only | Admin has both methods |
| **Invoices Page** | ✅ Full access | ❌ NO ACCESS | Admin only |
| **Reports Page** | ✅ Full access | ❌ NO ACCESS | Admin only |
| **Create Member** | ✅ Yes | ❌ No | Admin privilege |
| **Create Invoice** | ✅ Yes | ❌ No | Admin privilege |
| **View All Data** | ✅ System-wide | ❌ Personal only | Key difference |
| **API Authorization** | Full endpoints | Limited endpoints | Backend enforces |

---

## BROWSER DEVTOOLS INSPECTION

### localStorage Check
**After Admin Login:**
```javascript
// Run in Console:
localStorage.getItem('accessToken')  // Should return JWT string
let user = JSON.parse(localStorage.getItem('user'))
console.log(user)
// Expected: {userId: X, username: "gymadmin", role: "Admin", memberId: null, trainerId: null}
```

**After Member Login:**
```javascript
let user = JSON.parse(localStorage.getItem('user'))
console.log(user)
// Expected: {userId: Y, username: "testmember", role: "Member", memberId: Z, trainerId: null}
```

### Network Tab Check
**For Each API Call:**
- [ ] Request Headers contain: `Authorization: Bearer <token>`
- [ ] Response status 200/201 (success)
- [ ] Response status 401 → auto-logout (if token invalid)
- [ ] Response status 403 → access denied (if role insufficient)

### Console Check
**Expected:**
- [ ] NO errors during normal operation
- [ ] Role-based navigation warnings show: "Bạn không có quyền truy cập trang này"
- [ ] API errors are caught and shown in toast notifications

---

## ISSUES FOUND

### High Priority
_Document any critical access control failures here_
- [ ] Issue 1: _________________________________________________
- [ ] Issue 2: _________________________________________________

### Medium Priority
_Document any UI/UX issues_
- [ ] Issue 1: _________________________________________________
- [ ] Issue 2: _________________________________________________

### Low Priority
_Document any cosmetic issues_
- [ ] Issue 1: _________________________________________________
- [ ] Issue 2: _________________________________________________

---

## SCREENSHOTS / OBSERVATIONS

### Admin View
_Take screenshots of:_
- [ ] Admin dashboard with all 9 menu items
- [ ] Members page with create button
- [ ] Checkins page with both buttons (Manual + QR)

### Member View
_Take screenshots of:_
- [ ] Member dashboard with only 4 menu items
- [ ] Schedules page (own schedules only)
- [ ] Checkins page (QR button only)
- [ ] Attempt to access blocked page (should show error)

---

## CONCLUSION

### Overall Assessment
- **Admin Role**: [ ✓ PASS / ✗ FAIL / ⚠️ PARTIAL ]
- **Member Role**: [ ✓ PASS / ✗ FAIL / ⚠️ PARTIAL ]
- **Access Control**: [ ✓ PASS / ✗ FAIL / ⚠️ PARTIAL ]

### Summary
_Write 2-3 sentences summarizing the test results_

Example:
```
Admin role successfully displays all 9 navigation items and has full system access. Member role correctly shows only 4 menu items (Dashboard, Schedules, Memberships, Checkins) and is restricted from accessing admin pages. Access control properly redirects unauthorized page access attempts to dashboard with appropriate error messages.
```

Your summary:
______________________________________________________________________________
______________________________________________________________________________
______________________________________________________________________________

### Pass Rate Estimate
- Total test cases: ~40
- Passed: _____
- Failed: _____
- Pass rate: _____%

### Ready for Production?
- [ ] YES - All critical tests passed
- [ ] NO - Issues found (see Issues section)
- [ ] NEEDS WORK - List items: _________________________________

---

## NEXT STEPS

Based on test results:

1. **If all tests passed:**
   - [ ] Document as production-ready
   - [ ] Create user training materials
   - [ ] Deploy to production

2. **If issues found:**
   - [ ] Log issues in tracking system
   - [ ] Prioritize fixes (High → Medium → Low)
   - [ ] Re-test after fixes

3. **Code fixes needed:**
   - [ ] Update role checks in `app.js`
   - [ ] Update API authorization in backend controllers
   - [ ] Add missing access control checks

---

## MANUAL TESTING INSTRUCTIONS

### To Execute This Test:

1. **Start Server:**
   ```bash
   dotnet run --project "GymManegement.csproj"
   ```

2. **Open Browser:**
   - Use Chrome/Edge for best DevTools
   - Open: http://localhost:5250/login.html
   - Open DevTools (F12)

3. **Test Admin First:**
   - Login with gymadmin / Gym@2026
   - Go through sections 1.1 - 1.9
   - Mark checkboxes as you complete each test
   - Take screenshots

4. **Create Member Account:**
   - Logout
   - Follow section 2.1
   - Create testmember account

5. **Test Member Role:**
   - Login with testmember / Test@2026
   - Go through sections 3.1 - 3.8
   - Compare with Admin view
   - Verify access restrictions

6. **Fill Results:**
   - Complete all checkboxes
   - Fill in notes for any failures
   - Add screenshots to project folder
   - Save this document with results

---

## TESTER INFORMATION

- **Tester Name**: _________________________________
- **Test Date**: _________________________________
- **Test Duration**: _____ minutes
- **Browser**: Chrome / Edge / Firefox / Other: __________
- **Browser Version**: _________________________________
- **OS**: Windows / Mac / Linux
- **Server Status**: Running ✓ / Had issues ✗

---

**END OF MANUAL TEST PLAN**

---

## TECHNICAL NOTES

### Role-Based Access Control Implementation

**Frontend (app.js):**
```javascript
const allowedPages = {
  'Admin': ['dashboard', 'members', 'memberships', 'trainers', 'facilities', 'schedules', 'checkins', 'invoices', 'reports'],
  'SuperAdmin': ['dashboard', 'members', 'memberships', 'trainers', 'facilities', 'schedules', 'checkins', 'invoices', 'reports'],
  'Member': ['dashboard', 'schedules', 'memberships', 'checkins'],
  'Trainer': ['dashboard', 'schedules', 'checkins']
};
```

**Navigation Hiding:**
- Menu items with `data-role-required="admin"` are hidden for Member role
- `initNavigation()` function runs on page load
- `navigateTo()` function blocks unauthorized page access

**Token Storage:**
- Token: `localStorage.getItem('accessToken')`
- User: `JSON.parse(localStorage.getItem('user'))`

**API Authentication:**
- All API calls include: `Authorization: Bearer <token>`
- 401 response → auto-logout → redirect to /login.html
- 403 response → access denied → show error toast

### Backend Authorization (Should Match)

Controllers should enforce role-based access:
```csharp
[Authorize(Roles = "Admin,SuperAdmin")]  // Admin-only endpoints
[Authorize]  // All authenticated users, filter by user context
```

**Critical Endpoints:**
- Members CRUD: Admin only
- Trainers CRUD: Admin only
- Facilities CRUD: Admin only
- Invoices: Admin can see all, Member sees own
- Reports: Admin only
- Schedules: All can create, filtered by role
- Checkins: All can view own, Admin sees all

---

**This document serves as a comprehensive guide for manual testing. Execute tests and record results in the checkboxes and notes sections above.**
