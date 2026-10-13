# Implementation Plan: Fix Payments.js - Member Filter + Sorting

## Context
File: `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\payments.js`

**Exploration Findings:**
- Existing patterns from `invoices.js` and `members.js` show consistent dropdown filter implementation
- API responses use defensive accessor pattern: `data?.Data || data?.data || data?.items || []`
- Member dropdowns follow pattern: fetch from `/api/Member?pageNumber=1&pageSize=1000`
- Invoice filtering by member uses: `/api/Invoice/member/{memberId}`
- All modals inject styles via `injectXxxModalStyles()` pattern and use same `.gym-modal-overlay` structure
- Form validation follows centralized `validateXxxForm()` pattern with error display in dedicated error divs
- Pagination uses client-side pagination when filtering (store filtered array, slice for display)
- Sorting is server-side via query params: `sortBy=FieldName&sortDir=asc|desc`

**Current payments.js structure:**
- `renderPayments()` creates the card with filters section and table container
- Current filter: `paymentMethodFilter` dropdown (Cash, BankTransfer, etc.)
- `loadPayments()` fetches from `/api/Payment?pageNumber=X&pageSize=Y`
- `showCreatePaymentModal()` has static dropdowns for members and invoices (loads all Pending invoices)
- No member filter exists in main view
- No sorting applied to API calls
- Defensive accessor already present: `data?.Data || data?.data || data?.items || []`

