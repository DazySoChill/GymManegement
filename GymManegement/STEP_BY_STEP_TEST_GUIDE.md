# Step-by-Step Test Guide with Expected Results

## 🎯 Complete Testing Walkthrough

This document provides a **detailed step-by-step guide** with exact expected results for each action.

---

## 📋 TEST SETUP

### Prerequisites
- [ ] Server running on http://localhost:5250
- [ ] Browser: Chrome/Edge (recommended for DevTools)
- [ ] DevTools open (F12)
- [ ] Network tab recording
- [ ] Console tab visible

### Starting Point
```bash
# In project directory:
cd "d:\Workspace\Độ án 2\GymManegement\GymManegement"
dotnet run --project "GymManegement.csproj"

# Wait for server to start, then open browser to:
http://localhost:5250/login.html
```

---

## 🔴 PART 1: ADMIN ROLE TESTING (10 minutes)

### Test 1.1: Admin Login

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Open http://localhost:5250/login.html | Login page loads, "Gym Management" header visible | [ ] |
| 2 | Look at "Tài khoản demo" section | Three demo buttons visible: admin, trainer1, member1 | [ ] |
| 3 | Click the "admin" demo button | Username field fills with "admin", password with "gym@2026" | [ ] |
| 4 | Click "Đăng nhập" button | Button shows "Đang xử lý..." with spinner | [ ] |
| 5 | Wait for response | Redirects to http://localhost:5250/ or /index.html | [ ] |
| 6 | Check URL | URL should be root / or /index.html, NOT /login.html | [ ] |
| 7 | Check page title | "Tổng quan" in top bar | [ ] |
| 8 | Check user badge (top-right) | Shows "admin" or "gymadmin" with role badge "Admin" or "SuperAdmin" | [ ] |

**DevTools Check:**
```javascript
// In Console, run:
localStorage.getItem('accessToken')
// Result: "eyJhbGci..." (long JWT string)

JSON.parse(localStorage.getItem('user'))
// Result: 
{
  userId: 1,
  username: "admin" or "gymadmin",
  role: "Admin" or "SuperAdmin",
  memberId: null,
  trainerId: null
}
```

**Expected API Call (Network tab):**
- Request: POST http://localhost:5250/api/auth/login
- Body: `{"username":"admin","password":"gym@2026"}`
- Response: 200 OK
- Response body: `{"token":"...", "userId":1, "username":"admin", "role":"Admin"}`

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

### Test 1.2: Admin Navigation Menu Structure

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Look at left sidebar | Sidebar visible with "🏋️ GymManager" logo at top | [ ] |
| 2 | Count menu items | Exactly 9 items below logo | [ ] |
| 3 | Verify item 1 | "📊 Tổng quan" - highlighted/active (blue background) | [ ] |
| 4 | Verify item 2 | "👤 Hội viên" - visible, not hidden | [ ] |
| 5 | Verify item 3 | "🎫 Gói tập" - visible | [ ] |
| 6 | Verify item 4 | "💪 Huấn luyện viên" - visible | [ ] |
| 7 | Verify item 5 | "🏠 Phòng / Thiết bị" - visible | [ ] |
| 8 | Verify item 6 | "📅 Lịch tập" - visible | [ ] |
| 9 | Verify item 7 | "✅ Check-in" - visible | [ ] |
| 10 | Verify item 8 | "🧾 Hóa đơn" - visible | [ ] |
| 11 | Verify item 9 | "📈 Báo cáo" - visible | [ ] |
| 12 | Check footer | "Gym Management v2.0" at bottom of sidebar | [ ] |
| 13 | Test click | Click any menu item → page changes, item becomes active | [ ] |

**CSS Inspection (DevTools → Elements):**
- Select sidebar nav items
- Check computed styles
- Verify NO items have `display: none`
- All items should have `display: flex` or `display: block`

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

