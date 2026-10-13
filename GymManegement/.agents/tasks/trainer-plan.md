# Trainer Frontend Implementation Plan

## Executive Summary

Build complete Trainer frontend that inherits ALL Member features AND adds session management (create/manage training sessions). This is a NEW feature not yet built for any role.

**Key Decision:** Trainer role already exists in backend with full CRUD and authorization. Session management APIs (Schedule, Session) exist and are functional. Frontend follows established SPA pattern with role-based routing in `app.js`.

---

## 1. Existing Patterns Discovered

### Frontend Architecture
- **SPA with hash-based routing**: `app.js` handles navigation via `window.location.hash`
- **Role-based access control**: `allowedPagesByRole` object defines which pages each role can access
- **Modular JS files**: Each feature has its own JS file (e.g., `members.js`, `sessions.js`)
- **No separate HTML pages**: Single `index.html` with dynamic content rendering via `renderXxx(container)` functions
- **Shared utilities**: `api.js` (API client with JWT), `auth.js` (login/logout/role checking), `dashboard.js` (role-specific dashboards)
- **CSS framework**: Single `style.css` with CSS variables and card-based UI

### Backend APIs Available
**Schedule Controller** (`/api/Schedule`):
- `GET /api/Schedule` - paginated list with search/sort
- `GET /api/Schedule/{id}` - single schedule
- `GET /api/Schedule/trainer/{trainerId}` - schedules by trainer
- `GET /api/Schedule/date/{date}` - schedules by date
- `POST /api/Schedule` - create (Admin, Trainer roles)
- `PUT /api/Schedule/{id}` - update (Admin, Trainer roles)
- `DELETE /api/Schedule/{id}` - delete (Admin only)

**Session Controller** (`/api/Session`):
- `GET /api/Session` - paginated list
- `GET /api/Session/{id}` - single session
- `GET /api/Session/schedule/{scheduleId}` - sessions by schedule
- `GET /api/Session/member/{memberId}` - sessions by member
- `POST /api/Session` - create (Admin, Trainer roles)
- `PUT /api/Session/{id}` - update (Admin, Trainer roles)
- `PUT /api/Session/{id}/status` - update status (Admin, Trainer roles)
- `DELETE /api/Session/{id}` - delete (Admin only)

**Services**: `ScheduleService.cs`, `SessionService.cs` - fully implemented

