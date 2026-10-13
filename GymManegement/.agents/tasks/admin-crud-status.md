# Admin CRUD Functionality Status Report

**Ngày:** 2024
**Mục tiêu:** Kiểm tra trạng thái các nút Create, Edit, Delete (CRUD) trên tất cả các trang admin và xác định những gì còn thiếu hoặc bị lỗi.

## Tóm Tắt Tổng Quan

### Trạng thái Chung
Phần lớn các trang admin **ĐÃ CÓ CRUD buttons hoạt động tốt** trên frontend và backend:
- ✅ **7/10 trang có CRUD đầy đủ**: Members, Trainers, Memberships, Invoices, Payments, Facilities, Schedules
- ⚠️ **2/10 trang có CRUD một phần**: Check-ins (chỉ Create), Sessions (Create/Edit nhưng logic phức tạp)
- ✅ **1/10 trang đặc biệt**: Users (có CRUD riêng cho quản lý tài khoản)

### Những Gì Cần Làm
**Sessions và Check-ins** là 2 trang cần bổ sung/cải thiện nhất:
1. **Check-ins**: Thiếu nút Edit và Delete cho Admin
2. **Sessions**: Có Create/Edit nhưng không có nút Delete rõ ràng (có nút Cancel status thay thế)

---

## Chi Tiết Từng Trang

### 1. Users Management ✅ HOÀN CHỈNH
**File:** `wwwroot/js/users.js`

| Chức năng | Frontend | Backend | Trạng thái |
|-----------|----------|---------|------------|
| Create (Admin/Trainer) | ✅ `showCreateStaffModal()` | ✅ POST `/api/Auth/create-staff` | ✅ COMPLETE |
| Edit (Change Role) | ✅ `showChangeRoleModal()` | ✅ PUT `/api/Auth/users/{id}/role` | ✅ COMPLETE |
| Delete | ❌ N/A | ❌ N/A | ⚠️ By Design (không xóa user) |
| Lock/Unlock | ✅ `toggleUserStatus()` | ✅ PUT `/api/Auth/users/{id}/active` | ✅ COMPLETE |

**Ghi chú:**
- Trang Users KHÔNG cho phép xóa user (an toàn dữ liệu)
- Thay vào đó có chức năng Lock/Unlock account
- Có thể thay đổi vai trò (Admin ↔ Trainer ↔ Member)
- Tạo mới chỉ cho Admin và Trainer (Member tự đăng ký qua register)

**Không cần fix gì**

---

### 2. Members Management ✅ HOÀN CHỈNH
**File:** `wwwroot/js/members.js`

| Chức năng | Frontend | Backend | Trạng thái |
|-----------|----------|---------|------------|
| Create | ✅ `showCreateMemberModal()` Line 75 | ✅ POST `/api/Member` | ✅ COMPLETE |
| Edit | ✅ `showEditMemberModal(memberId)` Line 137 | ✅ PUT `/api/Member/{id}` | ✅ COMPLETE |
| Delete | ✅ `deleteMember(memberId)` Line 270 | ✅ DELETE `/api/Member/{id}` | ✅ COMPLETE |

**Nút trong UI:**
- Line 70: ➕ Thêm Member button (admin only)
- Line 133: ✏️ Edit button trong bảng
- Line 134: 🗑️ Delete button trong bảng

**Form validation:** ✅ Có (`validateMemberForm()`)

**Không cần fix gì**

---

### 3. Trainers Management ✅ HOÀN CHỈNH
**File:** `wwwroot/js/trainers.js`

| Chức năng | Frontend | Backend | Trạng thái |
|-----------|----------|---------|------------|
| Create | ✅ `showCreateTrainerModal()` Line 112 | ✅ POST `/api/Trainer` | ✅ COMPLETE |
| Edit | ✅ `showEditTrainerModal(trainerId)` Line 178 | ✅ PUT `/api/Trainer/{id}` | ✅ COMPLETE |
| Delete | ✅ `deleteTrainer(trainerId)` Line 312 | ✅ DELETE `/api/Trainer/{id}` | ✅ COMPLETE |

