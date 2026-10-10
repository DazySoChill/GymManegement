# Frontend Build Plan - Gym Management System

## Project Context

**Backend**: ASP.NET Core 8.0 Web API with JWT authentication
**Database**: SQL Server (GymDb)
**API Base URL**: `http://localhost:5000/api` (development)
**Authentication**: JWT Bearer tokens (8-hour expiry)
**Roles**: Admin, Trainer, Member

### Build & Test Commands
- **Build**: `dotnet build`
- **Run**: `dotnet run` (starts on HTTP port, HTTPS redirect configured)
- **Test**: Manual testing via frontend + Swagger UI at `/swagger`

---

## API Endpoints Documentation

### 1. Authentication (`/api/Auth`)

#### POST `/api/Auth/login` [AllowAnonymous]
**Request**:
```json
{
  "username": "string",
  "password": "string"
}
```
**Response**:
```json
{
  "token": "string",
  "username": "string",
  "fullName": "string",
  "email": "string",
  "role": "string", // "Admin" | "Trainer" | "Member"
  "memberId": number | null, // Only for Member role
  "expiresAt": "2024-01-01T00:00:00Z"
}
```
**Errors**: 401 Unauthorized if credentials invalid

#### POST `/api/Auth/register` [AllowAnonymous]
**Request**:
```json
{
  "username": "string",
  "password": "string", // min 6 chars
  "fullName": "string", // max 100 chars
  "email": "string" // valid email
}
```
**Response**:
```json
{
  "message": "Đăng ký thành công! Tài khoản đã được kích hoạt và Member được tạo tự động.",
  "user": {
    "userId": number,
    "username": "string",
    "fullName": "string",
    "email": "string",
    "role": "Member", // Always Member for register
    "isActive": true,
    "lastLoginAt": null,
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": null
  }
}
```

#### POST `/api/Auth/create-staff` [Admin only]
**Request**:
```json
{
  "username": "string", // max 50 chars
  "password": "string", // min 6 chars
  "fullName": "string", // max 100 chars
  "email": "string",
  "role": "Admin" | "Trainer" // Only these two allowed
}
```

#### POST `/api/Auth/change-password` [Authenticated]
**Request**:
```json
{
  "oldPassword": "string",
  "newPassword": "string"
}
```

#### GET `/api/Auth/me` [Authenticated]
**Response**:
```json
{
  "userId": "string",
  "username": "string",
  "fullName": "string",
  "email": "string",
  "role": "string",
  "memberId": "string" | null
}
```

#### GET `/api/Auth/users` [Admin only]
**Response**: Array of UserResponse

#### PUT `/api/Auth/users/{id}/active?isActive=true/false` [Admin only]

---

### 2. Members (`/api/Member`)

#### GET `/api/Member` [Authenticated]
**Query params**: `pageNumber=1`, `pageSize=10`, `searchTerm`, `sortBy`, `sortDir`
**Response**: PagedResult<MemberResponse>
```json
{
  "items": [{
    "memberId": number,
    "fullName": "string",
    "email": "string",
    "phone": "string" | null,
    "dateOfBirth": "2024-01-01T00:00:00Z" | null,
    "qrCode": "string",
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }],
  "pageNumber": 1,
  "pageSize": 10,
  "totalCount": 100,
  "totalPages": 10
}
```

#### GET `/api/Member/{id}` [Authenticated]
**Response**: MemberResponse or 404

#### POST `/api/Member` [SuperAdmin, Admin only]
**Request**:
```json
{
  "fullName": "string",
  "email": "string",
  "phone": "string" | null,
  "dateOfBirth": "2024-01-01T00:00:00Z" | null
}
```

#### PUT `/api/Member/{id}` [SuperAdmin, Admin only]
**Request**: Same as POST

#### DELETE `/api/Member/{id}` [SuperAdmin only]

---

### 3. Memberships (`/api/Membership`)

#### GET `/api/Membership` [Authenticated]
**Query params**: `pageNumber`, `pageSize`, `searchTerm`, `sortBy`, `sortDir`
**Response**: PagedResult<MembershipResponse>
```json
{
  "items": [{
    "membershipId": number,
    "memberId": number,
    "packageName": "string",
    "price": number,
    "startDate": "2024-01-01T00:00:00Z",
    "endDate": "2024-01-01T00:00:00Z",
    "daysRemaining": number, // Computed: Math.max(0, (EndDate - Now).Days)
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }]
}
```

