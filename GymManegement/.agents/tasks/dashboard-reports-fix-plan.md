# Dashboard & Reports Fix Plan

## Tổng quan

Dashboard và Reports đang sử dụng PascalCase field names (Data, Total, CheckinTime, v.v.) nhưng backend đã chuyển sang camelCase JSON serialization. Nhiều file frontend khác đã được fix (members, trainers, facilities, schedules, invoices, memberships) nhưng dashboard.js và reports.js chưa được fix.

## Root Cause

Backend JSON serialization đã chuyển từ PascalCase sang camelCase:
- **Cũ:** `{ Data: [...], Total: 10, PageNumber: 1 }`
- **Mới:** `{ data: [...], total: 10, pageNumber: 1 }`

Dashboard và Reports vẫn đang dùng pattern cũ → Dữ liệu không hiển thị hoặc hiển thị sai.

---

## FEAT 1: Fix dashboard.js - Admin Dashboard

### File: `wwwroot/js/dashboard.js`

### Issue 1.1: loadActiveMembersCount - PascalCase (Line 69)
**Hiện tại:**
```javascript
const count = result?.Total || 0;
```

**Sửa thành:**
```javascript
const count = result?.total || result?.Total || 0;
```

**Lý do:** Backend trả về `{ data: [...], total: 10 }` với camelCase

---

### Issue 1.2: loadMonthlyRevenue - PascalCase (Line 96-97)
**Hiện tại:**
```javascript
const payments = result?.Data || [];
...
.reduce((sum, p) => sum + (p.Amount || 0), 0);
```

**Sửa thành:**
```javascript
const payments = result?.data || result?.Data || [];
...
.reduce((sum, p) => sum + (p.amount || p.Amount || 0), 0);
```

**Lý do:** Backend trả về camelCase: `data`, `amount`

---

### Issue 1.3: loadMonthlyRevenue - PaymentDate field (Line 99)
**Hiện tại:**
```javascript
const paymentDate = new Date(p.PaymentDate);
```

**Sửa thành:**
```javascript
const paymentDate = new Date(p.paymentDate || p.PaymentDate);
```

**Lý do:** Backend trả về `paymentDate` (camelCase)

---

### Issue 1.4: loadTodayCheckins - PascalCase (Line 127)
**Hiện tại:**
```javascript
const checkins = result?.Data || [];
```

**Sửa thành:**
```javascript
const checkins = result?.data || result?.Data || [];
```

---

### Issue 1.5: loadTodayCheckins - CheckinTime field (Line 131)
**Hiện tại:**
```javascript
const checkinDate = new Date(c.CheckinTime).toISOString().split('T')[0];
```

**Sửa thành:**
```javascript
const checkinDate = new Date(c.checkinTime || c.CheckinTime).toISOString().split('T')[0];
```

**Lý do:** Backend trả về `checkinTime` (camelCase)

---

### Issue 1.6: loadActiveFacilities - PascalCase (Line 154)
**Hiện tại:**
```javascript
const count = result?.Total || 0;
```

**Sửa thành:**
```javascript
const count = result?.total || result?.Total || 0;
```

---

### Issue 1.7: loadActiveFacilities - Logic sai (Line 150-154)
**Vấn đề:** Đang đếm TẤT CẢ facilities, không filter theo status Active

**Hiện tại:**
```javascript
async function loadActiveFacilities() {
    try {
        const result = await apiFetch('/api/Facility?pageNumber=1&pageSize=1');
        const count = result?.total || result?.Total || 0;
        document.getElementById('activeFacilitiesCount').textContent = count;
```

**Sửa thành:**
```javascript
async function loadActiveFacilities() {
    try {
        // Fetch all facilities and filter by Active status
        const result = await apiFetch('/api/Facility?pageNumber=1&pageSize=1000');
        const facilities = result?.data || result?.Data || [];
        
        // Count only Active status facilities
        const activeCount = facilities.filter(f => 
            (f.status || f.Status) === 'Active'
        ).length;
        
        document.getElementById('activeFacilitiesCount').textContent = activeCount;
```

**Lý do:** Backend không có filter status parameter, phải filter ở client-side

---

