# Member features: package purchase, schedule registration, QR check-in

Added three member-specific workflows: viewing and purchasing membership packages with QR payment simulation, registering for schedules with localStorage persistence and cancellation, and QR-based check-in with duplicate prevention. The implementations are functional for the specified use cases but carry integration gaps and edge-case handling weaknesses.

**Watch for:** QR payment simulation bypasses actual payment verification (confirmed), localStorage schedule persistence won't scale across devices or survive cache clears (confirmed), check-in QR value is never validated server-side so any string will work (likely), missing error recovery for partial payment+membership creation failures (confirmed), no max-capacity enforcement on schedule registration (confirmed).

**Verdict**: NEEDS_CHANGES

## High-level view

The membership purchase flow chains two API calls (Payment then Membership) without transaction safety—if the second call fails, the payment record orphans with no rollback mechanism and the user sees an error but money was "paid". The QR payment modal is a visual placeholder with no backend integration; clicking "Xác Nhận Đã Thanh Toán" immediately proceeds without verifying any scan or transaction.

Schedule registration persists to localStorage keyed by member ID, so registrations survive page reloads but not device switches, browser changes, or cache clears. The UI disables "Đăng Ký" for already-registered schedules and shows a separate "Lịch Của Tôi" section with cancellation. Capacity limits displayed in the table are never checked before registration.

Check-in QR modal generates a timestamped member-specific code and displays it both as an emoji placeholder and in a copyable text field. The `/api/Checkin/qr` POST is called with this code and member ID, but the frontend never validates the code format or content. Already-checked-in errors are caught and shown as a specific message. The modal-inject pattern is shared across all three files using the same style ID.

## Issues (5)

1. **Payment-membership transaction gap** — if POST /api/Membership fails after POST /api/Payment succeeds, the payment record orphans and the user loses money. Wrap both calls in a backend transaction or implement compensating deletion of the payment record on membership creation failure.
2. **QR payment is cosmetic** — the QR modal shows a placeholder emoji and a "confirm" button that bypasses payment verification entirely. The feature will mislead users into thinking payment was processed. Either integrate a real QR payment provider or add prominent UI text clarifying this is a simulation.
3. **localStorage schedule persistence won't sync** — registrations saved in localStorage will disappear on cache clear, device switch, or browser change. Replace with backend persistence (e.g., POST /api/ScheduleRegistration endpoint) or document this as a known limitation.
4. **No capacity enforcement on registration** — the UI shows max capacity but never checks current enrollment before allowing registration. A popular class could exceed capacity with no warning. Add a backend capacity check or at least a frontend warning based on enrollment count.
5. **Check-in QR code is never validated** — any string passed to /api/Checkin/qr will be accepted by the frontend logic. If the backend doesn't validate format or freshness, users could fabricate check-ins. Confirm backend validation exists or add frontend format checking.

<details>
<summary>Details</summary>

## Membership purchase: two-stage API call without rollback

The purchase flow opens three nested modals: package selection → purchase confirmation → QR payment. Clicking "Xác Nhận Đã Thanh Toán" in the QR modal calls `processPurchase`, which posts to `/api/Payment` then `/api/Membership` sequentially:

```javascript
await apiFetch('/api/Payment', {
    method: 'POST',
    body: JSON.stringify(paymentData)
});

// Step 2: Create membership
const membershipData = { ... };
await apiFetch('/api/Membership', {
    method: 'POST',
    body: JSON.stringify(membershipData)
});
```

If the second call throws, the first payment record persists. The user sees "Lỗi mua gói tập" but the payment was already recorded as "Completed". The backend needs a transaction boundary or the frontend needs to delete the orphaned payment on error.

The QR modal itself is purely cosmetic: a 📱 emoji placeholder, a display of the package price, and a "confirm" button. No actual QR provider integration, no transaction ID verification, no callback from a payment gateway. Users will believe they need to scan the QR to pay, but clicking "confirm" immediately proceeds.

## Schedule registration: localStorage keyed by member ID

`getMyScheduleIds(memberId)` reads `localStorage` key `memberSchedules_${memberId}`, returning an array of schedule IDs. `registerSchedule` appends to this array and saves it back. The table render checks `isRegistered` by testing `registeredIds.includes(schedule.scheduleId)` and either shows a disabled "✅ Đã đăng ký" button or an active "📌 Đăng Ký" button.

