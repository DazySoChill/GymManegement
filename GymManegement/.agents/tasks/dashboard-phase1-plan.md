# Implementation Plan: Phase 1 Admin Frontend Fixes

## Overview
This plan addresses three critical issues in the admin frontend:
1. **PascalCase/camelCase API mismatch** - Backend returns PascalCase (`Data`, `PageNumber`) but frontend expects camelCase (`items`, `pageNumber`)
2. **Facilities Create modal** - Currently a stub that shows error
3. **Facilities Edit modal** - Currently a stub that shows error

## Current State Analysis

### Backend API Response Format
- **PagedResult<T>** in `API/DTOs/Common/PagedResult.cs` has properties: `Data`, `Total`, `PageNumber`, `PageSize`, `TotalPages`
- All controllers return responses serialized with default System.Text.Json (PascalCase)
- Example response: `{"Data": [...], "Total": 10, "PageNumber": 1, "PageSize": 10, "TotalPages": 1}`

### Frontend Expectations
- **All JS modules** expect: `data.items`, `data.total`, `data.pageNumber`, `data.pageSize`, `data.totalPages`
- Found in: members.js, trainers.js, facilities.js, schedules.js, sessions.js, invoices.js, payments.js, memberships.js, checkins.js

### Facilities Module Status
- **Current implementation** (wwwroot/js/facilities.js):
  - Line 95-97: `showCreateFacilityModal()` - stub function showing error message
  - Line 99-101: `showEditFacilityModal(id)` - stub function showing error message
  - Missing modal styles injection (pattern from members.js)
  - Table rendering exists (lines 50-86)
  - Pagination exists (lines 88-93)

### Available Helper Functions (from api.js)
- `apiFetch(path, options)` - API fetch with JWT authentication
- `showLoading()` / `hideLoading()` - Loading spinner controls
- `showSuccess(message)` - Success toast notification
- `showError(message)` - Error toast notification
- `escapeHtml(text)` - XSS prevention
- `formatDate(date)` - Date formatting to DD/MM/YYYY

### Facility API Endpoints (FacilityController.cs)
- **POST /api/Facility** - Create new facility (Admin/SuperAdmin only)
  - Request DTO: `CreateFacilityRequest` with `Name`, `Description?`, `Status` (default: "Active")
- **PUT /api/Facility/{id}** - Update facility (Admin/SuperAdmin only)
  - Request DTO: `UpdateFacilityRequest` with `Name`, `Description?`, `Status`
- **GET /api/Facility/{id}** - Get facility by ID
- Status values: "Active", "Maintenance", "Inactive"

## Implementation Steps

### ✅ Step 1: Configure System.Text.Json for camelCase in Program.cs
**What:** Add JSON serialization options to use camelCase property naming for all API responses.

**Where:** `d:\Workspace\Độ án 2\GymManegement\GymManegement\Program.cs`

**Change location:** After line 66 where `builder.Services.AddControllers();` is called.

**Exact modification:**
```csharp
// BEFORE (line 66):
builder.Services.AddControllers();

// AFTER:
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
    });
```

**Rationale:** This configures the ASP.NET Core JSON serializer to convert all C# PascalCase properties to camelCase in JSON responses. This affects ALL API endpoints globally, so `PagedResult<T>.Data` becomes `data`, `PageNumber` becomes `pageNumber`, etc. This is the standard approach for JavaScript/TypeScript frontends consuming .NET APIs.

**Files modified:**
- `Program.cs` (line 66)

**Verification:**
```powershell
# Build the project to ensure no syntax errors
dotnet build GymManegement.csproj

# Start the API
dotnet run --project GymManegement.csproj

# In another terminal, test an API endpoint
curl -H "Authorization: Bearer <token>" http://localhost:5250/api/Member?pageNumber=1&pageSize=10

# Expected: Response should have "data", "pageNumber", "total" (camelCase) instead of "Data", "PageNumber", "Total"
```

**Risks:**
- ⚠️ **BREAKING CHANGE**: This affects ALL API responses across the entire application
- If any non-browser client (mobile app, external service, Postman collections) depends on PascalCase, they will break
- However, the frontend JS already expects camelCase, so this change is required for the app to work correctly
- **Mitigation**: After making this change, test ALL admin pages (Members, Trainers, Schedules, Sessions, Invoices, Payments, Memberships, Users) to ensure they still load data correctly

