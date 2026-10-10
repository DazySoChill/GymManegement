# Web UI Audit Report
**Date:** 2026-10-09  
**Purpose:** Audit api.js endpoints vs actual backend controllers after SQL2 rebuild

---

## Executive Summary

✅ **GOOD NEWS**: Hầu hết các endpoint trong `api.js` đã khớp với backend controllers!

❌ **CRITICAL ISSUES** tìm thấy:
1. **Checkin endpoints** - sai route (`/api/checkins` vs `/api/checkin`)
2. **Invoice endpoints** - thiếu API trong backend (overdue, updateStatus, exportPdf)
3. **Payment endpoints** - thiếu API trong backend (updateStatus)
4. **Session endpoints** - thiếu API trong backend (updateStatus)
5. **Auth endpoints** - sai route và thiếu API (forgotPassword, resetPassword, refreshToken, profile)
6. **Export endpoints** - KHÔNG có API nào cho export trong backend
7. **Membership renew** - thiếu API trong backend

---

## Detailed Audit: Frontend vs Backend

### ✅ 1. Members API - **MATCHED**
| Frontend (api.js) | Backend Controller | Status |
|-------------------|-------------------|--------|
| `GET /api/members` | `GET /api/Member` | ✅ OK |
| `GET /api/members/{id}` | `GET /api/Member/{id}` | ✅ OK |
| `POST /api/members` | `POST /api/Member` | ✅ OK |
| `PUT /api/members/{id}` | `PUT /api/Member/{id}` | ✅ OK |
| `DELETE /api/members/{id}` | `DELETE /api/Member/{id}` | ✅ OK |
| `GET /api/members/export?format=` | ❌ MISSING | ❌ NO API |

**Issue**: Export endpoint không tồn tại trong backend.

---

### ❌ 2. Memberships API - **PARTIAL MATCH**
| Frontend (api.js) | Backend Controller | Status |
|-------------------|-------------------|--------|
| `GET /api/memberships/member/{id}` | `GET /api/Membership/member/{memberId}` | ✅ OK |
| `GET /api/memberships/member/{id}/active` | `GET /api/Membership/member/{memberId}/active` | ✅ OK |
| `POST /api/memberships` | `POST /api/Membership` | ✅ OK |
| `PUT /api/memberships/{id}` | `PUT /api/Membership/{id}` | ✅ OK |
| `POST /api/memberships/{id}/renew` | ❌ MISSING | ❌ NO API |
| `GET /api/memberships/export?format=` | ❌ MISSING | ❌ NO API |

**Issues**:
- Renew endpoint không có trong backend
- Export endpoint không tồn tại

---

### ✅ 3. Trainers API - **MATCHED**
| Frontend (api.js) | Backend Controller | Status |
|-------------------|-------------------|--------|
| `GET /api/trainers` | `GET /api/Trainer` | ✅ OK |
| `GET /api/trainers/{id}` | `GET /api/Trainer/{id}` | ✅ OK |
| `POST /api/trainers` | `POST /api/Trainer` | ✅ OK |
| `PUT /api/trainers/{id}` | `PUT /api/Trainer/{id}` | ✅ OK |
| `DELETE /api/trainers/{id}` | `DELETE /api/Trainer/{id}` | ✅ OK |
| `GET /api/trainers/export?format=` | ❌ MISSING | ❌ NO API |

**Issue**: Export endpoint không tồn tại.

---

### ✅ 4. Facilities API - **MATCHED**
| Frontend (api.js) | Backend Controller | Status |
|-------------------|-------------------|--------|
| `GET /api/facilities` | `GET /api/Facility` | ✅ OK |
| `GET /api/facilities/{id}` | `GET /api/Facility/{id}` | ✅ OK |
| `GET /api/facilities/active` | ❌ MISSING | ❌ NO API |
| `POST /api/facilities` | `POST /api/Facility` | ✅ OK |
| `PUT /api/facilities/{id}` | `PUT /api/Facility/{id}` | ✅ OK |
| `DELETE /api/facilities/{id}` | `DELETE /api/Facility/{id}` | ✅ OK |
| `GET /api/facilities/export?format=` | ❌ MISSING | ❌ NO API |