The "Lịch Của Tôi" section fetches all schedules from `/api/Schedule?pageNumber=1&pageSize=1000` (confirmed: hard-coded page size of 1000, which will break if more than 1000 schedules exist) and filters client-side by `scheduleIds.includes(s.scheduleId)`. Each row has a "🗑️ Hủy" button that triggers `cancelSchedule`, which shows a confirm dialog, filters the ID out of the array, saves to localStorage, and reloads.

Because localStorage is browser-local, a member who registers on desktop won't see those registrations on mobile. Clearing browser data wipes all registrations. There's no API persistence of schedule-member relationships.

The max capacity is displayed in the table but never checked. If 50 members each register for a class with capacity 30, localStorage will happily store all 50 registrations. The backend may enforce capacity, but the frontend gives no feedback.

## Check-in QR modal: pre-filled code, no format validation

`showQRCheckinModal(memberId)` generates `qrValue = "MEMBER_${memberId}_${Date.now()}"` and injects a modal with:
- A 📱 placeholder div styled as `.qr-placeholder`
- A gray box displaying the qrValue as plain text
- An input field pre-filled with the qrValue (allowing manual edit)
- A "Xác Nhận Check-in" button that reads the input value and calls `processQRCheckin`

`processQRCheckin` reads `document.getElementById('qrCodeInput').value`, trims it, and posts to `/api/Checkin/qr` with `{ qrCode, memberId }`. No validation of format, no check that the code matches the generated value, no expiry logic. If the server accepts any string, a user could type "abc" and check in.

The error handler looks for `'already'` or `'đã check-in'` in the error message (case-insensitive) and shows a specific message: "Bạn đã check-in rồi. Vui lòng checkout trước." Any other error is shown as "Lỗi check-in: [message]".

The modal styles are injected once via `ensureModalStyles()` which checks for `#membership-modal-styles` and creates a `<style>` block if missing. This is the same style ID used in memberships.js's `injectModalStyles()`. Both files inject the same set of CSS rules (`.gym-modal-overlay`, `.gym-modal`, `.qr-placeholder`, etc.), so whichever file runs first will create the styles and the second will skip injection. This is safe but relies on exact duplication of the style text between files.

## Admin/Trainer views preserved

All three files check role and conditionally render different UIs. The stubs (`showCreateMembershipModal`, `showEditMembershipModal`, `showCreateScheduleModal`, `showEditScheduleModal`, `showManualCheckinModal`) all call `showError('Chức năng ... chưa được triển khai đầy đủ')`, so the buttons are visible but non-functional.

## Modal injection: shared style ID across files

Both memberships.js and checkins.js inject a `<style id="membership-modal-styles">` element with duplicated style text. Whichever file runs first will create the `<style>` and the second will skip. This works but is fragile: if one file updates its style text and the other doesn't, the styles will diverge depending on load order.

## Purchase modal onclick escaping

`showPurchaseModal` and `showQRPaymentModal` embed JSON.stringify(pkg) into onclick attributes via `.replace(/"/g, '&quot;')`. If `pkg.name` contained a backtick or single quote, it could break the attribute boundary. The current package names are Vietnamese text with spaces, so the risk is low but would break if package names included quotes.

## API surface and error handling

The membership purchase flow shows a generic "Lỗi mua gói tập: [message]" on any error. The check-in flow has special handling for already-checked-in errors. The schedule registration flow has no error handling for localStorage.setItem quota exceeded.

The member check-ins view calls `/api/Checkin/member/${memberId}` and expects an array. If the API returns paginated data instead, this will break.

The member schedules view fetches all schedules with `pageSize=1000`, which will fail silently if more than 1000 schedules exist.

</details>

<details>
<summary>File map</summary>

## Files changed

- `wwwroot/js/memberships.js` — Added member view with package purchase flow (3 modals), QR payment simulation, and dual API post sequence
- `wwwroot/js/schedules.js` — Added localStorage persistence for schedule registrations, "Đăng Ký" button with disabled state, "Lịch Của Tôi" section with cancellation
- `wwwroot/js/checkins.js` — Added "Check-in QR" button in member header, QR modal with pre-filled code, POST /api/Checkin/qr call, already-checked-in error handling

Full diff not provided; review based on reading the three files directly.

</details>