### Issue 1.8: renderRecentCheckinsTable - PascalCase (Line 592-597)
**Hiện tại:**
```javascript
if (!data || !data.Data || data.Data.length === 0) {
...
const sortedItems = [...data.Data].sort((a, b) => {
    return new Date(b.CheckinTime) - new Date(a.CheckinTime);
});
```

**Sửa thành:**
```javascript
const items = data?.data || data?.Data || [];
if (items.length === 0) {
    container.innerHTML = '<p class="empty-state-text">Chưa có check-in nào</p>';
    return;
}

const sortedItems = [...items].sort((a, b) => {
    return new Date(b.checkinTime || b.CheckinTime) - new Date(a.checkinTime || a.CheckinTime);
});
```

---

### Issue 1.9: renderRecentCheckinsTable - MemberName, CheckinTime, CheckoutTime (Line 600-618)
**Hiện tại:**
```javascript
const memberName = item.MemberName || `Member #${item.MemberId || '-'}`;

const hasCheckedOut = item.CheckoutTime && 
                     item.CheckoutTime !== '' && 
                     !item.CheckoutTime.startsWith('0001-01-01');

html += `<tr>
    <td>${escapeHtml(memberName)}</td>
    <td>${formatDateTime(item.CheckinTime)}</td>
    <td>${hasCheckedOut ? formatDateTime(item.CheckoutTime) : 'Chưa ra'}</td>
```

**Sửa thành:**
```javascript
const memberName = item.memberName || item.MemberName || `Member #${item.memberId || item.MemberId || '-'}`;

const checkoutTime = item.checkoutTime || item.CheckoutTime;
const hasCheckedOut = checkoutTime && 
                     checkoutTime !== '' && 
                     !checkoutTime.startsWith('0001-01-01');

html += `<tr>
    <td>${escapeHtml(memberName)}</td>
    <td>${formatDateTime(item.checkinTime || item.CheckinTime)}</td>
    <td>${hasCheckedOut ? formatDateTime(checkoutTime) : 'Chưa ra'}</td>
```

---

## FEAT 2: Fix dashboard.js - Trainer Dashboard

### File: `wwwroot/js/dashboard.js`

### Issue 2.1: getTrainerId - PascalCase (Line 190)
**Hiện tại:**
```javascript
const trainers = result?.Data || [];
```

**Sửa thành:**
```javascript
const trainers = result?.data || result?.Data || [];
```

---

### Issue 2.2: getTrainerId - Email, TrainerId fields (Line 192-198)
**Hiện tại:**
```javascript
const trainer = trainers.find(t => 
    t.Email && t.Email.toLowerCase() === user.email.toLowerCase()
);

if (trainer) {
    _cachedTrainerId = trainer.TrainerId;
    return trainer.TrainerId;
```

**Sửa thành:**
```javascript
const trainer = trainers.find(t => {
    const trainerEmail = t.email || t.Email;
    return trainerEmail && trainerEmail.toLowerCase() === user.email.toLowerCase();
});

if (trainer) {
    _cachedTrainerId = trainer.trainerId || trainer.TrainerId;
    return trainer.trainerId || trainer.TrainerId;
```

---

### Issue 2.3: loadTrainerTodayClasses - PascalCase (Line 249)
**Hiện tại:**
```javascript
const schedules = result?.Data || [];
```

**Sửa thành:**
```javascript
const schedules = result?.data || result?.Data || [];
```

---

### Issue 2.4: loadTrainerTodayClasses - TrainerId, StartTime (Line 253-256)
**Hiện tại:**
```javascript
const todayClasses = schedules.filter(s => {
    const scheduleDate = new Date(s.StartTime).toISOString().split('T')[0];
    return s.TrainerId === trainerId && scheduleDate === today;
});
```

**Sửa thành:**
```javascript
const todayClasses = schedules.filter(s => {
    const scheduleDate = new Date(s.startTime || s.StartTime).toISOString().split('T')[0];
    const scheduleTrainerId = s.trainerId || s.TrainerId;
    return scheduleTrainerId === trainerId && scheduleDate === today;
});
```

---

### Issue 2.5: loadTrainerMonthlyAttended - PascalCase (Line 267)
**Hiện tại:**
```javascript
const schedules = result?.Data || [];
```

**Sửa thành:**
```javascript
const schedules = result?.data || result?.Data || [];
```

---