**Issues**:
- `/active` endpoint không có
- Export endpoint không tồn tại

---

### ✅ 5. Schedules API - **MATCHED**
| Frontend (api.js) | Backend Controller | Status |
|-------------------|-------------------|--------|
| `GET /api/schedules` | `GET /api/Schedule` | ✅ OK |
| `GET /api/schedules/{id}` | `GET /api/Schedule/{id}` | ✅ OK |
| `POST /api/schedules` | `POST /api/Schedule` | ✅ OK |
| `PUT /api/schedules/{id}` | `PUT /api/Schedule/{id}` | ✅ OK |
| `DELETE /api/schedules/{id}` | `DELETE /api/Schedule/{id}` | ✅ OK |
| `GET /api/schedules/export?format=` | ❌ MISSING | ❌ NO API |

**Issue**: Export endpoint không tồn tại.

---

### ❌ 6. Sessions API - **PARTIAL MATCH**
| Frontend (api.js) | Backend Controller | Status |
|-------------------|-------------------|--------|
| `GET /api/sessions` | `GET /api/Session` | ✅ OK |
| `GET /api/sessions/{id}` | `GET /api/Session/{id}` | ✅ OK |
| `POST /api/sessions` | `POST /api/Session` | ✅ OK |
| `PUT /api/sessions/{id}/status` | ❌ MISSING | ❌ NO API |
| `DELETE /api/sessions/{id}` | `DELETE /api/Session/{id}` | ✅ OK |
| `GET /api/sessions/export?format=` | ❌ MISSING | ❌ NO API |

**Issues**:
- `PUT /status` endpoint không có (backend chỉ có `PUT /{id}` full update)
- Export endpoint không tồn tại

---

### ❌ 7. Checkins API - **WRONG ROUTE**
| Frontend (api.js) | Backend Controller | Status |
|-------------------|-------------------|--------|
| `GET /api/checkins` | `GET /api/Checkin` | ❌ WRONG |
| `POST /api/checkins` | `POST /api/Checkin/manual` | ❌ WRONG |
| `POST /api/checkins/qr` | `POST /api/Checkin/qr` | ❌ WRONG |
| `GET /api/checkins/export?format=` | ❌ MISSING | ❌ NO API |

**CRITICAL**: Frontend dùng `/api/checkins` (số nhiều) nhưng backend là `/api/Checkin` (số ít)!

**Backend actual routes:**
- `GET /api/Checkin`
- `GET /api/Checkin/{id}`
- `GET /api/Checkin/member/{memberId}`
- `GET /api/Checkin/date-range?from=&to=`
- `POST /api/Checkin/manual`
- `POST /api/Checkin/qr`

---

### ❌ 8. Invoices API - **PARTIAL MATCH**
| Frontend (api.js) | Backend Controller | Status |
|-------------------|-------------------|--------|
| `GET /api/invoices` | `GET /api/Invoice` | ✅ OK |
| `GET /api/invoices/{id}` | `GET /api/Invoice/{id}` | ✅ OK |
| `GET /api/invoices/member/{id}` | `GET /api/Invoice/member/{memberId}` | ✅ OK |
| `GET /api/invoices/overdue` | `GET /api/Invoice/overdue` | ✅ OK |
| `POST /api/invoices` | `POST /api/Invoice` | ✅ OK |
| `PUT /api/invoices/{id}/status` | ❌ MISSING | ❌ NO API |
| `GET /api/invoices/export?format=` | ❌ MISSING | ❌ NO API |
| `GET /api/invoices/{id}/pdf` | ❌ MISSING | ❌ NO API |

**Issues**:
- `PUT /status` endpoint không có (backend chỉ có `PUT /{id}` full update)
- Export endpoints không tồn tại
- PDF export không có

---

### ❌ 9. Payments API - **PARTIAL MATCH**
| Frontend (api.js) | Backend Controller | Status |
|-------------------|-------------------|--------|
| `GET /api/payments/invoice/{id}` | `GET /api/Payment/invoice/{invoiceId}` | ✅ OK |
| `POST /api/payments` | `POST /api/Payment` | ✅ OK |
| `PUT /api/payments/{id}/status` | ❌ MISSING | ❌ NO API |
| `GET /api/payments/export?format=` | ❌ MISSING | ❌ NO API |