### Trainer-Specific Patterns
- **Trainer ID lookup**: `dashboard.js` has `getTrainerId()` function that fetches trainer info by matching JWT email against `/api/Trainer` list
- **Trainer dashboard**: Already implemented with stats (today's classes, monthly attended, today checkins) and today's schedule list
- **Authorization**: Backend enforces `[Authorize(Roles = "SuperAdmin,Admin,Trainer")]` for create/update operations

### Member Features to Inherit
From `app.js` allowedPagesByRole.Member:
- `dashboard` - member dashboard with stats
- `memberships` - view/manage membership packages
- `schedules` - view class schedules (calendar view)
- `sessions` - register for classes, view registered sessions
- `checkins` - view check-in history
- `member-schedule` - personal weekly schedule preferences
- `profile` - user profile management

---

## 2. Backend API Status

### ✅ Fully Implemented (No Changes Needed)
- Schedule CRUD endpoints
- Session CRUD endpoints with status management
- Trainer CRUD endpoints
- Authorization middleware with role checking
- All required services and repositories

### ❌ NOT Needed
- No new entities required
- No new controllers required
- No DTOs to create
- Backend is 100% ready for Trainer frontend

---

## 3. Implementation Plan

### Phase 1: Update Role-Based Access Control

- [ ] **1.1. Update `app.js` allowedPagesByRole for Trainer**
      
      **What**: Modify `allowedPagesByRole.Trainer` array to include all Member pages PLUS session management capabilities.
      
      **Current Trainer pages**: `['dashboard', 'schedules', 'sessions', 'checkins', 'profile']`
      
      **New Trainer pages**: `['dashboard', 'memberships', 'schedules', 'sessions', 'checkins', 'member-schedule', 'profile']`
      
      **Rationale**: Trainer inherits ALL Member features, so must have access to same pages. `memberships` and `member-schedule` are Member-only features that Trainer needs.
      
      **Files**: 
      - `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\app.js`
      
      **Verify**: 
      - Login as Trainer role
      - Confirm sidebar navigation shows: Dashboard, Gói tập, Lịch Class, Đăng ký Class, Check-in, Lịch Tập Của Tôi, Cá nhân
      - Navigate to each page and confirm no "Bạn không có quyền truy cập trang này" error

---

### Phase 2: Extend Existing JS Modules with Trainer-Specific Logic

- [ ] **2.1. Update `sessions.js` to enable session creation for Trainers**
      
      **What**: Modify `renderAllSessions()` function to show "➕ Tạo session" button for Trainer role (currently only Admin).
      
      **Current logic**: 
      ```javascript
      const canManage = role === 'Admin' || role === 'Trainer';
      ```
      Button render: 
      ```javascript
      ${canManage ? '<button class="btn btn-primary" onclick="showCreateSessionModal()">➕ Tạo session</button>' : ''}
      ```
      
      **Issue**: `showCreateSessionModal()` function exists but is incomplete (doesn't handle form submission properly based on truncated code).
      
      **Action**: 
      - Verify `showCreateSessionModal()` function is complete (read full file)
      - If incomplete, implement full modal with form validation
      - Ensure session creation calls `POST /api/Session` with `{scheduleId, memberId, status}`
      - Add success/error handling
      
      **Files**: 
      - `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\sessions.js`
      
      **Verify**: 
      - Login as Trainer
      - Navigate to "Đăng ký Class" page
      - Click "➕ Tạo session" button → modal appears
      - Fill form and submit → new session created
      - Run: Check browser console for no errors, verify session appears in table

- [ ] **2.2. Update `sessions.js` to filter sessions by Trainer's schedules (Trainer scope)**
      
      **What**: When Trainer views sessions, show ONLY sessions for schedules they created.
      
      **Current behavior**: `renderAllSessions()` shows ALL sessions regardless of trainer.
      
      **New behavior**: 
      1. Get trainerId via `getTrainerId()` from `dashboard.js`
      2. Fetch trainer's schedules: `GET /api/Schedule/trainer/{trainerId}`
      3. Extract scheduleIds from trainer's schedules
      4. Filter sessions table to show only sessions matching those scheduleIds
      
      **Implementation approach**:
      - Add new function `loadTrainerSessions()` in `sessions.js`
      - Modify `renderAllSessions()` to check role and call `loadTrainerSessions()` if Trainer
      - Keep Admin behavior unchanged (sees all sessions)
      
      **Files**: 
      - `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\sessions.js`
      
      **Verify**: 
      - Login as Trainer with known trainerId (e.g., trainerId=1)
      - Navigate to "Đăng ký Class"
      - Confirm sessions table shows ONLY sessions for schedules where trainer is the creator
      - Login as Admin → confirm still sees ALL sessions

- [ ] **2.3. Update `schedules.js` to enable schedule creation for Trainers**
      
      **What**: Read full `schedules.js` file (currently only read first 150 lines). Verify and complete schedule creation modal for Trainer role.
      
      **Expected**: Backend allows Trainer to `POST /api/Schedule` (confirmed in ScheduleController.cs line 39).
      
      **Action**:
      - Read full `schedules.js` file
      - Find `renderSchedules()` function
      - Verify "➕ Tạo schedule" button is shown for `role === 'Admin' || role === 'Trainer'`
      - Verify `showCreateScheduleModal()` function exists and is complete
      - Ensure form includes: className, trainerId (auto-fill with current trainer), facilityId, startTime, endTime, maxCapacity, dayOfWeek
      - Validate trainerId is correctly set to current user's trainerId (use `getTrainerId()`)
      
      **Files**: 
      - `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\schedules.js`
      
      **Verify**: 
      - Login as Trainer
      - Navigate to "Lịch Class"
      - Click "➕ Tạo schedule" → modal appears with trainerId pre-filled
      - Submit form → new schedule created
      - Verify via: `GET /api/Schedule/trainer/{trainerId}` returns new schedule

- [ ] **2.4. Update `schedules.js` to filter schedules by Trainer (Trainer scope)**
      
      **What**: When Trainer views schedules, show ONLY schedules they created.
      
      **Current behavior**: Likely shows ALL schedules.
      
      **New behavior**: 
      - Get trainerId via `getTrainerId()`
      - Fetch schedules using `GET /api/Schedule/trainer/{trainerId}` instead of `GET /api/Schedule`
      - Admin continues to see all schedules
      
      **Files**: 
      - `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\schedules.js`
      
      **Verify**: 
      - Login as Trainer with trainerId=1
      - Navigate to "Lịch Class"
      - Confirm table shows ONLY schedules where trainerId=1
      - Login as Admin → confirm sees ALL schedules

- [ ] **2.5. Update `dashboard.js` Trainer dashboard to add session stats**
      
      **What**: Enhance `renderTrainerDashboard()` with additional session-related statistics.
      
      **Current stats**: Today's classes count, monthly attended count, today checkins count.
      
      **New stats to add**:
      - "Sessions Pending Approval" - count of sessions with status='Registered' for trainer's schedules
      - "Sessions This Week" - count of sessions for trainer's schedules in current week
      
      **Files**: 
      - `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\dashboard.js`
      
      **Verify**: 
      - Login as Trainer
      - View dashboard
      - Confirm new stat cards appear with correct counts
      - Verify counts by manually checking via API endpoints

---

### Phase 3: Member Feature Inheritance (No Code Changes)

- [ ] **3.1. Verify Trainer can access Member features**
      
      **What**: Test that Trainer role can access all inherited Member features without modification.
      
      **Features to test**:
      - `memberships` page - view membership packages (read-only for Trainer)
      - `member-schedule` page - Trainer's personal weekly schedule preferences
      - `checkins` page - Trainer's check-in history
      - `profile` page - Trainer profile management
      
      **Files**: No changes needed, testing only.
      
      **Verify**: 
      - Login as Trainer
      - Navigate to "Gói tập" → page loads without errors
      - Navigate to "Lịch Tập Của Tôi" → page loads, can add/edit preferences
      - Navigate to "Check-in" → page loads, shows Trainer's check-ins
      - Navigate to "Cá nhân" → page loads, can edit profile
      - For each page, check browser console for errors

---

### Phase 4: Testing & Validation

- [ ] **4.1. Integration testing with real Trainer account**
      
      **What**: End-to-end testing with actual Trainer user from database.
      
      **Test scenarios**:
      1. **Login as Trainer** → redirects to dashboard
      2. **Create Schedule** → POST succeeds, schedule appears in list
      3. **View Sessions for Schedule** → only shows sessions for Trainer's schedules
      4. **Approve Member Registration** → update session status from 'Registered' to 'Attended'
      5. **Access Member Features** → memberships, member-schedule, checkins all work
      6. **Verify Authorization** → Trainer cannot access Admin-only pages (members, trainers, facilities, invoices, payments, reports, users)
      
      **Files**: No files modified, end-to-end testing.
      
      **Verify**: 
      - Complete all test scenarios successfully
      - No console errors
      - No authorization failures (403 errors)
      - Database confirms changes (check Schedules, Sessions tables)

- [ ] **4.2. Cross-role authorization testing**
      
      **What**: Verify role boundaries are enforced.
      
      **Test scenarios**:
      1. **Admin** → can still access ALL features including Trainer features
      2. **Member** → CANNOT access Trainer features (schedule creation, session approval)
      3. **Trainer** → CANNOT access Admin-only features (delete schedule, manage users)
      
      **Files**: No files modified, authorization testing.
      
      **Verify**: 
      - Login as Admin → navigate to "Đăng ký Class" → can create sessions and approve
      - Login as Member → sidebar does NOT show Admin/Trainer-only features
      - Login as Trainer → attempt to delete schedule → 403 error or disabled button

---

## 4. Files to Create

**None.** All implementation is modification of existing files.

---

## 5. Files to Modify

1. `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\app.js` - update Trainer's allowed pages
2. `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\sessions.js` - add Trainer session management
3. `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\schedules.js` - add Trainer schedule management
4. `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\dashboard.js` - enhance Trainer dashboard stats

---

## 6. Build & Test Commands

### Build
```bash
# ASP.NET Core app (backend)
cd "d:\Workspace\Độ án 2\GymManegement\GymManegement"
dotnet build
```

### Run
```bash
# Start development server
dotnet run
# Access at: http://localhost:5250
```

### Verification
1. **Browser**: Open `http://localhost:5250/index.html`
2. **Login**: Use Trainer credentials from database
3. **Console**: Check browser DevTools console for errors
4. **Network**: Monitor API calls in Network tab
5. **Database**: Verify changes in `Schedules` and `Sessions` tables

---

## 7. Risks & Blockers

### Risks
1. **Incomplete functions in sessions.js** - The file was truncated at line 763. `showCreateSessionModal()` and `submitSessionRegistration()` may be incomplete. **Mitigation**: Read full file and complete functions if needed.

2. **TrainerId lookup dependency** - `getTrainerId()` in dashboard.js fetches all trainers and matches by email. If trainer email doesn't match JWT email, lookup fails. **Mitigation**: Add error handling and logging to `getTrainerId()`.

3. **Session approval workflow unclear** - Task description says "trainer hoặc admin sẽ duyệt member đó" but current Session API only has status update. Need to confirm status flow: Registered → Attended/Cancelled. **Mitigation**: Document status workflow and ensure UI reflects it.

### Blockers
**None.** All backend APIs exist and are functional. Frontend patterns are well-established.

---

## 8. Future Enhancements (Out of Scope)

1. **Real-time notifications** - Notify trainer when member registers for their class
2. **Session capacity management** - Warn when session registrations exceed schedule maxCapacity
3. **Trainer schedule conflict detection** - Prevent creating overlapping schedules
4. **Bulk session approval** - Allow trainer to approve multiple registrations at once
5. **Session attendance QR code** - Generate QR code for quick check-in at session time

---

## 9. Implementation Order Summary

1. Update role-based access (app.js) - **Foundation**
2. Session management (sessions.js) - **Core Feature**
3. Schedule management (schedules.js) - **Core Feature**
4. Dashboard enhancements (dashboard.js) - **Polish**
5. Member feature verification - **Testing**
6. Integration & authorization testing - **Validation**

**Estimated effort**: 4-6 hours for implementation + 2 hours testing

---

**Plan completed on**: 2024-01-09  
**Ready for implementation**: ✅ Yes
