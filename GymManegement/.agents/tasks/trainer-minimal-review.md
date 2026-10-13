# Trainer Minimal Permissions Review

Trainer role restrictions to dashboard, schedules, checkins, and profile only.

**User requirement**: Simplify trainer functionality to core needs: check-in like a member (visible to admin), create/view/edit own schedules only, access dashboard and profile. Remove memberships, sessions, and member-schedule pages.

**Watch for**: Goal 4 (MEDIUM) - schedules.js getTrainerId() helper defined in dashboard.js not schedules.js, creating cross-module dependency.

**Verdict**: APPROVED

## High-level view

The Trainer allowedPages array in app.js correctly contains only ['dashboard', 'schedules', 'checkins', 'profile'], excluding 'sessions', 'memberships', and 'member-schedule' as required. The dashboard routing correctly calls renderTrainerDashboard() for Trainer role. The checkins module correctly treats Trainer like Member when memberId exists, reusing renderMemberCheckins() and the quickCheckin() button. The schedules module provides full list view to Trainer with ownership-based edit restrictions and auto-fills trainer field in create/edit modals, but the required getTrainerId() helper is defined in dashboard.js instead of schedules.js, creating a hidden cross-module dependency that will break if dashboard.js is not loaded first or is refactored.

<details>
<summary>Issues (1)</summary>

1. **getTrainerId() defined in wrong module** — Move getTrainerId() and clearTrainerIdCache() from dashboard.js to schedules.js or a shared utility module. Schedules.js calls getTrainerId() but doesn't define it, creating a cross-module dependency. Currently works because dashboard.js loads before schedules.js in index.html, but fragile to refactoring. (LOW - architectural concern, no functional impact)

</details>

<details>
<summary>Details</summary>

## Trainer route restriction includes unwanted 'sessions' page

app.js defines allowedPagesByRole with this Trainer entry:

```javascript
'Trainer': ['dashboard', 'schedules', 'checkins', 'profile'],
```

Confirmed: The current code matches the goal. Trainer has exactly the four specified pages, not including 'sessions', 'memberships', or 'member-schedule'.

**Update**: Re-reading the file content from the tool output, the Trainer line is:

```javascript
'Trainer': ['dashboard', 'schedules', 'checkins', 'profile'],
```

This is correct per Goal 1. However, based on the user's message history, there were issues with 'sessions' being present. Let me verify by checking the actual file content again from what was read.

Looking at the read output for app.js:

```javascript
const allowedPagesByRole = {
    'Admin': ['dashboard', 'members', 'memberships', 'trainers', 'facilities', 'schedules', 'checkins', 'invoices', 'payments', 'reports', 'users', 'profile'],
    'Trainer': ['dashboard', 'schedules', 'checkins', 'profile'],
    'Member': ['dashboard', 'memberships', 'schedules', 'sessions', 'checkins', 'member-schedule', 'profile']
};
```

This is **correct** — Trainer does NOT have 'sessions', 'memberships', or 'member-schedule'. Goal 1 is satisfied.

## Dashboard routing for Trainer role

dashboard.js renderDashboard() contains:

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

The function correctly routes Trainer to renderTrainerDashboard(), not renderMemberDashboard(). Goal 2 is satisfied.

## Checkins treating Trainer like Member

checkins.js renderCheckins() logic:

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

The condition `(role === 'Member' || role === 'Trainer') && memberId` correctly treats Trainer the same as Member when memberId exists. The renderMemberCheckins() function displays check-in history with a "✅ Check In" button powered by quickCheckin(), which performs the same validation and API call for both roles. Goal 3 is satisfied.

## Schedules ownership-based restrictions for Trainer

schedules.js implements several ownership checks:

**Table rendering**: The renderSchedulesTable() function calls getTrainerId() when role is Trainer, then renders action buttons conditionally:

```javascript
// Check if Trainer can edit this schedule (ownership check)
const canEdit = role === 'Admin' || (role === 'Trainer' && schedule.trainerId === currentTrainerId);

// Later in the table row:
${showActionsColumn ? `
    <td>
        ${canEdit ? `
            <div class="action-buttons">
                <button class="btn btn-sm btn-info" onclick="showEditScheduleModal(${schedule.scheduleId})">✏️</button>
                <button class="btn btn-sm btn-danger" onclick="deleteSchedule(${schedule.scheduleId})">🗑️</button>
            </div>
        ` : `
            <span style="color: #999; font-size: 0.9em;">Chỉ xem</span>
        `}
    </td>
` : ''}
```

Admin can edit all schedules. Trainer can only edit schedules where `schedule.trainerId === currentTrainerId`. Others show "Chỉ xem". This satisfies the requirement.

**Create modal**: showCreateScheduleModal() auto-fills and disables the trainer field for Trainer role:

```javascript
<select id="trainerId" name="trainerId" ${role === 'Trainer' ? 'disabled style="background:#f5f5f5;cursor:not-allowed;"' : ''} required>
    <option value="">-- Chọn HLV --</option>
    ${trainers.map(t => `<option value="${t.trainerId}" ${role === 'Trainer' && t.trainerId === currentTrainerId ? 'selected' : ''}>${escapeHtml(t.fullName)}</option>`).join('')}
</select>
${role === 'Trainer' ? `<input type="hidden" id="trainerIdHidden" value="${currentTrainerId}">` : ''}
```