#### GET `/api/Membership/{id}` [Authenticated]

#### GET `/api/Membership/member/{memberId}` [Authenticated]
**Response**: Array of memberships for member

#### GET `/api/Membership/member/{memberId}/active` [Authenticated]
**Response**: Active membership or 404

#### GET `/api/Membership/active` [Authenticated]
**Response**: Array of all active memberships

#### GET `/api/Membership/expiring?daysAhead=7` [Authenticated]

#### POST `/api/Membership` [SuperAdmin, Admin only]
**Request**:
```json
{
  "memberId": number,
  "packageName": "string",
  "price": number,
  "startDate": "2024-01-01T00:00:00Z",
  "endDate": "2024-01-01T00:00:00Z"
}
```

#### PUT `/api/Membership/{id}` [SuperAdmin, Admin only]

#### DELETE `/api/Membership/{id}` [SuperAdmin only]

#### POST `/api/Membership/{id}/renew` [SuperAdmin, Admin only]
**Request**: CreateMembershipRequest (memberId auto-copied from existing)

---

### 4. Trainers (`/api/Trainer`)

#### GET `/api/Trainer` [Authenticated]
**Response**: PagedResult<TrainerResponse>
```json
{
  "items": [{
    "trainerId": number,
    "fullName": "string",
    "phone": "string" | null,
    "email": "string",
    "specialization": "string" | null,
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }]
}
```

#### GET `/api/Trainer/{id}` [Authenticated]

#### POST `/api/Trainer` [SuperAdmin, Admin only]
**Request**:
```json
{
  "fullName": "string",
  "phone": "string",
  "email": "string",
  "specialization": "string"
}
```

#### PUT `/api/Trainer/{id}` [SuperAdmin, Admin only]

#### DELETE `/api/Trainer/{id}` [SuperAdmin only]

---

### 5. Facilities (`/api/Facility`)

#### GET `/api/Facility` [Authenticated]
**Response**: PagedResult<FacilityResponse>
```json
{
  "items": [{
    "facilityId": number,
    "name": "string",
    "description": "string" | null,
    "status": "Active" | "Maintenance" | "Inactive",
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }]
}
```

#### GET `/api/Facility/active` [Authenticated]

#### GET `/api/Facility/{id}` [Authenticated]

#### POST `/api/Facility` [SuperAdmin, Admin only]
**Request**:
```json
{
  "name": "string",
  "description": "string" | null,
  "status": "Active" | "Maintenance" | "Inactive"
}
```

#### PUT `/api/Facility/{id}` [SuperAdmin, Admin only]

#### DELETE `/api/Facility/{id}` [SuperAdmin only]

---

### 6. Schedules (`/api/Schedule`)

#### GET `/api/Schedule` [Authenticated]
**Response**: PagedResult<ScheduleResponse>
```json
{
  "items": [{
    "scheduleId": number,
    "trainerId": number,
    "trainerName": "string",
    "facilityId": number,
    "facilityName": "string",
    "className": "string",
    "startTime": "2024-01-01T10:00:00Z",
    "endTime": "2024-01-01T11:00:00Z",
    "maxCapacity": number,
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }]
}
```

#### GET `/api/Schedule/{id}` [Authenticated]

#### GET `/api/Schedule/trainer/{trainerId}` [Authenticated]

#### GET `/api/Schedule/date/{date}` [Authenticated]
**date format**: YYYY-MM-DD

#### POST `/api/Schedule` [SuperAdmin, Admin, Trainer]
**Request**:
```json
{
  "trainerId": number,
  "facilityId": number,
  "className": "string",
  "startTime": "2024-01-01T10:00:00Z",
  "endTime": "2024-01-01T11:00:00Z",
  "maxCapacity": 20 // default
}
```

#### PUT `/api/Schedule/{id}` [SuperAdmin, Admin, Trainer]

#### DELETE `/api/Schedule/{id}` [SuperAdmin, Admin only]

---

### 7. Sessions (`/api/Session`)

#### GET `/api/Session` [Authenticated]
**Response**: PagedResult<SessionResponse>
```json
{
  "items": [{
    "sessionId": number,
    "memberId": number,
    "scheduleId": number,
    "registrationDate": "2024-01-01T00:00:00Z",
    "status": "Registered" | "Attended" | "Cancelled",
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }]
}
```