---

### ✅ Step 2: Fix PagedResult property name mismatch
**What:** The backend `PagedResult<T>` uses `Data` property, but frontend expects `items`. We have two options:

**Option A (PREFERRED):** Rename the C# property from `Data` to `Items` to match frontend expectations after camelCase conversion.

**Option B:** Update all frontend JS files to use `data.data` instead of `data.items`.

**Decision:** Choose **Option A** because:
1. `Items` is more semantically clear than `Data` for a collection
2. Less frontend code to change (1 C# file vs 9+ JS files)
3. Follows common pagination patterns (e.g., ASP.NET Core OData uses `items`)

**Where:** `d:\Workspace\Độ án 2\GymManegement\GymManegement\API\DTOs\Common\PagedResult.cs`

**Exact modification:**
```csharp
// BEFORE:
public class PagedResult<T>
{
    public List<T> Data { get; set; } = new();
    public int Total { get; set; }
    public int PageNumber { get; set; }
    public int PageSize { get; set; }
    public int TotalPages => PageSize > 0 ? (int)Math.Ceiling((double)Total / PageSize) : 0;
}

// AFTER:
public class PagedResult<T>
{
    public List<T> Items { get; set; } = new();
    public int Total { get; set; }
    public int PageNumber { get; set; }
    public int PageSize { get; set; }
    public int TotalPages => PageSize > 0 ? (int)Math.Ceiling((double)Total / PageSize) : 0;
}
```

**Files modified:**
- `API/DTOs/Common/PagedResult.cs`
- All repositories that set `.Data` property (grep results show 13 files in DAL/Repositories/Implementations/)
- All services that set `.Data` property (grep results show 10 files in Service/BUS/Implementations/)

**Verification:**
```powershell
# After renaming, build will fail on all usages of .Data
dotnet build GymManegement.csproj

# Fix all compilation errors by replacing `.Data` with `.Items` in:
# - DAL/Repositories/Implementations/*.cs (13 files)
# - Service/BUS/Implementations/*.cs (10 files)

# After fixing all, build should succeed
dotnet build GymManegement.csproj

# Expected: Build succeeds with 0 errors
```

**Alternative (if Option A causes issues):**
If renaming `Data` to `Items` breaks other parts of the system not visible in this scan, revert and instead update frontend to use `data.data`:
```javascript
// In all JS files, change:
data.items -> data.data
```

---

### ✅ Step 3: Inject Facility Modal Styles
**What:** Add modal CSS styles injection function following the pattern from members.js.

**Where:** `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\facilities.js`

**Change location:** Add new function after line 5 (after variable declarations, before `renderFacilities` function).

**Exact addition:**
```javascript
// Insert after line 5:

// Inject modal styles once
function injectFacilityModalStyles() {
    if (document.getElementById('facility-modal-styles')) return;
    
    const style = document.createElement('style');
    style.id = 'facility-modal-styles';
    style.textContent = `
        .gym-modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.5);
            z-index: 9999;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .gym-modal {
            background: white;
            border-radius: 12px;
            padding: 32px;
            max-width: 500px;
            width: 90%;
            max-height: 90vh;
            overflow-y: auto;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
        }
        .gym-modal h3 {
            margin-top: 0;
            margin-bottom: 20px;
            color: #2c3e50;
        }
        .gym-modal-close {
            position: absolute;
            top: 16px;
            right: 16px;
            background: none;
            border: none;
            font-size: 24px;
            cursor: pointer;
            color: #999;
        }
        .gym-modal-close:hover {
            color: #333;
        }
        .form-group {
            margin-bottom: 16px;
        }
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #2c3e50;
        }
        .form-group input,
        .form-group select,
        .form-group textarea {
            width: 100%;
            padding: 10px;
            border: 2px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
        }
        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: #3498db;
        }
        .form-group .error {
            color: #e74c3c;
            font-size: 12px;
            margin-top: 4px;
        }
        .form-group input.invalid,
        .form-group textarea.invalid,
        .form-group select.invalid {
            border-color: #e74c3c;
        }
        .gym-modal-buttons {
            display: flex;
            gap: 12px;
            margin-top: 24px;
            justify-content: flex-end;
        }
        .required {
            color: #e74c3c;
        }
    `;
    document.head.appendChild(style);
}
```

