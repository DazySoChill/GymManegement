# Implementation Plan: Add Human-Readable Names to 4 Admin Pages

## Background
Phase 1 already added `memberName`, `trainerName`, `facilityName` to `SessionResponse` and `ScheduleResponse` using a batch-fetch pattern with `GetByIdsAsync` to avoid N+1 query issues. `MemberRepository.GetByIdsAsync` already exists and follows this pattern.

`CheckinResponse` already has `MemberName` field but `CheckinService.ToResponse()` sets it to `string.Empty` instead of fetching the actual name.

This plan will add human-readable names to:
1. **MembershipResponse** - needs `memberName`
2. **InvoiceResponse** - needs `memberName` (from Invoice.MemberId - already exists in entity), `membershipId` → show `packageName`
3. **PaymentResponse** - needs `memberName` (from Payment.MemberId - already exists)
4. **CheckinResponse** - already has `MemberName` field, just need to populate it in service

## Current State Analysis

### DTOs Currently
- **MembershipResponse**: Has `MemberId`, `PackageName` (literal string, not FK). Needs `MemberName` added.
- **InvoiceResponse**: Has `MembershipId`. Needs `MemberName` and `PackageName` (from the membership) added.
- **PaymentResponse**: Has `MemberId`. Needs `MemberName` added.
- **CheckinResponse**: Already has `MemberName` field but service sets it to empty string.

### Repositories
- `IMemberRepository.GetByIdsAsync(List<int>)` - **EXISTS** ✓
- `IMembershipRepository.GetByIdsAsync(List<int>)` - **DOES NOT EXIST** - needs to be added
- No Package entity or repository exists (PackageName is a literal string in Membership table)

### Services
- `MembershipService`: Uses only `IMembershipRepository` (single repo injection)
- `InvoiceService`: Uses `IInvoiceRepository` + `IInvoiceRepository` (2 repos)
- `PaymentService`: Uses `IPaymentRepository` + `IInvoiceRepository` (2 repos)
- `CheckinService`: Already injects `IMemberRepository` ✓ - just not using it for batch fetch

### Frontend JS
All 4 files (`memberships.js`, `invoices.js`, `payments.js`, `checkins.js`) need null-safe access with `|| '-'` fallbacks where names are displayed.

## Plan Items

- [ ] 1. Add `GetByIdsAsync` method to `IMembershipRepository` interface.
      Files: `d:\Workspace\Độ án 2\GymManegement\GymManegement\DAL\Repositories\Interfaces\IMembershipRepository.cs`
      Add signature: `Task<List<Membership>> GetByIdsAsync(List<int> membershipIds);`
      Verify: Build succeeds (`dotnet build` or equivalent)

- [ ] 2. Implement `GetByIdsAsync` in `MembershipRepository` following the exact pattern from `MemberRepository.GetByIdsAsync`.
      Files: `d:\Workspace\Độ án 2\GymManegement\GymManegement\DAL\Repositories\Implementations\MembershipRepository.cs`
      Add method with `WHERE MembershipId IN @MembershipIds AND IsDeleted = 0` query using Dapper.
      Verify: Build succeeds

- [ ] 3. Add `MemberName` property to `MembershipResponse` DTO.
      Files: `d:\Workspace\Độ án 2\GymManegement\GymManegement\API\DTOs\Membership\MembershipResponse.cs`
      Add: `public string MemberName { get; set; } = string.Empty;` after `MemberId`
      Verify: Build succeeds

- [ ] 4. Add `MemberName` and `PackageName` properties to `InvoiceResponse` DTO.
      Files: `d:\Workspace\Độ án 2\GymManegement\GymManegement\API\DTOs\Invoice\InvoiceResponse.cs`
      Add: `public string MemberName { get; set; } = string.Empty;` after `MembershipId`
      Add: `public string PackageName { get; set; } = string.Empty;` after `MemberName`
      Verify: Build succeeds

- [ ] 5. Add `MemberName` property to `PaymentResponse` DTO.
      Files: `d:\Workspace\Độ án 2\GymManegement\GymManegement\API\DTOs\Payment\PaymentResponse.cs`
      Add: `public string MemberName { get; set; } = string.Empty;` after `MemberId`
      Verify: Build succeeds

- [ ] 6. Update `MembershipService.GetAllAsync` to use batch fetch pattern for member names.
      Files: `d:\Workspace\Độ án 2\GymManegement\GymManegement\Service\BUS\Implementations\MembershipService.cs`
      - Inject `IMemberRepository` in constructor (add parameter, store in field `_memberRepo`)
      - In `GetAllAsync`: collect all `MemberId` values, call `_memberRepo.GetByIdsAsync`, build dictionary, use in mapping
      - Add new overload: `ToResponse(Membership m, Dictionary<int, Member> memberDict)` that looks up member name
      - Keep original `ToResponse(Membership m)` for single-item methods (`GetByIdAsync`)
      Verify: Build succeeds

- [ ] 7. Update `InvoiceService.GetAllAsync` to batch-fetch both members and memberships.
      Files: `d:\Workspace\Độ án 2\GymManegement\GymManegement\Service\BUS\Implementations\InvoiceService.cs`
      - Inject `IMemberRepository` and `IMembershipRepository` in constructor
      - In `GetAllAsync`: collect distinct `MemberId` and `MembershipId` (filter nulls), call `GetByIdsAsync` on both, build dictionaries
      - Add overload: `ToResponse(Invoice i, Dictionary<int, Member> memberDict, Dictionary<int, Membership> membershipDict)`
      - Keep original `ToResponse(Invoice i)` for single-item methods
      Verify: Build succeeds