#### GET `/api/Session/{id}` [Authenticated]

#### GET `/api/Session/schedule/{scheduleId}` [Authenticated]

#### GET `/api/Session/member/{memberId}` [Authenticated]

#### POST `/api/Session` [SuperAdmin, Admin, Trainer]
**Request**:
```json
{
  "memberId": number,
  "scheduleId": number,
  "registrationDate": "2024-01-01T00:00:00Z", // defaults to now
  "status": "Registered" // default
}
```

#### PUT `/api/Session/{id}` [SuperAdmin, Admin, Trainer]

#### PUT `/api/Session/{id}/status` [SuperAdmin, Admin, Trainer]

#### DELETE `/api/Session/{id}` [SuperAdmin, Admin only]

---

### 8. Check-ins (`/api/Checkin`)

**Aliases**: `/api/Checkin` and `/api/Checkins` (both work)

#### GET `/api/Checkin` [Authenticated]
**Response**: PagedResult<CheckinResponse>
```json
{
  "items": [{
    "checkinId": number,
    "memberId": number,
    "memberName": "string",
    "checkinTime": "2024-01-01T10:00:00Z",
    "checkoutTime": "2024-01-01T12:00:00Z" | null,
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }]
}
```

#### GET `/api/Checkin/{id}` [Authenticated]

#### GET `/api/Checkin/member/{memberId}` [Authenticated]

#### GET `/api/Checkin/date-range?from=2024-01-01&to=2024-01-31` [Authenticated]

#### GET `/api/Checkin/date/{date}` [Authenticated]

#### POST `/api/Checkin/manual` [SuperAdmin, Admin, Trainer]
**Request**:
```json
{
  "memberId": number,
  "checkinTime": "2024-01-01T10:00:00Z" // defaults to now
}
```

#### POST `/api/Checkin/qr` [AllowAnonymous]
**Request**: QRCheckinRequest (implementation specific)

---

### 9. Invoices (`/api/Invoice`)

#### GET `/api/Invoice` [Authenticated]
**Response**: PagedResult<InvoiceResponse>
```json
{
  "items": [{
    "invoiceId": number,
    "membershipId": number,
    "totalAmount": number,
    "invoiceDate": "2024-01-01T00:00:00Z",
    "dueDate": "2024-01-08T00:00:00Z",
    "status": "Pending" | "Paid" | "Overdue",
    "description": "string" | null,
    "isOverdue": boolean, // Computed: Status=="Pending" && DueDate < Now
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }]
}
```

#### GET `/api/Invoice/{id}` [Authenticated]

#### GET `/api/Invoice/member/{memberId}` [Authenticated]

#### GET `/api/Invoice/status/{status}` [Authenticated]

#### GET `/api/Invoice/overdue` [Authenticated]

#### GET `/api/Invoice/unpaid` [Authenticated]

#### POST `/api/Invoice` [SuperAdmin, Admin only]
**Request**:
```json
{
  "membershipId": number,
  "totalAmount": number,
  "invoiceDate": "2024-01-01T00:00:00Z", // defaults to now
  "dueDate": "2024-01-08T00:00:00Z", // defaults to +7 days
  "description": "string" | null
}
```

#### PUT `/api/Invoice/{id}` [SuperAdmin, Admin only]

#### PUT `/api/Invoice/{id}/status` [SuperAdmin, Admin only]

#### DELETE `/api/Invoice/{id}` [SuperAdmin only]

---

### 10. Payments (`/api/Payment`)

#### GET `/api/Payment` [Authenticated]
**Response**: PagedResult<PaymentResponse>
```json
{
  "items": [{
    "paymentId": number,
    "invoiceId": number,
    "amount": number,
    "paymentDate": "2024-01-01T00:00:00Z",
    "paymentMethod": "Cash" | "BankTransfer" | "Card" | "MoMo" | "ZaloPay",
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }]
}
```

#### GET `/api/Payment/{id}` [Authenticated]

#### GET `/api/Payment/invoice/{invoiceId}` [Authenticated]

#### GET `/api/Payment/member/{memberId}` [Authenticated]

