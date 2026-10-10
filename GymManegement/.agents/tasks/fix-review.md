# Middleware ordering and error handling consistency

The changes move GlobalExceptionMiddleware before CORS in the middleware pipeline and standardize error handling in InvoiceService. Two files changed, addressing middleware placement and service layer consistency.

**Watch for:** InvalidOperationException from SessionService will now return 400 (expected), but middleware placement before CORS means unhandled exceptions from CORS itself are now caught — unintended benefit. MemberId validation adds a database round-trip on every session creation (confirmed performance cost).

**Verdict**: APPROVED

## High-level view

The middleware now sits before CORS, static files, and authentication, catching exceptions from the entire downstream pipeline. This follows ASP.NET Core conventions (exception handling → CORS → auth → endpoints) and ensures consistent error responses across all middleware layers.

InvoiceService.UpdateAsync now returns null for missing entities instead of throwing KeyNotFoundException, matching the pattern used by MemberService, TrainerService, and other services. Controllers already handle null by returning 404, so the HTTP response stays the same.

SessionService validates MemberId > 0 and confirms the member exists before creating a session. Both checks throw InvalidOperationException, which the middleware catches and converts to 400 Bad Request. The member existence check adds a database query to the session creation path; this is a documented tradeoff for explicit validation over relying on foreign key constraint failures.

<details>
<summary>Issues (1)</summary>

1. **MemberId validation adds database round-trip** — SessionService.CreateAsync queries the member table on every session creation to validate MemberId. Consider caching member IDs or deferring to database foreign key constraints if session creation latency becomes a concern.

</details>

<details>
<summary>Details</summary>

## Middleware pipeline order

Program.cs now registers GlobalExceptionMiddleware immediately after `UseHttpsRedirection()` and before `UseCors()`. The previous order had the middleware after CORS, meaning exceptions thrown by CORS middleware itself would bypass the global handler.

The new order:
```
UseHttpsRedirection()
→ GlobalExceptionMiddleware
→ UseCors()
→ UseDefaultFiles()
→ UseStaticFiles()
→ UseAuthentication()
→ UseAuthorization()
→ MapControllers()
```

The middleware converts InvalidOperationException and ArgumentException to 400, KeyNotFoundException to 404, and all other exceptions to 500 with a sanitized message ("Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.").

## Session creation validation

SessionService.CreateAsync validates MemberId in two steps:

1. **Range check**: `if (request.MemberId <= 0)` throws InvalidOperationException
2. **Existence check**: `await _memberRepo.GetByIdAsync(request.MemberId)` queries the member table; if null, throws InvalidOperationException

The existence check adds a SELECT query to the session creation path. If session creation is high-volume, this could be optimized by caching member IDs or accepting foreign key failures as the validation mechanism.

RegistrationDate defaults to `DateTime.UtcNow` if the request provides `DateTime.MinValue`, preventing SQL Server datetime range errors (SQL Server datetime minimum is 1753-01-01, C# DateTime.MinValue is 0001-01-01).

## InvoiceService consistency

InvoiceService.UpdateAsync previously threw KeyNotFoundException when the invoice didn't exist:

```csharp
if (entity is null)
    throw new KeyNotFoundException($"Hóa đơn với ID {id} không tồn tại.");
```

Now it returns null:

```csharp
if (entity is null) return null;
```

This matches the pattern in MemberService.UpdateAsync, TrainerService.UpdateAsync, ScheduleService.UpdateAsync, and PaymentService.UpdateAsync. Controllers check for null and return 404, so the HTTP response is unchanged. The difference is whether the 404 path goes through exception handling (throw → catch in middleware → log → return 404) or a direct return (return null → controller checks → return 404). The direct return is faster and doesn't log a warning, which is appropriate since "resource not found" is a normal client error, not an exceptional condition.

GlobalExceptionMiddleware still handles KeyNotFoundException for any code that does throw it, so this change doesn't break backward compatibility if other services still use exceptions for not-found cases.

## Error response shape

GlobalExceptionMiddleware returns JSON with `statusCode` and `message` fields:

```json
{
  "statusCode": 400,
  "message": "MemberId phải được cung cấp và lớn hơn 0."
}
```

For 500 errors, the message is sanitized to "Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau." regardless of the actual exception message, preventing internal details from leaking to clients. The full exception is logged via `ILogger<GlobalExceptionMiddleware>` at Error level, so it's captured for debugging without exposing it in the response.

Controllers don't need try-catch blocks around service calls. InvalidOperationException, ArgumentException, and KeyNotFoundException propagate to the middleware and return the appropriate status code. Unhandled exceptions become 500 responses.

## Test coverage gap

The changes were verified by build (confirmed: build succeeds), but runtime behavior wasn't tested. The review relies on code inspection to confirm:

- SessionService throws InvalidOperationException for MemberId <= 0 and nonexistent members (confirmed by reading SessionService.cs lines 54-60)
- InvoiceService.UpdateAsync returns null for missing invoices (confirmed by reading InvoiceService.cs lines 70-72)
- GlobalExceptionMiddleware catches InvalidOperationException and returns 400 (confirmed by reading GlobalExceptionMiddleware.cs lines 20-24)
- Middleware is registered before CORS (confirmed by reading Program.cs lines 107-111)

Not tested:
- Actual HTTP response when POST /api/session is called with MemberId=0
- Actual HTTP response when POST /api/session is called with a nonexistent MemberId
- Actual HTTP response when PUT /api/invoice/{id} is called with a nonexistent ID
- Middleware behavior when CORS middleware throws an exception (edge case, unlikely in practice)

</details>

<details>
<summary>File map</summary>

**2 files changed**

- `Program.cs` — moved GlobalExceptionMiddleware registration before UseCors()
- `Service/BUS/Implementations/InvoiceService.cs` — UpdateAsync returns null instead of throwing KeyNotFoundException
- `Service/BUS/Implementations/SessionService.cs` — already contained MemberId validation (no changes in this pass)
- `Middleware/GlobalExceptionMiddleware.cs` — pre-existing middleware (no changes)

Full diff available in `.agents/tasks/fix-changes.md`

</details>