**Rationale:** This is copied from members.js (lines 9-83) with only the style ID changed to avoid conflicts. Provides consistent modal styling across all admin pages.

**Files modified:**
- `wwwroot/js/facilities.js` (add ~85 lines after line 5)

**Verification:**
- No build step needed (static JS file)
- Visual check: Modals should render with consistent styling matching Members and Trainers pages

---

### ✅ Step 4: Implement Create Facility Modal
**What:** Replace the stub `showCreateFacilityModal()` function (lines 95-97) with full implementation.

**Where:** `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\facilities.js`

**Change location:** Replace lines 95-97

**Exact replacement:**
```javascript
// BEFORE (lines 95-97):
function showCreateFacilityModal() {
    showError('Chức năng tạo cơ sở chưa được triển khai đầy đủ');
}

// AFTER:
function showCreateFacilityModal() {
    injectFacilityModalStyles();
    
    const modal = document.createElement('div');
    modal.className = 'gym-modal-overlay';
    modal.innerHTML = `
        <div class="gym-modal" style="position: relative;">
            <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()">×</button>
            <h3>➕ Thêm Cơ Sở Vật Chất</h3>
            <form id="createFacilityForm">
                <div class="form-group">
                    <label>Tên cơ sở <span class="required">*</span></label>
                    <input type="text" id="facilityName" name="name" required>
                    <div class="error" id="nameError"></div>
                </div>
                <div class="form-group">
                    <label>Mô tả</label>
                    <textarea id="facilityDescription" name="description" rows="3"></textarea>
                    <div class="error" id="descriptionError"></div>
                </div>
                <div class="form-group">
                    <label>Trạng thái <span class="required">*</span></label>
                    <select id="facilityStatus" name="status" required>
                        <option value="Active">Active</option>
                        <option value="Maintenance">Maintenance</option>
                        <option value="Inactive">Inactive</option>
                    </select>
                    <div class="error" id="statusError"></div>
                </div>
                <div class="gym-modal-buttons">
                    <button type="button" class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                    <button type="submit" class="btn btn-primary">Tạo Cơ Sở</button>
                </div>
            </form>
        </div>
    `;
    document.body.appendChild(modal);
    
    // Form submit handler
    const form = document.getElementById('createFacilityForm');
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        // Validate form
        if (!validateFacilityForm()) {
            return;
        }
        
        // Gather data
        const formData = {
            name: document.getElementById('facilityName').value.trim(),
            description: document.getElementById('facilityDescription').value.trim() || null,
            status: document.getElementById('facilityStatus').value
        };
        
        try {
            showLoading();
            await apiFetch('/api/Facility', {
                method: 'POST',
                body: JSON.stringify(formData)
            });
            hideLoading();
            showSuccess('Tạo cơ sở thành công!');
            modal.remove();
            await loadFacilities();
        } catch (error) {
            hideLoading();
            showError('Lỗi tạo cơ sở: ' + error.message);
        }
    });
}
```

**Rationale:** Follows the exact pattern from `showCreateMemberModal()` in members.js (lines 217-281), adapted for facility fields (Name, Description, Status). Uses the same validation, error handling, and success flow.

**Files modified:**
- `wwwroot/js/facilities.js` (replace lines 95-97 with ~72 lines)

**Verification:**
```powershell
# Start the API
dotnet run --project GymManegement.csproj

# Manual browser test:
# 1. Navigate to http://localhost:5250, login as Admin
# 2. Go to "Cơ Sở Vật Chất" page
# 3. Click "➕ Thêm cơ sở" button
# Expected: Modal appears with Name input, Description textarea, Status dropdown
# 4. Fill form: Name="Test Facility", Description="Test", Status="Active"
# 5. Click "Tạo Cơ Sở"
# Expected: Success toast, modal closes, new facility appears in table
# 6. Check browser console
# Expected: No errors
```

---

### ✅ Step 5: Implement Edit Facility Modal
**What:** Replace the stub `showEditFacilityModal(id)` function (lines 99-101) with full implementation.

**Where:** `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\facilities.js`

**Change location:** Replace lines 99-101

