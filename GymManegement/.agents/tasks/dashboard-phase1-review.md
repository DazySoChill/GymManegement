# Admin Dashboard Real Data Integration

This change replaces hardcoded placeholder values in the admin dashboard with live data fetched from backend APIs. Four stat cards now display active members count, monthly revenue, today's checkins, and active facilities count. The recent checkins table adds a status column and sorts by most recent first.

The implementation uses dynamic date filtering (current month for revenue, today for checkins) and handles API response variations (`totalCount` vs `total`, `items` vs `data`). Loading states show "Đang tải..." before data arrives, error states show "Lỗi" on failure. Auth headers are present via the existing `apiFetch` wrapper.

**Watch for:** API response field name mismatches between backend and frontend (**likely** — the code checks both `totalCount` and `total`, but other field names like `paymentDate` vs `transactionDate` vs `createdAt` may not match actual backend DTOs).

**Verdict**: NEEDS_CHANGES

## High-level view

The stat cards call individual helper functions that fetch data from paginated endpoints. Active members and facilities extract `totalCount` or `total` from PagedResult responses. Monthly revenue fetches all payments (up to 1000), filters by current month in JavaScript, and sums the amounts. Today's checkins fetches all checkins (up to 1000), filters by today's date, and counts the results. The recent checkins table sorts by `checkinTime` descending and adds a status column distinguishing "Đang tập" (still checked in) from "Đã ra" (checked out).

Date filtering uses `new Date()` for dynamic current-month and current-day comparisons, not hardcoded strings. Currency formatting delegates to `formatCurrency()`, which uses Vietnamese locale with thousand separators. Error handling wraps each stat loader in try-catch, logging errors to console and displaying "Lỗi" in the card.

The code assumes API response field names (`paymentDate`, `checkinTime`, `memberName`) that may differ from the backend DTOs. The fallback pattern (`p.paymentDate || p.transactionDate || p.createdAt`) suggests uncertainty about actual field names. This creates a runtime dependency on field name conventions that isn't verified at build time.

<details>
<summary>Issues (5)</summary>

1. **API response field name mismatches** — Backend DTOs may not expose fields named `paymentDate`, `transactionDate`, `createdAt`, `checkinTime`, `checkoutTime`, `memberName`, `memberId` in camelCase. C# conventions use PascalCase (`PaymentDate`, `CheckinTime`). Check backend DTOs and match exact field names or configure JSON serialization to camelCase.

2. **PageSize 1000 fetches full datasets without pagination** — Monthly revenue and today's checkins fetch up to 1000 records and filter client-side. If payment or checkin volume exceeds 1000, results will be incomplete. Backend should provide filtered endpoints (`/api/Payment/monthly-total`, `/api/Checkin/today-count`) or frontend should implement true pagination.

3. **Fallback field name pattern papers over missing API contract** — `p.paymentDate || p.transactionDate || p.createdAt` tries three field names, suggesting the implementation doesn't know which one the backend uses. This obscures API contract failures. Remove fallbacks and use the correct field name.

4. **Checkout time null check may fail on empty string or sentinel date** — Status logic assumes `checkoutTime` is null/undefined for active checkins. If backend returns empty string or `"0001-01-01T00:00:00"`, the status will show "Đã ra" incorrectly. Verify backend null representation or add explicit checks for sentinel values.

5. **Generic error state lacks actionable context** — Displaying "Lỗi" doesn't distinguish network failures from auth failures from server errors. Add error type detection or include the error message so users know whether to retry, log in again, or report the issue.

</details>

<details>
<summary>Details</summary>

## API response field name uncertainty

The monthly revenue loader checks three possible date field names:

```javascript
const dateStr = p.paymentDate || p.transactionDate || p.createdAt;
```

C# backend DTOs typically expose PascalCase field names (`PaymentDate`, `TransactionDate`) unless JSON serialization is configured for camelCase. The code assumes camelCase but includes fallbacks, suggesting the author doesn't know which field the backend actually returns.

The recent checkins table references `item.checkinTime`, `item.checkoutTime`, `item.memberName`, `item.memberId`. If the backend returns `CheckinTime`, `CheckoutTime`, `MemberName`, `MemberId` (PascalCase), these references will be undefined and the table will show "Member #undefined", invalid dates, and missing status badges.

The active members and facilities loaders check both `totalCount` and `total`:

```javascript
const count = result?.totalCount || result?.total || 0;
```

Only one field name is correct. The fallback hides API contract violations that should be caught during testing.

## Client-side filtering as pagination workaround

Monthly revenue fetches up to 1000 payments:

```javascript
const result = await apiFetch('/api/Payment?pageNumber=1&pageSize=1000');
const payments = result?.items || result?.data || [];
```

Then filters by current month in JavaScript. If the gym processes more than 1000 payments in any month, the pageSize cap will truncate results and revenue will be underreported.

Similarly, today's checkins fetches up to 1000 checkins and filters by today's date. If daily checkin volume exceeds 1000, the count will be wrong.

The backend should provide filtered endpoints that return totals directly (`GET /api/Payment/monthly-total?month=12&year=2024`, `GET /api/Checkin/today-count`), not require the frontend to fetch and filter full datasets.

## Loading and error states

The error state displays "Lỗi" but doesn't tell the user what failed or how to recover. Console logging is sufficient for debugging but the UI should distinguish network failures from auth failures from server errors if possible.

## Recent checkins status column

The table adds a fourth column showing whether the member is still in the gym:

```javascript
const status = item.checkoutTime ? 'Đã ra' : 'Đang tập';
const badgeClass = item.checkoutTime ? 'badge-secondary' : 'badge-success';
```

This assumes `checkoutTime` is null or undefined when the member hasn't checked out yet. If the backend returns an empty string or `"0001-01-01T00:00:00"` instead of null, the condition will evaluate incorrectly.



</details>

<details>
<summary>File map</summary>

**Changed:**
- `wwwroot/js/dashboard.js` — Added four helper functions (`loadActiveMembersCount`, `loadMonthlyRevenue`, `loadTodayCheckins`, `loadActiveFacilities`) that fetch real data from backend APIs. Updated `renderAdminDashboard` to call these helpers in parallel. Replaced static "-" placeholders with "Đang tải..." loading state. Changed card #3 from "Gói Tập Sắp Hết Hạn" to "Check-in Hôm Nay", changed card #4 from "Check-in Hôm Nay" to "Cơ Sở Vật Chất Hoạt Động". Updated `renderRecentCheckinsTable` to sort by checkinTime descending and add a status column with badges.

**Not changed:**
- No backend files modified
- No CSS files modified
- No other admin pages modified

**Diff:** `git show HEAD`

</details>