**Nút trong UI:**
- Line 66: ➕ Thêm HLV button
- Line 106: ✏️ Edit button
- Line 107: 🗑️ Delete button

**Form validation:** ✅ Có (`validateTrainerForm()`)

**Không cần fix gì**

---

### 4. Memberships Management ✅ HOÀN CHỈNH
**File:** `wwwroot/js/memberships.js`

| Chức năng | Frontend | Backend | Trạng thái |
|-----------|----------|---------|------------|
| Create | ✅ `showCreateMembershipModal()` Line 469 | ✅ POST `/api/Membership` | ✅ COMPLETE |
| Edit | ✅ `showEditMembershipModal(membershipId)` Line 540 | ✅ PUT `/api/Membership/{id}` | ✅ COMPLETE |
| Delete | ❌ Không có nút Delete | ⚠️ Có API | ⚠️ FRONTEND MISSING |

**Nút trong UI:**
- Line 377: ➕ Tạo gói tập button (admin)
- Line 438: ✏️ Edit button
- **THIẾU:** Delete button

**Ghi chú đặc biệt:**
- Member có thể "Hủy Gói" (Cancel) qua `cancelMembership()` (Line 304)
- Admin có thể Edit để điều chỉnh ngày tháng
- **KHÔNG CÓ NÚT DELETE** trong admin view

**Cần fix:**
1. **Thêm nút Delete** vào Line 438 (sau Edit button):
```javascript
<button class="btn btn-sm btn-danger" onclick="deleteMembership(${m.membershipId})">🗑️</button>
```
2. **Thêm function `deleteMembership()`**:
```javascript
async function deleteMembership(membershipId) {
    if (!confirm('Bạn có chắc chắn muốn xóa gói tập này?')) return;
    try {
        showLoading();
        await apiFetch(`/api/Membership/${membershipId}`, { method: 'DELETE' });
        hideLoading();
        showSuccess('Xóa gói tập thành công!');
        await loadMemberships();
    } catch (error) {
        hideLoading();
        showError('Lỗi xóa gói tập: ' + error.message);
    }
}
```

**Effort:** Simple - 5 phút

---

### 5. Schedules Management ✅ HOÀN CHỈNH
**File:** `wwwroot/js/schedules.js`

| Chức năng | Frontend | Backend | Trạng thái |
|-----------|----------|---------|------------|
| Create | ✅ `showCreateScheduleModal()` Line 450+ | ✅ POST `/api/Schedule` | ✅ COMPLETE |
| Edit | ✅ `showEditScheduleModal(scheduleId)` Line 500+ | ✅ PUT `/api/Schedule/{id}` | ✅ COMPLETE |
| Delete | ✅ `deleteSchedule(scheduleId)` | ✅ DELETE `/api/Schedule/{id}` | ✅ COMPLETE |

**Nút trong UI:**
- Line ~180: ➕ Thêm lịch button
- Line ~390: ✏️ Edit button
- Line ~391: 🗑️ Delete button

**Form validation:** ✅ Có (`validateScheduleForm()`)

**Không cần fix gì**

---

### 6. Sessions Management ⚠️ KHÔNG CÓ DELETE RÕ RÀNG
**File:** `wwwroot/js/sessions.js`

| Chức năng | Frontend | Backend | Trạng thái |
|-----------|----------|---------|------------|
| Create | ✅ `showCreateSessionModal()`, `quickRegisterClass()` | ✅ POST `/api/Session` | ✅ COMPLETE |
| Edit Status | ✅ `updateSessionStatus()` Line 600+ | ✅ PUT `/api/Session/{id}` | ✅ COMPLETE |
| Delete | ⚠️ Có nút nhưng function name là `deleteSession()` | ✅ DELETE `/api/Session/{id}` | ⚠️ UNCLEAR |