### Test 1.3: Admin Dashboard Content

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Ensure on Dashboard page | "Tổng quan" highlighted in sidebar | [ ] |
| 2 | Check stats row | 4 colored cards in a row at top | [ ] |
| 3 | Card 1 (blue) | Label: "Hội viên hoạt động", Icon: 👤, Value: number (not "—") | [ ] |
| 4 | Card 2 (yellow/orange) | Label: "Sắp hết hạn (7 ngày)", Icon: ⚠️, Value: number | [ ] |
| 5 | Card 3 (red) | Label: "Hóa đơn quá hạn", Icon: 🧾, Value: number | [ ] |
| 6 | Card 4 (green) | Label: "Doanh thu tháng này", Icon: 💰, Value: formatted money | [ ] |
| 7 | Check below stats | Two cards side by side: "⚠️ Hội viên sắp hết hạn" and "🧾 Hóa đơn quá hạn" | [ ] |
| 8 | Card content | Tables or lists showing members/invoices (or "Không có dữ liệu") | [ ] |

**Expected API Calls (Network tab):**
1. GET /api/dashboard/stats → 200 OK
2. GET /api/dashboard/expiring → 200 OK
3. GET /api/dashboard/overdue → 200 OK

Each request should have:
- Header: `Authorization: Bearer <token>`

**Expected Response Example:**
```json
// /api/dashboard/stats
{
  "activeMembers": 125,
  "expiringMemberships": 15,
  "overdueInvoices": 8,
  "currentMonthRevenue": 15000000
}
```

**Verify Data Scope:**
- Numbers represent ALL members in system (not just one user)
- Admin sees system-wide statistics

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

### Test 1.4: Admin Members Page - Full Access

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Click "👤 Hội viên" in sidebar | Page changes to Members page | [ ] |
| 2 | Check page header | Title: "👤 Danh sách hội viên" | [ ] |
| 3 | Check toolbar (top-right) | Search box with 🔍 icon, placeholder: "Tìm kiếm hội viên..." | [ ] |
| 4 | **CRITICAL: Check create button** | **"+ Thêm hội viên" button visible** (blue/purple, primary style) | [ ] |
| 5 | Check table headers | Columns: ID, Họ tên, SĐT, Email, Ngày tham gia, Trạng thái, Thao tác | [ ] |
| 6 | Check table content | Rows of members load (or "Không có dữ liệu" if empty) | [ ] |
| 7 | Check action column | Each row has: ✏️ Sửa button, 🗑️ Xóa button | [ ] |
| 8 | Check pagination | Pagination controls at bottom (if >10 members) | [ ] |

**Test Create Member Flow:**

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Click "+ Thêm hội viên" | Modal opens with title "Thêm hội viên" | [ ] |
| 2 | Check modal form | Fields: Họ tên*, SĐT, Email*, Ngày sinh, Ngày tham gia*, Trạng thái | [ ] |
| 3 | Fill required fields | Enter: Họ tên="Test User", Email="test@gym.com", Ngày tham gia=today | [ ] |
| 4 | Click "💾 Lưu" | Modal closes, success toast: "Thêm hội viên thành công" | [ ] |
| 5 | Check table | Table refreshes, new member appears in list | [ ] |

**Expected API Calls:**
1. GET /api/members?page=1&pageSize=10 → 200 OK
2. POST /api/members (after create) → 201 Created

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

### Test 1.5: Admin Trainers Page

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Click "💪 Huấn luyện viên" | Page changes to Trainers page | [ ] |
| 2 | Check create button | "+ Thêm HLV" button visible | [ ] |
| 3 | Check table | Columns: ID, Họ tên, SĐT, Email, Chuyên môn, Thao tác | [ ] |
| 4 | Check actions | Each row has edit/delete buttons | [ ] |

**Expected API:** GET /api/trainers → 200 OK

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