**Exact replacement:**
```javascript
// BEFORE (lines 99-101):
function showEditFacilityModal(id) {
    showError('Chức năng sửa cơ sở chưa được triển khai đầy đủ');
}

// AFTER:
async function showEditFacilityModal(facilityId) {
    injectFacilityModalStyles();
    
    try {
        showLoading();
        const facility = await apiFetch(`/api/Facility/${facilityId}`);
        hideLoading();
        
        if (!facility) {
            showError('Không tìm thấy cơ sở');
            return;
        }
        
        const modal = document.createElement('div');
        modal.className = 'gym-modal-overlay';
        modal.innerHTML = `
            <div class="gym-modal" style="position: relative;">
                <button class="gym-modal-close" onclick="this.closest('.gym-modal-overlay').remove()">×</button>
                <h3>✏️ Sửa Thông Tin Cơ Sở</h3>
                <form id="editFacilityForm">
                    <div class="form-group">
                        <label>Tên cơ sở <span class="required">*</span></label>
                        <input type="text" id="editFacilityName" name="name" value="${escapeHtml(facility.name)}" required>
                        <div class="error" id="editNameError"></div>
                    </div>
                    <div class="form-group">
                        <label>Mô tả</label>
                        <textarea id="editFacilityDescription" name="description" rows="3">${escapeHtml(facility.description || '')}</textarea>
                        <div class="error" id="editDescriptionError"></div>
                    </div>
                    <div class="form-group">
                        <label>Trạng thái <span class="required">*</span></label>
                        <select id="editFacilityStatus" name="status" required>
                            <option value="Active" ${facility.status === 'Active' ? 'selected' : ''}>Active</option>
                            <option value="Maintenance" ${facility.status === 'Maintenance' ? 'selected' : ''}>Maintenance</option>
                            <option value="Inactive" ${facility.status === 'Inactive' ? 'selected' : ''}>Inactive</option>
                        </select>
                        <div class="error" id="editStatusError"></div>
                    </div>
                    <div class="gym-modal-buttons">
                        <button type="button" class="btn btn-secondary" onclick="this.closest('.gym-modal-overlay').remove()">Hủy</button>
                        <button type="submit" class="btn btn-primary">Cập Nhật</button>
                    </div>
                </form>
            </div>
        `;
        document.body.appendChild(modal);
        
        // Form submit handler
        const form = document.getElementById('editFacilityForm');
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            
            // Validate form
            if (!validateFacilityForm(true)) {
                return;
            }
            
            // Gather data
            const formData = {
                name: document.getElementById('editFacilityName').value.trim(),
                description: document.getElementById('editFacilityDescription').value.trim() || null,
                status: document.getElementById('editFacilityStatus').value
            };
            
            try {
                showLoading();
                await apiFetch(`/api/Facility/${facilityId}`, {
                    method: 'PUT',
                    body: JSON.stringify(formData)
                });
                hideLoading();
                showSuccess('Cập nhật cơ sở thành công!');
                modal.remove();
                await loadFacilities();
            } catch (error) {
                hideLoading();
                showError('Lỗi cập nhật cơ sở: ' + error.message);
            }
        });
        
    } catch (error) {
        hideLoading();
        showError('Lỗi tải thông tin cơ sở: ' + error.message);
    }
}
```

**Rationale:** Follows the exact pattern from `showEditMemberModal(memberId)` in members.js (lines 283-366), adapted for facility fields. Fetches current facility data via GET, pre-fills form fields (including selected status), submits via PUT.

**Files modified:**
- `wwwroot/js/facilities.js` (replace lines 99-101 with ~88 lines)

**Verification:**
```powershell
# With API running, manual browser test:
# 1. On "Cơ Sở Vật Chất" page, click edit (✏️) button on any facility row
# Expected: Modal appears with current facility data pre-filled
# 2. Change status from "Active" to "Maintenance"
# 3. Click "Cập Nhật"
# Expected: Success toast, modal closes, table updates to show new status badge
# 4. Check browser console
# Expected: No errors
```

---

### ✅ Step 6: Add Form Validation Function
**What:** Add validation function for facility forms (both create and edit).

**Where:** `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\facilities.js`

**Change location:** Add at the end of the file (after the new `showEditFacilityModal` function)