### Issue 2.6: loadTrainerMonthlyAttended - TrainerId, ScheduleId (Line 269-270)
**Hiện tại:**
```javascript
const trainerSchedules = schedules.filter(s => s.TrainerId === trainerId);
const scheduleIds = trainerSchedules.map(s => s.ScheduleId);
```

**Sửa thành:**
```javascript
const trainerSchedules = schedules.filter(s => {
    const scheduleTrainerId = s.trainerId || s.TrainerId;
    return scheduleTrainerId === trainerId;
});
const scheduleIds = trainerSchedules.map(s => s.scheduleId || s.ScheduleId);
```

---

### Issue 2.7: loadTrainerMonthlyAttended - Status, RegistrationDate (Line 287-293)
**Hiện tại:**
```javascript
const attended = sessionArray.filter(session => {
    if (session.Status !== 'Attended') return false;
    
    const regDate = new Date(session.RegistrationDate);
    return regDate.getMonth() === currentMonth && 
           regDate.getFullYear() === currentYear;
});
```

**Sửa thành:**
```javascript
const attended = sessionArray.filter(session => {
    const status = session.status || session.Status;
    if (status !== 'Attended') return false;
    
    const regDate = new Date(session.registrationDate || session.RegistrationDate);
    return regDate.getMonth() === currentMonth && 
           regDate.getFullYear() === currentYear;
});
```

---

### Issue 2.8: loadTrainerTodayCheckins - PascalCase (Line 311)
**Hiện tại:**
```javascript
const checkins = result?.Data || [];
```

**Sửa thành:**
```javascript
const checkins = result?.data || result?.Data || [];
```

---

### Issue 2.9: loadTrainerTodayCheckins - CheckinTime (Line 315)
**Hiện tại:**
```javascript
const checkinDate = new Date(c.CheckinTime).toISOString().split('T')[0];
```

**Sửa thành:**
```javascript
const checkinDate = new Date(c.checkinTime || c.CheckinTime).toISOString().split('T')[0];
```

---

### Issue 2.10: loadTodaySchedulesList - PascalCase (Line 327)
**Hiện tại:**
```javascript
const schedules = result?.Data || [];
```

**Sửa thành:**
```javascript
const schedules = result?.data || result?.Data || [];
```

---

### Issue 2.11: loadTodaySchedulesList - TrainerId, StartTime (Line 331-334)
**Hiện tại:**
```javascript
const todaySchedules = schedules.filter(s => {
    const scheduleDate = new Date(s.StartTime).toISOString().split('T')[0];
    return s.TrainerId === trainerId && scheduleDate === today;
});
```

**Sửa thành:**
```javascript
const todaySchedules = schedules.filter(s => {
    const scheduleDate = new Date(s.startTime || s.StartTime).toISOString().split('T')[0];
    const scheduleTrainerId = s.trainerId || s.TrainerId;
    return scheduleTrainerId === trainerId && scheduleDate === today;
});
```

---

### Issue 2.12: loadTodaySchedulesList - ClassName, StartTime, EndTime, FacilityName (Line 345-350)
**Hiện tại:**
```javascript
html += `
    <tr>
        <td>${escapeHtml(schedule.ClassName)}</td>
        <td>${formatTime(schedule.StartTime)} - ${formatTime(schedule.EndTime)}</td>
        <td>${escapeHtml(schedule.FacilityName || '-')}</td>
    </tr>
`;
```

**Sửa thành:**
```javascript
html += `
    <tr>
        <td>${escapeHtml(schedule.className || schedule.ClassName)}</td>
        <td>${formatTime(schedule.startTime || schedule.StartTime)} - ${formatTime(schedule.endTime || schedule.EndTime)}</td>
        <td>${escapeHtml(schedule.facilityName || schedule.FacilityName || '-')}</td>
    </tr>
`;
```

---

## FEAT 3: Fix reports.js - Revenue & Members Reports

### File: `wwwroot/js/reports.js`

### Issue 3.1: loadRevenueDetails - Response fields (Line 118-124)
**Vấn đề:** Backend trả về object chứa array, không phải array trực tiếp

**Backend response từ ReportService.cs:**
```csharp
return new { Month = month, Year = year, Data = rows };
```

