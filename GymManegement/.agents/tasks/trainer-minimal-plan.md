# Implementation Plan: Simplify Trainer Role

This plan simplifies the Trainer role to have ONLY 4 pages: dashboard, schedules, checkins, and profile. The trainer will be able to check in like a member and manage their own class schedules.

## Background

Based on user requirements (messages 1-12), the Trainer role needs to:
1. Check in just like a Member (using their memberId) and be visible in admin's check-in management
2. View all class schedules but only edit/delete schedules they created (where trainerId matches)
3. Create new class schedules with their trainerId auto-filled (no selection of other trainers)
4. Have only 4 pages accessible: dashboard, schedules, checkins, profile

Currently, Trainer has access to: dashboard, memberships, schedules, sessions, checkins, member-schedule, and profile. This needs to be reduced.

## Findings

**app.js:**
- Line 8: `allowedPagesByRole` object defines which pages each role can access
- Current Trainer pages: `['dashboard', 'memberships', 'schedules', 'sessions', 'checkins', 'member-schedule', 'profile']`

**dashboard.js:**
- Line 5-13: `renderDashboard()` function routes by role
- Line 8: Currently sends Trainer to `renderMemberDashboard()`
- Lines 275-406: `renderTrainerDashboard()` ALREADY EXISTS with trainer-specific stats
- Line 231: `getTrainerId()` helper ALREADY EXISTS - fetches trainerId by matching email from JWT with Trainer table

**checkins.js:**
- Line 190: `renderCheckins()` function routes by role
- Line 193-195: Already handles Trainer like Member - calls `renderMemberCheckins(container, memberId)` when `(role === 'Member' || role === 'Trainer') && memberId`
- This is already correct - no changes needed for check-in functionality

**schedules.js:**
- Line 270-325: `renderSchedules()` - Admin gets management view, Member/Trainer get personal schedule view
- Currently Trainer is grouped with Member and sees personal schedule preferences + registered classes view
- Need to change: Trainer should see full schedule list like Admin, but with restricted edit/delete permissions
- Line 408-440: `renderSchedulesTable()` - Renders schedule table with action buttons for canManage
- Line 442-465: `renderSchedulesPagination()` - Pagination controls
- Line 683-813: `showCreateScheduleModal()` - Creates modal for new schedule, already handles Trainer role with auto-filled trainerId at lines 696-700 and disabled dropdown
- Line 815-951: `showEditScheduleModal(scheduleId)` - Edit modal, already handles Trainer role with disabled trainer selection at lines 826-829
- Line 1056-1070: `deleteSchedule(scheduleId)` - Delete function with confirmation
- Need to add: Ownership checks in edit and delete for Trainer role

## Implementation Steps

- [ ] 1. Update allowed pages for Trainer role in app.js
      Remove 'memberships', 'sessions', 'member-schedule' from Trainer's allowed pages.
      Files: wwwroot/js/app.js (line 8)
      Verify: Log in as Trainer and confirm only 4 menu items appear: Dashboard, Lịch Class, Check-in, Cá nhân. Attempting to navigate to removed pages should redirect to dashboard with error.

- [ ] 2. Fix Trainer dashboard routing in dashboard.js
      Change line 8 to call `renderTrainerDashboard(container)` instead of `renderMemberDashboard(container)` when role === 'Trainer'.
      Files: wwwroot/js/dashboard.js (line 8)
      Verify: Log in as Trainer, go to Dashboard, confirm it shows trainer-specific stats (Class Hôm Nay, Học Viên Đã Attend, Check-in Hôm Nay, Lịch Dạy Hôm Nay table) instead of member stats.

- [ ] 3. Update renderSchedules to show full schedule list for Trainer
      Modify renderSchedules() function so Trainer sees the full schedule management view (like Admin) instead of the personal schedule view (like Member).
      Change condition at line 272 from `if (role === 'Member' || role === 'Trainer')` to `if (role === 'Member')`.
      Files: wwwroot/js/schedules.js (lines 270-325)
      Verify: Log in as Trainer, go to Lịch Class, confirm they see the full schedule table with filters (not personal schedule preferences + registered classes). The table should show all schedules from all trainers.

- [ ] 4. Add ownership-based edit/delete permissions in renderSchedulesTable
      Modify renderSchedulesTable() to show edit/delete buttons for Trainer only on schedules where `schedule.trainerId === currentTrainerId`. For schedules they don't own, show read-only text 'Chỉ xem'.
      - Line 408: Add `await getTrainerId()` call if role === 'Trainer' to get currentTrainerId
      - Line 410: Update canManage logic: `const canManage = role === 'Admin' || (role === 'Trainer' && ...)` 
      - Inside the table loop (around line 441), conditionally render action buttons or 'Chỉ xem' text based on ownership
      Files: wwwroot/js/schedules.js (lines 408-440)
      Verify: Log in as Trainer A who has created some schedules. Confirm they see edit/delete buttons ONLY on their own schedules. Other trainers' schedules show 'Chỉ xem' text instead of buttons. Clicking edit/delete on their own schedule should work.

- [ ] 5. Add ownership check in showEditScheduleModal for Trainer
      Before showing the edit modal, if role === 'Trainer', fetch the schedule and verify `schedule.trainerId === currentTrainerId`. If not, show error 'Bạn chỉ có thể sửa lịch tập do bạn tạo ra.' and return early.
      - After line 821 (the showLoading() call), add role check
      - If Trainer, call getTrainerId() before the Promise.all
      - After fetching schedule (line 823-828), add ownership verification for Trainer
      Files: wwwroot/js/schedules.js (lines 815-951)
      Verify: Log in as Trainer A, manually call showEditScheduleModal() with a scheduleId belonging to Trainer B (use browser console). Confirm error message appears and modal does not open. Calling with their own scheduleId should open the modal normally.

- [ ] 6. Add ownership check in deleteSchedule for Trainer
      Before deleting, if role === 'Trainer', fetch the schedule first and verify ownership. If `schedule.trainerId !== currentTrainerId`, show error 'Bạn chỉ có thể xóa lịch tập do bạn tạo ra.' and return early.
      - After the confirm() check at line 1060, add role === 'Trainer' check
      - If Trainer, fetch schedule and verify trainerId matches before proceeding with delete
      Files: wwwroot/js/schedules.js (lines 1056-1070)
      Verify: Log in as Trainer A, manually call deleteSchedule() with a scheduleId belonging to Trainer B (use browser console). Confirm error message appears and schedule is NOT deleted. Calling with their own scheduleId should show confirmation and delete successfully.

## Verification Commands

Since this is a frontend-only change with no build step:
- Open browser DevTools Console to check for JavaScript errors
- Test the application by logging in as different roles (Admin, Trainer, Member)
- Use browser's Network tab to verify API calls are made correctly
- Test user workflows:
  - Trainer login → check menu items (only 4)
  - Trainer dashboard → verify trainer-specific stats display
  - Trainer schedules → see all schedules, edit/delete only own schedules
  - Trainer check-in → perform check-in like a member
  - Admin check-in list → verify trainer check-ins appear

## Notes

- The `getTrainerId()` helper already exists in dashboard.js (line 231) and is already used in schedules.js for the create/edit modals
- Trainer check-in functionality is already correct - renders member check-in view with their memberId
- The `renderTrainerDashboard()` function already exists and is fully implemented with proper stats
- The create schedule modal already auto-fills and disables trainer selection for Trainer role
- Need to make schedules.js functions async or ensure getTrainerId() is properly awaited in ownership checks