**Exact addition:**
```javascript
// Add at end of file:

function validateFacilityForm(isEdit = false) {
    const prefix = isEdit ? 'edit' : '';
    const nameInput = document.getElementById(prefix + 'FacilityName') || document.getElementById(prefix === 'edit' ? 'editFacilityName' : 'facilityName');
    const statusInput = document.getElementById(prefix + 'FacilityStatus') || document.getElementById(prefix === 'edit' ? 'editFacilityStatus' : 'facilityStatus');
    
    let isValid = true;
    
    // Clear previous errors
    const nameError = document.getElementById(prefix + 'NameError') || document.getElementById((isEdit ? 'editNameError' : 'nameError'));
    const statusError = document.getElementById(prefix + 'StatusError') || document.getElementById((isEdit ? 'editStatusError' : 'statusError'));
    
    nameError.textContent = '';
    statusError.textContent = '';
    nameInput.classList.remove('invalid');
    statusInput.classList.remove('invalid');
    
    // Validate name
    if (!nameInput.value.trim()) {
        nameError.textContent = 'Vui lòng nhập tên cơ sở';
        nameInput.classList.add('invalid');
        isValid = false;
    } else if (nameInput.value.trim().length < 3) {
        nameError.textContent = 'Tên cơ sở phải có ít nhất 3 ký tự';
        nameInput.classList.add('invalid');
        isValid = false;
    }
    
    // Validate status
    const validStatuses = ['Active', 'Maintenance', 'Inactive'];
    if (!validStatuses.includes(statusInput.value)) {
        statusError.textContent = 'Trạng thái không hợp lệ';
        statusInput.classList.add('invalid');
        isValid = false;
    }
    
    return isValid;
}
```

**Rationale:** Follows the pattern from `validateMemberForm(isEdit)` in members.js (lines 368-416). Validates required name field (min 3 characters) and status field (must be one of the three valid values).

**Files modified:**
- `wwwroot/js/facilities.js` (add ~38 lines at end)

**Verification:**
```powershell
# Manual browser test:
# 1. Click "➕ Thêm cơ sở"
# 2. Leave Name empty, click "Tạo Cơ Sở"
# Expected: Red error message "Vui lòng nhập tên cơ sở", input border turns red
# 3. Enter "AB" (2 chars), click "Tạo Cơ Sở"
# Expected: Error "Tên cơ sở phải có ít nhất 3 ký tự"
# 4. Enter "Test Facility", click "Tạo Cơ Sở"
# Expected: Validation passes, API call is made
```

---

## Risk Assessment

### High Risk
1. **Step 1 & 2 (camelCase conversion)**: BREAKING CHANGE affecting all API endpoints
   - **Impact**: Every API response changes from PascalCase to camelCase
   - **Affected areas**: All 9 admin pages (Members, Trainers, Facilities, Schedules, Sessions, Invoices, Payments, Memberships, Users)
   - **Mitigation**: 
     - Make these changes TOGETHER (Step 1 + Step 2 in same commit)
     - Test ALL admin pages after change
     - If any page breaks, it means there's a mismatch to fix (likely expecting `Data` instead of `Items`)
   - **Rollback plan**: Revert Program.cs change and PagedResult property rename if extensive issues found

### Medium Risk
2. **Property rename conflicts**: Renaming `Data` to `Items` requires updating 23+ files
   - **Impact**: Build will fail until all `.Data` usages are changed to `.Items`
   - **Mitigation**: Use IDE Find & Replace: `.Data` → `.Items` in Service/ and DAL/ folders
   - **Verification**: Build succeeds with 0 errors

### Low Risk
3. **Facilities modals**: Self-contained feature, no impact on existing code
   - **Impact**: Only facilities.js is modified
   - **Rollback**: Easy - revert facilities.js to stub functions

## Testing Checklist

After implementing all steps, test in this order:

### Phase 1: Build Verification
- [ ] `dotnet build GymManegement.csproj` succeeds with 0 errors
- [ ] No breaking changes in C# compilation

### Phase 2: API Response Format Verification
- [ ] Start API: `dotnet run --project GymManegement.csproj`
- [ ] Call any paginated endpoint (e.g., GET /api/Member?pageNumber=1&pageSize=10)
- [ ] Verify response has camelCase keys: `{"items": [...], "total": X, "pageNumber": 1, "pageSize": 10, "totalPages": X}`
- [ ] NOT PascalCase: should NOT see `{"Data": [...], "Total": X, ...}`

