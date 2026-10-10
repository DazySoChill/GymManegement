# Visual Test Guide - What to Look For

## 📸 Screenshot-by-Screenshot Guide

This guide shows you exactly what to look for in each screen.

---

## 🔴 ADMIN VIEW SCREENSHOTS

### Screenshot 1: Admin Navigation Sidebar

**What you should see:**

```
┌─────────────────────────────┐
│  🏋️ GymManager             │
├─────────────────────────────┤
│ 📊 Tổng quan        [ACTIVE]│ ← 1
│ 👤 Hội viên                 │ ← 2
│ 🎫 Gói tập                  │ ← 3
│ 💪 Huấn luyện viên          │ ← 4
│ 🏠 Phòng / Thiết bị         │ ← 5
│ 📅 Lịch tập                 │ ← 6
│ ✅ Check-in                 │ ← 7
│ 🧾 Hóa đơn                  │ ← 8
│ 📈 Báo cáo                  │ ← 9
├─────────────────────────────┤
│ Gym Management v2.0         │
└─────────────────────────────┘
```

**✓ Check:**
- [ ] COUNT = 9 items exactly
- [ ] All items visible (none have display:none)
- [ ] All items clickable

---

### Screenshot 2: Admin Dashboard

**What you should see:**

```
┌──────────────────────────────────────────────────┐
│  Tổng quan                    👤 gymadmin        │
│                                  [SuperAdmin]    │
├──────────────────────────────────────────────────┤
│  ┌───────────┐ ┌───────────┐ ┌───────────┐     │
│  │ 👤        │ │ ⚠️        │ │ 🧾        │     │
│  │ Hội viên  │ │ Sắp hết   │ │ Hóa đơn   │     │
│  │ hoạt động │ │ hạn       │ │ quá hạn   │     │
│  │   125     │ │    15     │ │     8     │ ← Numbers show system-wide
│  └───────────┘ └───────────┘ └───────────┘     │
│                                                  │
│  ⚠️ Hội viên sắp hết hạn                        │
│  ┌─────────────────────────────────────┐        │
│  │ Nguyễn Văn A - Hết hạn: 05/10/2026  │        │
│  │ Trần Thị B   - Hết hạn: 07/10/2026  │        │
│  └─────────────────────────────────────┘        │
└──────────────────────────────────────────────────┘
```

**✓ Check:**
- [ ] 4 stat cards visible
- [ ] Numbers show (not "—")
- [ ] Stats represent ALL members (not just self)
- [ ] User badge shows "Admin" or "SuperAdmin"

---

### Screenshot 3: Admin Members Page

**What you should see:**

```
┌──────────────────────────────────────────────────┐
│  👤 Danh sách hội viên                           │
│  ┌────────────┐ ┌──────────────────┐            │
│  │🔍 Tìm kiếm│ │ + Thêm hội viên   │ ← BUTTON  │
│  └────────────┘ └──────────────────┘            │
├──────────────────────────────────────────────────┤
│ ID │ Họ tên        │ SĐT        │ Email         │
├────┼───────────────┼────────────┼───────────────┤
│ 1  │ Nguyễn Văn A  │ 0901234567 │ a@gym.com     │
│ 2  │ Trần Thị B    │ 0907654321 │ b@gym.com     │
│    │               │            │ [✏️ Sửa][🗑️ Xóa]│
└──────────────────────────────────────────────────┘
```

**✓ Check:**
- [ ] **"+ Thêm hội viên" button visible** (PRIMARY - blue/purple)
- [ ] Search box present
- [ ] Table shows all members (not filtered)
- [ ] Action buttons visible: ✏️ Sửa, 🗑️ Xóa
- [ ] Can click "+ Thêm hội viên" → modal opens

---

### Screenshot 4: Admin Checkins Page

**What you should see:**

```
┌──────────────────────────────────────────────────┐
│  ✅ Lịch sử Check-in                             │
│  ┌─────────────────────┐ ┌──────────────────┐   │
│  │ 📝 Check-in thủ công │ │ 📷 Check-in QR  │   │ ← TWO BUTTONS
│  └─────────────────────┘ └──────────────────┘   │
├──────────────────────────────────────────────────┤
│ ID │ Hội viên      │ Session │ Thời gian         │
├────┼───────────────┼─────────┼───────────────────┤
│ 1  │ Nguyễn Văn A  │ S123    │ 09/10 08:30       │
│ 2  │ Trần Thị B    │ S124    │ 09/10 09:15       │
└──────────────────────────────────────────────────┘
```

**✓ Check:**
- [ ] **TWO buttons visible**
- [ ] "📝 Check-in thủ công" button (Manual)
- [ ] "📷 Check-in QR" button (QR)
- [ ] Table shows ALL members' checkins (not filtered)

---

### Screenshot 5: Admin Invoices Page

**What you should see:**