**Hiện tại:**
```javascript
const details = await apiFetch(`/api/Report/revenue/detail?month=${month}&year=${year}`);

if (!details || details.length === 0) {
```

**Sửa thành:**
```javascript
const response = await apiFetch(`/api/Report/revenue/detail?month=${month}&year=${year}`);
const details = response?.data || response?.Data || [];

if (details.length === 0) {
```

**Lý do:** Backend trả về `{ month, year, data: [...] }` không phải array trực tiếp

---

### Issue 3.2: loadRevenueDetails - Field names trong detail items (Line 128-133)
**Backend SQL trả về:** `InvoiceId, InvoiceDate, TotalAmount, Status, PackageName, MemberName`

**Hiện tại:**
```javascript
details.forEach(item => {
    html += `
        <tr>
            <td>${formatDate(item.date)}</td>
            <td>${item.count}</td>
            <td>${formatCurrency(item.totalAmount)}</td>
```

**Phân tích:** Có vẻ như đây là aggregated report (theo ngày), không phải chi tiết từng invoice. Backend SQL trả về invoice details nhưng frontend expect daily aggregation. Cần kiểm tra lại backend logic.

**Sửa tạm thời (support cả 2 formats):**
```javascript
details.forEach(item => {
    // Support both aggregated format (date, count, totalAmount) 
    // and detailed format (invoiceDate, totalAmount)
    const displayDate = item.date || item.invoiceDate || item.InvoiceDate;
    const displayCount = item.count || '-';
    const displayAmount = item.totalAmount || item.TotalAmount || 0;
    
    html += `
        <tr>
            <td>${formatDate(displayDate)}</td>
            <td>${displayCount}</td>
            <td>${formatCurrency(displayAmount)}</td>
```

**Note:** Backend SQL hiện tại trả về invoice details, KHÔNG phải aggregation theo ngày. Có thể cần sửa backend hoặc thay đổi table headers.

---

### Issue 3.3: loadExpiringMemberships - Response wrapper (Line 143)
**Vấn đề:** Backend trả về object chứa array, không phải array trực tiếp

**Backend response từ ReportService.cs:**
```csharp
return new { DaysAhead = daysAhead, Data = rows };
```

**Hiện tại:**
```javascript
const data = await apiFetch(`/api/Report/expiring-soon?daysAhead=${daysAhead}`);

if (!data || data.length === 0) {
```

**Sửa thành:**
```javascript
const response = await apiFetch(`/api/Report/expiring-soon?daysAhead=${daysAhead}`);
const data = response?.data || response?.Data || [];

if (data.length === 0) {
```

---

### Issue 3.4: loadExpiringMemberships - Field names (Line 151-157)
**Backend:** Trả về Membership entities với Member navigation. Membership entity có: `MembershipId, MemberId, PackageName, Price, StartDate, EndDate, Member { FullName }`

**Hiện tại (frontend expects):**
```javascript
html += `
    <tr>
        <td>${escapeHtml(item.memberName || '-')}</td>
        <td>${escapeHtml(item.packageName)}</td>
        <td>${formatDate(item.endDate)}</td>
        <td><span class="badge badge-warning">${item.daysRemaining} ngày</span></td>
```

**Vấn đề:** 
- `memberName` không có trong Membership entity (phải dùng `Member.FullName`)
- `daysRemaining` không có trong entity (phải tính client-side)

**Sửa thành:**
```javascript
data.forEach(item => {
    // Backend returns Membership entity with camelCase
    const memberName = item.member?.fullName || item.Member?.FullName || '-';
    const packageName = item.packageName || item.PackageName;
    const endDate = item.endDate || item.EndDate;
    
    // Calculate days remaining
    const today = new Date();
    const end = new Date(endDate);
    const daysRemaining = Math.ceil((end - today) / (1000 * 60 * 60 * 24));
    
    html += `
        <tr>
            <td>${escapeHtml(memberName)}</td>
            <td>${escapeHtml(packageName)}</td>
            <td>${formatDate(endDate)}</td>
            <td><span class="badge badge-warning">${daysRemaining} ngày</span></td>
```

**Note:** Backend cần sửa để include Member navigation hoặc trả về DTO với memberName và daysRemaining đã tính sẵn.

---

### Issue 3.5: loadMembersReport - Response type (Line 173)
**Backend SQL trả về:** `{ TotalMembers, ActiveMembers, InactiveMembers }` - 1 object duy nhất, KHÔNG phải array

**Hiện tại:**
```javascript
const data = await apiFetch('/api/Report/members');

if (!data || data.length === 0) {
    container.innerHTML = '<p class="empty-state-text">Không có dữ liệu members</p>';
    return;
}

let html = '<table><thead><tr><th>ID</th><th>Họ tên</th><th>Email</th><th>Trạng thái</th></tr></thead><tbody>';
data.forEach(member => {
```

**Vấn đề:** Backend trả về summary stats, KHÔNG phải member list. Frontend đang expect member list.

**2 options:**

**Option A: Sửa backend để trả về member list**
Backend SQL sửa thành:
```sql
SELECT MemberId, FullName, Email, IsDeleted 
FROM Members 
WHERE IsDeleted = 0
ORDER BY MemberId
```

**Option B: Sửa frontend để hiển thị stats**
```javascript
const stats = await apiFetch('/api/Report/members');

if (!stats) {
    container.innerHTML = '<p class="empty-state-text">Không có dữ liệu members</p>';
    return;
}

// Display as stats cards instead of table
const totalMembers = stats.totalMembers || stats.TotalMembers || 0;
const activeMembers = stats.activeMembers || stats.ActiveMembers || 0;
const inactiveMembers = stats.inactiveMembers || stats.InactiveMembers || 0;

container.innerHTML = `
    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-label">Tổng Members</div>
            <div class="stat-value">${totalMembers}</div>
        </div>
        <div class="stat-card">
            <div class="stat-label">Members Hoạt Động</div>
            <div class="stat-value">${activeMembers}</div>
        </div>
        <div class="stat-card">
            <div class="stat-label">Members Đã Xóa</div>
            <div class="stat-value">${inactiveMembers}</div>
        </div>
    </div>
`;
```

**Recommendation:** Chọn Option B (sửa frontend) vì backend stats có ý nghĩa hơn cho Reports page.

---

## Verification Steps

### Sau khi fix dashboard.js:

1. **Test Admin Dashboard:**
```bash
# Login as Admin
# Navigate to Dashboard
# Verify:
- Tổng Members Hoạt Động: Hiển thị số chính xác
- Doanh Thu Tháng Này: Hiển thị số tiền
- Check-in Hôm Nay: Hiển thị số check-ins hôm nay
- Cơ Sở Vật Chất Hoạt Động: Chỉ đếm facilities có status = "Active"
- Recent Checkins table: Hiển thị member names, thời gian vào/ra đúng
```

2. **Test Trainer Dashboard:**
```bash
# Login as Trainer
# Navigate to Dashboard
# Verify:
- Class Hôm Nay: Hiển thị số class của trainer
- Học Viên Đã Attend: Hiển thị số đúng
- Check-in Hôm Nay: Hiển thị tổng số check-ins
- Lịch Dạy Hôm Nay table: Hiển thị class name, thời gian, phòng
```

3. **Check Browser Console:**
```bash
# Open DevTools (F12) → Console tab
# Should see NO errors like:
- "Cannot read property 'Data' of undefined"
- "Cannot read property 'CheckinTime' of undefined"
```

---

### Sau khi fix reports.js:

1. **Test Revenue Details:**
```bash
# Navigate to Báo Cáo & Thống Kê
# Chọn tháng/năm → Click "Xem"
# Verify:
- Table hiển thị dữ liệu (có thể là daily aggregation hoặc invoice details)
- Doanh Thu summary hiển thị đúng
- Export Excel hoạt động
```

2. **Test Expiring Memberships:**
```bash
# Nhập "7" vào Số ngày trước → Click "Xem"
# Verify:
- Table hiển thị members có gói sắp hết hạn
- Member name, Package name, End date, Days remaining hiển thị đúng
```

3. **Test Members Report:**
```bash
# Verify:
- Stats cards hiển thị: Tổng Members, Members Hoạt Động, Members Đã Xóa
- Số liệu chính xác
```

---

## Summary of Changes

### dashboard.js:
- **Admin Dashboard:** 9 field fixes (total, data, checkinTime, checkoutTime, memberName, amount, paymentDate, status filter)
- **Trainer Dashboard:** 12 field fixes (data, email, trainerId, startTime, className, facilityName, status, registrationDate)
- **Pattern:** Defensive accessors `item.field || item.Field || fallback`

### reports.js:
- **Revenue Details:** Response wrapper fix + field mapping
- **Expiring Memberships:** Response wrapper fix + Member navigation + daysRemaining calculation
- **Members Report:** Switch from table to stats cards (backend mismatch)
- **Pattern:** Handle nested response wrappers `{ data: [...] }`

### Total Changes:
- **21 field name fixes** (PascalCase → camelCase with fallbacks)
- **3 response wrapper fixes** (unwrap `{ data: [...] }`)
- **1 logic fix** (Active facilities filter)
- **1 UI restructure** (Members report table → stats cards)

---

## Backend Issues Found (Optional Follow-up)

### 1. Revenue Detail endpoint mismatch
**Current:** Returns invoice list with fields: `InvoiceId, InvoiceDate, TotalAmount, Status, PackageName, MemberName`
**Frontend expects:** Daily aggregation with fields: `date, count, totalAmount`

**Suggestion:** Create separate endpoints:
- `/api/Report/revenue/invoices` - Detailed invoice list
- `/api/Report/revenue/daily` - Daily aggregation

### 2. Expiring Memberships missing fields
**Current:** Returns Membership entities
**Missing:** `memberName`, `daysRemaining` fields

**Suggestion:** Create ReportDTO:
```csharp
public class ExpiringMembershipDto {
    public string MemberName { get; set; }
    public string PackageName { get; set; }
    public DateTime EndDate { get; set; }
    public int DaysRemaining { get; set; }
}
```

### 3. Members Report endpoint mismatch
**Current:** Returns stats object `{ TotalMembers, ActiveMembers, InactiveMembers }`
**Frontend expected:** Member list

**Resolution:** Frontend sẽ được sửa để hiển thị stats (đúng hơn cho Reports page)

---

## Files to Modify

1. **d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\dashboard.js**
   - Admin dashboard functions (lines 69-618)
   - Trainer dashboard functions (lines 190-350)

2. **d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\reports.js**
   - All report loading functions (lines 100-220)

---

## Deployment

**No build required** - Frontend only changes.

1. Save modified JS files
2. Hard refresh browser (Ctrl+F5) to clear cache
3. Test each dashboard and report function

---

## Testing Checklist

### Dashboard.js - Admin
- [ ] Tổng Members count hiển thị
- [ ] Doanh thu tháng này hiển thị
- [ ] Check-in hôm nay hiển thị
- [ ] Cơ sở vật chất chỉ đếm Active
- [ ] Recent checkins table có data
- [ ] Member names hiển thị đúng
- [ ] Thời gian vào/ra hiển thị đúng

### Dashboard.js - Trainer
- [ ] Class hôm nay count hiển thị
- [ ] Học viên attend count hiển thị
- [ ] Check-in hôm nay count hiển thị
- [ ] Lịch dạy hôm nay table có data
- [ ] Class name, time, room hiển thị đúng

### Reports.js
- [ ] Active members count hiển thị
- [ ] Monthly revenue hiển thị
- [ ] Revenue details table có data
- [ ] Expiring memberships table có data
- [ ] Member names trong expiring table đúng
- [ ] Days remaining tính đúng
- [ ] Members report stats cards hiển thị
- [ ] Export Excel hoạt động

### Console Errors
- [ ] Không có lỗi "Cannot read property 'Data'"
- [ ] Không có lỗi "Cannot read property 'CheckinTime'"
- [ ] Không có lỗi field undefined

---

## Notes

1. **Defensive Programming:** Tất cả field accessors dùng pattern `item.field || item.Field || fallback` để support cả PascalCase và camelCase.

2. **Response Wrappers:** Report endpoints trả về `{ data: [...] }` chứ không phải array trực tiếp. Phải unwrap trước khi loop.

3. **Active Facilities Filter:** Backend không có status parameter nên phải fetch all và filter ở client-side.

4. **Members Report:** Frontend expect member list nhưng backend trả về stats. Sửa frontend để hiển thị stats cards (hợp lý hơn cho Reports page).

5. **Browser Cache:** Nhớ hard refresh (Ctrl+F5) sau khi deploy để clear cached JS files.