### Test 1.6: Admin Facilities Page

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Click "🏠 Phòng / Thiết bị" | Page changes to Facilities page | [ ] |
| 2 | Check create button | "+ Thêm phòng" button visible | [ ] |
| 3 | Check table | Columns: ID, Tên, Mô tả, Trạng thái, Thao tác | [ ] |

**Expected API:** GET /api/facilities → 200 OK

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

### Test 1.7: Admin Schedules Page

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Click "📅 Lịch tập" | Page changes to Schedules page | [ ] |
| 2 | Check create button | "+ Đặt lịch tập" button visible | [ ] |
| 3 | Check table | Columns: ID, Hội viên, HLV, Phòng, Bắt đầu, Kết thúc, Thao tác | [ ] |
| 4 | Check data scope | Shows ALL schedules for ALL members (not filtered to one user) | [ ] |

**Expected API:** GET /api/schedules?page=1&pageSize=10 → 200 OK

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

### Test 1.8: Admin Checkins Page - CRITICAL TEST

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Click "✅ Check-in" | Page changes to Checkins page | [ ] |
| 2 | Check page header | Title: "✅ Lịch sử Check-in" | [ ] |
| 3 | **CRITICAL: Count buttons** | **TWO buttons visible in toolbar** | [ ] |
| 4 | **Button 1** | **"📝 Check-in thủ công"** (Manual checkin) - MUST BE VISIBLE | [ ] |
| 5 | **Button 2** | **"📷 Check-in QR"** (QR checkin) - MUST BE VISIBLE | [ ] |
| 6 | Check table | Columns: ID, Hội viên, Session, Thời gian, Phương thức | [ ] |
| 7 | Check data scope | Shows ALL checkins for ALL members (not filtered) | [ ] |

**Test Manual Checkin Button:**

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Click "📝 Check-in thủ công" | Modal opens: "📝 Check-in thủ công" | [ ] |
| 2 | Check form fields | Dropdowns: Hội viên*, Session*, Phương thức | [ ] |
| 3 | Click Cancel | Modal closes | [ ] |

**Expected API:** GET /api/checkins?page=1&pageSize=10 → 200 OK

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

### Test 1.9: Admin Invoices Page

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Click "🧾 Hóa đơn" | Page changes to Invoices page | [ ] |
| 2 | Check create button | "+ Tạo hóa đơn" button visible | [ ] |
| 3 | Check tab filters | 4 tabs: Tất cả, Chờ TT, Đã TT, Quá hạn | [ ] |
| 4 | Check table | Columns: ID, Hội viên, Tổng tiền, Ngày tạo, Hạn TT, Trạng thái, Thao tác | [ ] |
| 5 | Check actions | Each row has: 💰 Thanh toán, 🗑️ Xóa | [ ] |
| 6 | Check data scope | Shows ALL invoices for ALL members | [ ] |

**Expected API:** GET /api/invoices?page=1&pageSize=10 → 200 OK

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

### Test 1.10: Admin Reports Page

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Click "📈 Báo cáo" | Page changes to Reports page | [ ] |
| 2 | Check header | Title: "📈 Báo cáo doanh thu" | [ ] |
| 3 | Check controls | Month dropdown, Year input, "Xem báo cáo" button | [ ] |
| 4 | Check stats section | 4 stat cards: Tổng doanh thu, Đã thu, Chờ thanh toán, Số hóa đơn | [ ] |
| 5 | Check detail table | Invoice detail table with columns | [ ] |
| 6 | Check active members | Second card: "👤 Hội viên đang hoạt động" | [ ] |

**Expected API:** GET /api/reports/revenue?month=12&year=2026 → 200 OK

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

### Test 1.11: Admin Logout

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Click user avatar/badge (top-right) | Dropdown menu opens | [ ] |
| 2 | Check dropdown items | Options: 👤 Hồ sơ, ⚙️ Cài đặt, divider, 🚪 Đăng xuất | [ ] |
| 3 | Click "🚪 Đăng xuất" | Immediately redirects to /login.html | [ ] |
| 4 | Check URL | Now at http://localhost:5250/login.html | [ ] |
| 5 | Open DevTools Console | Run: `localStorage.getItem('accessToken')` → Result: null | [ ] |
| 6 | Check user data | Run: `localStorage.getItem('user')` → Result: null | [ ] |
| 7 | Try to access main page | Navigate to http://localhost:5250/ → Redirects back to /login.html | [ ] |

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