```
┌──────────────────────────────────────────────────┐
│  🧾 Hóa đơn                                      │
│  [Tất cả][Chờ TT][Đã TT][Quá hạn]               │ ← Tabs
│  ┌──────────────────┐                           │
│  │ + Tạo hóa đơn    │ ← BUTTON                  │
│  └──────────────────┘                           │
├──────────────────────────────────────────────────┤
│ ID │ Hội viên │ Tổng tiền │ Trạng thái           │
├────┼──────────┼───────────┼──────────────────────┤
│ 1  │ Nguyễn A │ 500.000đ  │ [Đã TT]   [💰][🗑️]  │
│ 2  │ Trần B   │ 300.000đ  │ [Chờ TT]  [💰][🗑️]  │
└──────────────────────────────────────────────────┘
```

**✓ Check:**
- [ ] **"+ Tạo hóa đơn" button visible**
- [ ] Tab filters present
- [ ] Shows ALL invoices (all members)
- [ ] Action buttons: 💰 Thanh toán, 🗑️ Xóa

---

### Screenshot 6: Admin Reports Page

**What you should see:**

```
┌──────────────────────────────────────────────────┐
│  📈 Báo cáo doanh thu                            │
│  [Tháng 12▼] [2026] [Xem báo cáo]               │
├──────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐                │
│  │ Tổng DT     │ │ Đã thu      │                │
│  │ 15.000.000đ │ │ 12.000.000đ │                │
│  └─────────────┘ └─────────────┘                │
│                                                  │
│  Invoice detail table...                         │
└──────────────────────────────────────────────────┘
```

**✓ Check:**
- [ ] Reports page accessible
- [ ] Revenue stats visible
- [ ] Month/year selectors work
- [ ] Shows system-wide financial data

---

### Screenshot 7: Admin DevTools - localStorage

**Open DevTools (F12) → Console, type:**

```javascript
JSON.parse(localStorage.getItem('user'))
```

**Expected output:**
```javascript
{
  userId: 1,
  username: "gymadmin",
  role: "Admin",        // or "SuperAdmin"
  memberId: null,
  trainerId: null
}
```

**✓ Check:**
- [ ] `role` = "Admin" or "SuperAdmin"
- [ ] `username` = "gymadmin" or "admin"
- [ ] Token exists: `localStorage.getItem('accessToken')` returns JWT string

---

### Screenshot 8: Admin DevTools - Network Tab

**Look at any API call (e.g., GET /api/members):**

```
Request Headers:
  Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
  Content-Type: application/json

Response:
  Status: 200 OK
  Body: [array of members]
```

**✓ Check:**
- [ ] Authorization header present
- [ ] Bearer token included
- [ ] Status 200 (success)
- [ ] No 401/403 errors

---

## 🟢 MEMBER VIEW SCREENSHOTS

### Screenshot 9: Member Navigation Sidebar

**What you should see:**

```
┌─────────────────────────────┐
│  🏋️ GymManager             │
├─────────────────────────────┤
│ 📊 Tổng quan        [ACTIVE]│ ← 1
│ 📅 Lịch tập                 │ ← 2
│ 🎫 Gói tập                  │ ← 3
│ ✅ Check-in                 │ ← 4
├─────────────────────────────┤
│ Gym Management v2.0         │
└─────────────────────────────┘
```

**✓ Check:**
- [ ] COUNT = **ONLY 4 items**
- [ ] NO "Hội viên" item
- [ ] NO "Huấn luyện viên" item
- [ ] NO "Phòng / Thiết bị" item
- [ ] NO "Hóa đơn" item
- [ ] NO "Báo cáo" item

**❌ Should NOT see:**
```
┌─────────────────────────────┐
│ ❌ 👤 Hội viên              │ ← MUST BE HIDDEN
│ ❌ 💪 Huấn luyện viên       │ ← MUST BE HIDDEN
│ ❌ 🏠 Phòng / Thiết bị      │ ← MUST BE HIDDEN
│ ❌ 🧾 Hóa đơn               │ ← MUST BE HIDDEN
│ ❌ 📈 Báo cáo               │ ← MUST BE HIDDEN
└─────────────────────────────┘
```

---

### Screenshot 10: Member Dashboard

**What you should see:**

```
┌──────────────────────────────────────────────────┐
│  Tổng quan                    👤 testmember      │
│                                  [Member]        │
├──────────────────────────────────────────────────┤
│  ┌───────────┐ ┌───────────┐                    │
│  │ 🎫        │ │ ✅        │                    │
│  │ Gói tập   │ │ Check-in  │                    │
│  │ của tôi   │ │ hôm nay   │                    │
│  │     2     │ │     1     │ ← Personal stats only
│  └───────────┘ └───────────┘                    │
│                                                  │
│  📅 Lịch tập sắp tới của tôi                    │
│  ┌─────────────────────────────────────┐        │
│  │ 10/10 14:00 - Yoga with Trainer A   │        │
│  └─────────────────────────────────────┘        │
└──────────────────────────────────────────────────┘
```

