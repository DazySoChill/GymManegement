# Invoice Membership Dropdown Redesign - Requirements Analysis

## Current Understanding

### User Request (Translated & Clarified)
Bạn muốn sửa dropdown "Gói tập" khi tạo/sửa hóa đơn thành 2 sections:

1. **Gói Tập Có Sẵn (Available Packages)**
   - Đây là các gói gym định sẵn (Basic, Advanced, VIP, Annual)
   - Hiện tại trong `memberships.js` có constant `AVAILABLE_PACKAGES`
   - Member có thể mua trực tiếp

2. **Gói Tập Hiện Tại Của Member (Member's Purchased Packages)**
   - Khi chọn member → Show các memberships chưa thanh toán của member đó
   - Các membership đã mua nhưng chưa paid

### Proposed Workflow Change
**Current:**
- Member mua gói → Tạo Payment (Pending) + Membership (active ngay)

**Desired:**
- Member mua gói → Tạo Payment (Pending) + Membership (Pending/Inactive)
- Admin duyệt Payment → Payment.status = Paid
- Membership becomes Active sau khi Payment = Paid

---

## Questions to Clarify

### Q1: Membership Creation Timing
Khi member mua gói, có tạo Membership ngay không?
- **Option A:** Tạo Membership ngay (status=Pending), chờ Payment approved
- **Option B:** Chỉ tạo Payment, chờ approved rồi mới tạo Membership

### Q2: Invoice → Membership Link
Invoice có link đến Membership như hiện tại không?
- **Current:** Invoice.MembershipId (nullable)
- **Desired:** ???

### Q3: "Gói Tập Có Sẵn" in Invoice
Khi tạo invoice với "Gói Tập Có Sẵn", có tạo Membership không?
- Hay chỉ là invoice phí thường (locker, PT, etc.)?

---

## Proposed Solution (Based on Best Understanding)

### Frontend Changes Needed

#### 1. Extract AVAILABLE_PACKAGES to Shared Location
**Current:** Defined in `memberships.js` only
**Change:** Move to `shared.js` or inline in invoices.js

```javascript
const AVAILABLE_PACKAGES = [
  { id: 'basic', name: 'Gói Cơ Bản', price: 500000, durationDays: 30, description: '1 tháng - Sử dụng tất cả thiết bị' },
  { id: 'advanced', name: 'Gói Nâng Cao', price: 1200000, durationDays: 90, description: '3 tháng - Bao gồm 2 buổi PT/tháng' },
  { id: 'vip', name: 'Gói VIP', price: 2000000, durationDays: 180, description: '6 tháng - Không giới hạn PT + dinh dưỡng' },
  { id: 'annual', name: 'Gói Năm', price: 3500000, durationDays: 365, description: '12 tháng - Tất cả dịch vụ cao cấp' }
];
```

#### 2. Redesign Invoice Create Modal

**Member Selection:**
```html
<select id="memberId" onchange="updateInvoicePackageDropdown()">
  <option value="">-- Chọn thành viên --</option>
  <!-- Load all members -->
</select>
```

**Package/Membership Selection:**
```html
<select id="packageSelection">
  <optgroup label="📦 Gói Tập Có Sẵn">
    <option value="package:basic">Gói Cơ Bản - 500,000đ (30 ngày)</option>
    <option value="package:advanced">Gói Nâng Cao - 1,200,000đ (90 ngày)</option>
    <option value="package:vip">Gói VIP - 2,000,000đ (180 ngày)</option>
    <option value="package:annual">Gói Năm - 3,500,000đ (365 ngày)</option>
  </optgroup>
  <optgroup label="💳 Gói Đã Mua (Chưa Thanh Toán)" id="memberMembershipsGroup">
    <!-- Populated when member selected -->
    <!-- Show memberships with Payment.status=Pending -->
  </optgroup>
</select>
```

**Amount Field (Auto-fill):**
```html
<input type="number" id="totalAmount" readonly>
<!-- Auto-filled when package selected -->
```

#### 3. JavaScript Logic

```javascript
async function updateInvoicePackageDropdown() {
    const memberId = document.getElementById('memberId').value;
    const packageSelect = document.getElementById('packageSelection');
    
    // Clear member memberships group
    const memberGroup = document.getElementById('memberMembershipsGroup');
    memberGroup.innerHTML = '';
    
    if (!memberId) {
        return;
    }
    
    try {
        showLoading();
        // Fetch member's memberships with pending payments
        const memberships = await apiFetch(`/api/Membership/member/${memberId}`);
        hideLoading();
        
        const pendingMemberships = memberships.filter(m => {
            // Logic to find pending memberships
            // Need to check if there's a Pending payment for this membership
            return m.daysRemaining > 0 || /* has pending payment */;
        });
        
        pendingMemberships.forEach(ms => {
            const option = document.createElement('option');
            option.value = `membership:${ms.membershipId}`;
            option.textContent = `${ms.packageName} - ${formatCurrency(ms.price)} - ${ms.daysRemaining > 0 ? 'Active' : 'Pending'}`;
            memberGroup.appendChild(option);
        });
        
    } catch (error) {
        console.error('Error loading memberships:', error);
    }
}

// Auto-fill amount when package selected
document.getElementById('packageSelection').addEventListener('change', (e) => {
    const value = e.target.value;
    
    if (value.startsWith('package:')) {
        // Extract package id
        const packageId = value.split(':')[1];
        const pkg = AVAILABLE_PACKAGES.find(p => p.id === packageId);
        if (pkg) {
            document.getElementById('totalAmount').value = pkg.price;
        }
    } else if (value.startsWith('membership:')) {
        // Extract membership id
        const membershipId = parseInt(value.split(':')[1]);
        // Find membership price
        const ms = /* find from loaded memberships */;
        if (ms) {
            document.getElementById('totalAmount').value = ms.price;
        }
    }
});
```

---

## Backend Changes Needed (If Any)

### API Endpoints to Check/Add

1. **GET /api/Membership/member/{memberId}**
   - ✅ Already exists
   - Returns all memberships for member

2. **GET /api/Payment/membership/{membershipId}**
   - ❓ Check if exists
   - To find if membership has pending payment

3. **Membership Status Logic**
   - Currently: Active immediately when created?
   - Need: Pending until payment approved?

---

## Implementation Plan

### Phase 1: Frontend Quick Fix (No Backend Changes)
**Duration:** 30 minutes

1. Add AVAILABLE_PACKAGES to invoices.js
2. Redesign dropdown with 2 optgroups
3. Add member → package cascade
4. Auto-fill amount

**Limitations:**
- Cannot truly filter "chưa thanh toán" memberships
- Just shows all member's memberships

### Phase 2: Full Solution (With Backend)
**Duration:** 2-3 hours

1. Backend: Add Membership.Status (Pending/Active)
2. Backend: Link Payment → Membership properly
3. Backend: Approve payment → Activate membership
4. Frontend: Filter Pending memberships only

---

## Decision Needed

**Which approach do you prefer?**

**Option A: Quick Frontend-Only Fix (30 min)**
- Dropdown có 2 sections
- Chọn member → Load memberships
- Amount auto-fill
- ⚠️ Không filter được "chưa thanh toán" chính xác

**Option B: Full Backend + Frontend (2-3 hours)**
- Workflow approval đúng
- Membership có status
- Filter chính xác
- ✅ Giải pháp đầy đủ

**Option C: Phân Tách**
- Tôi làm Phase 1 trước (quick fix)
- Bạn test xem có đủ không
- Nếu cần Phase 2 thì làm sau

---

## Recommendations

Tôi đề xuất **Option C** vì:
1. Bạn có thể test UI ngay
2. Nếu backend logic cần thay đổi, làm riêng workflow
3. Tránh risk phá vỡ existing functionality

**Bạn chọn option nào?**
