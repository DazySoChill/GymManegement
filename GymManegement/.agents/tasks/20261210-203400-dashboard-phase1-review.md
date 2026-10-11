# Admin Dashboard Phase 1: Real Data Integration

This change replaces the admin dashboard's static stat cards and hardcoded API calls with dynamic data loading that uses the correct backend endpoints, extracts the right response fields, and filters client-side where server-side filtering isn't available. The dashboard now shows live member counts, monthly revenue calculated from payment records, today's check-in count, and active facility count. The Recent Checkins table gained a Status column distinguishing members still in the gym from those who have left.

**Watch for:** Missing pagination causing incomplete counts when client-side filtering exceeds 1000 records (confirmed), CheckoutTime sentinel date handling may not match all backend patterns (likely), error state UX provides no recovery path (confirmed).

**Verdict**: NEEDS_CHANGES

## High-level view

All four stat cards now fetch from real APIs — Member, Payment, Checkin, and Facility endpoints — and extract counts or sums from PagedResult responses. Monthly revenue fetches up to 1000 payments and filters by month/year client-side; today's check-ins do the same. The Recent Checkins table uses PascalCase field names matching the backend DTOs and displays a Status badge based on whether CheckoutTime is null or a sentinel date. Loading states show "Đang tải..." before fetch completes. Error handling catches failures and displays Vietnamese error text, distinguishing auth errors from connection errors, but leaves the stat card in an error state with no retry mechanism. Date calculations use `new Date()` throughout — no hardcoded strings. The card previously labeled "Gói Tập Sắp Hết Hạn" was replaced with "Cơ Sở Vật Chất Hoạt Động" (Active Facilities).

<details>
<summary>Issues (3)</summary>

1. **Client-side filtering pagination gap** — Monthly revenue and today's check-ins fetch pageSize=1000 and filter client-side. If actual monthly payments or daily check-ins exceed 1000, the counts and sums will be incomplete. Use server-side filtering (query params for date ranges) or fetch all pages.

