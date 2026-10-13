# Implementation Plan: Trainer Frontend Reset (Inherit 100% Member Behavior)

**Goal**: Reset Trainer frontend to inherit 100% of Member behavior — identical pages, identical views, identical functions. This is a SIMPLIFICATION, not a feature addition.

**Strategy**: Remove all Trainer-specific rendering logic and make Trainer role use the same code paths as Member role throughout the frontend.

---

## Findings Summary

### app.js (Line 7)
- **Current**: Trainer has restricted pages: `['dashboard', 'schedules', 'checkins', 'profile']`
- **Current**: Member has: `['dashboard', 'memberships', 'schedules', 'sessions', 'checkins', 'member-schedule', 'profile']`
- **Issue**: Trainer cannot access `memberships`, `sessions`, `member-schedule` pages

### dashboard.js
- **Lines 11-12**: Role check splits `renderTrainerDashboard()` vs `renderMemberDashboard()`
- **Lines 220-275**: `getTrainerId()` function fetches trainerId by email lookup
- **Lines 276-442**: `renderTrainerDashboard()` shows trainer-specific stats (Class Hôm Nay, Học Viên Đã Attend, Check-in Hôm Nay, Lịch Dạy Hôm Nay)
- **Usage**: `getTrainerId()` is called in dashboard, schedules, and sessions modules

### checkins.js
- **Lines 75-78**: `renderCheckins()` checks role and calls `renderMemberCheckins()` for BOTH Member AND Trainer
- **Already correct**: Trainer already uses Member view for check-ins

### schedules.js
- **Lines 261-269**: `renderSchedules()` checks role — Member gets personal schedule view, Admin/Trainer get management view
- **Lines 520-523, 709-712, 840-842, 851-853, 1054-1057**: `getTrainerId()` used to:
  1. Auto-fill trainer dropdown when creating schedule (Lines 709-712)
  2. Filter edit permissions (Lines 840-842, 1054-1057)
  3. Check ownership for editing (Lines 520-523, 851-853)
- **Issue**: Trainer gets management view instead of Member personal schedule view

### sessions.js
- **Lines 189-197**: `renderSessions()` splits three ways: Member, Trainer, Admin
- **Lines 493-656**: `renderTrainerSessions()` shows session approval UI (approve/reject pending registrations)
- **Lines 496-498, 546-548, 737-739, 769-771**: `getTrainerId()` used for filtering trainer's schedules
- **Issue**: Trainer gets approval UI instead of Member registration view

