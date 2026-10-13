# Trainer schedule filtering and access control

Trainers now see only the schedules they created. The "Đăng ký Class" (sessions) page was removed from Trainer navigation, and schedule create/edit forms prevent trainers from assigning schedules to other trainers. The filtering uses the existing `/api/Schedule/trainer/{trainerId}` endpoint and branches on role in four places: list loading, date filtering, create modal, and edit modal.

**Watch for:** Edit modal fetches currentTrainerId but never uses it — dead code (confirmed). Date filtering is client-side for Trainer but server-side for Admin, creating maintenance asymmetry (likely). Role checks repeated in five functions without a helper (likely).

**Verdict**: NEEDS_CHANGES

## High-level view

The sessions page was removed from Trainer role in `allowedPagesByRole`, so trainers no longer see "Đăng ký Class" in their sidebar. This is a simple array edit and works as intended.

Schedule list and date filter now branch on role. Trainers call `/api/Schedule/trainer/{trainerId}` instead of the paginated all-schedules endpoint. The date filter fetches all trainer schedules and filters client-side, which is a mismatch with Admin's server-side date filtering but acceptable for the scale of data a single trainer owns.

Create and edit modals disable the trainer dropdown for Trainer role, pre-fill it with the current trainer, and use a hidden input to carry the trainerId through form submission. This prevents trainers from assigning schedules to other trainers. Validation skips the disabled dropdown for Trainer role since disabled selects have no value. The edit modal fetches `currentTrainerId` but never uses it — the hidden input carries `schedule.trainerId` instead, making the fetch dead code.

<details>
<summary>Issues (3)</summary>

1. **Edit modal fetches unused currentTrainerId** — `showEditScheduleModal` fetches `currentTrainerId` via `getTrainerId()` for Trainer role but never uses it. The hidden input carries `schedule.trainerId` (the trainer already assigned to the schedule) instead of `currentTrainerId`. This is dead code. Remove the fetch or use `currentTrainerId` to validate that the current trainer owns the schedule before allowing edits.

2. **Date filter client-side for Trainer, server-side for Admin** — `loadSchedulesByDate` fetches all trainer schedules and filters by date in JavaScript, while Admin calls `/api/Schedule/date/{date}` which filters server-side. This asymmetry is functional but creates maintenance risk: changes to date filtering logic must be mirrored in two places. Consider adding a `/api/Schedule/trainer/{trainerId}/date/{date}` endpoint to keep filtering server-side for both roles.

3. **Role check pattern repeated in five functions** — `getRole() === 'Trainer'` appears in `loadSchedules`, `loadSchedulesByDate`, `showCreateScheduleModal`, `showEditScheduleModal`, and `validateScheduleForm`. If role names change or new roles need schedule filtering (e.g., Admin with limited scope), all five call sites must be updated. Extract a helper: `function shouldFilterByTrainer() { return getRole() === 'Trainer'; }` and use it consistently.

</details>

<details>
<summary>Details</summary>

## Sessions page removed from Trainer navigation

The `allowedPagesByRole` map in `app.js` removed `'sessions'` from Trainer:

```javascript
'Trainer': ['dashboard', 'schedules', 'checkins', 'profile']
```

## Schedule list filtered by trainer

`loadSchedules()` branches on role:

```javascript
if (role === 'Trainer') {
    const trainerId = await getTrainerId();
    if (!trainerId) {
        hideLoading();
        showError('Không tìm thấy thông tin trainer');
        return;
    }
    const items = await apiFetch(`/api/Schedule/trainer/${trainerId}`);
    data = { items: items, pageNumber: 1, totalPages: 1 };
} else {
    data = await apiFetch(`/api/Schedule?pageNumber=${schedulesCurrentPage}&pageSize=${schedulesPageSize}`);
}
```

For Trainer role, it calls `getTrainerId()`, validates the result, fetches from `/api/Schedule/trainer/{trainerId}`, and wraps the response in a pagination structure since the backend returns `IEnumerable<ScheduleResponse>` instead of a paginated response.

## Date filter branches on role

`loadSchedulesByDate()` also branches:

```javascript
if (role === 'Trainer') {
    const trainerId = await getTrainerId();
    if (!trainerId) {
        hideLoading();
        showError('Không tìm thấy thông tin trainer');
        return;
    }
    const allItems = await apiFetch(`/api/Schedule/trainer/${trainerId}`);
    items = allItems.filter(s => {
        const d = new Date(s.startTime);
        return d.toISOString().startsWith(date);
    });
} else {
    items = await apiFetch(`/api/Schedule/date/${date}`);
}
```

Trainer role fetches all schedules for the trainer and filters by date in JavaScript. Admin role calls `/api/Schedule/date/{date}` which filters server-side. Date filtering logic lives in two places: if date format changes or time-zone handling needs adjustment, both the client-side filter and the backend endpoint must be updated.

## Create modal disables trainer dropdown for Trainer role

`showCreateScheduleModal()` fetches trainers and facilities, then checks role:

```javascript
const role = getRole();
let currentTrainerId = null;
if (role === 'Trainer') {
    currentTrainerId = await getTrainerId();
    if (!currentTrainerId) {
        hideLoading();
        showError('Không tìm thấy thông tin trainer');
        return;
    }
}
```

The modal HTML conditionally disables the trainer dropdown and adds a hidden input. Form submission reads from the hidden input for Trainer, the dropdown for Admin. Disabled selects don't submit their values, so the hidden input carries the trainerId.

## Edit modal fetches unused currentTrainerId

`showEditScheduleModal()` fetches `currentTrainerId` for Trainer role but never uses it:

```javascript
const role = getRole();
let currentTrainerId = null;
if (role === 'Trainer') {
    currentTrainerId = await getTrainerId();
}
```

The hidden input uses `schedule.trainerId`, not `currentTrainerId`:

```javascript
${role === 'Trainer' ? `<input type="hidden" id="editTrainerIdHidden" value="${schedule.trainerId}">` : ''}
```

The variable is dead code. The edit modal doesn't validate that the current user is the trainer who created the schedule — it just disables the dropdown to prevent changing the assignment. A Trainer could open the edit modal for any schedule in their filtered list, and the modal trusts that the list was filtered correctly. If the backend doesn't validate trainer ownership on PUT, a Trainer could craft a request to edit another trainer's schedule (**possible** — depends on backend authorization).

## Validation skips trainer dropdown for Trainer role

`validateScheduleForm()` skips the trainer dropdown validation when role is Trainer since disabled selects have no value:

```javascript
if (getRole() !== 'Trainer') {
    if (!trainerId.value) {
        document.getElementById(prefix + 'trainerIdError').textContent = 'Vui lòng chọn HLV';
        trainerId.classList.add('invalid');
        isValid = false;
    }
}
```

</details>

<details>
<summary>File map</summary>

- `wwwroot/js/app.js` — removed 'sessions' from Trainer allowedPagesByRole
- `wwwroot/js/schedules.js` — added role-based branching in loadSchedules, loadSchedulesByDate, showCreateScheduleModal, showEditScheduleModal, validateScheduleForm

Full diff: `.agents/tasks/trainer-schedules-fix-summary.md`

</details>
