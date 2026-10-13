# Add Human-Readable Names to Admin DTOs

Four admin pages (Memberships, Invoices, Payments, Checkins) now display member and package names instead of raw IDs. The implementation adds name fields to response DTOs and uses batch-fetch to populate them without N+1 query overhead. All 4 services collect IDs, call `GetByIdsAsync` once per entity type, build dictionaries, and map in `Select()`.

**Watch for:** InvoiceResponse is missing the MemberId field (confirmed) - the entity has it, the DTO should expose it for backward compatibility even though the current frontend doesn't use it.

**Verdict**: CHANGES_REQUESTED

## High-level view

All four DTOs gained name fields (MemberName on all, PackageName on Invoice and Membership). The MembershipRepository now has `GetByIdsAsync` following the same Dapper IN-clause pattern as MemberRepository. Each service collects distinct IDs from the result set, fetches entities in a single batch call, builds a dictionary, and passes it to a new ToResponse overload that looks up names. InvoiceService fetches two entity types in parallel (members and memberships). Frontend JS files display the new name fields with null fallbacks (`|| '-'` or `|| 'Member ' + id`). The build succeeded with only dependency version warnings.

InvoiceResponse exposes MembershipId and the new MemberName/PackageName but not MemberId, even though the Invoice entity has MemberId. This breaks the backward compatibility guideline that existing ID fields should be preserved in DTOs.

<details>
<summary>Issues (1)</summary>

1. **InvoiceResponse missing MemberId field** — The Invoice entity has `MemberId` (used throughout InvoiceService for lookups and creation), but InvoiceResponse doesn't expose it. Add `public int MemberId { get; set; }` to InvoiceResponse after InvoiceId. Update the two ToResponse overloads to map `MemberId = i.MemberId`.

</details>

<details>
<summary>Details</summary>

## Batch fetch eliminates N+1 queries

All four services (MembershipService, InvoiceService, PaymentService, CheckinService) follow the same pattern in their `GetAllAsync` methods:

1. Extract distinct IDs: `var memberIds = result.Data.Select(x => x.MemberId).Distinct().ToList()`
2. Batch fetch: `var members = await _memberRepo.GetByIdsAsync(memberIds)`
3. Dictionary: `var memberDict = members.ToDictionary(m => m.MemberId)`
4. Map: `result.Data.Select(x => ToResponse(x, memberDict)).ToList()`

InvoiceService extends this to two entity types, fetching members and memberships in parallel before building both dictionaries.

Each service has two ToResponse overloads: the original parameterless version (used by GetByIdAsync, GetByMemberIdAsync, and other single-item methods) returns empty strings for name fields, and the dictionary-based version (used by GetAllAsync) looks up names. The separation keeps single-item methods simple while the paginated endpoint benefits from batch optimization.

## MembershipRepository GetByIdsAsync follows the pattern

The implementation uses Dapper with an IN clause and the IsDeleted guard:

```csharp
var query = @"
    SELECT * FROM Memberships 
    WHERE MembershipId IN @MembershipIds AND IsDeleted = 0";
```

Dapper maps the list parameter to SQL IN syntax. The method returns an empty list when the input is null or empty rather than hitting the database.

## DTOs gained name fields, kept ID fields

- **MembershipResponse**: Added `MemberName` after `MemberId`. The existing `MemberId` and `PackageName` fields remain unchanged.
- **InvoiceResponse**: Added `MemberName` and `PackageName` after `MembershipId`. The existing `MembershipId` remains. **Missing MemberId** - the entity has it, the DTO should expose it.
- **PaymentResponse**: Added `MemberName` after `MemberId`. The existing `MemberId` and `InvoiceId` remain unchanged.
- **CheckinResponse**: Already had `MemberName` declared but service set it to empty string. The field now gets populated via batch fetch. The existing `MemberId` remains unchanged.

All new properties default to `string.Empty`, matching the project convention.

## InvoiceResponse backward compatibility gap

The Invoice entity has `public int MemberId { get; set; }` (line 7 of Invoice.cs). InvoiceService uses it extensively:

- `CreateAsync` sets `MemberId` from the request or pulls it from the invoice entity
- `GetByMemberIdAsync` filters by MemberId
- The ToResponse method accesses `i.MemberId` to look up member names in the dictionary

But InvoiceResponse doesn't expose MemberId. The DTO has InvoiceId, MembershipId, the new MemberName/PackageName fields, but not MemberId. This breaks the backward compatibility principle: existing ID fields should be preserved even when adding human-readable name fields.

The current frontend doesn't reference `inv.memberId`, so this doesn't break existing behavior, but it's an incomplete mapping that could surprise a future consumer expecting the member ID.

## Frontend null fallbacks

- **memberships.js** line 461: `${m.memberName || 'Member ' + m.memberId}`
- **invoices.js** line 190: `${inv.memberName || '-'}`
- **invoices.js** line 192: `${inv.packageName || (inv.membershipId ? 'MS ' + inv.membershipId : '-')}`
- **payments.js** line 233: `${payment.memberName || 'Member ' + payment.memberId}`
- **checkins.js**: Already had member name rendering; backend now populates the field instead of returning empty string

Each fallback handles the case where the backend returns empty string or the property is missing. The memberships and payments pages fall back to "Member {id}", invoices falls back to '-' for member name and shows the package name with membership ID fallback if available.

## Dependency injection

MembershipService, InvoiceService, and PaymentService all added IMemberRepository to their constructor parameters. InvoiceService also added IMembershipRepository. CheckinService already had IMemberRepository injected (from prior work).

Program.cs already registers all repository interfaces (IMemberRepository, IMembershipRepository, etc.), so no new DI registrations were needed. The build note confirms this.

## Build outcome

The project built successfully with 2 warnings (NU1603) about Microsoft.IdentityModel.Tokens and System.IdentityModel.Tokens.Jwt version resolution. These are non-critical dependency warnings where the package manager found compatible newer versions. Zero compilation errors.

</details>

<details>
<summary>File map</summary>

- `API/DTOs/Membership/MembershipResponse.cs` — added MemberName property
- `API/DTOs/Invoice/InvoiceResponse.cs` — added MemberName and PackageName properties (missing MemberId field)
- `API/DTOs/Payment/PaymentResponse.cs` — added MemberName property
- `API/DTOs/Checkin/CheckinResponse.cs` — no change, already had MemberName field
- `DAL/Repositories/Interfaces/IMembershipRepository.cs` — added GetByIdsAsync signature
- `DAL/Repositories/Implementations/MembershipRepository.cs` — implemented GetByIdsAsync with Dapper IN clause
- `Service/BUS/Implementations/MembershipService.cs` — injected IMemberRepository, batch fetch in GetAllAsync, added ToResponse dictionary overload
- `Service/BUS/Implementations/InvoiceService.cs` — injected IMemberRepository and IMembershipRepository, dual batch fetch in GetAllAsync, added ToResponse dictionary overload
- `Service/BUS/Implementations/PaymentService.cs` — injected IMemberRepository, batch fetch in GetAllAsync, added ToResponse dictionary overload
- `Service/BUS/Implementations/CheckinService.cs` — batch fetch in GetAllAsync, added ToResponse dictionary overload (already had IMemberRepository)
- `wwwroot/js/memberships.js` — display memberName with 'Member ' + id fallback
- `wwwroot/js/invoices.js` — display memberName and packageName with fallbacks
- `wwwroot/js/payments.js` — display memberName with 'Member ' + id fallback
- `wwwroot/js/checkins.js` — no change, already rendering memberName

See full diff: `git show 296621d`

</details>
