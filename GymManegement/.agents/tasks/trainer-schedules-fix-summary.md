# Trainer Schedules Fix Summary

## Changes Made

### 1. app.js - Removed 'sessions' page from Trainer navigation
- **File**: `wwwroot/js/app.js`
- **Change**: Removed 'sessions' from the Trainer allowed pages array
- **Before**: `'Trainer': ['dashboard', 'schedules', 'sessions', 'checkins', 'profile']`
- **After**: `'Trainer': ['dashboard', 'schedules', 'checkins', 'profile']`
- **Impact**: Trainers no longer see "Đăng ký Class" in their navigation menu

### 2. schedules.js - Filter schedules by trainer
- **File**: `wwwroot/js/schedules.js`
- **Changes**:

#### a. Updated `loadSchedules()` function
- Added role detection: `const role = getRole()`
- For Trainer role:
  - Fetches trainerId using `await getTrainerId()` (function exists in dashboard.js)
  - Calls `/api/Schedule/trainer/{trainerId}` endpoint (confirmed to exist in ScheduleController.cs)
  - Backend returns `IEnumerable<ScheduleResponse>` (not paginated)
  - Wraps result in pagination structure for frontend compatibility
- For Admin role: Uses existing paginated endpoint

#### b. Updated `loadSchedulesByDate()` function
- Added role detection
- For Trainer role:
  - Fetches all trainer's schedules
  - Filters by date client-side
- For Admin role: Uses existing date endpoint

#### c. Updated `showCreateScheduleModal()` function
- Added role detection and `getTrainerId()` call
- For Trainer role:
  - Trainer dropdown is disabled and pre-filled with current trainer
  - Added hidden input to store trainerId
  - Form submit reads trainerId from hidden input instead of disabled select
- For Admin role: Dropdown works normally

#### d. Updated `showEditScheduleModal()` function
- Added role detection and `getTrainerId()` call
- For Trainer role:
  - Trainer dropdown is disabled (cannot change trainer assignment)
  - Added hidden input to preserve trainerId
  - Form submit reads trainerId from hidden input
- For Admin role: Dropdown is editable

#### e. Updated `validateScheduleForm()` function
- Added role check: `if (getRole() !== 'Trainer')`
- For Trainer role: Skips validation of disabled trainer dropdown (trainerId comes from hidden input)
- For Admin role: Validates trainer dropdown as before

## Backend Verification

### API Endpoint Confirmed
- **Endpoint**: `GET /api/Schedule/trainer/{trainerId}`
- **Controller**: `ScheduleController.cs`
- **Service Method**: `GetByTrainerIdAsync(int trainerId)`
- **Return Type**: `IEnumerable<ScheduleResponse>` (array, not paginated)
- **Authorization**: `[Authorize]` (all authenticated users can access)

### Helper Function
- **Function**: `getTrainerId()`
- **Location**: `dashboard.js`
- **Type**: `async function`
- **Implementation**: 
  - Caches trainerId after first fetch
  - Fetches all trainers via `/api/Trainer?pageNumber=1&pageSize=1000`
  - Finds trainer by email (from JWT token user info)
  - Returns trainerId or null

## User Experience Changes

### For Trainer Role:
1. **Navigation**: "Đăng ký Class" (sessions) page removed from sidebar
2. **Schedule List**: Only shows schedules created by that trainer
3. **Create Schedule**: 
   - Trainer dropdown is disabled and auto-filled with current trainer
   - Cannot assign schedule to another trainer
4. **Edit Schedule**: 
   - Can only edit schedules they created (filtered in list)
   - Trainer assignment cannot be changed
5. **Date Filter**: Works correctly with trainer-filtered schedules

### For Admin Role:
- No changes - all existing functionality preserved
- Can see and manage all schedules from all trainers
- Full control over trainer assignment in create/edit modals

## Testing Recommendations

1. **Login as Trainer** and verify:
   - "Đăng ký Class" is not in navigation
   - Schedule list shows only own schedules
   - Create schedule has pre-filled, disabled trainer dropdown
   - Edit schedule maintains trainer assignment
   - Date filter works with filtered schedules

2. **Login as Admin** and verify:
   - All schedules visible
   - Can assign any trainer when creating
   - Can change trainer when editing

## Notes

- All changes are client-side only (no backend modifications needed)
- Backend endpoint `/api/Schedule/trainer/{trainerId}` already existed
- The `getTrainerId()` function already existed in `dashboard.js`
- No database migrations or service changes required
- Trainer filtering is consistent with existing patterns for sessions and checkins