**Backend API endpoints (assumed from invoices.js patterns):**
- `GET /api/Payment?pageNumber=1&pageSize=10&sortBy=PaymentDate&sortDir=desc` - paginated, sorted
- `GET /api/Member?pageNumber=1&pageSize=1000` - for member dropdown
- `GET /api/Invoice/member/{memberId}` - invoices for specific member
- `GET /api/Invoice/status/Pending` - pending invoices (already used in create modal)
- `GET /api/Invoice/status/Overdue` - overdue invoices (will use for member's unpaid invoices)

---

## Implementation Steps

### ✅ Step 1: Add Sorting to loadPayments()
**What:** Modify the `loadPayments()` function to add `sortBy=PaymentDate&sortDir=desc` to the API query string so newest payments appear first.

**Where:** Line 82 in `payments.js` - the `apiFetch` call inside `loadPayments()`

**How:**
- Current API call: `` `/api/Payment?pageNumber=${fetchPageNumber}&pageSize=${fetchPageSize}` ``
- Change to: `` `/api/Payment?pageNumber=${fetchPageNumber}&pageSize=${fetchPageSize}&sortBy=PaymentDate&sortDir=desc` ``
- This matches the pattern used in `invoices.js` line 71

**Verify:** 
1. Open browser DevTools Network tab
2. Reload Thanh toán page
3. Verify API call includes `sortBy=PaymentDate&sortDir=desc`
4. Check table displays newest payments first (highest PaymentDate at top)
5. Run syntax check: `node --check "d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\payments.js"`

---

### ✅ Step 2: Add Member Filter Dropdown in Filters Section
**What:** Add a member dropdown filter next to the existing `paymentMethodFilter` in the `renderPayments()` function's filters HTML. Populate it from `/api/Member` endpoint.

**Where:** Line 73-82 in `payments.js` - the `container.innerHTML` block, specifically the `.filters` div

**How:**
- Add a new `<select id="paymentMemberFilter">` before the existing `paymentMethodFilter` dropdown
- HTML structure to insert:
```html
<select id="paymentMemberFilter" onchange="filterPaymentsByMember()">
    <option value="">Tất cả thành viên</option>
    <!-- Will be populated by loadMembersForFilter() -->
</select>
```
- Create new async function `loadMembersForFilter()` that:
  1. Fetches from `/api/Member?pageNumber=1&pageSize=1000`
  2. Uses defensive accessor: `members?.Data || members?.data || members?.items || []`
  3. Populates the dropdown: `document.getElementById('paymentMemberFilter').innerHTML = '<option value="">Tất cả thành viên</option>' + members.map(m => `<option value="${m.memberId}">${escapeHtml(m.fullName)} (ID: ${m.memberId})</option>`).join('')`
- Call `loadMembersForFilter()` at the end of `renderPayments()` after `await loadPayments()`

**Verify:**
1. Reload Thanh toán page
2. Verify member dropdown appears with "Tất cả thành viên" + list of members
3. Check console for errors
4. Run syntax check: `node --check "d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\payments.js"`

---

### ✅ Step 3: Implement filterPaymentsByMember() Function
**What:** Create the `filterPaymentsByMember()` function that filters payments by selected member. When a member is selected, show only that member's payments; when cleared, show all payments.

**Where:** Add new function after `changePaymentsPage()` function (around line 161)

**How:**
```javascript
async function filterPaymentsByMember() {
    const memberId = document.getElementById('paymentMemberFilter')?.value;
    
    // Reset to page 1 when filter changes
    paymentsCurrentPage = 1;
    
    if (!memberId) {
        // No filter: load all payments normally
        await loadPayments();
        return;
    }
    
    try {
        showLoading();
        // Fetch all payments for this member (no pagination on this endpoint)
        const allPayments = await apiFetch(`/api/Payment?pageNumber=1&pageSize=9999&sortBy=PaymentDate&sortDir=desc`);
        hideLoading();
        
        const items = allPayments?.Data || allPayments?.data || allPayments?.items || [];
        
        // Filter client-side by memberId
        const filtered = items.filter(p => p.memberId === parseInt(memberId));
        
        // Client-side pagination
        const totalPages = Math.ceil(filtered.length / paymentsPageSize) || 1;
        const startIdx = (paymentsCurrentPage - 1) * paymentsPageSize;
        const endIdx = startIdx + paymentsPageSize;
        const pageItems = filtered.slice(startIdx, endIdx);
        
        const displayData = {
            items: pageItems,
            pageNumber: paymentsCurrentPage,
            totalPages: totalPages,
            totalCount: filtered.length
        };
        
        renderPaymentsTable(displayData);
        renderPaymentsPagination(displayData);
        
    } catch (error) {
        hideLoading();
        showError('Không thể lọc thanh toán theo thành viên: ' + error.message);
        console.error('Error filtering payments by member:', error);
    }
}
```

**Pattern rationale:** This follows the same client-side filtering pattern used in `invoices.js` `loadInvoicesByStatus()` (lines 89-123) - fetch all matching records, store them, paginate client-side.

**Verify:**
1. Reload page, select a member from dropdown
2. Verify table shows only that member's payments
3. Test pagination with filtered results
4. Select "Tất cả thành viên" - verify all payments load again
5. Check console for errors
6. Run syntax check: `node --check "d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\payments.js"`

---

### ✅ Step 4: Add Member Dropdown to Create Payment Modal
**What:** In `showCreatePaymentModal()`, add a member dropdown as the first form field, and make it control which invoices are shown in the invoice dropdown (cascade behavior).

**Where:** Line 165-242 in `payments.js` - the modal HTML in `showCreatePaymentModal()`

**How:**
1. **Move member dropdown above invoice dropdown** in the modal form HTML (it currently comes after)
2. **Modify the invoice dropdown** to initially show empty state:
   - Change from pre-populated with all Pending invoices
   - To: `<option value="">-- Chọn thành viên trước --</option>` (disabled until member selected)
3. **Add change event listener** after modal is appended to DOM:
```javascript
// After: document.body.appendChild(modal);

// Add member selection handler
const memberSelect = document.getElementById('memberId');
const invoiceSelect = document.getElementById('invoiceId');

memberSelect.addEventListener('change', async () => {
    const selectedMemberId = memberSelect.value;
    
    if (!selectedMemberId) {
        // Reset invoice dropdown
        invoiceSelect.innerHTML = '<option value="">-- Chọn thành viên trước --</option>';
        invoiceSelect.disabled = true;
        return;
    }
    
    try {
        showLoading();
        // Fetch Pending and Overdue invoices for this member
        const [pendingInvoices, overdueInvoices] = await Promise.all([
            apiFetch(`/api/Invoice/status/Pending`),
            apiFetch(`/api/Invoice/status/Overdue`)
        ]);
        hideLoading();
        
        const allUnpaid = [...(pendingInvoices || []), ...(overdueInvoices || [])];
        const memberUnpaid = allUnpaid.filter(inv => inv.memberId === parseInt(selectedMemberId));
        
        // Populate invoice dropdown with this member's unpaid invoices
        if (memberUnpaid.length === 0) {
            invoiceSelect.innerHTML = '<option value="">-- Không có hóa đơn chờ thanh toán --</option>';
        } else {
            invoiceSelect.innerHTML = '<option value="">-- Không liên kết --</option>' + 
                memberUnpaid.map(inv => {
                    const statusBadge = inv.status === 'Overdue' ? '🔴' : '🟡';
                    return `<option value="${inv.invoiceId}">${statusBadge} HĐ #${inv.invoiceId} - ${formatCurrency(inv.totalAmount)} - ${formatDate(inv.dueDate)} (${inv.status})</option>`;
                }).join('');
        }
        invoiceSelect.disabled = false;
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải hóa đơn: ' + error.message);
        invoiceSelect.innerHTML = '<option value="">-- Lỗi tải dữ liệu --</option>';
    }
});
```

**Pattern rationale:** This cascading dropdown pattern ensures user selects member first, then sees only relevant invoices. The emoji indicators (🔴 Overdue, 🟡 Pending) provide visual clarity. Pattern is similar to the optgroup structure in `invoices.js` `showCreateInvoiceModal()` (lines 346-353).

**Verify:**
1. Click "➕ Ghi nhận thanh toán" button
2. Verify member dropdown is first, invoice dropdown shows "-- Chọn thành viên trước --" and is disabled
3. Select a member with pending/overdue invoices
4. Verify invoice dropdown populates with that member's unpaid invoices only
5. Verify emoji indicators show (🔴 for Overdue, 🟡 for Pending)
6. Select a member with no unpaid invoices - verify dropdown shows "-- Không có hóa đơn chờ thanh toán --"
7. Create a payment - verify it works
8. Run syntax check: `node --check "d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\payments.js"`

---

### ✅ Step 5: Update changePaymentsPage() to Respect Active Filter
**What:** Modify `changePaymentsPage()` to maintain member filter state when paginating. Currently it only checks `paymentMethodFilter`; it should also check `paymentMemberFilter`.

**Where:** Line 157-159 in `payments.js` - the `changePaymentsPage()` function

**How:**
- Current logic only checks for `paymentMethodFilter` 
- Add check: if `paymentMemberFilter` has a value, call `filterPaymentsByMember()` instead of `loadPayments()`
- The function should become:
```javascript
function changePaymentsPage(page) {
    paymentsCurrentPage = page;
    
    // Check if member filter is active
    const memberFilter = document.getElementById('paymentMemberFilter')?.value;
    if (memberFilter) {
        filterPaymentsByMember();
        return;
    }
    
    // Otherwise use existing method filter logic
    loadPayments();
}
```

**Pattern rationale:** This ensures pagination works correctly with both filters. The member filter takes precedence because it's more specific.

**Verify:**
1. Filter by a member with many payments (>10)
2. Navigate to page 2 using pagination
3. Verify filtered results persist (still showing only that member's payments)
4. Clear filter, paginate - verify server-side pagination works
5. Run syntax check: `node --check "d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\payments.js"`

---

## Final Verification Checklist

After all changes are complete:

1. **Syntax Check:**
   ```powershell
   node --check "d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\payments.js"
   ```
   Expected: No errors

2. **Browser Testing:**
   - Start backend API (if not running)
   - Open Admin panel → Thanh toán page
   - Verify newest payments appear first (sorted by date DESC)
   - Test member filter dropdown:
     - Select member → verify filtering works
     - Paginate filtered results → verify pagination works
     - Clear filter → verify all payments load
   - Test create payment modal:
     - Open modal
     - Select member → verify invoice dropdown populates with only that member's unpaid invoices
     - Verify Pending (🟡) and Overdue (🔴) indicators show
     - Create payment → verify success
   - Check browser console for errors

3. **Edge Cases:**
   - Member with no payments - verify empty state shows
   - Member with no unpaid invoices in create modal - verify message shows
   - Very long member names - verify dropdown doesn't break layout
   - Network error during filter - verify error toast shows

4. **Integration:**
   - Verify existing payment method filter still works
   - Verify both filters can work independently
   - Verify pagination works with and without filters

---

## Notes

- **No backend changes required** - all endpoints already exist per exploration findings
- **Defensive coding:** All API responses use `?.` accessor and fallback to `[]`
- **Existing functionality preserved:** Payment method filter, view/delete actions, all existing features remain unchanged
- **Pattern consistency:** All implementations match existing codebase patterns from invoices.js and members.js
- **User experience:** Member selection in create modal now prevents selecting wrong member's invoices