**Issues**:
- `PUT /status` endpoint không có (backend chỉ có `PUT /{id}` full update)
- Export endpoint không tồn tại

---

### ❌ 10. Auth API - **MAJOR MISMATCH**
| Frontend (api.js) | Backend Controller | Status |
|-------------------|-------------------|--------|
| `POST /api/auth/login` | `POST /api/Auth/login` | ✅ OK |
| `POST /api/auth/register` | `POST /api/Auth/register` | ✅ OK |
| `POST /api/auth/change-password` | `POST /api/Auth/change-password` | ✅ OK |
| `POST /api/auth/forgot-password` | ❌ MISSING | ❌ NO API |
| `POST /api/auth/reset-password` | ❌ MISSING | ❌ NO API |
| `POST /api/auth/refresh` | ❌ MISSING | ❌ NO API |
| `GET /api/auth/profile` | ❌ WRONG ROUTE | ❌ `/me` |
| `PUT /api/auth/profile` | ❌ MISSING | ❌ NO API |

**Backend actual routes:**
- `POST /api/Auth/login`
- `POST /api/Auth/register`
- `POST /api/Auth/create-staff`
- `POST /api/Auth/change-password`
- `GET /api/Auth/users`
- `PUT /api/Auth/users/{id}/active`
- `GET /api/Auth/me` ← Frontend expects `/profile`

**CRITICAL**: 
- Frontend dùng `/api/auth/profile` nhưng backend là `/api/Auth/me`
- Forgot/reset password không có trong backend (đã bỏ theo SQL2 simplification)
- Refresh token không có
- Update profile không có

---

### ❌ 11. Reports API - **PARTIAL MATCH**
| Frontend (api.js) | Backend Controller | Status |
|-------------------|-------------------|--------|
| `GET /api/reports/active-members` | `GET /api/Report/active-members` | ✅ OK |
| `GET /api/reports/revenue?month=&year=` | `GET /api/Report/revenue?month=&year=` | ✅ OK |
| `GET /api/reports/revenue/detail?month=&year=` | `GET /api/Report/revenue/detail?month=&year=` | ✅ OK |
| `GET /api/reports/expiring-soon?daysAhead=` | ❌ MISSING | ❌ NO API |
| `GET /api/reports/{type}/export?format=` | ❌ MISSING | ❌ NO API |

**Issues**:
- Expiring-soon endpoint không có
- Export endpoint không tồn tại

---

## Critical Issues Summary

### 🔴 BLOCKER (Must Fix to Make UI Work)
1. **Checkin route mismatch**: `/api/checkins` → `/api/Checkin`
2. **Auth profile route**: `/api/auth/profile` → `/api/Auth/me`

### 🟡 HIGH PRIORITY (Features Won't Work)
3. All **Export endpoints** (12 endpoints across all modules)
4. **Status update endpoints**: Invoice, Payment, Session (3 endpoints)
5. **Membership renew** endpoint
6. **Forgot/Reset password** endpoints (if needed)
7. **Facility active filter** endpoint
8. **Report expiring-soon** endpoint

### 🟢 LOW PRIORITY (Nice to Have)
9. **Auth refresh token** endpoint
10. **Update profile** endpoint

---

## Root Cause Analysis

### Why This Happened:
1. **SQL2 rebuild** đơn giản hóa database → Một số features bị bỏ (OTP, password reset)
2. **Old frontend** được viết cho database cũ với nhiều features hơn
3. **Controller naming**: Backend dùng singular (`/api/Member`) nhưng frontend dùng plural (`/api/members`) → May mắn ASP.NET Core case-insensitive nên hầu hết vẫn work
4. **Export feature** chưa được implement ở backend
5. **Partial update endpoints** (`/status`) chưa có, chỉ có full update

---

## Next Steps - Options for Resolution

Bạn có **4 OPTIONS** để fix Web UI:


---

## OPTION 1: Quick Fix Frontend Only (1-2 hours)
**Approach:** Sửa `api.js` và disable các features chưa có backend