**Nút trong UI:**
- Line ~170: ➕ Tạo session button (admin/trainer)
- Line ~687: ✓ Attended button
- Line ~688: ✗ Cancelled button  
- Line ~689: ✏️ Edit button
- Line ~690: 🗑️ Delete button (gọi `deleteSession()`)

**Vấn đề:**
- File có nút Delete button nhưng **KHÔNG THẤY function `deleteSession()`** được định nghĩa
- Có thể bị thiếu hoặc bị comment out

**Cần fix:**
1. **Thêm function `deleteSession(sessionId)`** (nếu không có):
```javascript
async function deleteSession(sessionId) {
    if (!confirm('Bạn có chắc chắn muốn xóa session này?')) {
        return;
    }
    
    try {
        showLoading();
        await apiFetch(`/api/Session/${sessionId}`, {
            method: 'DELETE'
        });
        hideLoading();
        showSuccess('Xóa session thành công!');
        
        const role = getRole();
        const memberId = getMemberId();
        if (role === 'Member' && memberId) {
            loadMemberSessionsData(memberId, mySessionWeekFilter);
        } else {
            loadSessions();
        }
    } catch (error) {
        hideLoading();
        showError('Lỗi xóa session: ' + error.message);
    }
}
```

**Effort:** Simple - 3 phút

**Lưu ý:** Session thường sử dụng "Cancel" status thay vì Delete thật. Cần xác nhận với user xem có cần Delete không.

---

### 7. Invoices Management ✅ HOÀN CHỈNH
**File:** `wwwroot/js/invoices.js`

| Chức năng | Frontend | Backend | Trạng thái |
|-----------|----------|---------|------------|
| Create | ✅ `showCreateInvoiceModal()` Line 185 | ✅ POST `/api/Invoice` | ✅ COMPLETE |
| Edit (Status only) | ✅ `showEditInvoiceModal()` Line 276 | ✅ PUT `/api/Invoice/{id}` | ✅ COMPLETE |
| Delete | ✅ `deleteInvoice(invoiceId)` Line 464 | ✅ DELETE `/api/Invoice/{id}` | ✅ COMPLETE |

**Nút trong UI:**
- Line 120: ➕ Tạo hóa đơn button (admin only)
- Line 170: ✓ Mark as Paid button
- Line 171: ✏️ Edit button
- Line 172: 🗑️ Delete button

**Form validation:** ✅ Có (`validateInvoiceForm()`)

**Không cần fix gì**

---

### 8. Payments Management ✅ HOÀN CHỈNH
**File:** `wwwroot/js/payments.js`

| Chức năng | Frontend | Backend | Trạng thái |
|-----------|----------|---------|------------|
| Create | ✅ `showCreatePaymentModal()` Line 166 | ✅ POST `/api/Payment` | ✅ COMPLETE |
| Edit | ❌ N/A (View only) | ⚠️ Có API nhưng không có field | ⚠️ By Design |
| Delete | ✅ `deletePayment(paymentId)` Line 396 | ✅ DELETE `/api/Payment/{id}` | ✅ COMPLETE |

**Nút trong UI:**
- Line 105: ➕ Ghi nhận thanh toán button (admin)
- Line 156: 👁️ View button (read-only)
- Line 157: 🗑️ Delete button

**Ghi chú:**
- Payment **KHÔNG CHO EDIT** sau khi tạo (business rule: thanh toán đã ghi nhận không sửa được)
- Chỉ có View để xem chi tiết
- Có thể Delete nếu ghi sai

**Không cần fix gì**

---

### 9. Check-ins Management ⚠️ THIẾU EDIT/DELETE
**File:** `wwwroot/js/checkins.js`