#### POST `/api/Payment` [SuperAdmin, Admin only]
**Request**:
```json
{
  "invoiceId": number,
  "amount": number,
  "paymentDate": "2024-01-01T00:00:00Z", // defaults to now
  "paymentMethod": "Cash" | "BankTransfer" | "Card" | "MoMo" | "ZaloPay"
}
```

#### PUT `/api/Payment/{id}` [SuperAdmin, Admin only]

#### PUT `/api/Payment/{id}/status` [SuperAdmin, Admin only]

#### DELETE `/api/Payment/{id}` [SuperAdmin only]

---

### 11. Reports (`/api/Report`) [Admin only]

#### GET `/api/Report/active-members` [SuperAdmin, Admin only]

#### GET `/api/Report/revenue?month=1&year=2024` [SuperAdmin, Admin only]

#### GET `/api/Report/revenue/detail?month=1&year=2024` [SuperAdmin, Admin only]

#### GET `/api/Report/expiring-soon?daysAhead=7` [SuperAdmin, Admin only]

#### GET `/api/Report/members` [SuperAdmin, Admin only]

#### GET `/api/Report/revenue/export?month=1&year=2024` [SuperAdmin, Admin only]
**Response**: Excel file download (application/vnd.openxmlformats-officedocument.spreadsheetml.sheet)

---

## Role-Based Access Matrix

| Feature | Admin | Trainer | Member |
|---------|-------|---------|--------|
| View Members | ✅ | ✅ | ❌ |
| Create/Edit/Delete Members | ✅ | ❌ | ❌ |
| View Memberships (all) | ✅ | ✅ | ❌ |
| View Own Membership | ✅ | ✅ | ✅ |
| Create/Edit Memberships | ✅ | ❌ | ❌ |
| View Trainers | ✅ | ✅ | ✅ |
| Create/Edit Trainers | ✅ | ❌ | ❌ |
| View Facilities | ✅ | ✅ | ✅ |
| Create/Edit Facilities | ✅ | ❌ | ❌ |
| View Schedules (all) | ✅ | ✅ | ✅ |
| Create/Edit Schedules | ✅ | ✅ (own) | ❌ |
| View Sessions (all) | ✅ | ✅ | ❌ |
| View Own Sessions | ✅ | ✅ | ✅ |
| Create/Edit Sessions | ✅ | ✅ | ❌ |
| View Check-ins (all) | ✅ | ✅ | ❌ |
| View Own Check-ins | ✅ | ✅ | ✅ |
| Manual Check-in | ✅ | ✅ | ❌ |
| View Invoices (all) | ✅ | ❌ | ❌ |
| View Own Invoices | ✅ | ❌ | ✅ |
| Create/Edit Invoices | ✅ | ❌ | ❌ |
| View Payments (all) | ✅ | ❌ | ❌ |
| View Own Payments | ✅ | ❌ | ✅ (via invoices) |
| Create/Edit Payments | ✅ | ❌ | ❌ |
| View Reports | ✅ | ❌ | ❌ |
| Export Reports | ✅ | ❌ | ❌ |

---

## Frontend File Structure

```
wwwroot/
├── login.html              # Login/Register page (public)
├── index.html              # Main dashboard (role-based routing)
├── css/
│   └── style.css          # Unified styles for all pages
└── js/
    ├── api.js             # API client with JWT handling
    ├── auth.js            # Authentication logic & localStorage
    ├── app.js             # Main app initialization & routing
    ├── dashboard.js       # Dashboard page (role-specific stats)
    ├── members.js         # Members management (Admin/Trainer view only)
    ├── memberships.js     # Memberships management + Member view own
    ├── trainers.js        # Trainers management
    ├── facilities.js      # Facilities management
    ├── schedules.js       # Schedules management
    ├── sessions.js        # Sessions management + Member register
    ├── checkins.js        # Check-ins management
    ├── invoices.js        # Invoices management + Member view own
    ├── payments.js        # Payments management
    └── reports.js         # Reports (Admin only)
```

---

## Implementation Plan

### Phase 1: Core Infrastructure

- [ ] 1. Create `wwwroot/` directory structure with all subdirectories (css/, js/).
      Files: wwwroot/css/, wwwroot/js/
      Verify: `dotnet build` succeeds, directory exists