### memberships.js
- **Lines 59-67**: `renderMemberships()` checks role — Member gets personal memberships + purchase UI, Admin/Trainer get management view
- **Issue**: Trainer would get management view instead of Member view (but Trainer doesn't have access to this page currently)

---

## Implementation Plan

- [ ] **1. Update app.js allowedPagesByRole — Make Trainer array identical to Member array**
   
   **What**: Change line 8 from:
   ```javascript
   'Trainer': ['dashboard', 'schedules', 'checkins', 'profile'],
   ```
   to:
   ```javascript
   'Trainer': ['dashboard', 'memberships', 'schedules', 'sessions', 'checkins', 'member-schedule', 'profile'],
   ```
   
   **Files**: `wwwroot/js/app.js`
   
   **Verify**: Log in as Trainer, confirm navigation sidebar shows all Member pages (Gói tập, Lịch Tập, Đăng ký Class, Lịch Tập Của Tôi)

---

- [ ] **2. Update dashboard.js renderDashboard() — Remove Trainer branch, merge into Member**
   
   **What**: Change lines 8-15 from:
   ```javascript
   async function renderDashboard(container) {
       const role = getRole();
       
       if (isAdmin()) {
           await renderAdminDashboard(container);
       } else if (role === 'Trainer') {
           await renderTrainerDashboard(container);
       } else if (role === 'Member') {
           await renderMemberDashboard(container);
       }
   }
   ```
   to:
   ```javascript
   async function renderDashboard(container) {
       const role = getRole();
       
       if (isAdmin()) {
           await renderAdminDashboard(container);
       } else {
           // Both Member and Trainer use Member dashboard
           await renderMemberDashboard(container);
       }
   }
   ```
   
   **Keep**: `renderTrainerDashboard()` (lines 276-442), `getTrainerId()` (lines 233-275), and related functions for now — they are not called but remain for potential future use or debugging
   
   **Files**: `wwwroot/js/dashboard.js`
   
   **Verify**: Log in as Trainer, navigate to Dashboard, confirm it shows Member dashboard (Buổi tập sắp tới, Trạng Thái Gói Tập, Số Ngày Còn Lại, 5 Lần Check-in Gần Nhất, Gói Tập Của Tôi)

---

- [ ] **3. Update checkins.js renderCheckins() — Simplify role check (already correct for Trainer)**
   
   **What**: Change lines 75-81 from:
   ```javascript
   async function renderCheckins(container) {
       const role = getRole();
       const memberId = getMemberId();
       
       if ((role === 'Member' || role === 'Trainer') && memberId) {
           await renderMemberCheckins(container, memberId);
       } else {
           await renderAllCheckins(container);
       }
   }
   ```
   to:
   ```javascript
   async function renderCheckins(container) {
       const role = getRole();
       const memberId = getMemberId();
       
       if (role === 'Member' || role === 'Trainer') {
           if (memberId) {
               await renderMemberCheckins(container, memberId);
           } else {
               container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-text">Không tìm thấy thông tin member</div></div>';
           }
       } else {
           await renderAllCheckins(container);
       }
   }
   ```
   
   **Rationale**: Trainer already uses Member view. This change adds safety check for missing memberId.
   
   **Files**: `wwwroot/js/checkins.js`
   
   **Verify**: Log in as Trainer, navigate to Check-in, confirm it shows Member view (Lịch Sử Check-in with ✅ Check In button and date filters)

---

- [ ] **4. Update schedules.js renderSchedules() — Make Trainer use Member view**
   
   **What**: Change lines 261-287 from:
   ```javascript
   async function renderSchedules(container) {
       const role = getRole();
       const memberId = getMemberId();
       const canManage = role === 'Admin' || role === 'Trainer';
       
       if (role === 'Member') {
           // Member view - Show both personal schedule preferences and registered classes
           container.innerHTML = `...`;
           
           await Promise.all([
               loadPersonalSchedules(memberId),
               loadRegisteredClasses(memberId)
           ]);
           
       } else {
           // Admin/Trainer view
           container.innerHTML = `...`;
           
           await loadSchedules();
       }
   }
   ```
   to:
   ```javascript
   async function renderSchedules(container) {
       const role = getRole();
       const memberId = getMemberId();
       
       if (role === 'Member' || role === 'Trainer') {
           // Member and Trainer view - Show both personal schedule preferences and registered classes
           if (!memberId) {
               container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-text">Không tìm thấy thông tin member</div></div>';
               return;
           }
           
           container.innerHTML = `
               <div class="card">
                   <div class="card-header">
                       <h2 class="card-title">Lịch Tập</h2>
                   </div>
                   
                   <!-- Personal Schedule Preferences -->
                   <div style="padding: 20px; border-bottom: 2px solid #e0e0e0;">
                       <h3 style="margin: 0 0 16px 0; color: #2c3e50;">📅 Lịch Tập Cá Nhân</h3>
                       <div id="personalSchedulesContainer">
                           <div style="text-align: center; padding: 20px;">
                               <div class="spinner"></div>
                           </div>
                       </div>
                   </div>
                   
                   <!-- Registered Classes -->
                   <div style="padding: 20px;">
                       <h3 style="margin: 0 0 16px 0; color: #2c3e50;">🏋️ Lớp Đã Đăng Ký</h3>
                       <div id="registeredClassesContainer">
                           <div style="text-align: center; padding: 20px;">
                               <div class="spinner"></div>
                           </div>
                       </div>
                   </div>
               </div>
           `;
           
           await Promise.all([
               loadPersonalSchedules(memberId),
               loadRegisteredClasses(memberId)
           ]);
           
       } else {
           // Admin view
           const canManage = role === 'Admin';
           
           container.innerHTML = `
               <div class="card">
                   <div class="card-header">
                       <h2 class="card-title">Lịch Tập</h2>
                       ${canManage ? '<button class="btn btn-primary" onclick="showCreateScheduleModal()">➕ Thêm lịch</button>' : ''}
                   </div>
                   
                   <div class="filters">
                       <input type="date" id="scheduleDate" onchange="loadSchedulesByDate()">
                       <button class="btn btn-info" onclick="loadSchedules()">🔍 Tất cả</button>
                   </div>
                   
                   <div class="table-container" id="schedulesTableContainer"></div>
                   <div id="schedulesPagination" class="pagination"></div>
               </div>
           `;
           
           await loadSchedules();
       }
   }
   ```
   
   **Keep**: All `getTrainerId()` calls and trainer-specific logic in `showCreateScheduleModal()` and `renderSchedulesTable()` — they handle the case where Admin creates schedules and must select a trainer, which remains valid
   
   **Files**: `wwwroot/js/schedules.js`
   
   **Verify**: Log in as Trainer, navigate to Lịch Tập, confirm it shows Member view (📅 Lịch Tập Cá Nhân section + 🏋️ Lớp Đã Đăng Ký section)

---

- [ ] **5. Update sessions.js renderSessions() — Make Trainer use Member view**
   
   **What**: Change lines 189-197 from:
   ```javascript
   async function renderSessions(container) {
       const role = getRole();
       const memberId = getMemberId();
       
       if (role === 'Member' && memberId) {
           await renderMemberSessions(container, memberId);
       } else if (role === 'Trainer') {
           await renderTrainerSessions(container);
       } else {
           await renderAllSessions(container);
       }
   }
   ```
   to:
   ```javascript
   async function renderSessions(container) {
       const role = getRole();
       const memberId = getMemberId();
       
       if (role === 'Member' || role === 'Trainer') {
           if (memberId) {
               await renderMemberSessions(container, memberId);
           } else {
               container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-text">Không tìm thấy thông tin member</div></div>';
           }
       } else {
           await renderAllSessions(container);
       }
   }
   ```
   
   **Keep**: `renderTrainerSessions()` (lines 493-656), `filterTrainerSessions()`, `loadTrainerSessions()`, `renderTrainerSessionsTable()`, `approveTrainerSession()`, `rejectTrainerSession()` — they are not called but remain for potential future use
   
   **Files**: `wwwroot/js/sessions.js`
   
   **Verify**: Log in as Trainer, navigate to Đăng ký Class, confirm it shows Member view (📚 Lớp Có Thể Đăng Ký section + 📝 Lớp Đã Đăng Ký section with week filters)

---

- [ ] **6. Update memberships.js renderMemberships() — Make Trainer use Member view**
   
   **What**: Change lines 59-67 from:
   ```javascript
   async function renderMemberships(container) {
       const role = getRole();
       const memberId = getMemberId();
       
       if (role === 'Member' && memberId) {
           // Member view - show only own memberships
           await renderMemberMemberships(container, memberId);
       } else {
           // Admin/Trainer view - show all memberships
           await renderAllMemberships(container);
       }
   }
   ```
   to:
   ```javascript
   async function renderMemberships(container) {
       const role = getRole();
       const memberId = getMemberId();
       
       if (role === 'Member' || role === 'Trainer') {
           if (memberId) {
               // Member and Trainer view - show only own memberships
               await renderMemberMemberships(container, memberId);
           } else {
               container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-text">Không tìm thấy thông tin member</div></div>';
           }
       } else {
           // Admin view - show all memberships
           await renderAllMemberships(container);
       }
   }
   ```
   
   **Files**: `wwwroot/js/memberships.js`
   
   **Verify**: Log in as Trainer, navigate to Gói tập, confirm it shows Member view (Gói Tập Có Sẵn section with package cards + Gói Tập Của Tôi section)

---

- [ ] **7. Verify cross-module consistency — Test all Trainer pages**
   
   **What**: Manual testing checklist for Trainer role
   
   **Test scenarios**:
   1. Log in as Trainer with an account that has a corresponding Member record (same email)
   2. Confirm navigation sidebar shows: Dashboard, Gói tập, Lịch Tập, Đăng ký Class, Lịch Tập Của Tôi, Check-in, Cá nhân
   3. Navigate to each page and confirm:
      - **Dashboard**: Shows Member stats (Buổi tập sắp tới, Trạng Thái Gói Tập, Số Ngày Còn Lại, Check-ins, Gói tập)
      - **Gói tập**: Shows available packages to purchase + personal memberships
      - **Lịch Tập**: Shows personal schedule preferences + registered classes
      - **Đăng ký Class**: Shows available classes to register + registered sessions with cancel button
      - **Lịch Tập Của Tôi**: Shows personal schedule preferences management (if `renderMemberSchedule()` exists in code)
      - **Check-in**: Shows personal check-in history + quick check-in button
      - **Cá nhân**: Shows profile (should work unchanged)
   4. Test one purchase flow: Buy a package as Trainer, confirm it creates membership
   5. Test one registration flow: Register for a class as Trainer, confirm it creates session
   6. Test one check-in flow: Click Check In button as Trainer, confirm it creates check-in record
   
   **Files**: All modified JS files
   
   **Verify**: Run through all test scenarios above. Success = Trainer behaves identically to Member across all pages. No errors in browser console (F12).

---

## Notes

- **Backend AuthService**: DO NOT TOUCH. The auto-create logic in `Service/BUS/Implementations/AuthService.cs` is backend-only and out of scope.
  
- **getTrainerId() function**: KEEP for now. It's used in Admin schedule creation flow (to select trainer from dropdown) and may be useful for future features. Does not affect Trainer-as-Member behavior since Trainer no longer calls trainer-specific render functions.

- **Unused functions**: `renderTrainerDashboard()`, `renderTrainerSessions()`, and related trainer-specific functions are NOT deleted. They remain in the codebase but are never called. This is intentional — they may be useful for reference or future restoration.

- **memberId requirement**: After this reset, Trainer role requires a valid `memberId` (from Members table) to function. If a Trainer account exists without a corresponding Member record, pages will show "Không tìm thấy thông tin member" error. This is expected behavior — the backend AuthService auto-creates Member records when needed, so this should not occur in production unless data integrity is broken.

- **Role symmetry**: After this plan, Trainer and Member frontend code paths are identical. The only difference is the role string in the JWT token, which may affect backend API permissions (not changed by this plan).

---

## Verification Commands

After each step, open the browser console (F12) and:

```javascript
// Check current role
getRole()  // Should return 'Trainer'

// Check memberId exists
getMemberId()  // Should return a number (e.g., 4, 5)

// Check user info
getUser()  // Should show email, userId, role
```

If `getMemberId()` returns `null`, the Trainer account does not have a corresponding Member record. Contact Admin to create one or use the backend AuthService auto-create flow (login triggers it).

---

## Build/Test Commands

This is a frontend-only change. No build step required for vanilla JavaScript.

**Test**:
1. Open browser to login page: `http://localhost:5000` (or your dev server port)
2. Log in as Trainer
3. Navigate through all pages and verify behavior matches Member

**Browser Console Check**:
```javascript
// After each navigation, check for errors
console.log('Current page:', currentPage);
console.log('Role:', getRole());
console.log('MemberId:', getMemberId());
```

No JavaScript errors should appear. All pages should render Member view.