2. **CheckoutTime sentinel date heuristic incomplete** — Code checks for null, empty string, and dates starting with "0001-01-01", but backend may return other sentinel patterns (e.g., "1900-01-01", "9999-12-31", or SQL Server's default DateTime minimum). Verify all sentinel values returned by the API and add them to the condition, or standardize backend to only return null for "not checked out".

3. **Error states provide no recovery** — When a stat card fetch fails, the card shows "Lỗi tải dữ liệu" or similar, but there's no refresh button, no automatic retry, and the error persists until the user manually reloads the entire page. Add a retry button or auto-retry with exponential backoff.

</details>

<details>
<summary>Details</summary>

## Real API integration with correct field extraction

The original dashboard called `/api/Report/active-members` and `/api/Report/revenue`, endpoints that either don't exist or don't return PagedResult. The new implementation calls the standard paginated endpoints (`/api/Member`, `/api/Payment`, `/api/Checkin`, `/api/Facility`) and extracts `Total` for counts or `Data` for filtering and aggregation.

All field references use PascalCase (`Data`, `Total`, `PaymentDate`, `CheckinTime`, `CheckoutTime`, `MemberName`, `MemberId`) matching the backend DTOs. Fallback field name patterns were removed, forcing the code to break visibly if backend casing changes.

```javascript
// Before (wrong field names, wrong endpoint)
const activeMembers = await apiFetch('/api/Report/active-members');
document.getElementById('activeMembersCount').textContent = activeMembers || 0;

// After (correct endpoint, extract Total)
const result = await apiFetch('/api/Member?pageNumber=1&pageSize=1');
const count = result?.Total || 0;
document.getElementById('activeMembersCount').textContent = count;
```

Monthly revenue filtering uses `new Date()` to get the current month and year, filters `payments.Data` where `PaymentDate` month/year match, and sums the `Amount` field. Date calculation is dynamic; no hardcoded month or year strings appear.

```javascript
const now = new Date();
const currentMonth = now.getMonth();
const currentYear = now.getFullYear();

const result = await apiFetch('/api/Payment?pageNumber=1&pageSize=1000');
const payments = result?.Data || [];

const filtered = payments.filter(p => {
    if (!p.PaymentDate) return false;
    const date = new Date(p.PaymentDate);
    return date.getMonth() === currentMonth && date.getFullYear() === currentYear;
});

const total = filtered.reduce((sum, p) => sum + (p.Amount || 0), 0);
document.getElementById('monthlyRevenue').textContent = formatCurrency(total);
```



## Client-side filtering exceeds pagination limit

Monthly revenue and today's check-ins fetch `pageSize=1000` and filter the results in JavaScript. If the gym processes more than 1000 payments in a month or more than 1000 check-ins in a day, the aggregation will be incomplete. The dashboard will display a lower count/sum than reality.

The plan document acknowledged this limitation with a note: "PageSize of 1000 for filtering operations is acceptable for MVP (optimize later if needed)". For a production system, either the backend should add query parameters for date range filtering (e.g., `/api/Payment?startDate=2024-12-01&endDate=2024-12-31`) or the frontend should fetch all pages in a loop until `PageNumber == TotalPages`.

Monthly revenue is more likely to hit this limit than daily check-ins. A gym with 50 members paying monthly fees would generate only 50 payments/month, well under 1000. But a gym with 200 members, multiple payment types (membership, sessions, merchandise), and weekly recurring charges could exceed 1000 records in a month.

## Status column and CheckoutTime handling

The Recent Checkins table gained a Status column with badges: "Đang tập" (still in gym) for null `CheckoutTime`, "Đã ra" (left) otherwise. The code checks three conditions for "not checked out":

```javascript
const hasCheckedOut = item.CheckoutTime && 
                     item.CheckoutTime !== '' && 
                     !item.CheckoutTime.startsWith('0001-01-01');
const status = hasCheckedOut ? 'Đã ra' : 'Đang tập';
const badgeClass = hasCheckedOut ? 'badge-secondary' : 'badge-success';
```

This handles null, empty string, and C# DateTime default (`0001-01-01T00:00:00`). However, if the backend uses SQL Server's DateTime minimum (`1753-01-01T00:00:00`), or a placeholder like `1900-01-01` or `9999-12-31`, those won't match the pattern and will be treated as valid check-out times, displaying "Đã ra" incorrectly.

The safest approach is for the backend to only return null (or omit the field) when CheckoutTime is not set, and return a proper ISO datetime when it is set. If the backend cannot change, the frontend should check against a whitelist of sentinel values or check if the year is outside a reasonable range (e.g., `year < 2000 || year > 2100`).

## Loading states and error handling structure

Each stat-loading function shows "Đang tải..." in the card's HTML before any fetch. All four load functions run in parallel via `Promise.all`.

Error handling wraps each fetch in a try-catch block. Errors are logged to console and analyzed to provide localized messages: "Lỗi xác thực" for 401/403, "Lỗi kết nối" for network failures, "Lỗi tải dữ liệu" for everything else. The card displays the error text in place of the stat value, leaving it in a failed state.

```javascript
} catch (error) {
    console.error('Error loading active members:', error);
    const errorMsg = error.message?.includes('401') || error.message?.includes('403') 
        ? 'Lỗi xác thực' 
        : error.message?.includes('Network') || error.message?.includes('fetch')
        ? 'Lỗi kết nối'
        : 'Lỗi tải dữ liệu';
    document.getElementById('activeMembersCount').textContent = errorMsg;
}
```

The error states provide no recovery mechanism. A user whose dashboard fails to load must refresh the entire page to retry.



## Stat card #3 replaced Expiring Memberships with Active Facilities

The plan recommended replacing "Gói Tập Sắp Hết Hạn" (Expiring Memberships) with "Cơ Sở Vật Chất Hoạt Động" (Active Facilities), arguing that facility count is more useful for a dashboard overview while expiring memberships should be a separate alert section. The implementation followed this recommendation. The card now calls `/api/Facility?pageNumber=1&pageSize=1` and displays `result.Total`.





## Code comments document the 1000-record limitation

JSDoc comments on `loadMonthlyRevenue` and `loadTodayCheckins` state:

```javascript
/**
 * Load Monthly Revenue
 * Note: Fetches up to 1000 payments and filters client-side. If monthly volume exceeds 1000, results may be incomplete.
 */
```

This surfaces the limitation for future maintainers.

</details>

<details>
<summary>File Map</summary>

## Changed Files

- **wwwroot/js/dashboard.js** — Replaced hardcoded stat card logic with real API calls; added helper functions for each stat; replaced Report endpoints with paginated CRUD endpoints; fixed field name casing to match backend DTOs; added Status column to Recent Checkins table; added error handling and loading states.

Full diff: compare commits `b7c7c34..48880b9` in branch `master`.

</details>