- [ ] 2. Implement `js/api.js` - API client with fetch wrapper, JWT injection, error handling, and automatic 401 redirect.
      - Base API URL configuration
      - `getAuthHeaders()` function to inject Bearer token
      - Generic `apiCall(method, endpoint, body, requiresAuth)` wrapper
      - Error handling with user-friendly messages
      - Automatic redirect to login on 401
      Files: wwwroot/js/api.js
      Verify: Manual inspection of code structure

- [ ] 3. Implement `js/auth.js` - Authentication state management.
      - `saveAuth(loginResponse)` - stores token, user info in localStorage
      - `getAuth()` - retrieves current auth state
      - `isAuthenticated()` - boolean check
      - `getRole()` - returns current user role
      - `logout()` - clears localStorage and redirects to login
      Files: wwwroot/js/auth.js
      Verify: Manual inspection + browser console testing

### Phase 2: Login/Register Page

- [ ] 4. Create `login.html` with clean, modern design (no pre-filled test buttons).
      - Single page with tabs/toggle between Login and Register forms
      - Login form: username, password, submit button
      - Register form: username, password, fullName, email, submit button
      - Error message display area
      - Clean white background with professional form styling
      - Centered layout with card-style container
      Files: wwwroot/login.html
      Verify: Open in browser, visually inspect styling

- [ ] 5. Implement login form submission in `login.html`.
      - Calls POST `/api/Auth/login`
      - On success: saves auth via `auth.js`, redirects to `/index.html`
      - On error: displays error message without page reload
      Files: wwwroot/login.html
      Verify: Test with valid/invalid credentials, check localStorage and redirect

- [ ] 6. Implement register form submission in `login.html`.
      - Calls POST `/api/Auth/register`
      - On success: displays success message, switches to login tab
      - On error: displays validation errors without page reload
      Files: wwwroot/login.html
      Verify: Create new account, verify in database, test login with new account

### Phase 3: Main Application Shell

- [ ] 7. Create `index.html` - Main SPA shell with navigation and content area.
      - Header with logo, user info display (name, role), logout button
      - Left sidebar navigation (role-based menu items)
      - Main content area (`<div id="app-content">`)
      - Footer (optional)
      - On load: checks `isAuthenticated()`, redirects to login if false
      Files: wwwroot/index.html
      Verify: Open in browser after login, verify navigation appears, logout works

- [ ] 8. Implement `js/app.js` - Routing and page initialization.
      - `init()` function runs on index.html load
      - `renderNavigation(role)` - builds sidebar menu based on role
      - `loadPage(pageName)` - dynamic content loading router
      - Hash-based routing (`#members`, `#dashboard`, etc.)
      - Default route: `#dashboard`
      - Navigation items per role:
        - Admin: Dashboard, Members, Memberships, Trainers, Facilities, Schedules, Sessions, Check-ins, Invoices, Payments, Reports (11 items)
        - Trainer: Dashboard, Members (view), Schedules (manage), Sessions (manage), Check-ins (manual) (5 items)
        - Member: Dashboard, My Membership, Schedules (view), My Sessions, My Check-ins, My Invoices (6 items)
      Files: wwwroot/js/app.js
      Verify: Click navigation items, verify correct page loads, verify role filtering works

### Phase 4: Dashboard Page

- [ ] 9. Implement `js/dashboard.js` - Role-specific dashboard stats.
      - Admin dashboard:
        - Total active members (GET `/api/Report/active-members`)
        - Total revenue this month (GET `/api/Report/revenue?month=X&year=Y`)
        - Expiring memberships (GET `/api/Report/expiring-soon?daysAhead=7`)
        - Recent check-ins (GET `/api/Checkin?pageSize=5`)
      - Trainer dashboard:
        - Today's schedules (GET `/api/Schedule/date/{today}`)
        - Recent sessions (GET `/api/Session?pageSize=10`)
        - Recent check-ins (GET `/api/Checkin?pageSize=5`)
      - Member dashboard:
        - Active membership status (GET `/api/Membership/member/{memberId}/active`)
        - Upcoming sessions (GET `/api/Session/member/{memberId}`)
        - Recent check-ins (GET `/api/Checkin/member/{memberId}`)
        - Unpaid invoices (GET `/api/Invoice/member/{memberId}`)
      Files: wwwroot/js/dashboard.js
      Verify: Load dashboard as each role, verify stats appear correctly

### Phase 5: Admin Pages (Data Management)

