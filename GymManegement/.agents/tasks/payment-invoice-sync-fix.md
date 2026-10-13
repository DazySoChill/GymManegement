# Payment & Invoice Sync Fix

**Date:** 2026-10-11  
**Issue:** Hóa đơn mới tạo (Pending) không hiện trong trang Thanh Toán  
**Status:** ✅ FIXED

---

## 🐛 Root Cause

**Problem:** Trang "Thanh Toán" CHỈ hiện Payment records (đã thanh toán)

**Flow hiện tại:**
1. Tạo Invoice mới → Status = `Pending` (chưa thanh toán)
2. Invoice lưu trong Invoice table
3. **Payment chưa được tạo** (vì chưa thanh toán!)
4. Trang Thanh Toán load từ Payment table → **Không thấy Invoice Pending**

**Kết quả:**
- Admin tạo invoice mới
- Invoice không hiện trong trang Thanh Toán
- Admin không biết cần thanh toán invoice nào
- Data "lệch nhau" giữa Hóa Đơn và Thanh Toán

---

## ✅ Solution

### Redesign Trang Thanh Toán với 2 Sections:

**Section 1: ⏳ Hóa Đơn Chưa Thanh Toán (Pending)**
- Load từ `/api/Invoice/status/Pending`
- Hiện tất cả invoices chờ thanh toán
- Nút "💵 Thanh toán" cho mỗi invoice

**Section 2: ✅ Lịch Sử Thanh Toán**
- Load từ `/api/Payment` (như cũ)
- Hiện tất cả payment records đã hoàn thành
- Filter by member, payment method

---

## 🔧 Implementation

### 1. Thêm Pending Invoices Section

**Function:** `loadPendingInvoices()`

```javascript
async function loadPendingInvoices() {
    try {
        const pendingInvoices = await apiFetch('/api/Invoice/status/Pending');
        
        if (!pendingInvoices || pendingInvoices.length === 0) {
            // Show empty state
            return;
        }
        
        // Render table with pending invoices
        // Each row has "💵 Thanh toán" button
        pendingInvoices.forEach(inv => {
            const isOverdue = new Date(inv.dueDate) < new Date();
            html += `
                <tr>
                    <td>${inv.invoiceId}</td>
                    <td>${inv.memberName}</td>
                    <td>${formatCurrency(inv.totalAmount)}</td>
                    <td>${formatDate(inv.invoiceDate)}</td>
                    <td ${isOverdue ? 'style="color: red;"' : ''}>${formatDate(inv.dueDate)}</td>
                    <td>${escapeHtml(inv.description || '-')}</td>
                    <td>
                        <button onclick="showPayInvoiceModal(${inv.invoiceId}, ${inv.memberId}, ${inv.totalAmount})">
                            💵 Thanh toán
                        </button>
                    </td>
                </tr>
            `;
        });
    }
}
```

**Features:**
- Hiện invoice ID, member, amount, dates, description
- Highlight overdue invoices (màu đỏ + ⚠️)
- Nút "Thanh toán" cho mỗi invoice

---

### 2. Payment Modal for Invoice

**Function:** `showPayInvoiceModal(invoiceId, memberId, amount)`

```javascript
async function showPayInvoiceModal(invoiceId, memberId, amount) {
    // 1. Load invoice & member details
    const [invoice, members] = await Promise.all([
        apiFetch(`/api/Invoice/${invoiceId}`),
        apiFetch('/api/Member?pageNumber=1&pageSize=1000')
    ]);
    
    // 2. Show modal with pre-filled data:
    //    - Member name (readonly)
    //    - Invoice ID & description (readonly)
    //    - Amount (readonly, pre-filled from invoice)
    //    - Payment method (dropdown: Cash, Card, QR, Bank, MoMo, ZaloPay)
    //    - Payment date (date picker, default = today)
    //    - Transaction ID (optional text field)
    
    // 3. On submit:
    //    a) Create Payment record
    //    b) Update Invoice status → Paid
    //    c) Reload both sections
}
```

**Workflow:**
1. User clicks "💵 Thanh toán" on pending invoice
2. Modal shows với invoice details pre-filled
3. User chọn payment method & date
4. Click "✅ Xác Nhận Thanh Toán"
5. Backend:
   - `POST /api/Payment` → Create payment record
   - `PUT /api/Invoice/{id}/status` → Update invoice status = Paid
6. Frontend:
   - Success toast
   - Reload pending invoices (invoice biến mất từ section 1)
   - Reload payment history (payment mới hiện trong section 2)

---

### 3. Update Page Structure

**Before:**
```html
<div class="card">
    <h2>Quản lý Thanh Toán</h2>
    <button>➕ Ghi nhận thanh toán</button>
    <table><!-- Payment records only --></table>
</div>
```

