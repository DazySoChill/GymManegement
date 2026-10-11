# Role-change endpoint and frontend integration

This change implements the backend API endpoint for changing user roles and wires it to the existing frontend role-change modal. The endpoint restricts role changes to admins, validates role values at both the DTO and service layer, prevents self-role-change, and returns appropriate HTTP status codes. The frontend modal dynamically generates a role selector excluding the user's current role and calls the new endpoint on confirmation.

**Watch for:** No concerns remain. All blocking issues from prior reviews have been resolved.

**Verdict**: APPROVED

## High-level view

The backend adds a PUT endpoint at `/api/Auth/users/{id}/role` protected by admin-only authorization. The endpoint extracts the admin's user ID from the JWT and blocks role changes if the target ID matches, preventing admin lockout. Role values are validated at both the DTO layer (regex) and service layer (hardcoded array), though the service's false-return for invalid roles gets mistranslated to 404 NotFound—unreachable in practice since the DTO regex catches all invalid values first. The frontend `showChangeRoleModal` dynamically builds a modal with a role dropdown excluding the current role, removes any existing modal before rendering to prevent DOM accumulation, and uses `escapeHtml()` on interpolated username/role values.

<details>
<summary>Issues (0)</summary>

No blocking issues. The service's false-return for invalid roles is mistranslated to 404 NotFound, but this path is unreachable since DTO validation catches all invalid values first.

</details>

<details>
<summary>Details</summary>

## Self-change prevention

The controller endpoint extracts the current user's ID from the JWT sub claim and compares it to the target user ID. If they match, it returns 400 BadRequest. This prevents an admin from changing their own role to Member or Trainer, which would lock them out of admin operations.

## Service false-return mistranslated to 404

The service's `UpdateUserRoleAsync` validates the role against `validRoles` array and returns `false` if invalid. The controller translates this to 404 NotFound: `return ok ? Ok(...) : NotFound(...)`. A validation failure is not a "not found" condition. The DTO's `[RegularExpression]` catches all invalid role values before they reach the service, so this path is unreachable, but the translation is misleading if someone reads the code or if the DTO validation is ever bypassed.

## Frontend modal cleanup

The `showChangeRoleModal` function calls `getElementById('changeRoleModal').remove()` before creating a new modal. Without this, calling the function twice without closing the modal would append a second modal to the DOM. The old modal would remain hidden but still registered in event listeners and consuming memory.

</details>

<details>
<summary>File map</summary>

- **API/DTOs/Auth/UpdateUserRoleRequest.cs** — new DTO with Required and RegularExpression validation for role field
- **Controllers/AuthController.cs** — new PUT endpoint `/api/Auth/users/{id:int}/role` with Admin authorization and self-change prevention
- **Service/BUS/Interfaces/IAuthService.cs** — added `UpdateUserRoleAsync(int userId, string newRole)` to interface
- **Service/BUS/Implementations/AuthService.cs** — implemented `UpdateUserRoleAsync` with role validation and repository call
- **wwwroot/js/users.js** — replaced stub modal with functional implementation: dynamic modal generation, role dropdown, API call, error handling

Full diff: `git diff HEAD -- Controllers/AuthController.cs Service/BUS/Implementations/AuthService.cs Service/BUS/Interfaces/IAuthService.cs wwwroot/js/users.js API/DTOs/Auth/UpdateUserRoleRequest.cs`

</details>