- [ ] 10. Implement `js/members.js` - Members CRUD (Admin/Trainer view only).
       - List view with pagination, search, sort
       - Table columns: ID, Full Name, Email, Phone, Date of Birth, QR Code, Created At
       - Create member form (Admin only)
       - Edit member modal (Admin only)
       - Delete confirmation (SuperAdmin only - graceful degradation: hide if role != SuperAdmin)
       - View-only mode for Trainer role
       Files: wwwroot/js/members.js
       Verify: As Admin - create, edit, view members. As Trainer - view only works. As Member - navigation hidden

- [ ] 11. Implement `js/memberships.js` - Memberships CRUD + Member view own.
       - Admin/Trainer view: List all memberships with member name, package, dates, days remaining
       - Admin actions: Create, Edit, Renew, View expiring
       - Member view: Shows only own membership(s), read-only
       - Filter options: All, Active, Expiring Soon
       - Display days remaining with color coding (red < 7, yellow < 30, green >= 30)
       Files: wwwroot/js/memberships.js
       Verify: As Admin - manage all. As Member - see only own membership

- [ ] 12. Implement `js/trainers.js` - Trainers CRUD (Admin only).
       - List view with ID, Full Name, Email, Phone, Specialization
       - Create trainer form
       - Edit trainer modal
       - Delete confirmation (SuperAdmin only - graceful degradation)
       - View-only mode for non-Admin roles
       Files: wwwroot/js/trainers.js
       Verify: As Admin - full CRUD works. As Trainer/Member - navigation hidden

- [ ] 13. Implement `js/facilities.js` - Facilities CRUD (Admin only).
       - List view with ID, Name, Description, Status
       - Status badge color coding (Active=green, Maintenance=yellow, Inactive=red)
       - Create facility form with status dropdown
       - Edit facility modal
       - Delete confirmation (SuperAdmin only - graceful degradation)
       - Filter: All / Active only
       Files: wwwroot/js/facilities.js
       Verify: As Admin - full CRUD. Status colors render correctly

### Phase 6: Scheduling & Sessions

- [ ] 14. Implement `js/schedules.js` - Schedules management (Admin/Trainer create, all view).
       - Calendar-style or list view with date filter
       - Show: Class Name, Trainer, Facility, Start/End Time, Max Capacity
       - Create schedule form (Admin/Trainer only) - dropdowns for trainer/facility from APIs
       - Edit schedule modal (Admin/Trainer only)
       - Delete confirmation (Admin only)
       - Member role: view-only list
       - Date range filter (today, this week, next week, custom)
       Files: wwwroot/js/schedules.js
       Verify: As Admin - full CRUD. As Trainer - create own schedules. As Member - view only

- [ ] 15. Implement `js/sessions.js` - Session registrations (Admin/Trainer manage, Member register).
       - Admin/Trainer view: List all sessions with Member name, Schedule, Status
       - Admin/Trainer actions: Create session (assign member to schedule), Update status
       - Member view: List own sessions + "Register for Class" button
       - Registration flow: Member selects schedule from list, clicks register, creates session
       - Status badge colors: Registered=blue, Attended=green, Cancelled=red
       Files: wwwroot/js/sessions.js
       Verify: As Member - register for schedule, see own sessions. As Admin - manage all sessions

### Phase 7: Check-ins, Invoices, Payments

- [ ] 16. Implement `js/checkins.js` - Check-in history (Admin/Trainer manual, Member view own).
       - Admin/Trainer view: List all check-ins with date filter, manual check-in button
       - Manual check-in form: Select member from dropdown, submit
       - Member view: List own check-ins with checkin/checkout times
       - Date range filter (today, this week, this month, custom)
       - Display duration if checkout time exists
       Files: wwwroot/js/checkins.js
       Verify: As Admin - manual check-in works. As Member - see only own check-ins

- [ ] 17. Implement `js/invoices.js` - Invoice management (Admin manage, Member view own).
       - Admin view: List all invoices with Member, Membership, Amount, Status, Due Date
       - Admin actions: Create invoice (from membership), Update status (Pending/Paid/Overdue)
       - Member view: List own invoices, read-only
       - Overdue highlighting (red background or badge)
       - Filter: All, Pending, Paid, Overdue, Unpaid
       - Status update modal for Admin
       Files: wwwroot/js/invoices.js
       Verify: As Admin - create, update status. As Member - view own invoices