## 🟢 PART 2: MEMBER ACCOUNT CREATION (3 minutes)

### Test 2.1: Register New Member Account

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Ensure on login page | At http://localhost:5250/login.html | [ ] |
| 2 | Look at tabs | Two tabs: "Đăng nhập" (active), "Tạo tài khoản" | [ ] |
| 3 | Click "Tạo tài khoản" tab | Tab switches, form changes to registration form | [ ] |
| 4 | Check form fields | Fields: Tên đăng nhập*, Họ và tên, Email*, Mật khẩu*, Xác nhận mật khẩu* | [ ] |
| 5 | Check helper text | "🔒 Tài khoản đăng ký sẽ có quyền Member..." text below form | [ ] |

**Fill Registration Form:**

| Step | Field | Value | Check |
|------|-------|-------|-------|
| 6 | Tên đăng nhập | `testmember` | [ ] |
| 7 | Họ và tên | `Test Member` (optional) | [ ] |
| 8 | Email | `testmember@gym.com` | [ ] |
| 9 | Mật khẩu | `Test@2026` | [ ] |
| 10 | Xác nhận mật khẩu | `Test@2026` | [ ] |

**Submit and Verify:**

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 11 | Click "Tạo tài khoản" | Button shows "Đang xử lý..." with spinner | [ ] |
| 12 | Wait for response | Success message appears: "✓ Tạo tài khoản thành công! Bạn có thể đăng nhập ngay." | [ ] |
| 13 | Check message color | Green background (success style) | [ ] |
| 14 | Wait ~2 seconds | Auto-switches back to "Đăng nhập" tab | [ ] |
| 15 | Check username field | Pre-filled with "testmember" | [ ] |

**Expected API Call (Network tab):**
- Request: POST /api/auth/register
- Body: `{"username":"testmember","email":"testmember@gym.com","password":"Test@2026"}`
- Response: 200 or 201
- Response body: `{"userId":X, "token":"...", "role":"Member"}`

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

## 🟢 PART 3: MEMBER ROLE TESTING (10 minutes)

### Test 3.1: Member Login

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Ensure on "Đăng nhập" tab | "Đăng nhập" tab active, "testmember" pre-filled | [ ] |
| 2 | Enter password | Type: `Test@2026` | [ ] |
| 3 | Click "Đăng nhập" | Button shows "Đang xử lý..." | [ ] |
| 4 | Wait for response | Redirects to http://localhost:5250/ | [ ] |
| 5 | Check user badge | Top-right shows "testmember" with role badge "Member" | [ ] |

**DevTools Check:**
```javascript
// In Console:
JSON.parse(localStorage.getItem('user'))
// Expected result:
{
  userId: 25,  // some number
  username: "testmember",
  role: "Member",  // ← CRITICAL: must be "Member"
  memberId: 42,    // ← Should have a memberId (not null)
  trainerId: null
}
```

**Expected API Call:**
- POST /api/auth/login → 200 OK
- Response includes: `"role":"Member"`

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