- [ ] 8. Update `PaymentService.GetAllAsync` to batch-fetch member names.
      Files: `d:\Workspace\Độ án 2\GymManegement\GymManegement\Service\BUS\Implementations\PaymentService.cs`
      - Inject `IMemberRepository` in constructor (add parameter, store in field `_memberRepo`)
      - In `GetAllAsync`: collect distinct `MemberId`, call `_memberRepo.GetByIdsAsync`, build dictionary
      - Add overload: `ToResponse(Payment p, Dictionary<int, Member> memberDict)` 
      - Keep original `ToResponse(Payment p)` for single-item methods
      Verify: Build succeeds

- [ ] 9. Update `CheckinService.GetAllAsync` to populate `MemberName` using batch fetch.
      Files: `d:\Workspace\Độ án 2\GymManegement\GymManegement\Service\BUS\Implementations\CheckinService.cs`
      - `CheckinService` already injects `IMemberRepository` ✓
      - In `GetAllAsync`: collect distinct `MemberId`, call `_memberRepo.GetByIdsAsync`, build dictionary
      - Add overload: `ToResponse(Checkin c, Dictionary<int, Member> memberDict)` that looks up member name
      - Use the dictionary overload in `GetAllAsync`, keep original `ToResponse(Checkin c)` for other methods
      Verify: Build succeeds

- [ ] 10. Register new repository dependency in `Program.cs` if any service added a new repo injection.
      Files: `d:\Workspace\Độ án 2\GymManegement\GymManegement\Program.cs`
      Check: `IMemberRepository`, `IMembershipRepository` are already registered ✓. No new registrations needed.
      Verify: Build succeeds

- [ ] 11. Update `memberships.js` frontend to display `memberName` with null fallback.
      Files: `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\memberships.js`
      In `renderMembershipsTable`: Change `<td>${m.memberId}</td>` to `<td>${m.memberName || 'Member ' + m.memberId}</td>`
      Verify: Open Memberships page in browser, confirm member names display (not just IDs)

- [ ] 12. Update `invoices.js` frontend to display `memberName` and `packageName` with null fallbacks.
      Files: `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\invoices.js`
      In `renderInvoicesTable`: 
      - Add column for Member Name: `<th>Member</th>`
      - Display: `<td>${inv.memberName || 'Member ' + inv.memberId}</td>`
      - Change MembershipId column to show package: `<td>${inv.packageName || (inv.membershipId ? 'MS ' + inv.membershipId : '-')}</td>`
      In `renderMemberInvoices` (member view): same changes
      Verify: Open Invoices page, confirm member names and package names display

- [ ] 13. Update `payments.js` frontend to display `memberName` with null fallback.
      Files: `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\payments.js`
      In `renderPaymentsTable`: Change `<td>${payment.memberId || '-'}</td>` to `<td>${payment.memberName || 'Member ' + payment.memberId}</td>`
      Verify: Open Payments page, confirm member names display

- [ ] 14. Update `checkins.js` frontend to display `memberName` (should already be coming from backend after step 9).
      Files: `d:\Workspace\Độ án 2\GymManegement\GymManegement\wwwroot\js\checkins.js`
      In `renderCheckinsTable`: Confirm it already uses `${escapeHtml(memberName)}` - already correct ✓
      The JS already has client-side fallback logic via `fetchCheckinMemberName` - no change needed.
      Verify: Open Checkins page, confirm member names display from backend (not client-side fetch fallback)

- [ ] 15. Run full build and verify no compilation errors.
      Command: `dotnet build` (or the project's build command)
      Verify: Build succeeds with 0 errors

- [ ] 16. Test all 4 admin pages in the browser.
      Manual test:
      - Navigate to Memberships page → member names display (not just IDs)
      - Navigate to Invoices page → member names and package names display
      - Navigate to Payments page → member names display
      - Navigate to Checkins page → member names display
      Verify: All 4 pages show human-readable names instead of raw IDs

## Conflict Risks
- **Low risk**: Adding new properties to DTOs is additive (no breaking changes to existing code)
- **Low risk**: Adding `GetByIdsAsync` to `IMembershipRepository` follows existing pattern from `IMemberRepository`
- **Medium risk**: Constructor changes in services - ensure all DI registrations in `Program.cs` are correct (already verified they exist)
- **Low risk**: Frontend changes are isolated to display logic (no API contract changes)

## Key Pattern to Follow
All batch fetch implementations must follow this exact pattern from `SessionService.GetAllAsync`:

```csharp
// 1. Collect distinct IDs
var memberIds = sessions.Select(s => s.MemberId).Distinct().ToList();

// 2. Batch fetch (parallel if multiple repos)
var members = await _memberRepo.GetByIdsAsync(memberIds);

// 3. Build dictionary for O(1) lookup
var memberDict = members.ToDictionary(m => m.MemberId);

// 4. Map using dictionary in loop (no DB calls in loop!)
var responses = sessions.Select(s => ToResponse(s, memberDict)).ToList();
```

## Notes
- No Package entity/repository exists - `PackageName` in Membership is a literal string stored in the database
- `CheckinResponse.MemberName` field already exists but is unused - we're just wiring it up
- All services already have their repositories registered in `Program.cs` - no new registrations needed
- Frontend files already have defensive `|| '-'` patterns in some places - ensure consistency across all 4 files