### Changes Needed:
1. **Fix critical routes** (5 mins):
   - `/api/checkins` → `/api/Checkin`
   - `/api/auth/profile` → `/api/Auth/me`

2. **Remove/disable missing features** (30 mins):
   - Comment out all export functions
   - Remove forgot/reset password UI
   - Remove status update buttons
   - Remove renew membership button
   - Remove facility active filter
   - Remove expiring-soon report

3. **Update frontend pages** (1 hour):
   - `js/pages/checkins.js` - fix API calls
   - `js/pages/invoices.js` - remove status update, export, pdf
   - `js/pages/payments.js` - remove status update, export
   - `js/pages/sessions.js` - remove status update
   - `js/pages/memberships.js` - remove renew button
   - `js/pages/facilities.js` - remove active filter
   - `js/pages/reports.js` - remove expiring-soon
   - Remove all export buttons across all pages
   - Fix login page auth profile call

### ✅ Pros:
- Nhanh nhất
- Không touch backend
- Web UI hoạt động ngay với các core features

### ❌ Cons:
- Mất nhiều features (export, status updates, renew, etc.)
- UI có thể trông "incomplete" với buttons bị disable

### Effort: **1-2 hours**
### Risk: **Low**

---

## OPTION 2: Add Missing Backend APIs (3-5 hours)
**Approach:** Implement các APIs còn thiếu vào backend

### Backend Changes Needed:

#### 2.1. Add Export Endpoints (2 hours)
Implement export cho tất cả controllers:
- MemberController: `GET /export?format=excel`
- MembershipController: `GET /export?format=excel`
- TrainerController: `GET /export?format=excel`
- FacilityController: `GET /export?format=excel`
- ScheduleController: `GET /export?format=excel`
- SessionController: `GET /export?format=excel`
- CheckinController: `GET /export?format=excel`
- InvoiceController: `GET /export?format=excel`, `GET /{id}/pdf`
- PaymentController: `GET /export?format=excel`
- ReportController: `GET /{type}/export?format=excel`

**Implementation**: Use ExportService (already exists in BLL)

#### 2.2. Add Status Update Endpoints (1 hour)
- InvoiceController: `PUT /{id}/status`
- PaymentController: `PUT /{id}/status`
- SessionController: `PUT /{id}/status`

#### 2.3. Add Membership Renew (30 mins)
- MembershipController: `POST /{id}/renew`

#### 2.4. Add Facility Active Filter (15 mins)
- FacilityController: `GET /active`

#### 2.5. Add Report Expiring Soon (30 mins)
- ReportController: `GET /expiring-soon?daysAhead=7`

#### 2.6. Add Auth Profile Alias (15 mins)
- AuthController: Add `GET /profile` as alias to `GET /me`

#### 2.7. Fix Checkin Route Alias (15 mins)
- CheckinController: Add route alias for `/api/Checkins`

### Frontend Changes:
- Fix 2 critical routes only (checkins, auth profile) - done by backend aliases

### ✅ Pros:
- Full feature parity
- Web UI hoạt động 100%
- Professional, complete solution
- Export features very useful for business

### ❌ Cons:
- Mất nhiều thời gian hơn
- Phải test lại backend
- Risk của bugs mới

### Effort: **3-5 hours**
### Risk: **Medium**

---

## OPTION 3: Hybrid - Fix Critical + Add Essential APIs (1.5-2 hours)
**Approach:** Fix blockers + add only essential APIs, bỏ nice-to-have

### Backend Changes:
1. **Fix critical routes** (30 mins):
   - AuthController: Add `GET /profile` alias
   - CheckinController: Add route handling for plural

2. **Add essential APIs only** (1 hour):
   - Status updates: Invoice, Payment, Session (`PUT /{id}/status`)
   - Facility active filter (`GET /active`)
   - Membership renew (`POST /{id}/renew`)

### Frontend Changes:
3. **Disable export features** (30 mins):
   - Comment out all export functions in api.js
   - Remove export buttons from all pages
   - Remove forgot/reset password UI
   - Remove expiring-soon report

### ✅ Pros:
- Balance giữa time và features
- Core business features work (status updates, renew)
- Reasonable effort
- Web UI usable ngay

### ❌ Cons:
- Vẫn thiếu export (có thể add sau)
- Thiếu một số reports