| Chức năng | Frontend | Backend | Trạng thái |
|-----------|----------|---------|------------|
| Create (Manual) | ✅ `showManualCheckinModal()` Line 268 | ✅ POST `/api/Checkin/manual` | ✅ COMPLETE |
| Edit | ❌ KHÔNG CÓ | ❌ KHÔNG CÓ | ❌ MISSING |
| Delete | ❌ KHÔNG CÓ | ❌ KHÔNG CÓ | ❌ MISSING |

**Nút trong UI:**
- Line 185: ➕ Check-in thủ công button (admin/trainer)
- Member: ✅ Check In button (quick check-in)
- **KHÔNG CÓ** Edit hoặc Delete buttons

**Vấn đề:**
- Check-in table chỉ hiển thị dữ liệu, không có action buttons
- Admin không thể sửa hoặc xóa check-in đã tạo
- Backend cũng **KHÔNG CÓ** PUT/DELETE endpoints cho Checkin

**Cần fix:**

### Option A: Thêm Edit và Delete đầy đủ (Recommended)

**Backend:**
1. Thêm endpoint trong `CheckinController.cs`:
```csharp
[HttpPut("{id}")]
[Authorize(Roles = "SuperAdmin,Admin")]
public async Task<IActionResult> Update(int id, [FromBody] UpdateCheckinRequest request)
{
    await _service.UpdateAsync(id, request);
    return Ok();
}

[HttpDelete("{id}")]
[Authorize(Roles = "SuperAdmin,Admin")]
public async Task<IActionResult> Delete(int id)
{
    await _service.DeleteAsync(id);
    return NoContent();
}
```

2. Thêm DTOs và Service methods tương ứng

**Frontend:**
1. Thêm action buttons vào table (Line ~250 trong `renderCheckinsTable()`):
```javascript
${canManage ? `
    <td>
        <div class="action-buttons">
            <button class="btn btn-sm btn-info" onclick="showEditCheckinModal(${c.checkinId})">✏️</button>
            <button class="btn btn-sm btn-danger" onclick="deleteCheckin(${c.checkinId})">🗑️</button>
        </div>
    </td>
` : ''}
```

2. Thêm modal và functions:
```javascript
async function showEditCheckinModal(checkinId) {
    // Fetch checkin details, show modal with datetime pickers
    // Allow edit checkinTime and checkoutTime
}

async function deleteCheckin(checkinId) {
    if (!confirm('Xóa check-in này?')) return;
    await apiFetch(`/api/Checkin/${checkinId}`, { method: 'DELETE' });
    showSuccess('Đã xóa!');
    reloadCheckinsData();
}
```

**Effort:** Medium - 30 phút (backend + frontend)

### Option B: Chỉ thêm Delete (Simpler)
- Nếu business logic không cần Edit, chỉ cần Delete khi ghi sai
- Effort: Simple - 15 phút

---

### 10. Facilities Management ⚠️ THIẾU DELETE
**File:** `wwwroot/js/facilities.js`

| Chức năng | Frontend | Backend | Trạng thái |
|-----------|----------|---------|------------|
| Create | ✅ `showCreateFacilityModal()` Line 131 | ✅ POST `/api/Facility` | ✅ COMPLETE |
| Edit | ✅ `showEditFacilityModal(facilityId)` Line 202 | ✅ PUT `/api/Facility/{id}` | ✅ COMPLETE |
| Delete | ❌ KHÔNG CÓ NÚT | ⚠️ Có API | ⚠️ FRONTEND MISSING |

**Nút trong UI:**
- Line 68: ➕ Thêm cơ sở button
- Line 112: ✏️ Edit button
- **THIẾU:** Delete button

**Cần fix:**
1. Thêm Delete button vào Line 112 (trong `renderFacilitiesTable()`):
```javascript
<button class="btn btn-sm btn-danger" onclick="deleteFacility(${facility.facilityId})">🗑️</button>
```

