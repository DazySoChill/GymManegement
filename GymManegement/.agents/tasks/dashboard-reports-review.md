# Dashboard and Reports API Field Alignment

Dashboard and reports pages now use camelCase field access with defensive PascalCase fallbacks for API responses. The active members count uses the dedicated report endpoint, and facilities filter to "Available" status only.

**Watch for:** Active members API endpoint relies on backend data quality (confirmed); revenue detail response format may return invoice list rather than daily aggregation (likely); expiring memberships assumes Member navigation property is included in API response (possible).

**Verdict**: APPROVED

## High-level view

Active members now calls `/api/Report/active-members` instead of paginating all members, which matches the report requirement and backend implementation. Monthly revenue, checkin counts, and facilities all use defensive field access with both camelCase and PascalCase fallbacks to handle backend serialization variations. Facilities filter client-side to count only "Available" status, matching the database schema where active facilities are marked "Available" not "Active". Trainer dashboard matches trainers by email since JWT tokens don't include trainerId, requiring a lookup against the trainers list each session.

Revenue details and expiring memberships unwrap response objects expecting `{ data: [...] }` wrappers. Revenue supports both aggregated (date/count/totalAmount) and invoice (invoiceDate/totalAmount) formats since backend SQL suggests invoice details. Expiring memberships navigates nested Member objects for fullName. Members report changed from table to stats cards because backend returns a summary object, not a member list.

Console logging covers every major API call for debugging. Error messages display in containers rather than alerts, keeping the UI context intact when APIs fail.

<details>
<summary>Issues (6)</summary>

1. **Revenue detail format mismatch** — Backend may return invoice list, not daily aggregation. Frontend handles both but displays "count" column with "-" for invoice format. Verify backend returns aggregated data or remove count column.

2. **Member navigation property assumption** — Expiring memberships reads `item.member.fullName`, assuming backend includes Member navigation. If not included, names show as "-". Verify backend includes Member or flatten the response.

3. **Session endpoint response inconsistency** — `loadTrainerMonthlyAttended` checks both array and wrapped formats for session responses. Backend should return consistent format. Verify `/api/Session/schedule/{id}` returns unwrapped array or always wrapped.

4. **Trainer lookup inefficiency** — Trainer dashboard fetches all 1000 trainers to match email on every render (cached per session). If trainer count grows, consider backend endpoint `/api/Trainer/by-email/{email}` to avoid bulk fetch.

5. **Client-side filtering at scale** — Dashboard fetches up to 1000 records (payments, checkins, facilities, schedules) and filters client-side. For large gyms, this becomes slow. Consider backend query params (e.g., `?fromDate=2026-10-01&toDate=2026-10-31`) or report endpoints.

6. **Hardcoded page size limits** — Multiple endpoints use `pageSize=1000` assuming small datasets. If member count exceeds 1000, pagination breaks. Backend should support date/status filters or dedicated aggregate endpoints.

</details>

<details>
<summary>Details</summary>

## Active members endpoint migration

`loadActiveMembersCount()` switched from `/api/Member?pageNumber=1&pageSize=1` (which returned total count of all members via `result.Total`) to `/api/Report/active-members`, which returns a plain number counting only active members, not deleted ones. The new endpoint is used in both dashboard.js and reports.js.

The API returns a bare number, not wrapped, so the code checks `count || 0` directly.

## Defensive field access pattern

Every PagedResult unwrapping uses `result?.data || result?.Data || []` to handle both camelCase (expected) and PascalCase (legacy) serialization. Individual fields use the same pattern: `item.memberName || item.MemberName`.

Monthly revenue reads `p.paymentDate || p.PaymentDate` and `p.amount || p.Amount`. Today's checkins reads `c.checkinTime || c.CheckinTime`. Recent checkins table reads `item.memberName || item.MemberName`, `item.memberId || item.MemberId`, `item.checkinTime || item.CheckinTime`, `item.checkoutTime || item.CheckoutTime`.

Trainer dashboard reads `t.email || t.Email`, `t.trainerId || t.TrainerId` when looking up trainerId. Schedule filtering reads `s.startTime || s.StartTime`, `s.trainerId || s.TrainerId`. Session status reads `session.status || session.Status`, `session.registrationDate || session.RegistrationDate`.

## Facilities filter by Available status

`loadActiveFacilities()` fetches all facilities (`pageSize=1000`) and filters client-side to count only `status === 'Available'`. Database schema uses "Available" for active facilities, not "Active". Maintenance and Inactive facilities are excluded.

## Trainer ID lookup by email

`getTrainerId()` fetches all trainers and matches by email since JWT tokens include `user.email` but not `trainerId`. The match is case-insensitive. Result is cached in `_cachedTrainerId` to avoid repeated lookups within the same session.

If no trainer matches, dashboard shows "Không tìm thấy thông tin trainer". This can happen if the trainer account exists in Users but not in Trainers table, or if email case differs.