**After:**
```html
<!-- Section 1: Pending Invoices -->
<div class="card">
    <h2>⏳ Hóa Đơn Chưa Thanh Toán (Pending)</h2>
    <table id="pendingInvoicesContainer">
        <!-- Invoice ID, Member, Amount, Due Date, Description, [Thanh toán] -->
    </table>
</div>

<!-- Section 2: Payment History -->
<div class="card">
    <h2>✅ Lịch Sử Thanh Toán</h2>
    <button>➕ Ghi nhận thanh toán</button>
    <table><!-- Payment records --></table>
</div>
```

---

## 🎬 User Flow

### Scenario: Admin tạo invoice và thanh toán

**Step 1: Tạo Invoice**
1. Vào trang **Hóa Đơn**
2. Click **"Tạo Hóa Đơn"**
3. Chọn member, gói tập, số tiền
4. Click **"Tạo Hóa Đơn"**
5. ✅ Invoice được tạo với status = `Pending`

**Step 2: Thanh Toán**
1. Vào trang **Thanh Toán**
2. ✅ **Thấy invoice mới trong section "⏳ Hóa Đơn Chưa Thanh Toán"**
3. Click nút **"💵 Thanh toán"**
4. Modal hiện ra với invoice details pre-filled
5. Chọn phương thức: **"Cash"**
6. Click **"✅ Xác Nhận Thanh Toán"**
7. ✅ Payment record được tạo
8. ✅ Invoice status → `Paid`
9. ✅ Invoice biến mất từ section "Pending"
10. ✅ Payment hiện trong section "Lịch Sử Thanh Toán"

---

## 📊 Data Flow

### Before (Broken):
```
Tạo Invoice (Pending) → Invoice table
                        ↓
                   Payment page: ❌ KHÔNG THẤY (chỉ load Payment table)
```

### After (Fixed):
```
Tạo Invoice (Pending) → Invoice table
                        ↓
                   Payment page Section 1: ✅ THẤY (load Invoice/status/Pending)
                        ↓
              Click "💵 Thanh toán" → Modal
                        ↓
              POST /api/Payment + PUT /api/Invoice/status
                        ↓
                   Invoice status = Paid → Biến mất từ Section 1
                   Payment record → Hiện trong Section 2
```

---

## 🧪 Testing

### Test 1: Pending Invoice Appears
1. Tạo invoice mới (status = Pending)
2. Vào trang **Thanh Toán**
3. ✅ **Expected:** Invoice hiện trong section "⏳ Hóa Đơn Chưa Thanh Toán"

### Test 2: Pay Invoice Flow
1. Click **"💵 Thanh toán"** trên invoice pending
2. ✅ Modal hiện với invoice details
3. Chọn payment method: **Cash**
4. Click **"✅ Xác Nhận Thanh Toán"**
5. ✅ **Expected:**
   - Success toast
   - Invoice biến mất từ section 1
   - Payment hiện trong section 2

### Test 3: Overdue Invoice Highlight
1. Tạo invoice với `dueDate` < today
2. Vào trang **Thanh Toán**
3. ✅ **Expected:** Due date màu đỏ + ⚠️ icon

### Test 4: Empty State
1. Thanh toán tất cả invoices
2. ✅ **Expected:** Section 1 hiện "Không có hóa đơn chưa thanh toán"

---

## 📝 Files Modified

1. **`wwwroot/js/payments.js`**
   - Added: `loadPendingInvoices()` function
   - Added: `showPayInvoiceModal()` function
   - Modified: `renderPayments()` - added pending invoices section
   - Lines: ~90 lines added

---

## ✅ Benefits

| Aspect | Before | After |
|--------|--------|-------|
| Invoice visibility | ❌ Không thấy pending | ✅ Thấy ngay khi tạo |
| Payment flow | ⚠️ Phải vào Hóa Đơn | ✅ Thanh toán trực tiếp |
| Data sync | ❌ Lệch nhau | ✅ Đồng bộ real-time |
| User experience | ⚠️ Confusing | ✅ Clear workflow |
| Overdue tracking | ❌ Không highlight | ✅ Màu đỏ + ⚠️ |

---

## 🎯 Summary

**Problem:** Hóa đơn mới không hiện trong Thanh Toán

**Solution:** 
1. ✅ Thêm section "Hóa Đơn Chưa Thanh Toán"
2. ✅ Load pending invoices từ API
3. ✅ Nút "Thanh toán" cho mỗi invoice
4. ✅ Modal thanh toán với pre-filled data
5. ✅ Create payment + update invoice status
6. ✅ Reload cả 2 sections sau khi thanh toán

**Result:** Data đồng bộ, workflow rõ ràng, UX tốt hơn! 🎉

---

**All changes complete! Test với Ctrl+F5 refresh!** 🚀