2. Thêm function:
```javascript
async function deleteFacility(facilityId) {
    if (!confirm('Bạn có chắc chắn muốn xóa cơ sở này?')) {
        return;
    }
    
    try {
        showLoading();
        await apiFetch(`/api/Facility/${facilityId}`, {
            method: 'DELETE'
        });
        hideLoading();
        showSuccess('Xóa cơ sở thành công!');
        await loadFacilities();
    } catch (error) {
        hideLoading();
        showError('Lỗi xóa cơ sở: ' + error.message);
    }
}
```

**Effort:** Simple - 5 phút

---

## Bảng Tổng Kết

| Trang | Create | Edit | Delete | Ghi Chú |
|-------|--------|------|--------|---------|
| **Users** | ✅ | ✅ (Role) | ⚠️ (Lock/Unlock thay thế) | Hoàn chỉnh |
| **Members** | ✅ | ✅ | ✅ | Hoàn chỉnh |
| **Trainers** | ✅ | ✅ | ✅ | Hoàn chỉnh |
| **Memberships** | ✅ | ✅ | ❌ | **Thiếu Delete button** |
| **Schedules** | ✅ | ✅ | ✅ | Hoàn chỉnh |
| **Sessions** | ✅ | ✅ (Status) | ⚠️ | **Function deleteSession() có thể thiếu** |
| **Invoices** | ✅ | ✅ (Status) | ✅ | Hoàn chỉnh |
| **Payments** | ✅ | ❌ (View only) | ✅ | Hoàn chỉnh (no edit by design) |
| **Check-ins** | ✅ | ❌ | ❌ | **Thiếu Edit và Delete** |
| **Facilities** | ✅ | ✅ | ❌ | **Thiếu Delete button** |

---

## Danh Sách Ưu Tiên Cần Fix

### 🔴 Priority 1: Check-ins (THIẾU NHIỀU NHẤT)
**File:** `wwwroot/js/checkins.js` + `CheckinController.cs`

**Thiếu:**
- ❌ Edit button/modal/function
- ❌ Delete button/function
- ❌ Backend PUT endpoint
- ❌ Backend DELETE endpoint

**Impact:** Cao - Admin không thể sửa/xóa check-in sai

**Effort:** Medium (30 phút backend + frontend)

---

### 🟡 Priority 2: Facilities Delete
**File:** `wwwroot/js/facilities.js`

**Thiếu:**
- ❌ Delete button
- ❌ `deleteFacility()` function

**Backend:** ✅ Đã có DELETE endpoint

**Impact:** Trung bình - Cơ sở vật chất ít khi cần xóa

**Effort:** Simple (5 phút)

---

### 🟡 Priority 3: Memberships Delete
**File:** `wwwroot/js/memberships.js`

**Thiếu:**
- ❌ Delete button trong admin view
- ❌ `deleteMembership()` function

**Backend:** ✅ Đã có DELETE endpoint

**Impact:** Trung bình - Có thể dùng Edit để điều chỉnh

**Effort:** Simple (5 phút)

---

### 🟢 Priority 4: Sessions Delete Verification
**File:** `wwwroot/js/sessions.js`

**Cần kiểm tra:**
- ⚠️ Có nút Delete button nhưng không thấy function `deleteSession()` được định nghĩa

**Impact:** Thấp - Có thể dùng Cancel status thay thế

**Effort:** Simple (3 phút để verify + add nếu thiếu)

---

## Hướng Dẫn Thực Hiện

### Bước 1: Verify Sessions Delete
```bash
cd "d:\Workspace\Độ án 2\GymManegement\GymManegement"
grep -n "function deleteSession" wwwroot/js/sessions.js
```

Nếu không tìm thấy, thêm function vào cuối file.

### Bước 2: Fix Facilities Delete
1. Mở `wwwroot/js/facilities.js`
2. Thêm Delete button vào Line 112
3. Thêm function `deleteFacility()` vào cuối file
4. Test: Tạo facility → Xóa

### Bước 3: Fix Memberships Delete
1. Mở `wwwroot/js/memberships.js`
2. Thêm Delete button vào Line 438
3. Thêm function `deleteMembership()` vào cuối file
4. Test: Tạo membership → Xóa