### Test 3.2: Member Navigation Menu - CRITICAL TEST

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Look at left sidebar | Sidebar visible with logo | [ ] |
| 2 | **COUNT menu items** | **Exactly 4 items ONLY** (not 9!) | [ ] |
| 3 | Verify item 1 | "📊 Tổng quan" - visible and active | [ ] |
| 4 | Verify item 2 | "📅 Lịch tập" - visible | [ ] |
| 5 | Verify item 3 | "🎫 Gói tập" - visible | [ ] |
| 6 | Verify item 4 | "✅ Check-in" - visible | [ ] |
| 7 | **CRITICAL: Verify HIDDEN** | **"👤 Hội viên" - MUST NOT BE VISIBLE** | [ ] |
| 8 | **Verify HIDDEN** | **"💪 Huấn luyện viên" - MUST NOT BE VISIBLE** | [ ] |
| 9 | **Verify HIDDEN** | **"🏠 Phòng / Thiết bị" - MUST NOT BE VISIBLE** | [ ] |
| 10 | **Verify HIDDEN** | **"🧾 Hóa đơn" - MUST NOT BE VISIBLE** | [ ] |
| 11 | **Verify HIDDEN** | **"📈 Báo cáo" - MUST NOT BE VISIBLE** | [ ] |

**DevTools Inspection:**

```javascript
// Open Elements tab, find sidebar nav
// Check each menu item
document.querySelectorAll('#sidebar nav a').forEach(link => {
  const page = link.dataset.page;
  const visible = link.style.display !== 'none';
  console.log(page, visible ? '✓ visible' : '✗ hidden');
});

// Expected output:
// dashboard ✓ visible
// schedules ✓ visible
// memberships ✓ visible
// checkins ✓ visible
// members ✗ hidden      ← MUST BE HIDDEN
// trainers ✗ hidden     ← MUST BE HIDDEN
// facilities ✗ hidden   ← MUST BE HIDDEN
// invoices ✗ hidden     ← MUST BE HIDDEN
// reports ✗ hidden      ← MUST BE HIDDEN
```

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

### Test 3.3: Member Dashboard - Personal View

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Ensure on Dashboard | "Tổng quan" active in sidebar | [ ] |
| 2 | Check stats cards | Stats show PERSONAL data, not system-wide | [ ] |
| 3 | Compare with Admin | Member stats DIFFERENT from admin stats | [ ] |
| 4 | Check content | Shows own memberships, own upcoming schedules | [ ] |

**Expected vs Actual:**

| Metric | Admin View | Member View |
|--------|-----------|-------------|
| "Hội viên hoạt động" | 125 (all members) | Not shown OR shows 1 (self) |
| Data scope | System-wide | Personal only |
| Dashboard purpose | Management overview | Personal overview |

**Expected API:** GET /api/dashboard/stats (with member filter) → 200 OK

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