- [ ] 18. Implement `js/payments.js` - Payment management (Admin manage, Member view via invoices).
       - Admin view: List all payments with Invoice ID, Amount, Method, Date
       - Admin actions: Record payment (select invoice, amount, method, date)
       - Payment method dropdown: Cash, BankTransfer, Card, MoMo, ZaloPay
       - Link to invoice details
       - Member: No direct access (see payments through invoice detail)
       Files: wwwroot/js/payments.js
       Verify: As Admin - record payment, verify invoice status updates

### Phase 8: Reports (Admin Only)

- [ ] 19. Implement `js/reports.js` - Reports dashboard (Admin only).
       - Active Members count + list
       - Revenue report: Month/Year selector, display total + detail table
       - Expiring Soon: Days ahead slider (1-30), display list
       - Members Report: Full member list export option
       - Revenue Export button (downloads Excel file)
       Files: wwwroot/js/reports.js
       Verify: As Admin - all reports load correctly, export downloads file

### Phase 9: Styling & Polish

- [ ] 20. Implement `css/style.css` - Unified professional styling.
       - CSS variables for color scheme (primary, secondary, success, warning, danger, neutral)
       - Responsive design (mobile-friendly sidebar toggle, tables scroll on small screens)
       - Form styling: consistent inputs, buttons, labels
       - Table styling: hover effects, striped rows, pagination controls
       - Modal/dialog styling
       - Navigation styling: active state, hover effects
       - Loading spinner/skeleton screens
       - Toast notifications for success/error messages
       - Clean, modern aesthetic (not too simple, not too complex)
       Files: wwwroot/css/style.css
       Verify: Visual inspection in browser at multiple screen sizes

### Phase 10: Integration Testing & Bug Fixes

- [ ] 21. End-to-end testing as Admin user.
       - Login as Admin
       - Navigate through all pages
       - Create sample data: Member, Membership, Trainer, Facility, Schedule, Session, Check-in, Invoice, Payment
       - Verify data appears correctly on all related pages
       - Test search, pagination, sorting on list pages
       - Test all CRUD operations
       - Test reports and export
       - Verify logout works
       Files: All existing files
       Verify: Full user flow completes without errors, data persists correctly

- [ ] 22. End-to-end testing as Member user.
       - Register new member account via `/login.html`
       - Login as Member
       - Verify navigation shows only: Dashboard, My Membership, Schedules, My Sessions, My Check-ins, My Invoices
       - Dashboard shows membership status, upcoming sessions
       - View schedules, register for a class
       - View own sessions, check-ins, invoices
       - Verify cannot access admin pages (direct URL navigation shows error or redirects)
       - Verify logout works
       Files: All existing files
       Verify: Member sees only authorized content, no errors

- [ ] 23. Cross-browser compatibility testing.
       - Test in Chrome, Firefox, Edge
       - Verify responsive design on mobile viewport
       - Fix any rendering issues
       Files: wwwroot/css/style.css, possibly JS files if needed
       Verify: Application works in all tested browsers

- [ ] 24. Error handling & edge cases.
       - Test network errors (stop backend, verify frontend shows friendly error)
       - Test expired token (wait 8+ hours or manually expire, verify auto-logout)
       - Test invalid data submission (empty forms, invalid emails, etc.)
       - Test pagination edge cases (page 0, page beyond max)
       - Test with empty database (no members, no schedules, etc.)
       - Verify all error messages are user-friendly
       Files: wwwroot/js/api.js, all page JS files
       Verify: No unhandled exceptions in browser console, friendly error messages shown

### Phase 11: Final Cleanup & Documentation

- [ ] 25. Code cleanup and comments.
       - Add JSDoc comments to all functions
       - Remove any console.log debugging statements
       - Ensure consistent code style (indentation, naming conventions)
       - Verify no hardcoded test data remains
       Files: All JS files
       Verify: Code review, run in browser with console open (no logs)

- [ ] 26. Performance optimization.
       - Minimize API calls (cache dropdown data like trainers, facilities)
       - Debounce search input fields
       - Lazy load pages (only load JS when navigating to page)
       - Optimize table rendering for large datasets
       Files: All JS files
       Verify: Test with larger datasets, verify smooth performance