For Trainer, the dropdown is disabled and pre-selected with currentTrainerId, and a hidden input holds the value for form submission. Admin can select any trainer.

**Edit modal**: showEditScheduleModal() performs an ownership check before allowing edit:

```javascript
// Ownership check for Trainer role
if (role === 'Trainer' && schedule.trainerId !== currentTrainerId) {
    showError('Bạn chỉ có thể sửa lịch tập do bạn tạo ra.');
    return;
}
```

The modal also disables the trainer dropdown for Trainer role, same as create.

**Delete function**: deleteSchedule() performs ownership check:

```javascript
// Ownership check for Trainer role
const role = getRole();
if (role === 'Trainer') {
    const currentTrainerId = await getTrainerId();
    if (!currentTrainerId) {
        hideLoading();
        showError('Không tìm thấy thông tin trainer');
        return;
    }
    
    // Fetch the schedule to check ownership
    const schedule = await apiFetch(`/api/Schedule/${scheduleId}`);
    if (schedule.trainerId !== currentTrainerId) {
        hideLoading();
        showError('Bạn chỉ có thể xóa lịch tập do bạn tạo ra.');
        return;
    }
}
```

Trainer can only delete their own schedules. These implementations satisfy Goal 4's requirements for ownership-based restrictions.

## getTrainerId() helper location creates cross-module dependency

Goal 4 requires a getTrainerId() helper to exist and work correctly. The helper is defined in dashboard.js:

```javascript
// Cached trainerId to avoid repeated lookups
let _cachedTrainerId = null;

function clearTrainerIdCache() {
    _cachedTrainerId = null;
    console.log('[clearTrainerIdCache] Cache cleared');
}

async function getTrainerId() {
    if (_cachedTrainerId !== null) {
        return _cachedTrainerId;
    }
    
    try {
        const user = getUser();
        if (!user || !user.email) {
            console.error('[getTrainerId] FAILED: No user email found in JWT token');
            return null;
        }
        
        const userEmail = user.email.trim().toLowerCase();
        
        const result = await apiFetch('/api/Trainer?pageNumber=1&pageSize=1000');
        console.log('[getTrainerId] API Response:', result);
        
        const trainers = result?.data || result?.Data || [];
        console.log(`[getTrainerId] Searching for email "${userEmail}" in ${trainers.length} trainers`);
        
        const trainer = trainers.find(t => {
            const trainerEmail = t.email || t.Email;
            if (!trainerEmail) return false;
            return trainerEmail.trim().toLowerCase() === userEmail;
        });
        
        if (trainer) {
            _cachedTrainerId = trainer.trainerId || trainer.TrainerId;
            console.log(`[getTrainerId] SUCCESS: Found trainerId ${_cachedTrainerId} for email ${userEmail}`);
            return _cachedTrainerId;
        }
        
        console.error(`[getTrainerId] FAILED: No trainer found with email "${userEmail}". Available emails: ${trainers.map(t => t.email || t.Email).filter(e => e).join(', ')}`);
        return null;
    } catch (error) {
        console.error('[getTrainerId] FAILED: API error:', error);
        return null;
    }
}
```

The function works correctly: it fetches all trainers, matches by email from the JWT token, caches the result, and returns the trainerId. The logic is sound.

However, schedules.js calls getTrainerId() in multiple places (renderSchedulesTable, showCreateScheduleModal, showEditScheduleModal, deleteSchedule) but does not define it. This creates a cross-module dependency: schedules.js relies on dashboard.js defining getTrainerId() globally. The current setup works because index.html loads dashboard.js before schedules.js, making the function available. If the load order changes, or if dashboard.js is refactored to remove the function, or if modules are converted to ES6 modules with explicit imports, the calls will fail with "getTrainerId is not defined".

The function should be in schedules.js (since schedules.js is the primary consumer) or in a shared utility module like auth.js. Placing it in dashboard.js works but violates separation of concerns. This is an architectural concern with no current functional impact.

## No regressions for Admin or Member roles

Admin role allowedPages includes all pages as before. Member role includes dashboard, memberships, schedules, sessions, checkins, member-schedule, and profile. The checkins.js conditional `(role === 'Member' || role === 'Trainer') && memberId` treats Member as before. The schedules.js conditional logic uses `role === 'Admin'` and `role === 'Trainer'` checks, leaving Member's behavior untouched (Member sees the personal schedules + registered classes view via the `if (role === 'Member')` branch in renderSchedules()). Goal 5 is satisfied.

</details>

## File map

<details>
<summary>Changed files</summary>

- **app.js** — Role-based page access control and routing logic. Trainer allowedPages array correctly limited to ['dashboard', 'schedules', 'checkins', 'profile'].
- **dashboard.js** — Dashboard rendering by role. Correctly routes Trainer to renderTrainerDashboard(). Defines getTrainerId() helper (should be in schedules.js).
- **checkins.js** — Check-in management. Correctly treats Trainer like Member when memberId exists, using renderMemberCheckins().
- **schedules.js** — Schedule management with ownership-based restrictions. Trainer sees full list, can only edit/delete own schedules, trainer field auto-filled in modals. Calls getTrainerId() but doesn't define it.

</details>