### Test 3.4: Member Schedules Page

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Click "📅 Lịch tập" | Page changes to Schedules page | [ ] |
| 2 | Check create button | "+ Đặt lịch tập" button may be visible (members can book) | [ ] |
| 3 | Check table | Table shows schedules | [ ] |
| 4 | **Check data filtering** | **ONLY shows OWN schedules** (where MemberId = testmember's memberId) | [ ] |
| 5 | Verify no other members | Should NOT see schedules for "Nguyễn Văn A", "Trần Thị B", etc. | [ ] |

**Expected API:** GET /api/schedules?memberId=42 → 200 OK (filtered)

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

### Test 3.5: Member Memberships Page

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Click "🎫 Gói tập" | Page changes to Memberships page | [ ] |
| 2 | Check dropdown | Member selector pre-filled with "Test Member" or own name | [ ] |
| 3 | Check table | Shows ONLY own memberships | [ ] |
| 4 | Verify data scope | Cannot see other members' memberships | [ ] |

**Expected API:** GET /api/memberships/member/42 → 200 OK (own data only)

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

### Test 3.6: Member Checkins Page - CRITICAL TEST

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Click "✅ Check-in" | Page changes to Checkins page | [ ] |
| 2 | **CRITICAL: Count buttons** | **ONLY ONE button visible** | [ ] |
| 3 | **Button visible** | **"📷 Check-in QR"** - MUST BE VISIBLE | [ ] |
| 4 | **Button HIDDEN** | **"📝 Check-in thủ công" - MUST NOT BE VISIBLE** | [ ] |
| 5 | Check table | Table shows checkin history | [ ] |
| 6 | **Check data filtering** | **ONLY shows OWN checkins** | [ ] |

**DevTools Check:**

```javascript
// Count visible buttons
document.querySelectorAll('#page-checkins .btn').length
// Expected: 1 button only (QR button)

// Check if manual button exists
document.querySelector('button[onclick*="openManualCheckin"]')
// Expected: null or style.display = 'none'
```

**Expected API:** GET /api/checkins?memberId=42 → 200 OK (filtered)

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

### Test 3.7: Member Access Control - CRITICAL TEST

**Test Scenario: Try to access admin-only pages directly**

#### Test 3.7.1: Access Members Page (Blocked)

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Type in address bar | `http://localhost:5250/index.html#members` | [ ] |
| 2 | Press Enter | URL changes, but page does NOT load Members page | [ ] |
| 3 | Check for error toast | **Toast appears: "⚠️ Bạn không có quyền truy cập trang này"** | [ ] |
| 4 | Check current page | **Still on Dashboard page** (redirected) | [ ] |
| 5 | Check URL | URL changes back to `#dashboard` | [ ] |
| 6 | Check sidebar | "Tổng quan" is active, NOT "Hội viên" | [ ] |

**DevTools Console Check:**
```javascript
// Should see:
// navigateTo("members")
// isAllowedPage("members", "Member") → false
// toast("Bạn không có quyền truy cập trang này", "error")
// navigateTo("dashboard")
```

**Network Tab Check:**
- NO API call to /api/members (blocked before API)
- Access control happens in frontend first

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

#### Test 3.7.2: Access Trainers Page (Blocked)

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Type: `#trainers` | Error toast appears, redirects to dashboard | [ ] |

**Result:** [ ✓ PASS / ✗ FAIL ]

---

#### Test 3.7.3: Access Facilities Page (Blocked)

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Type: `#facilities` | Error toast appears, redirects to dashboard | [ ] |

**Result:** [ ✓ PASS / ✗ FAIL ]

---

#### Test 3.7.4: Access Invoices Page (Blocked)

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Type: `#invoices` | Error toast appears, redirects to dashboard | [ ] |

**Result:** [ ✓ PASS / ✗ FAIL ]

---

#### Test 3.7.5: Access Reports Page (Blocked)

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Type: `#reports` | Error toast appears, redirects to dashboard | [ ] |

**Result:** [ ✓ PASS / ✗ FAIL ]

---

#### Test 3.7.6: Access Allowed Pages (Dashboard, Schedules)

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Type: `#dashboard` | Dashboard loads successfully, NO error | [ ] |
| 2 | Type: `#schedules` | Schedules page loads successfully, NO error | [ ] |
| 3 | Type: `#memberships` | Memberships page loads successfully, NO error | [ ] |
| 4 | Type: `#checkins` | Checkins page loads successfully, NO error | [ ] |

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

### Test 3.8: Member Logout

| Step | Action | Expected Result | Check |
|------|--------|----------------|-------|
| 1 | Click user badge (top-right) | Dropdown opens | [ ] |
| 2 | Click "🚪 Đăng xuất" | Redirects to /login.html | [ ] |
| 3 | Check localStorage | Token and user cleared | [ ] |

**Result:** [ ✓ PASS / ✗ FAIL ]  
**Notes:** _______________________________________________

---

## 📊 FINAL COMPARISON TABLE

### Complete Feature Comparison

| Feature | Admin/SuperAdmin | Member | Test Status |
|---------|------------------|--------|-------------|
| **Navigation** |
| Menu items count | 9 | 4 | [ ] |
| Dashboard visible | ✅ | ✅ | [ ] |
| Members visible | ✅ | ❌ | [ ] |
| Trainers visible | ✅ | ❌ | [ ] |
| Facilities visible | ✅ | ❌ | [ ] |
| Schedules visible | ✅ | ✅ | [ ] |
| Memberships visible | ✅ | ✅ | [ ] |
| Checkins visible | ✅ | ✅ | [ ] |
| Invoices visible | ✅ | ❌ | [ ] |
| Reports visible | ✅ | ❌ | [ ] |
| **Functionality** |
| Dashboard data scope | System-wide | Personal only | [ ] |
| Create member | ✅ | ❌ | [ ] |
| Create trainer | ✅ | ❌ | [ ] |
| Create facility | ✅ | ❌ | [ ] |
| Create schedule | ✅ | ✅ (own) | [ ] |
| Create membership | ✅ | ❌ | [ ] |
| Manual checkin | ✅ | ❌ | [ ] |
| QR checkin | ✅ | ✅ | [ ] |
| Create invoice | ✅ | ❌ | [ ] |
| View all members | ✅ | ❌ | [ ] |
| View own data | ✅ | ✅ | [ ] |
| Access reports | ✅ | ❌ | [ ] |
| **Security** |
| Can access #members URL | ✅ | ❌ (blocked) | [ ] |
| Can access #invoices URL | ✅ | ❌ (blocked) | [ ] |
| Can access #reports URL | ✅ | ❌ (blocked) | [ ] |
| Error toast on blocked access | N/A | ✅ | [ ] |
| Auto-redirect to dashboard | N/A | ✅ | [ ] |

---

## 🎯 TEST SUMMARY

### Completion Checklist

- [ ] Admin login successful
- [ ] Admin sees 9 menu items
- [ ] Admin can access all pages
- [ ] Admin dashboard shows system-wide stats
- [ ] Admin has all create buttons
- [ ] Admin checkins has 2 buttons
- [ ] Admin logout successful
- [ ] Member account created successfully
- [ ] Member login successful
- [ ] Member sees ONLY 4 menu items
- [ ] Member dashboard shows personal stats
- [ ] Member checkins has ONLY 1 button (QR)
- [ ] Member CANNOT access #members (blocked)
- [ ] Member CANNOT access #trainers (blocked)
- [ ] Member CANNOT access #facilities (blocked)
- [ ] Member CANNOT access #invoices (blocked)
- [ ] Member CANNOT access #reports (blocked)
- [ ] Error toast appears on blocked access
- [ ] Auto-redirect to dashboard works
- [ ] Member logout successful

### Test Results

**Total tests completed:** _____ / 75  
**Passed:** _____  
**Failed:** _____  
**Pass rate:** _____%

### Critical Tests Status

| Critical Test | Status |
|---------------|--------|
| Admin menu = 9 items | [ ✓ / ✗ ] |
| Member menu = 4 items | [ ✓ / ✗ ] |
| Member blocked from admin pages | [ ✓ / ✗ ] |
| Checkins button count (Admin=2, Member=1) | [ ✓ / ✗ ] |
| Role in localStorage correct | [ ✓ / ✗ ] |

### Overall Result

- [ ] ✅ ALL TESTS PASSED - RBAC working correctly
- [ ] ⚠️ SOME TESTS FAILED - Issues found (see notes)
- [ ] ❌ CRITICAL TESTS FAILED - Security issues present

---

## 📝 NOTES AND OBSERVATIONS

### Issues Found

#### High Priority (Security/Access Control)
_Document any access control failures here_

1. _______________________________________________
2. _______________________________________________
3. _______________________________________________

#### Medium Priority (Functionality)
_Document any functionality issues_

1. _______________________________________________
2. _______________________________________________

#### Low Priority (UI/UX)
_Document any cosmetic issues_

1. _______________________________________________
2. _______________________________________________

---

## ✅ SIGN-OFF

**Tested by:** _________________________________  
**Date:** _________________________________  
**Time spent:** _____ minutes  
**Browser:** _________________________________  
**Browser version:** _________________________________  

**Approved for production:** [ YES / NO ]

**Signature:** _________________________________

---

**END OF STEP-BY-STEP TEST GUIDE**