### Phase 3: All Admin Pages Data Loading
Test each page loads data correctly after camelCase change:
- [ ] Login as Admin at http://localhost:5250
- [ ] **Members page**: Table loads, pagination works
- [ ] **Trainers page**: Table loads, pagination works
- [ ] **Facilities page**: Table loads, pagination works
- [ ] **Schedules page**: Table loads, pagination works
- [ ] **Sessions page**: Table loads, pagination works
- [ ] **Invoices page**: Table loads, pagination works
- [ ] **Payments page**: Table loads, pagination works
- [ ] **Memberships page**: Table loads, pagination works
- [ ] **Users page**: Table loads, pagination works
- [ ] **Browser console**: No errors on any page

### Phase 4: Facilities CRUD Operations
- [ ] **Create**: Click "➕ Thêm cơ sở", fill form, submit → facility appears in table
- [ ] **Create validation**: Try submitting with empty name → error message appears
- [ ] **Edit**: Click edit (✏️) on a facility → modal pre-fills with current data
- [ ] **Edit submit**: Change status, submit → table updates with new status badge
- [ ] **Modal styling**: Modal looks consistent with Members/Trainers modals
- [ ] **Browser console**: No JavaScript errors

### Phase 5: Regression Testing (Existing Features)
Ensure existing CRUD operations still work:
- [ ] **Members**: Create, edit, delete still work
- [ ] **Trainers**: Create, edit, delete still work
- [ ] **Schedules**: Create, edit, delete still work
- [ ] **Sessions**: Create, edit, delete still work
- [ ] **Invoices**: Create, edit, delete, mark as paid still work
- [ ] **Payments**: Create, delete still work
- [ ] **Users**: Lock/unlock, role change modal still work

## File Change Summary

### Modified Files (7)
1. `Program.cs` - Add JSON camelCase configuration (1 line change → 5 lines)
2. `API/DTOs/Common/PagedResult.cs` - Rename `Data` to `Items` (1 property name)
3. `wwwroot/js/facilities.js` - Add modal styles, implement create/edit/validation (~243 lines added)
4. `Service/BUS/Implementations/*.cs` (10 files) - Change `.Data` to `.Items`
5. `DAL/Repositories/Implementations/*.cs` (13 files) - Change `.Data` to `.Items`

### Total Lines Changed
- Program.cs: +4 lines
- PagedResult.cs: 1 property name
- facilities.js: +243 lines
- Service layer: ~23 occurrences of `.Data` → `.Items`
- Repository layer: ~26 occurrences of `.Data` → `.Items`

## Dependencies

- **Step 3-6 depend on Step 1-2**: Facilities modals won't work until API returns camelCase responses
- **Step 5 depends on Step 4**: Edit modal uses same validation as create modal
- **Step 6 is required by Step 4-5**: Both modals call `validateFacilityForm()`

## Success Criteria

All criteria must pass:
1. ✅ Build succeeds with 0 errors
2. ✅ All API responses return camelCase properties (`items`, `pageNumber`, `total`, etc.)
3. ✅ All 9 admin pages load data correctly (no console errors)
4. ✅ Facilities create modal works: can create new facility, validation works
5. ✅ Facilities edit modal works: pre-fills data, can update facility
6. ✅ Existing CRUD operations (Members, Trainers, etc.) still work
7. ✅ No browser console errors on any page
8. ✅ Modal styling is consistent across all admin pages

## Notes for Implementer

- **IMPORTANT**: Steps 1 and 2 must be done TOGETHER in a single commit. Doing only Step 1 will break the frontend (expects `items` but gets `data`). Doing only Step 2 will break the backend (C# compilation fails).
- **Alternative approach**: If Step 2 (renaming Data→Items) causes unexpected issues, revert both Step 1 and Step 2, then update PagedResult.cs to add BOTH properties:
  ```csharp
  public List<T> Data { get; set; } = new();
  [JsonPropertyName("items")]
  public List<T> Items => Data; // Alias for frontend
  ```
  This keeps backend code unchanged while exposing camelCase `items` to frontend.
- **Code style**: Match existing patterns in members.js and trainers.js for consistency
- **Error messages**: Use Vietnamese language matching existing messages
- **Browser testing**: Chrome/Edge DevTools required for verification (F12 → Console + Network tabs)
