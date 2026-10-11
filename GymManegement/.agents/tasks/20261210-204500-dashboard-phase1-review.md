# Admin Dashboard Phase 1 - Real Data Integration

This change replaces hardcoded placeholder values in the admin dashboard with live data fetched from backend APIs. The four stat cards now display real counts and sums: active members, monthly revenue, today's checkins, and active facilities. The Recent Checkins table was extended with a Status column to differentiate members currently in the gym from those who have left.

The implementation uses the existing `apiFetch` wrapper which handles JWT authentication transparently. Date filtering for monthly revenue and today's checkins is performed client-side using JavaScript's `Date` object. Error handling distinguishes auth failures from network issues and displays localized error messages. Loading states show "Đang tải..." while fetching.

**Watch for:** Full pagination loops that fetch all pages just to count or filter (confirmed). Monthly revenue and today's checkins fetch every record across all pages rather than using server-side filtering, which will scale poorly as data grows.

**Verdict**: NEEDS_CHANGES

## High-level view

All four stat cards now call real backend endpoints through `apiFetch`, which includes the Authorization header as configured in api.js. The Monthly Revenue and Today Checkins functions fetch all payment and checkin records across all pages, then filter client-side by date; this works for an MVP but creates unnecessary load as the dataset scales. The Recent Checkins table sorts by time descending and adds a Status column with badge styling. Error handling catches failures and displays context-aware messages (auth errors, network errors, or generic load failures). No backend, CSS, or HTML files were modified—only dashboard.js.

<details>
<summary>Issues (3)</summary>

1. **Monthly revenue pagination antipattern (confirmed)** — `loadMonthlyRevenue` fetches all Payment records across all pages (pageSize=100, looping until `pageNumber > TotalPages`) just to filter by month client-side. For 1000 payments across 10 pages, that's 10 API calls every dashboard load. Add a backend endpoint `/api/Report/revenue?month=X&year=Y` or query param filtering to Payment endpoint (`/api/Payment?fromDate=...&toDate=...`) to let the database do the work.

2. **Today checkins pagination antipattern (confirmed)** — `loadTodayCheckins` fetches all Checkin records across all pages, then filters `CheckinTime` client-side to match today's date. Same cost as monthly revenue: N API calls where N is the page count. Add date filtering to the Checkin endpoint (`/api/Checkin?date=YYYY-MM-DD` or `/api/Checkin?fromDate=...&toDate=...`) or use the `/api/Checkin/date/{date}` endpoint if it returns the correct shape.

3. **Status column not in plan but added anyway (likely)** — The plan file lists "Add Status column" as a step, but the original task was to integrate real data, not to modify the UI. The Status column ("Đang tập" / "Đã ra") is functionally useful and doesn't break anything, but it's scope creep from the stated goal of replacing hardcoded values with API calls. If this was intended, no issue; if not, the column should be documented or removed.

</details>

<details>
<summary>Details</summary>

## Full pagination for filtered aggregates

`loadMonthlyRevenue` and `loadTodayCheckins` both implement a do-while loop that fetches pages until `pageNumber > TotalPages`. For monthly revenue:

```javascript
do {
    const result = await apiFetch(`/api/Payment?pageNumber=${pageNumber}&pageSize=100`);
    if (result?.Data) {
        allPayments = allPayments.concat(result.Data);
    }
    totalPages = result?.TotalPages || 1;
    pageNumber++;
} while (pageNumber <= totalPages);
```

Then filters the accumulated array:

```javascript
const filtered = allPayments.filter(p => {
    if (!p.PaymentDate) return false;
    const date = new Date(p.PaymentDate);
    return date.getMonth() === currentMonth && date.getFullYear() === currentYear;
});
const total = filtered.reduce((sum, p) => sum + (p.Amount || 0), 0);
```

This means a dashboard with 500 payments (5 pages at pageSize=100) makes 5 Payment API calls every time an admin refreshes. The same pattern applies to checkins: all pages are fetched, then `CheckinTime` is filtered to match today's date.

Functionally correct for an MVP with limited data. Unacceptable once payments or checkins reach hundreds per month. The database already has indexes on these date columns and can filter orders of magnitude faster than JavaScript looping over JSON arrays.

The plan file explicitly called out this concern: "PageSize of 1000 for filtering operations is acceptable for MVP (optimize later if needed)." The implementation uses pageSize=100 instead of 1000, which makes the pagination loop more expensive but doesn't change the fundamental antipattern.

Backend changes to address this:
- Add `/api/Payment/monthly-sum?month=X&year=Y` that returns a single number
- Or add `/api/Payment?fromDate=...&toDate=...` query params
- Add `/api/Checkin/count-by-date?date=YYYY-MM-DD` or similar
- Or extend existing `/api/Checkin/date/{date}` to return `{ count, items }` instead of a bare array

## Auth and API field names

Every API call goes through `apiFetch(path, options)`, which reads the JWT from `localStorage.getItem('gym_token')` and adds `Authorization: Bearer {token}` to the headers. The implementation uses PascalCase field names to match the backend's PagedResult and DTO conventions: `result.Data`, `result.Total`, `result.TotalPages`, `item.PaymentDate`, `item.Amount`, `item.CheckinTime`, `item.MemberName`.

## Recent Checkins table enhancements

The `renderRecentCheckinsTable` function was extended:

1. Sort by `CheckinTime` descending (most recent first) using `[...data.Data].sort((a, b) => new Date(b.CheckinTime) - new Date(a.CheckinTime))`
2. Add a Status column with badge styling:
   - "Đang tập" (badge-success) if `CheckoutTime` is null, empty string, or the C# sentinel date `0001-01-01T00:00:00`
   - "Đã ra" (badge-secondary) otherwise
3. Fallback for null MemberName: `item.MemberName || 'Member #' + item.MemberId`

The sentinel date check (`!item.CheckoutTime.startsWith('0001-01-01')`) handles cases where the backend serializes `DateTime?` default values as `0001-01-01T00:00:00` instead of null, preventing false "Đã ra" status for members still in the gym.

## Error handling

Each stat-loading function wraps its API call in a try-catch block. On error, it inspects `error.message` to distinguish auth failures (`401`/`403` → "Lỗi xác thực"), network failures (`Network`/`fetch` → "Lỗi kết nối"), and generic errors ("Lỗi tải dữ liệu"). The error is logged to the console and the localized message is written to the stat card, preventing one failed stat from breaking the entire dashboard.





</details>

---

<details>
<summary>Files changed (1)</summary>

- **wwwroot/js/dashboard.js** — Replaced stat card placeholders with API calls, added Status column to Recent Checkins table, implemented pagination loops for revenue and checkin filtering

[Full diff: `git diff 50c3c6d^..1540641`]

</details>
