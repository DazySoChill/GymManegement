# DTO time format alignment and dashboard enhancements

This change fixes validation errors when members create workout schedules, eliminates null reference errors during check-in rendering, and adds a "next workout" card to the member dashboard. The approach converts time properties from `TimeSpan` to `string` in the DTOs to match what the frontend sends, adds parsing and validation logic in the service layer, and implements client-side logic to calculate the next upcoming workout from schedule preferences.

**Watch for:** Frontend sends times as "HH:MM" but backend expects "HH:MM:SS" (likely), misalignment between checkins.js null guards vs member-schedule.js error location (confirmed), dashboard next-workout logic treats same-day past workouts as 7 days away which may confuse users expecting it to advance to the next day (confirmed).

**Verdict**: NEEDS_CHANGES

## High-level view

The DTO time fields now accept strings and the service layer parses them into `TimeSpan` values before database storage, validating format and enforcing that end times follow start times. The check-in error was addressed by adding null guards to two rendering functions in checkins.js, though the original error message referenced member-schedule.js which has no such operations. The dashboard fetches all member schedule preferences and walks through them to find the soonest workout, displaying day name and time range, but resets same-day schedules to next week if their time has passed rather than checking the next actual day.

<details>
<summary>Issues (3)</summary>

1. **Time format mismatch** — Frontend sends "HH:MM" from `<input type="time">`, backend expects "HH:MM:SS". Add `:00` in JavaScript before sending or handle both formats in TryParse.
2. **Null guard location mismatch** — Error message said member-schedule.js but guards were added to checkins.js. Verify the actual error source.
3. **Next workout same-day logic** — Same-day past workouts treated as 7 days away instead of checking tomorrow. Adjust calculation to roll forward correctly.

</details>

<details>
<summary>Details</summary>

## DTO string conversion with service-layer parsing

`CreateMemberScheduleRequest` and `UpdateMemberScheduleRequest` now define `StartTime` and `EndTime` as `string` with comments indicating `"HH:MM:SS"` format. `MemberSchedulePreferenceService.CreateAsync` and `UpdateAsync` call `TimeSpan.TryParse()` on these strings and throw `ArgumentException` if parsing fails. After successful parse, the methods validate that `endTime > startTime` and then assign the parsed `TimeSpan` values to the entity properties before persisting.

The frontend form in member-schedule.js appends `:00` to the time inputs before sending:

```javascript
startTime: startTime + ':00',
endTime: endTime + ':00'
```

**Likely concern:** The frontend depends on this concatenation in one specific form handler. If the concatenation is removed or the input value is malformed (direct API call, form manipulation), `TimeSpan.TryParse` will fail and return a generic "Định dạng giờ bắt đầu không hợp lệ" message. The frontend validation (`startTime >= endTime`) prevents some cases but doesn't check format structure.

## Null guards in checkins.js

Two functions in checkins.js now include early-return guards:

```javascript
function renderMemberCheckinsTable(checkins) {
    const container = document.getElementById('myCheckinsContainer');
    if (!container) return;
    // ...
}

async function renderCheckinsTable(data, countsMap = {}) {
    const container = document.getElementById('checkinsTableContainer');
    if (!container) return;
    // ...
}
```

The original error message reported by the user was "Lỗi tải danh sách check-in: Cannot set properties of null (setting 'innerHTML')" which suggests `loadSchedules` or a similar function in member-schedule.js. The result summary states the delete button was already present in member-schedule.js and these guards were added to checkins.js. **Confirmed mismatch:** The user's error message does not align with the file that was modified. Either the error originated from a different code path that also calls `innerHTML` on a missing container, or the diagnosis was incorrect. member-schedule.js has a `loadSchedules` function that sets `listContainer.innerHTML` multiple times but includes no null guard at the top.

## Dashboard next-workout calculation

dashboard.js defines three helper functions at file scope: `parseTimeToMinutes` (converts "HH:MM:SS" to total minutes), `formatTimeSpan` (returns "HH:MM" display format), and `loadNextWorkout` (fetches member schedules and calculates next upcoming workout).

The calculation logic:

```javascript
const currentDay = now.getDay(); // 0-6
const currentTime = now.getHours() * 60 + now.getMinutes();

activeSchedules.forEach(function(schedule) {
    const scheduleDay = schedule.dayOfWeek;
    const scheduleTime = parseTimeToMinutes(schedule.startTime);
    let daysUntil = scheduleDay - currentDay;
    if (daysUntil < 0) daysUntil += 7;
    if (daysUntil === 0 && scheduleTime < currentTime) daysUntil = 7;
    // ...
});
```

If the workout is today but the start time has passed, `daysUntil` is set to 7 (next week same day) rather than recalculating from the next day forward. **Confirmed gap:** If a user has a Monday 9am workout and a Tuesday 10am workout, and it's Monday 10am (past the Monday workout), the logic will report "Thứ Hai 09:00 - 11:00" as 7 days away instead of advancing to Tuesday's workout 24 hours away. The intent was likely to show the next occurrence of that specific schedule, but the UI label "Buổi tập sắp tới" (next workout session) implies the soonest upcoming workout across all schedules, not the next occurrence of today's schedule.



## Verification checklist results

1. DTOs use `string` for StartTime/EndTime — **confirmed**
2. Service parses strings to TimeSpan — **confirmed** with TryParse and validation
3. Delete button present and deleteSchedule is top-level — **confirmed**
4. Null guard on innerHTML in member-schedule.js — **not present**. Null guards were added to checkins.js instead. member-schedule.js loadSchedules function (line 75) sets `listContainer.innerHTML` without checking if `listContainer` is null first.
5. loadNextWorkout exists and is called — **confirmed**
6. No regressions — no database schema changes mentioned.

</details>

<details>
<summary>File map</summary>

- `API/DTOs/MemberSchedule/CreateMemberScheduleRequest.cs` — Changed StartTime and EndTime from TimeSpan to string with format comment
- `API/DTOs/MemberSchedule/UpdateMemberScheduleRequest.cs` — Changed StartTime and EndTime from TimeSpan to string with format comment
- `Service/BUS/Implementations/MemberSchedulePreferenceService.cs` — Added TryParse logic and validation for time strings in CreateAsync and UpdateAsync
- `wwwroot/js/member-schedule.js` — Appends `:00` to time inputs, renders delete button, calls deleteSchedule function
- `wwwroot/js/checkins.js` — Added null container guards in renderMemberCheckinsTable and renderCheckinsTable
- `wwwroot/js/dashboard.js` — Added parseTimeToMinutes, formatTimeSpan, loadNextWorkout functions and next workout stat card

[Full diff at: .agents/tasks/fix-schedule-dashboard-result.md]

</details>