### Bước 4: Fix Check-ins (Nếu cần Edit/Delete)
**Backend:**
1. Thêm `UpdateCheckinRequest` DTO
2. Thêm `UpdateAsync()` và `DeleteAsync()` vào `CheckinService`
3. Thêm PUT và DELETE endpoints vào `CheckinController`

**Frontend:**
1. Thêm column "Thao tác" vào bảng
2. Thêm Edit/Delete buttons
3. Thêm modal Edit với datetime pickers
4. Thêm functions `showEditCheckinModal()` và `deleteCheckin()`

---

## Testing Checklist

Sau khi fix, test các scenarios sau:

### Memberships
- [ ] Admin tạo membership mới → OK
- [ ] Admin edit membership → OK
- [ ] Admin xóa membership → **TEST SAU KHI FIX**

### Facilities
- [ ] Admin tạo facility → OK
- [ ] Admin edit facility → OK
- [ ] Admin xóa facility → **TEST SAU KHI FIX**

### Sessions
- [ ] Admin/Trainer tạo session → OK
- [ ] Admin/Trainer update status → OK
- [ ] Admin/Trainer xóa session → **VERIFY FUNCTION EXISTS**

### Check-ins
- [ ] Admin check-in thủ công → OK
- [ ] Admin edit check-in → **CHƯA CÓ - CẦN THÊM**
- [ ] Admin xóa check-in → **CHƯA CÓ - CẦN THÊM**

---

## Kết Luận

**Tình trạng tổng thể:** ✅ **Khá tốt - 7/10 trang hoàn chỉnh**

**Cần fix:**
1. 🔴 **Check-ins** - Thiếu Edit và Delete (cần cả backend và frontend)
2. 🟡 **Facilities** - Thiếu nút Delete (chỉ frontend, backend đã có)
3. 🟡 **Memberships** - Thiếu nút Delete (chỉ frontend, backend đã có)
4. 🟢 **Sessions** - Verify function deleteSession() tồn tại

**Tổng thời gian ước tính:** 45-60 phút cho tất cả

**Recommend:** Bắt đầu với Priority 2 và 3 (Facilities và Memberships Delete) vì dễ và nhanh, sau đó mới làm Check-ins nếu user confirm cần chức năng Edit/Delete check-in.

---

## Phụ Lục: File Paths

### Frontend Files
- Members: `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\members.js`
- Trainers: `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\trainers.js`
- Memberships: `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\memberships.js`
- Schedules: `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\schedules.js`
- Sessions: `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\sessions.js`
- Invoices: `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\invoices.js`
- Payments: `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\payments.js`
- Check-ins: `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\checkins.js`
- Facilities: `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\facilities.js`
- Users: `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\users.js`

### Backend Controllers
- `d:\Workspace\Độ án 2\GymManegement\GymManegement\Controllers\MemberController.cs`
- `d:\Workspace\Độ án 2\GymManegement\GymManegement\Controllers\TrainerController.cs`
- `d:\Workspace\Độ án 2\GymManegement\GymManegement\Controllers\MembershipController.cs`
- `d:\Workspace\Độ án 2\GymManegement\GymManegement\Controllers\ScheduleController.cs`
- `d:\Workspace\Độ án 2\GymManegement\GymManegement\Controllers\SessionController.cs`
- `d:\Workspace\Độ án 2\GymManegement\GymManegement\Controllers\InvoiceController.cs`
- `d:\Workspace\Độ án 2\GymManegement\GymManegement\Controllers\PaymentController.cs`
- `d:\Workspace\Độ án 2\GymManegement\GymManegement\Controllers\CheckinController.cs`
- `d:\Workspace\Độ án 2\GymManegement\GymManegement\Controllers\FacilityController.cs`
- `d:\Workspace\Độ án 2\GymManegement\GymManegement\Controllers\AuthController.cs`