- [ ] 27. Security review.
       - Verify all API calls use `requiresAuth: true` except login/register
       - Verify no sensitive data logged to console
       - Verify HTTPS redirect works (configured in Program.cs)
       - Verify CORS configuration is appropriate
       - Verify JWT token stored securely (localStorage acceptable for this project)
       Files: All JS files, Program.cs
       Verify: Manual security audit checklist

- [ ] 28. Final build and deployment verification.
       - Run `dotnet build` - must succeed with no warnings
       - Run `dotnet run` - application starts successfully
       - Open browser to root URL, verify redirects to login or index based on auth state
       - Perform smoke test of all major features
       - Verify static files served correctly from wwwroot/
       Files: All files
       Verify: Application runs end-to-end without errors

---

## Known Issues & Graceful Degradation

1. **SuperAdmin role**: Delete operations require SuperAdmin role, but most test accounts are Admin. Frontend will hide delete buttons if user role is not SuperAdmin. If backend returns 403, show friendly message.

2. **Trainer self-management**: Trainers can create schedules but API only allows editing own schedules. Frontend should filter schedule edit/delete based on trainerId matching logged-in user.

3. **Member registration auto-creates Member record**: Register endpoint automatically creates Member record with QRCode. Frontend should inform user of this.

4. **QR Check-in endpoint**: `/api/Checkin/qr` endpoint exists but QRCheckinRequest DTO structure not fully documented. Frontend can omit QR scanner feature and only implement manual check-in.

5. **Report export**: Export endpoint returns Excel file. Frontend must handle blob download correctly with Content-Disposition header.

6. **Date/Time handling**: All dates in UTC from backend. Frontend should display in local timezone but send in ISO 8601 UTC format.

7. **Pagination**: API uses 1-based page numbering (pageNumber=1 is first page). Frontend pagination must match this.

8. **Alias routes**: CheckinController has both `/api/Checkin` and `/api/Checkins` routes. Use `/api/Checkin` consistently.

9. **No Trainer role in test data**: If no test Trainer account exists, Admin testing must suffice for Trainer role testing.

10. **Session status management**: Session status is manually managed (Registered/Attended/Cancelled). No automatic transition based on schedule date. Frontend should allow Admin/Trainer to update status.

---

## Success Criteria

✅ Login page works without pre-filled test buttons, clean design
✅ Admin can view and manage all entities
✅ Member can only view/manage own data (membership, sessions, invoices)
✅ Navigation menu filtered correctly per role
✅ All API endpoints called with correct request/response format
✅ Data displays correctly on frontend (no undefined fields)
✅ Pagination, search, and sort work correctly
✅ Error messages display without page reload
✅ Logout clears localStorage and redirects to login
✅ Application works on HTTP protocol (HTTPS redirect can be tested later)
✅ No console errors in browser
✅ Responsive design works on desktop and tablet (mobile optional)
✅ Color-coded status badges for better UX
✅ Professional, clean, modern UI (not too simple, not too complex)

---

## Notes for Implementer

- **API Base URL**: Configure in `js/api.js` as `const API_BASE_URL = window.location.origin + '/api';` (auto-detects host)
- **Token Storage**: localStorage with key `gym_auth` containing full LoginResponse JSON
- **Error Handling**: Always show user-friendly messages, never expose raw API errors
- **Loading States**: Show loading spinner during API calls, disable submit buttons to prevent double-click
- **Form Validation**: Client-side validation before API call to match backend validation rules
- **Consistent Patterns**: Use same table/form/modal structure across all pages for maintainability
- **Role Checks**: Always check `getRole()` before rendering role-specific UI elements
- **Member ID Extraction**: For Member role, memberId is in auth object: `getAuth().memberId`
- **Date Formatting**: Use `new Date().toISOString()` for sending dates, `new Date(str).toLocaleDateString()` for display
- **Dropdown Population**: Load trainers/facilities/members for dropdowns on page init, cache in memory
- **Status Enums**: Hardcode status options in frontend (Active/Maintenance/Inactive, Pending/Paid/Overdue, etc.)
- **Pagination Component**: Create reusable pagination component used across all list pages
- **Modal Component**: Create reusable modal component for create/edit forms

---

**Plan Version**: 1.0
**Created**: 2024
**Backend Version**: .NET 8.0
**Target Frontend**: Vanilla JavaScript (ES6+), HTML5, CSS3 (no frameworks)
