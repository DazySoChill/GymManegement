# Implementation Plan: Admin Frontend for Gym Management System

## Overview
Build admin frontend CRUD interfaces for the Gym Management System. The project is a .NET 8 Web API backend with a vanilla JavaScript SPA frontend served from wwwroot/. The member frontend is already complete; this task adds admin-only management features.

## Architecture Context

### Project Structure
- **Backend**: .NET 8 Web API (Controllers/, API/DTOs/, Service/, DAL/)
- **Frontend**: Vanilla JS SPA in wwwroot/ with hash-based routing
- **API Base**: http://localhost:5250
- **Build**: `dotnet build GymManegement.csproj`
- **Run**: `dotnet run --project GymManegement.csproj`
- **No frontend build step**: JS/CSS are static files, no webpack/vite

### Frontend Patterns
- **SPA routing**: app.js handles hash navigation (#members, #trainers, etc.)
- **Module structure**: Each feature has a js file (members.js, trainers.js, etc.) with:
  - `async renderXXX(container)` - main render function
  - `loadXXX()` - fetch data via API
  - `renderXXXTable(data)` - generate table HTML
  - `renderXXXPagination(data)` - pagination controls
  - `showCreateXXXModal()`, `showEditXXXModal(id)` - CRUD modals
- **API calls**: Use `apiFetch(path, options)` from api.js with JWT authentication
- **Modals**: Inject HTML dynamically, use `.modal.show` CSS class, follow memberships.js pattern
- **Validation**: Client-side validation, show errors in modal, toast on success/failure
- **Role-based access**: Check `getRole() === 'Admin'` before showing management UI

### Available API Endpoints

#### Members (`/api/Member`)
- GET / - list with pagination/search
- GET /{id} - get by ID
- POST / - create (Admin only)
- PUT /{id} - update (Admin only)
- DELETE /{id} - soft delete (SuperAdmin only - likely won't use)
- **DTOs**: FullName, Email, Phone, DateOfBirth, QRCode (auto-generated)

#### Trainers (`/api/Trainer`)
- GET / - list with pagination/search
- GET /{id} - get by ID
- POST / - create (Admin only)
- PUT /{id} - update (Admin only)
- DELETE /{id} - soft delete (SuperAdmin only)
- **DTOs**: FullName, Email, Phone, Specialization

#### Memberships (`/api/Membership`)
- GET / - list with pagination/search
- GET /{id} - get by ID
- GET /member/{memberId} - get by member
- GET /active - active memberships
- POST /purchase - member self-purchase
- POST / - create (Admin only)
- PUT /{id} - update (Admin only)
- DELETE /{id} - soft delete
- POST /{id}/cancel - cancel membership
- **DTOs**: MemberId, PackageName (string, not separate entity), Price, StartDate, EndDate, DaysRemaining (computed)
- **Note**: No separate Package entity - PackageName is just a text field

#### Schedules (`/api/Schedule`)
- GET / - list with pagination/search
- GET /{id} - get by ID
- GET /trainer/{trainerId} - by trainer
- GET /date/{date} - by date
- POST / - create (Admin/Trainer)
- PUT /{id} - update (Admin/Trainer)
- DELETE /{id} - delete (Admin only)
- **DTOs**: ClassName, ScheduleDate, StartTime, EndTime, TrainerId, MaxCapacity, FacilityId (nullable)

#### Sessions (`/api/Session`)
- GET / - list with pagination/search
- GET /{id} - get by ID
- GET /schedule/{scheduleId} - by schedule
- GET /member/{memberId} - by member
- POST / - create (Admin/Trainer)
- PUT /{id} - update (Admin/Trainer)
- DELETE /{id} - delete (Admin only)
- PUT /{id}/status - update status
- **DTOs**: ScheduleId, MemberId, Status ('Registered', 'Completed', 'Cancelled'), RegistrationDate, Notes

#### Invoices (`/api/Invoice`)
- GET / - list with pagination/search
- GET /{id} - get by ID
- GET /member/{memberId} - by member
- GET /status/{status} - by status
- GET /overdue - overdue invoices
- GET /unpaid - unpaid invoices
- POST / - create (Admin only)
- PUT /{id} - update (Admin only)
- DELETE /{id} - delete (SuperAdmin only)
- PUT /{id}/status - update status
- **DTOs**: MembershipId, TotalAmount, InvoiceDate, DueDate, Status ('Pending', 'Paid', 'Overdue'), Description

#### Payments (`/api/Payment`)
- GET / - list with pagination/search
- GET /{id} - get by ID
- GET /invoice/{invoiceId} - by invoice
- GET /member/{memberId} - by member
- POST /process - process payment (authenticated users)
- POST / - create (Admin only)
- PUT /{id} - update (Admin only)
- DELETE /{id} - delete (SuperAdmin only)
- PUT /{id}/status - update status
- **DTOs**: MemberId, InvoiceId (nullable), Amount, PaymentMethod ('Cash', 'Card', 'QRCode'), PaymentDate, TransactionId, Status ('Completed', 'Pending', 'Failed')

#### Users/Auth (`/api/Auth`)
- GET /users - list all users (Admin only)
- PUT /users/{id}/active?isActive={bool} - lock/unlock (Admin only)
- POST /create-staff - create Admin/Trainer accounts
- POST /change-password - change password
- **Note**: No role switching endpoint exists - FEAT-004 may need backend support

## Implementation Plan

### ☐ 1. Complete Members CRUD
Implement create and edit modals for members.js (currently placeholders).

**Files**: `wwwroot/js/members.js`

**Steps**:
- Read `API/DTOs/Member/CreateMemberRequest.cs` and `UpdateMemberRequest.cs` for field names
- Replace `showCreateMemberModal()` with full implementation:
  - Inject modal HTML with form: FullName (text, required), Email (email, required), Phone (text, optional), DateOfBirth (date, required, max=today)
  - On submit: validate inputs, call `apiFetch('/api/Member', {method: 'POST', body: JSON.stringify({fullName, email, phone, dateOfBirth})})`, show success toast, reload members list via `loadMembers()`
  - Add close button (×) and cancel button
- Replace `showEditMemberModal(memberId)`:
  - Fetch `apiFetch('/api/Member/' + memberId)` to get current data
  - Show same modal with pre-filled values
  - On submit: validate, call `PUT /api/Member/{memberId}`, show toast, reload
- Optional: Add delete button in table (check `getRole() === 'Admin'`) calling `DELETE /api/Member/{id}` with confirmation
- Follow modal pattern from memberships.js: inject styles, use `.gym-modal-overlay`, `.gym-modal`, handle close events

**Verify**: Start API, login as Admin, navigate to Members page, test create/edit member. Check console for errors.

---

### ☐ 2. Complete Trainers CRUD
Same as members but for trainers.js.

**Files**: `wwwroot/js/trainers.js`

**Steps**:
- Read `API/DTOs/Trainer/CreateTrainerRequest.cs` and `UpdateTrainerRequest.cs`
- Implement `showCreateTrainerModal()`: form with FullName, Email, Phone, Specialization (text, e.g., "Yoga", "Strength Training")
- Implement `showEditTrainerModal(trainerId)`: fetch `/api/Trainer/{id}`, pre-fill, PUT on submit
- Optional: Add delete functionality
- Ensure validation and toast notifications

**Verify**: Navigate to Huấn luyện viên page, test create/edit trainer.

---

### ☐ 3. Complete Memberships Admin CRUD
Memberships.js has member-facing purchase flow; add admin create/edit for manual membership creation.

**Files**: `wwwroot/js/memberships.js`

**Steps**:
- Read `API/DTOs/Membership/CreateMembershipRequest.cs` and `UpdateMembershipRequest.cs`
- In `renderAllMemberships()` (admin view section), replace `showCreateMembershipModal()`:
  - Form: MemberId dropdown (fetch `/api/Member`, show FullName), PackageName text input, Price number, StartDate date, EndDate date
  - Calculate EndDate suggestion based on duration (30/90/180/365 days) if desired
  - POST to `/api/Membership`
- Implement `showEditMembershipModal(id)`: GET `/api/Membership/{id}`, pre-fill, PUT `/api/Membership/{id}`
- Admin can change package name, price, dates

**Verify**: Admin Gói tập page, create membership manually, edit existing membership.

---

### ☐ 4. Complete Schedules CRUD
Schedules.js needs create/edit/delete for class schedules.

**Files**: `wwwroot/js/schedules.js`

**Steps**:
- Read `API/DTOs/Schedule/CreateScheduleRequest.cs` and `UpdateScheduleRequest.cs`
- Read existing `schedules.js` render function to understand current UI
- Implement `showCreateScheduleModal()`:
  - Form: ClassName (text), ScheduleDate (date), StartTime (time input), EndTime (time input), TrainerId dropdown (fetch `/api/Trainer`), MaxCapacity (number), FacilityId dropdown (fetch `/api/Facility` if exists, or make optional/nullable)
  - Validate: EndTime > StartTime, date not in past
  - POST `/api/Schedule`
- Implement `showEditScheduleModal(id)`: GET `/api/Schedule/{id}`, pre-fill, PUT `/api/Schedule/{id}`
- Add delete button in table: `DELETE /api/Schedule/{id}` with confirmation (Admin only)

**Verify**: Lịch Class page, create schedule with trainer, edit time, delete schedule.

---

### ☐ 5. Complete Sessions (Class Registrations) CRUD
Sessions.js manages class registrations.

**Files**: `wwwroot/js/sessions.js`

**Steps**:
- Read `API/DTOs/Session/CreateSessionRequest.cs` and `UpdateSessionRequest.cs`
- Read existing `sessions.js` to see current UI
- Implement `showCreateSessionModal()`:
  - Form: ScheduleId dropdown (fetch `/api/Schedule`, show ClassName + date), MemberId dropdown (fetch `/api/Member`), Status dropdown ('Registered', 'Completed', 'Cancelled'), Notes textarea (optional)
  - POST `/api/Session`
- Implement `showEditSessionModal(id)`: mainly for updating Status
  - GET `/api/Session/{id}`, show form with Status dropdown, Notes
  - PUT `/api/Session/{id}` or PUT `/api/Session/{id}/status`
- Add delete button: `DELETE /api/Session/{id}` (Admin only)
- Ensure status badges use proper colors (Registered=success, Completed=info, Cancelled=danger)

**Verify**: Đăng ký Class page, create registration, change status to Completed, verify badge color.

---

### ☐ 6. Complete Invoices CRUD
Invoices.js has partial admin view; add create/edit modals.

**Files**: `wwwroot/js/invoices.js`

**Steps**:
- Read `API/DTOs/Invoice/CreateInvoiceRequest.cs` and `UpdateInvoiceRequest.cs`
- Replace `showCreateInvoiceModal()`:
  - Form: MembershipId dropdown (fetch `/api/Membership`, show PackageName + MemberId), TotalAmount (number), InvoiceDate (date, default today), DueDate (date, default today+7), Status dropdown ('Pending', 'Paid', 'Overdue'), Description (text, optional)
  - POST `/api/Invoice`
- Implement `showEditInvoiceModal(id)`: GET `/api/Invoice/{id}`, pre-fill, allow editing TotalAmount, DueDate, Status, Description, PUT `/api/Invoice/{id}`
- Optional delete: `DELETE /api/Invoice/{id}` (SuperAdmin only, may skip)
- Keep existing mark-as-paid button functionality

**Verify**: Hóa đơn page, create invoice for membership, edit due date and status.

---

### ☐ 7. Complete Payments CRUD
Payments.js needs admin create/edit.

**Files**: `wwwroot/js/payments.js`

**Steps**:
- Read `API/DTOs/Payment/CreatePaymentRequest.cs` and `UpdatePaymentRequest.cs`
- Check if `payments.js` already has `renderPayments()` - if basic, add role-based admin view
- Implement `showCreatePaymentModal()`:
  - Form: MemberId dropdown (fetch `/api/Member`), InvoiceId dropdown (fetch `/api/Invoice?status=Pending`, optional), Amount (number), PaymentMethod dropdown ('Cash', 'Card', 'QRCode'), PaymentDate (date, default today), TransactionId (text, auto-generate or manual), Status dropdown ('Completed', 'Pending', 'Failed')
  - POST `/api/Payment` or POST `/api/Payment/process` (check controller)
- Implement `showEditPaymentModal(id)`: GET `/api/Payment/{id}`, mainly edit Status, PUT `/api/Payment/{id}`
- Optional delete: `DELETE /api/Payment/{id}` (SuperAdmin only)

**Verify**: Thanh toán page, create payment record, edit status to Failed, verify badge.

---

### ☐ 8. Enhance User Management with Role Switching
Users.js shows users with lock/unlock. Add role switching buttons.

**Files**: `wwwroot/js/users.js`, potentially `Controllers/AuthController.cs` (to check for role endpoint)

**Steps**:
- Read `Controllers/AuthController.cs` to check if `PUT /api/Auth/users/{id}/role` exists
- If endpoint exists:
  - In `renderUsersTable()`, change role badges to color-coded: Admin=`badge-danger` (red), Trainer=`badge-primary` (blue), Member=`badge-success` (green)
  - Add action buttons: 'Make Admin', 'Make Trainer', 'Make Member' (only show buttons for roles user doesn't have)
  - On click: show confirmation modal "Change [username] from [currentRole] to [newRole]?"
  - On confirm: call `PUT /api/Auth/users/{id}/role` with `{role: newRole}`, show toast, reload users
  - Prevent changing current user's own role (check userId)
- If endpoint does NOT exist:
  - Update badges to color-coded
  - Add 'Change Role' button that opens a modal explaining backend API is needed
  - Document in findings: "AuthController needs PUT /api/Auth/users/{id}/role endpoint accepting {role: string}"
  - Workaround: emphasize existing create-staff functionality for creating Admin/Trainer accounts

**Verify**: Quản lý Users page, verify color-coded badges, test role switching (if backend supports), verify current user can't change own role.

---

### ☐ 9. Cross-Module Integration Testing
Test all admin features together, verify navigation, ensure no console errors.

**Files**: All `wwwroot/js/*.js` files

**Steps**:
- Start API: `dotnet run --project GymManegement.csproj`
- Open http://localhost:5250, login as Admin
- Navigate through each admin page:
  - Members: create, edit, search, paginate
  - Trainers: create, edit
  - Gói tập: create membership, edit
  - Lịch Class: create schedule, assign trainer, edit, delete
  - Đăng ký Class: create session, change status
  - Hóa đơn: create invoice, edit, filter by status
  - Thanh toán: create payment, edit status
  - Quản lý Users: view users with color badges, test role switching or verify workaround
- Check browser console for JavaScript errors
- Verify toast notifications appear on success/error
- Test pagination and search in each module
- Verify role-based access (non-admin should not see admin buttons)

**Verify**: Full end-to-end manual test of all admin features. Browser console clean of errors.

---

### ☐ 10. Code Review and Cleanup
Review all JS files for consistency, validation, error handling.

**Files**: All modified `wwwroot/js/*.js` files

**Steps**:
- Ensure all modals follow the same pattern (`.gym-modal-overlay`, close handlers, validation)
- Check that all API calls use `apiFetch()` with proper error handling (try/catch, showError)
- Verify all user inputs are escaped with `escapeHtml()` to prevent XSS
- Ensure all date/currency display uses `formatDate()`, `formatCurrency()`
- Check that all create/edit functions show loading spinner (`showLoading()`, `hideLoading()`)
- Verify all forms have required field validation before submitting
- Remove any console.log statements or commented-out code
- Ensure consistent code style (indentation, naming conventions) matching existing files

**Verify**: Code review checklist complete. No linting errors. Code is clean and maintainable.

---

## Notes

### Package Management
There is NO separate Package/Plan entity. Membership uses `PackageName` as a string field. The predefined packages in memberships.js (`AVAILABLE_PACKAGES`) are frontend-only constants for the member purchase flow. Admin can enter any package name when creating memberships manually.

### Role-Based Access
All admin CRUD operations must check `getRole() === 'Admin'` before showing create/edit/delete buttons. Existing code already has this pattern in members.js and invoices.js.

### API Authorization
Backend controllers enforce role-based authorization. Admin-only endpoints have `[Authorize(Roles = "Admin")]` or `[Authorize(Roles = "SuperAdmin,Admin")]`. Frontend should match this but backend is the enforcement layer.

### Modal Styling
Follow the pattern from memberships.js:
- `injectModalStyles()` to add CSS once
- `.gym-modal-overlay` for full-screen backdrop
- `.gym-modal` for modal content
- Close button (×) that removes the modal element
- Form validation with error messages
- Cancel and Submit buttons in `.gym-modal-buttons`

### User Role Switching
The requirement states admin should be able to switch users between roles. AuthController currently has:
- `POST /create-staff` - creates Admin/Trainer accounts
- `PUT /users/{id}/active` - lock/unlock accounts

If `PUT /users/{id}/role` doesn't exist, FEAT-004 should document this as a finding and implement a workaround UI or note that backend support is needed.

### Testing
Since there's no automated test framework for the frontend, verification is manual:
1. Start API: `dotnet run --project GymManegement.csproj`
2. Navigate to http://localhost:5250
3. Login as Admin (credentials depend on seed data)
4. Test each feature manually
5. Check browser console for errors

### Existing Issues
Members.js and trainers.js have placeholder CRUD functions. Invoices.js and payments.js have partial functionality. This plan completes all CRUD operations following existing patterns.

## Success Criteria
- Admin can create, read, update, and delete all entities (members, trainers, memberships, schedules, sessions, invoices, payments)
- User management shows color-coded role badges and supports role switching (if backend allows) or provides clear workaround
- All modals follow consistent styling and validation patterns
- All API calls have proper error handling and user feedback (toasts)
- Browser console is free of JavaScript errors
- Code is clean, consistent, and follows existing patterns

