# Implementation Plan: FEAT-004 - Role Change Endpoint

## Architecture decisions

**Service layer pattern**: Follow existing AuthService pattern - add `UpdateUserRoleAsync(int userId, string newRole)` to IAuthService interface and implementation. The service validates role enum ("Admin", "Trainer", "Member"), calls `_userRepo.GetByIdAsync()` to verify user exists, then calls `_userRepo.UpdateAsync(user)` with modified Role property. This matches the SetActiveAsync pattern already in AuthService.cs.

**Repository layer**: UserRepository.UpdateAsync() already exists and updates FullName, Email, Role, IsActive, and UpdatedAt - no repository changes needed. The existing method at line 76-88 handles all fields including Role.

**DTO location**: Create UpdateUserRoleRequest.cs in `API/DTOs/Auth/` to match CreateStaffRequest.cs pattern.

**Frontend logic**: Replace showChangeRoleModal placeholder with functional implementation that follows the existing modal patterns in users.js - show user info, dropdown with current role pre-selected, confirmation flow, and API call to PUT endpoint.

**Verification**: Build with `dotnet build`, manual test with `dotnet run` at http://localhost:5250 - login as Admin, navigate to Users page, change a user's role, verify the role badge updates and API returns success.

## Implementation Plan

- [ ] 1. Create UpdateUserRoleRequest DTO in API/DTOs/Auth/UpdateUserRoleRequest.cs with Role property and validation attribute requiring "Admin", "Trainer", or "Member".
      Files: `d:\Workspace\Độ án 2\GymManegement\GymManegement\API\DTOs\Auth\UpdateUserRoleRequest.cs`
      Verify: `dotnet build GymManegement.csproj` succeeds with no errors.

- [ ] 2. Add UpdateUserRoleAsync method signature to IAuthService interface in Service/BUS/Interfaces/IAuthService.cs.
      Method: `Task<bool> UpdateUserRoleAsync(int userId, string newRole);`
      Files: `d:\Workspace\Độ án 2\GymManegement\GymManegement\Service\BUS\Interfaces\IAuthService.cs`
      Verify: `dotnet build GymManegement.csproj` succeeds with no errors.

- [ ] 3. Implement UpdateUserRoleAsync in AuthService (Service/BUS/Implementations/AuthService.cs).
      Logic: Validate newRole is "Admin", "Trainer", or "Member"; fetch user with `await _userRepo.GetByIdAsync(userId)`; if null return false; set `user.Role = newRole`; call `await _userRepo.UpdateAsync(user)`; return true.
      Files: `d:\Workspace\Độ án 2\GymManegement\GymManegement\Service\BUS\Implementations\AuthService.cs`
      Verify: `dotnet build GymManegement.csproj` succeeds with no errors.

- [ ] 4. Add PUT /api/Auth/users/{id}/role endpoint to AuthController.
      Method signature: `[HttpPut("users/{id:int}/role")] [Authorize(Roles = "Admin")] public async Task<IActionResult> UpdateUserRole(int id, [FromBody] UpdateUserRoleRequest request)`
      Logic: Validate ModelState, call `await _service.UpdateUserRoleAsync(id, request.Role)`, return Ok with success message or NotFound if user doesn't exist.
      Response format: `Ok(new { message = "Đã thay đổi vai trò thành công." })` on success, `NotFound()` if user not found, `BadRequest(ModelState)` if validation fails.
      Files: `d:\Workspace\Độ án 2\GymManegement\GymManegement\Controllers\AuthController.cs`
      Verify: `dotnet build GymManegement.csproj` succeeds with no errors.

- [ ] 5. Replace showChangeRoleModal placeholder in wwwroot/js/users.js with functional implementation.
      Replace the current showChangeRoleModal function (lines 339-342) with a version that accepts (userId, username, currentRole) parameters, builds HTML form with user info display, role dropdown (Admin/Trainer/Member options), pre-selects currentRole, stores userId in data attribute, and calls modal.classList.add('show').
      Add confirmRoleChange() function to handle form submission: read userId from data attribute, read selected role from dropdown, confirm with user dialog, call apiFetch(`/api/Auth/users/${userId}/role`, {method: 'PUT', body: JSON.stringify({role: newRole})}), show success/error toast, reload users table on success.
      Files: `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\users.js`
      Verify: Start server with `dotnet run`, navigate to http://localhost:5250, login as Admin (username: admin, check existing data for credentials), click Users tab, click "Đổi vai trò" button on any user row, verify modal shows with user info and role dropdown, select new role, click confirm, verify success toast appears and table refreshes with updated role badge color.

- [ ] 6. Update changeRoleModal HTML in renderUsers function to include functional form structure.
      Replace placeholder modal content (lines 104-121) with: form with id="changeRoleForm", hidden input for userId, display of username (read-only), select dropdown with id="newRoleSelect" containing Admin/Trainer/Member options, submit button calling confirmRoleChange(), error message div with id="changeRoleError" (display: none by default).
      Files: `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\users.js`
      Verify: After making change, refresh browser at http://localhost:5250/users, verify modal HTML structure includes form elements, test role change again to confirm form submission works correctly.

## Notes

- UserRepository.UpdateAsync() already exists and updates the Role field along with FullName, Email, IsActive, and UpdatedAt - verified at line 76-88 of UserRepository.cs.
- The existing UPDATE SQL in UpdateAsync includes `Role = @Role` - no database schema or repository changes needed.
- AuthController uses `_service` field of type IAuthService (injected via constructor at line 13) - follow this pattern for the new endpoint.
- Existing endpoints return `Ok(new { message = "..." })` for success and `NotFound()` or `BadRequest(...)` for errors - match this format.
- Frontend users.js already has role badge color logic: Admin=badge-danger (red), Trainer=badge-primary (blue), Member=badge-success (green) - no changes needed, badges will auto-update on table refresh.
- The showChangeRoleModal function is called from renderUsersTable at line 300 with parameters (userId, username, currentRole) - implementation must accept these parameters.
- Modal pattern: add/remove 'show' class on .modal element, use closeChangeRoleModal() to remove 'show' class.
- After successful role change, call `await loadUsers()` to refresh the table and show updated role badge.