## Session response format ambiguity

`loadTrainerMonthlyAttended()` handles two response shapes from `/api/Session/schedule/{id}`:

```javascript
const sessionArray = Array.isArray(sessions) ? sessions : 
                   sessions?.data ? sessions.data :
                   sessions?.Data ? sessions.Data : [];
```

Backend sometimes returns an unwrapped array, sometimes a PagedResult wrapper. This indicates inconsistent API design.

## Revenue detail wrapper unwrapping

`loadRevenueDetails()` unwraps `response?.data || response?.Data || []` from `/api/Report/revenue/detail?month={m}&year={y}`.

Each detail item supports two formats:
- Aggregated: `{ date, count, totalAmount }`
- Invoice: `{ invoiceDate, totalAmount }` (no count)

Display logic reads `item.date || item.invoiceDate || item.InvoiceDate`, `item.count || '-'`, `item.totalAmount || item.TotalAmount`.

If backend returns invoice list, the count column shows "-" for every row. Either backend should aggregate by date, or frontend should hide the count column when format is detected as invoice list.

## Expiring memberships member name navigation

`loadExpiringMemberships()` unwraps `response?.data || response?.Data || []` from `/api/Report/expiring-soon?daysAhead={n}`.

Member name is read via navigation property: `item.member?.fullName || item.Member?.FullName || '-'`.

If backend doesn't include the Member navigation property (via `.Include(m => m.Member)` in EF query), `member` is null and names show as "-".

Days remaining is calculated client-side: `Math.ceil((end - today) / (1000 * 60 * 60 * 24))`, rounding up (4.1 days shows as 5).

## Members report format change

`loadMembersReport()` reads stats object from `/api/Report/members`:

```javascript
const totalMembers = stats.totalMembers || stats.TotalMembers || 0;
const activeMembers = stats.activeMembers || stats.ActiveMembers || 0;
const inactiveMembers = stats.inactiveMembers || stats.InactiveMembers || 0;
```

Backend returns `{ totalMembers, activeMembers, inactiveMembers }`, not a member list.

UI changed from table to stats cards. The stats view is more concise than a full member list, but loses member-level detail (names, emails, individual status).

## Console logging and error handling

Every API call logs the raw response (e.g., `console.log('Active Members - API Response:', count)`). Filtered/processed data is also logged in some cases ("Payments array:", "Count:").

Reports changed from `showError()` alerts to inline container messages:

```javascript
container.innerHTML = `<p class="empty-state-text">Lỗi tải doanh thu: ${escapeHtml(error.message)}</p>`;
```

Dashboard stats show errors inline: `document.getElementById('activeMembersCount').textContent = 'Lỗi kết nối'`.

This keeps error context visible without blocking interaction.

## Client-side filtering scale concern

`loadMonthlyRevenue()`, `loadTodayCheckins()`, `loadActiveFacilities()`, and all trainer functions fetch up to 1000 records and filter client-side by date, status, or trainerId.

For chains with 5000+ members or 10000+ payment records, fetching 1000 records and discarding most becomes slow. Backend should support query params like `?fromDate=2026-10-01&toDate=2026-10-31&status=Available` to filter server-side.

Current approach assumes datasets stay under 1000 records per entity type. If a month has 1200 payments, only the first 1000 are counted in monthly revenue.

</details>

<details>
<summary>File Map</summary>

**wwwroot/js/dashboard.js**
- `loadActiveMembersCount()` — switched to `/api/Report/active-members`
- `loadMonthlyRevenue()` — defensive field access `paymentDate`, `amount`
- `loadTodayCheckins()` — defensive field access `checkinTime`
- `loadActiveFacilities()` — filter by `status === 'Available'`
- `renderRecentCheckinsTable()` — defensive field access `memberName`, `checkinTime`, `checkoutTime`
- `getTrainerId()` — defensive field access `email`, `trainerId`
- `loadTrainerTodayClasses()` — defensive field access `startTime`, `trainerId`
- `loadTrainerMonthlyAttended()` — defensive field access, unwraps session response both ways
- `loadTrainerTodayCheckins()` — defensive field access `checkinTime`
- `loadTodaySchedulesList()` — defensive field access `className`, `startTime`, `endTime`, `facilityName`

**wwwroot/js/reports.js**
- `loadReportsData()` — calls `/api/Report/active-members`
- `loadRevenueDetails()` — unwraps `response.data`, defensive field access `date`, `invoiceDate`, `totalAmount`
- `loadExpiringMemberships()` — unwraps `response.data`, navigates `item.member.fullName`
- `loadMembersReport()` — reads stats object, changed UI to cards
- `exportRevenue()` — no field access changes (downloads file blob)

[Full diff: `git diff main -- wwwroot/js/dashboard.js wwwroot/js/reports.js`]

</details>