**✓ Check:**
- [ ] User badge shows "Member"
- [ ] Stats show PERSONAL data only (not system-wide)
- [ ] No "Hội viên hoạt động: 125" (that's admin data)
- [ ] Shows own memberships, own checkins

**Compare with Admin:**
- Admin: "Hội viên hoạt động: 125" (all members)
- Member: "Gói tập của tôi: 2" (own only)

---

### Screenshot 11: Member Schedules Page

**What you should see:**

```
┌──────────────────────────────────────────────────┐
│  📅 Lịch tập                                     │
│  ┌──────────────────┐                           │
│  │ + Đặt lịch tập   │ ← Button may be visible   │
│  └──────────────────┘     (members can book)    │
├──────────────────────────────────────────────────┤
│ ID │ HLV       │ Phòng  │ Bắt đầu               │
├────┼───────────┼────────┼───────────────────────┤
│ 15 │ Trainer A │ Room 1 │ 10/10 14:00 [✏️][🗑️] │ ← Own schedule
│ 22 │ Trainer B │ Room 2 │ 12/10 09:00 [✏️][🗑️] │ ← Own schedule
└──────────────────────────────────────────────────┘
```

**✓ Check:**
- [ ] Table shows ONLY own schedules
- [ ] Does NOT show other members' schedules
- [ ] Can edit/delete own schedules only

**❌ Should NOT see:**
```
│ 3  │ Nguyễn Văn A │ Trainer A │ Room 1 │ ... │ ← Other member
│ 7  │ Trần Thị B   │ Trainer B │ Room 2 │ ... │ ← Other member
```

---

### Screenshot 12: Member Checkins Page (CRITICAL)

**What you should see:**

```
┌──────────────────────────────────────────────────┐
│  ✅ Lịch sử Check-in                             │
│  ┌──────────────────┐                           │
│  │ 📷 Check-in QR   │ ← ONLY ONE BUTTON         │
│  └──────────────────┘                           │
├──────────────────────────────────────────────────┤
│ ID │ Session │ Thời gian         │ Phương thức  │
├────┼─────────┼───────────────────┼──────────────┤
│ 45 │ S789    │ 09/10 08:30       │ QR           │ ← Own checkin
│ 46 │ S790    │ 10/10 09:00       │ QR           │ ← Own checkin
└──────────────────────────────────────────────────┘
```

**✓ Check:**
- [ ] **ONLY ONE button: "📷 Check-in QR"**
- [ ] NO "📝 Check-in thủ công" button
- [ ] Table shows ONLY own checkins

**❌ Should NOT see:**
```
┌──────────────────────────────────────────────────┐
│  ┌─────────────────────┐ ┌──────────────────┐   │
│  │ ❌ 📝 Check-in thủ công │ │ 📷 Check-in QR  │   │ ← Manual button hidden
│  └─────────────────────┘ └──────────────────┘   │
└──────────────────────────────────────────────────┘
```

---

### Screenshot 13: Member Memberships Page

**What you should see:**

```
┌──────────────────────────────────────────────────┐
│  🎫 Tra cứu gói tập theo hội viên                │
│  [Test Member ▼] [Xem]                           │
├──────────────────────────────────────────────────┤
│ ID │ Loại gói  │ Giá       │ Từ ngày │ Đến ngày │
├────┼───────────┼───────────┼─────────┼──────────┤
│ 10 │ Monthly   │ 500.000đ  │ 01/10   │ 01/11    │ ← Own membership
│ 15 │ Quarterly │ 1.200.000đ│ 01/09   │ 01/12    │ ← Own membership
└──────────────────────────────────────────────────┘
```

**✓ Check:**
- [ ] Shows ONLY own memberships
- [ ] Dropdown pre-selected with own name
- [ ] Cannot see other members' memberships

---

### Screenshot 14: Member DevTools - localStorage

**Open DevTools (F12) → Console, type:**

```javascript
JSON.parse(localStorage.getItem('user'))
```

**Expected output:**
```javascript
{
  userId: 25,
  username: "testmember",
  role: "Member",      // ← MUST BE "Member"
  memberId: 42,        // ← Has a memberId
  trainerId: null
}
```

**✓ Check:**
- [ ] `role` = **"Member"** (not Admin)
- [ ] `username` = "testmember"
- [ ] `memberId` has a value (not null)

---

### Screenshot 15: Member Access Denied (CRITICAL TEST)

**Type in browser address bar:**
```
http://localhost:5250/index.html#members
```

**What you should see:**

```
┌──────────────────────────────────────────────────┐
│  📊 Tổng quan              👤 testmember [Member]│
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │ ⚠️ Bạn không có quyền truy cập trang này   │ │ ← ERROR TOAST
│  └────────────────────────────────────────────┘ │
│                                                  │
│  [Dashboard content loads instead]               │
│  URL changes back to: #dashboard                 │
└──────────────────────────────────────────────────┘
```

**✓ Check:**
- [ ] Error message appears: "Bạn không có quyền truy cập trang này"
- [ ] URL redirects to #dashboard
- [ ] Members page does NOT load
- [ ] Still on dashboard page

**❌ Should NOT see:**
```
┌──────────────────────────────────────────────────┐
│  👤 Danh sách hội viên                           │ ← Page should NOT load
│  [Member list table shown]                       │ ← Data should NOT appear
└──────────────────────────────────────────────────┘
```

---

### Screenshot 16: Member DevTools - Console Error

**After trying to access blocked page, check Console:**

```javascript
// Console should show:
navigateTo("members")
// Function blocks and shows toast
isAllowedPage("members", "Member") // returns false
// Auto-redirects to dashboard
```

**Network Tab should show:**
- [ ] NO API call to /api/members (blocked before API call)
- [ ] Access control happens in frontend first

---

## 🔍 DETAILED COMPARISON IMAGES

### Side-by-Side: Navigation Menu

```
ADMIN (9 items)              MEMBER (4 items)
┌─────────────────────┐     ┌─────────────────────┐
│ 📊 Tổng quan        │     │ 📊 Tổng quan        │ ✓
│ 👤 Hội viên         │     │ 📅 Lịch tập         │ ✓
│ 🎫 Gói tập          │     │ 🎫 Gói tập          │ ✓
│ 💪 Huấn luyện viên  │     │ ✅ Check-in         │ ✓
│ 🏠 Phòng / Thiết bị │     └─────────────────────┘
│ 📅 Lịch tập         │
│ ✅ Check-in         │
│ 🧾 Hóa đơn          │
│ 📈 Báo cáo          │
└─────────────────────┘
```

### Side-by-Side: Checkins Page Buttons

```
ADMIN                        MEMBER
┌─────────────────────┐     ┌─────────────────────┐
│ 📝 Check-in thủ công│     │                     │
│ 📷 Check-in QR      │     │ 📷 Check-in QR      │
└─────────────────────┘     └─────────────────────┘
     2 buttons                   1 button only
```

### Side-by-Side: Create Buttons

```
ADMIN                        MEMBER
Members page:                Members page:
[+ Thêm hội viên] ✓          [NO ACCESS] ✗

Invoices page:               Invoices page:
[+ Tạo hóa đơn] ✓            [NO ACCESS] ✗

Schedules page:              Schedules page:
[+ Đặt lịch tập] ✓           [+ Đặt lịch tập] ✓
```

---

## 📝 WHAT TO WRITE IN NOTES

For each screenshot, document:

### If PASS:
```
✓ Screenshot X: PASS
- All expected elements visible
- Correct number of menu items
- Role displayed correctly
- No errors in console
```

### If FAIL:
```
✗ Screenshot X: FAIL
- Issue: Member can see "Hội viên" menu item
- Expected: Hidden for Member role
- Actual: Visible and clickable
- Code to check: app.js line 45 (initNavigation)
- Severity: HIGH - security issue
```

---

## 🎯 CRITICAL VISUAL CHECKS SUMMARY

### Must Verify:

1. **Menu Count:**
   - Admin: 9 items ✓
   - Member: 4 items ✓

2. **Button Visibility:**
   - Admin Members page: "+ Thêm hội viên" visible ✓
   - Admin Checkins: 2 buttons ✓
   - Member Checkins: 1 button only ✓

3. **Access Denied:**
   - Member tries #members → Error toast + redirect ✓

4. **Role in DevTools:**
   - Admin: role = "Admin"/"SuperAdmin" ✓
   - Member: role = "Member" ✓

5. **Data Scope:**
   - Admin dashboard: system-wide stats ✓
   - Member dashboard: personal stats only ✓

---

## 📸 Screenshot Naming Convention

Save screenshots as:
```
01_admin_navigation_sidebar.png
02_admin_dashboard_stats.png
03_admin_members_page_with_create_button.png
04_admin_checkins_two_buttons.png
05_admin_invoices_page.png
06_admin_reports_page.png
07_admin_devtools_localstorage.png
08_admin_devtools_network_api.png
09_member_navigation_sidebar_4items.png
10_member_dashboard_personal.png
11_member_schedules_own_only.png
12_member_checkins_qr_only.png
13_member_memberships_own_only.png
14_member_devtools_localstorage.png
15_member_access_denied_toast.png
16_member_devtools_console_blocked.png
```

---

**Use this guide alongside MANUAL_TEST_RESULTS.md and QUICK_TEST_CHECKLIST.md for comprehensive testing.**