### Effort: **1.5-2 hours**
### Risk: **Low-Medium**

---

## OPTION 4: Rebuild Frontend from Scratch (8-12 hours)
**Approach:** Viết lại Web UI hoàn toàn mới, modern stack

### Approach:
- Modern framework: React/Vue.js hoặc vanilla modern JS
- Design system: Bootstrap 5 hoặc Tailwind
- Better UX/UI
- Chỉ build features có trong backend

### ✅ Pros:
- Clean start
- Modern, maintainable code
- No legacy baggage
- Perfect match với backend

### ❌ Cons:
- Mất nhiều thời gian nhất
- Overkill cho project này
- More complex setup

### Effort: **8-12 hours**
### Risk: **High** (scope creep)

---

## RECOMMENDATION: OPTION 3 (Hybrid)

### Why Option 3:
1. ✅ **Balance tốt nhất** giữa time và value
2. ✅ **Core features work**: CRUD, status updates, renewals
3. ✅ **Reasonable effort**: 1.5-2 hours
4. ✅ **Low risk**: Chỉ add simple endpoints
5. ✅ **Practical**: Theo phương châm "đơn giản hiệu quả"
6. ✅ **Incremental**: Export có thể add sau nếu cần

### Implementation Plan for Option 3:

#### Phase A: Backend (1 hour)
1. AuthController: Add `GET /profile` route
2. CheckinController: Add plural route handling  
3. InvoiceController: Add `PUT /{id}/status`
4. PaymentController: Add `PUT /{id}/status`
5. SessionController: Add `PUT /{id}/status`
6. MembershipController: Add `POST /{id}/renew`
7. FacilityController: Add `GET /active`

#### Phase B: Frontend (30 mins)
1. Remove export buttons from all pages
2. Remove forgot/reset password from login page
3. Remove expiring-soon report section
4. Test all CRUD operations

#### Phase C: Testing (30 mins)
1. Test login/profile
2. Test checkin (manual + QR)
3. Test status updates (Invoice, Payment, Session)
4. Test membership renew
5. Test facility active filter

---

## File Changes Needed (Option 3)

### Backend Files to Modify:
1. `Controllers/AuthController.cs` - Add /profile route
2. `Controllers/CheckinController.cs` - Handle plural route
3. `Controllers/InvoiceController.cs` - Add status endpoint
4. `Controllers/PaymentController.cs` - Add status endpoint
5. `Controllers/SessionController.cs` - Add status endpoint
6. `Controllers/MembershipController.cs` - Add renew endpoint
7. `Controllers/FacilityController.cs` - Add active endpoint

### Frontend Files to Modify:
1. `wwwroot/js/api.js` - Comment out export functions
2. `wwwroot/login.html` - Remove forgot password link
3. `wwwroot/js/pages/dashboard.js` - Remove expiring-soon section
4. `wwwroot/js/pages/members.js` - Remove export button
5. `wwwroot/js/pages/trainers.js` - Remove export button
6. `wwwroot/js/pages/facilities.js` - Remove export button
7. `wwwroot/js/pages/schedules.js` - Remove export button
8. `wwwroot/js/pages/sessions.js` - Remove export button
9. `wwwroot/js/pages/checkins.js` - Remove export button
10. `wwwroot/js/pages/invoices.js` - Remove export + PDF buttons
11. `wwwroot/js/pages/payments.js` - Remove export button
12. `wwwroot/js/pages/memberships.js` - Keep as is (has renew)
13. `wwwroot/js/pages/reports.js` - Remove expiring-soon section

---

## Decision Time

**Bạn muốn làm theo OPTION nào?**

- **OPTION 1**: Quick fix frontend only (1-2h, remove features)
- **OPTION 2**: Add all missing APIs (3-5h, full features)  
- **OPTION 3**: Hybrid approach (1.5-2h, core features) ⭐ **RECOMMENDED**
- **OPTION 4**: Rebuild from scratch (8-12h, modern stack)

Hoặc bạn muốn tôi:
- **OPTION 5**: Tự động làm theo OPTION 3 luôn không cần hỏi thêm

---

## Status: WAITING FOR DECISION
