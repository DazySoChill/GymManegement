# Implementation Plan: Database Schema Fix & Feature Addition

## Context Summary

**Project Type**: ASP.NET Core 8.0 Web API with Dapper ORM, SQL Server database  
**Language**: C#  
**Database**: SQL Server (GymDb)  
**Build**: `dotnet build` / `dotnet run`  
**Test**: Manual testing via Swagger UI at `/swagger` after running project

### Current Issues Identified

1. **Invoices table schema mismatch**:
   - DB schema (01_SCHEMA_SIMPLIFIED.sql) has `MemberId` column
   - InvoiceRepository.CreateAsync SQL **does NOT include MemberId** in INSERT statement
   - InvoiceRepository.GetByMemberIdAsync joins via Memberships table instead of direct MemberId lookup

2. **Memberships table column naming**:
   - DB schema has `MembershipType` column
   - C# entity and repositories use `PackageName` column
   - Need to verify which is in actual DB and align them

3. **Schedules table schema mismatch**:
   - DB schema (01_SCHEMA_SIMPLIFIED.sql) has `MemberId` column (FK to Members)
   - C# entity Schedule has NO MemberId property
   - C# ScheduleRepository INSERT uses `ClassName` and `MaxCapacity` (not in DB schema)
   - DB schema has `ScheduledDate` DATE + `StartTime`/`EndTime` TIME
   - C# entity has `StartTime`/`EndTime` as DATETIME (not separate date/time)

4. **Sessions table correct structure**:
   - Both DB and C# have: ScheduleId, MemberId, RegistrationDate, Status ✓

5. **Checkins table schema mismatch**:
   - DB schema has `SessionId` column (nullable FK)
   - C# entity Checkin has NO SessionId property
   - C# entity has `CheckoutTime` (nullable)
   - DB schema has `CheckinMethod` (Manual | QR)
   - Need to align: keep MemberId-based only (no SessionId), add CheckoutTime

6. **Payments table**:
   - ALTER script exists (ALTER_PAYMENTS_TABLE.sql) to add MemberId, TransactionId, Status
   - C# entity Payment already has these fields ✓
   - PaymentRepository CreateAsync already uses these columns ✓
   - Need to ensure ALTER script has been run

7. **Missing cancel membership feature**:
   - No CancelAsync in IMembershipRepository or IMembershipService
   - No cancel endpoint in MembershipController
   - No frontend cancel button

8. **MembershipService.CreateAsync bug**:
   - When creating auto-invoice, does NOT set `invoice.MemberId = membership.MemberId`
   - This causes invoice to have MemberId = 0 (default value)

---

## Implementation Plan

- [ ] 1. **Analyze current database schema vs code expectations**
      
      Read and compare:
      - SQL2/01_SCHEMA_SIMPLIFIED.sql (current schema)
      - All C# entity files in DAL/Entities/
      - All repository INSERT statements
      
      Create a schema gap analysis document listing:
      - Columns in DB but not in C# entities
      - Columns in C# entities but not in DB
      - Type mismatches (DATE vs DATETIME, etc.)
      
      **Files**: SQL2/01_SCHEMA_SIMPLIFIED.sql, DAL/Entities/*.cs, DAL/Repositories/Implementations/*.cs  
      **Verify**: Document created at .agents/tasks/schema-gap-analysis.txt showing all mismatches

- [ ] 2. **Create comprehensive schema fix SQL script**
      
      Write SQL2/COMPLETE_SCHEMA_FIX.sql with IF NOT EXISTS guards to:
      
      **Memberships table**:
      - Rename `MembershipType` to `PackageName` (if MembershipType exists)
      - OR add `PackageName` column (if it doesn't exist)
      - Ensure columns: MembershipId, MemberId, PackageName, Price, StartDate, EndDate, CreatedAt, UpdatedAt, IsDeleted, DeletedAt
      
      **Invoices table**:
      - Ensure `MemberId` column exists (INT NOT NULL with FK to Members)
      - Ensure `MembershipId` is nullable (INT NULL)
      - Ensure `DueDate` is nullable (DATE NULL)
      - Ensure `UpdatedAt` is nullable (DATETIME2 NULL)
      - Rename `Amount` to `TotalAmount` if needed
      - Rename `IssueDate` to `InvoiceDate` if needed
      
      **Schedules table**:
      - **REMOVE** MemberId column if it exists (Schedules don't belong to one member)
      - **ADD** ClassName NVARCHAR(100) NOT NULL DEFAULT ''
      - **ADD** MaxCapacity INT NOT NULL DEFAULT 20
      - **CHANGE** ScheduledDate + StartTime/EndTime (DATE + TIME) to just StartTime/EndTime (DATETIME2)
      - Ensure columns: ScheduleId, TrainerId, FacilityId, ClassName, StartTime, EndTime, MaxCapacity, CreatedAt, UpdatedAt, IsDeleted, DeletedAt
      
      **Sessions table**:
      - Ensure correct structure: SessionId, ScheduleId, MemberId, RegistrationDate, Status, CreatedAt, UpdatedAt, IsDeleted, DeletedAt
      - Remove ActualStartTime/ActualEndTime/Notes if they exist (not in C# entity)
      
      **Checkins table**:
      - **REMOVE** SessionId column if it exists
      - **REMOVE** CheckinMethod column if it exists
      - **ADD** CheckoutTime DATETIME2 NULL (if not exists)
      - Ensure columns: CheckinId, MemberId, CheckinTime, CheckoutTime, CreatedAt, UpdatedAt, IsDeleted, DeletedAt
      
      **Payments table**:
      - Run the existing ALTER_PAYMENTS_TABLE.sql logic inline (with IF NOT EXISTS guards)
      - Ensure columns: PaymentId, InvoiceId (nullable), MemberId, Amount, PaymentMethod, PaymentDate, TransactionId, Status, CreatedAt, UpdatedAt, IsDeleted, DeletedAt
      
      **Users table**:
      - Verify structure matches: UserId, Username, PasswordHash, FullName, Email, Role, IsActive, CreatedAt, UpdatedAt, IsDeleted, DeletedAt
      
      **Members, Trainers, Facilities**:
      - Verify these tables match C# entities (should already be correct)
      
      **Files**: SQL2/COMPLETE_SCHEMA_FIX.sql (new file)  
      **Verify**: Script runs without errors: `sqlcmd -S localhost -d GymDb -i SQL2/COMPLETE_SCHEMA_FIX.sql` (or via SSMS)

- [ ] 3. **Fix InvoiceRepository.CreateAsync SQL**
      
      In DAL/Repositories/Implementations/InvoiceRepository.cs:
      - Update CreateAsync INSERT statement to include `MemberId` column
      - Current: `INSERT INTO Invoices (MembershipId, TotalAmount, InvoiceDate, DueDate, Status, Description, CreatedAt, UpdatedAt, IsDeleted)`
      - Fixed: `INSERT INTO Invoices (MemberId, MembershipId, TotalAmount, InvoiceDate, DueDate, Status, Description, CreatedAt, UpdatedAt, IsDeleted)`
      - Add `entity.MemberId` to the parameters object
      
      Update GetByMemberIdAsync to use direct MemberId column:
      - Current: Joins via Memberships table
      - Fixed: `SELECT * FROM Invoices WHERE MemberId = @MemberId AND IsDeleted = 0 ORDER BY InvoiceDate DESC`
      
      **Files**: DAL/Repositories/Implementations/InvoiceRepository.cs  
      **Verify**: `dotnet build` succeeds with no errors

- [ ] 4. **Fix MembershipService.CreateAsync to populate Invoice.MemberId**
      
      In Service/BUS/Implementations/MembershipService.cs, in CreateAsync method:
      - When creating the auto-invoice, add: `MemberId = membership.MemberId`
      - Current code creates invoice without MemberId field
      - Fixed code:
        ```csharp
        var invoice = new Invoice
        {
            MemberId = membership.MemberId,        // ADD THIS LINE
            MembershipId = membership.MembershipId,
            InvoiceDate = DateTime.Today,
            DueDate = membership.EndDate,
            TotalAmount = membership.Price,
            Status = "Pending",
            Description = $"Hóa đơn cho gói tập {membership.PackageName}"
        };
        ```
      
      **Files**: Service/BUS/Implementations/MembershipService.cs  
      **Verify**: `dotnet build` succeeds with no errors

- [ ] 5. **Add cancel membership repository method**
      
      In DAL/Repositories/Interfaces/IMembershipRepository.cs:
      - Add method signature: `Task<bool> CancelAsync(int membershipId);`
      
      In DAL/Repositories/Implementations/MembershipRepository.cs:
      - Implement CancelAsync:
        ```csharp
        public async Task<bool> CancelAsync(int membershipId)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE Memberships 
                SET EndDate = CAST(GETDATE() AS DATE),
                    UpdatedAt = GETDATE()
                WHERE MembershipId = @MembershipId 
                  AND IsDeleted = 0
                  AND EndDate > CAST(GETDATE() AS DATE)";
            var rowsAffected = await conn.ExecuteAsync(sql, new { MembershipId = membershipId });
            return rowsAffected > 0;
        }
        ```
      - Logic: Set EndDate to today (effectively cancels it), only if it's currently active (EndDate > today)
      
      **Files**: DAL/Repositories/Interfaces/IMembershipRepository.cs, DAL/Repositories/Implementations/MembershipRepository.cs  
      **Verify**: `dotnet build` succeeds with no errors

- [ ] 6. **Add cancel membership service method**
      
      In Service/BUS/Interfaces/IMembershipService.cs:
      - Add method signature: `Task<bool> CancelAsync(int membershipId);`
      
      In Service/BUS/Implementations/MembershipService.cs:
      - Implement CancelAsync:
        ```csharp
        public async Task<bool> CancelAsync(int membershipId)
        {
            return await _repo.CancelAsync(membershipId);
        }
        ```
      
      **Files**: Service/BUS/Interfaces/IMembershipService.cs, Service/BUS/Implementations/MembershipService.cs  
      **Verify**: `dotnet build` succeeds with no errors

- [ ] 7. **Add cancel membership controller endpoint**
      
      In Controllers/MembershipController.cs:
      - Add POST endpoint:
        ```csharp
        /// <summary>Cancel membership - sets EndDate to today</summary>
        [HttpPost("{id:int}/cancel")]
        [Authorize] // Members can cancel their own
        public async Task<IActionResult> Cancel(int id)
        {
            // Verify ownership if user is Member
            var userRole = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
            if (userRole == "Member")
            {
                var membership = await _service.GetByIdAsync(id);
                if (membership == null) return NotFound();
                
                var userMemberIdStr = User.FindFirst("MemberId")?.Value;
                if (int.TryParse(userMemberIdStr, out int userMemberId) && userMemberId != membership.MemberId)
                {
                    return Forbid(); // Member can only cancel their own membership
                }
            }
            
            var success = await _service.CancelAsync(id);
            return success ? Ok(new { message = "Membership cancelled successfully" }) : NotFound();
        }
        ```
      
      **Files**: Controllers/MembershipController.cs  
      **Verify**: `dotnet build` succeeds, then run project and test endpoint via Swagger UI

- [ ] 8. **Create complete seed data SQL script**
      
      Write SQL2/COMPLETE_SEED_DATA.sql with full seed data:
      - DELETE existing data in correct order (respect FK constraints)
      - DBCC CHECKIDENT to reset all identity seeds to 0
      - INSERT data using exact column names from fixed schema:
      
      **Data to seed**:
      - 1 SuperAdmin user (Username: 'admin', Password: 'gym@2026' hashed with BCrypt)
      - 10 Trainers (with corresponding User records, Role='Trainer')
      - 30 Facilities (mix of Room and Equipment types)
      - 50 Members (with QRCodeValue, Status='Active')
      - 50 Users for Members (Username: 'member1' to 'member50', Role='Member')
      - 80 Memberships (PackageName: 'Monthly', 'Quarterly', 'Annual', varied dates)
      - 50 Schedules (ClassName values, MaxCapacity=20, mix of trainers and facilities)
      - 100 Sessions (MemberId + ScheduleId combinations, Status: 'Registered', 'Attended', 'Cancelled')
      - 150 Checkins (MemberId, CheckinTime, some with CheckoutTime)
      - 80 Invoices (MemberId + MembershipId, varied Status: 'Pending', 'Paid', 'Overdue')
      - 60 Payments (MemberId + InvoiceId, varied PaymentMethod: 'Cash', 'Card', 'QRCode', Status='Completed')
      
      **Important**: All INSERT statements must use the exact column names from COMPLETE_SCHEMA_FIX.sql
      
      **Files**: SQL2/COMPLETE_SEED_DATA.sql (new file)  
      **Verify**: Script runs without errors and inserts all records successfully

- [ ] 9. **Create master run script**
      
      Write SQL2/RUN_COMPLETE_FIX.sql that:
      ```sql
      USE GymDb;
      GO
      
      PRINT '========================================';
      PRINT 'Step 1: Applying schema fixes...';
      PRINT '========================================';
      GO
      
      :r .\COMPLETE_SCHEMA_FIX.sql
      GO
      
      PRINT '========================================';
      PRINT 'Step 2: Seeding data...';
      PRINT '========================================';
      GO
      
      :r .\COMPLETE_SEED_DATA.sql
      GO
      
      PRINT '========================================';
      PRINT '✅ Database fix complete!';
      PRINT '========================================';
      GO
      ```
      
      **Files**: SQL2/RUN_COMPLETE_FIX.sql (new file)  
      **Verify**: Run from SQL2 directory: `sqlcmd -S localhost -i RUN_COMPLETE_FIX.sql`

- [ ] 10. **Add cancel membership button to frontend**
       
       Find the member's membership display page (likely wwwroot/js/memberships.js or wwwroot/js/profile.js):
       - Add a "Cancel Membership" button next to active membership display
       - Button should be visible only for active memberships (EndDate >= today)
       - On click, confirm with user: "Are you sure you want to cancel this membership?"
       - If confirmed, call: `POST /api/Membership/{id}/cancel`
       - On success, show success message and refresh membership list
       - On error, show error message
       
       Example JS code:
       ```javascript
       async function cancelMembership(membershipId) {
           if (!confirm('Bạn có chắc muốn hủy gói tập này?')) return;
           
           try {
               const response = await api.post(`/Membership/${membershipId}/cancel`);
               showSuccess('Đã hủy gói tập thành công');
               loadMemberships(); // Refresh the list
           } catch (error) {
               showError('Lỗi khi hủy gói tập: ' + error.message);
           }
       }
       ```
       
       **Files**: wwwroot/js/memberships.js or wwwroot/js/profile.js (determine which file handles member's own membership display)  
       **Verify**: Run project, login as Member, navigate to memberships page, verify cancel button appears and works correctly

- [ ] 11. **Run comprehensive integration test**
       
       After all fixes are applied:
       
       1. Run the master SQL script: `sqlcmd -S localhost -i SQL2\RUN_COMPLETE_FIX.sql`
       2. Verify all tables have correct schema: Check column names and types in SSMS
       3. Verify seed data inserted correctly: `SELECT COUNT(*) FROM [TableName]` for each table
       4. Build the project: `dotnet build`
       5. Run the project: `dotnet run`
       6. Open Swagger UI at https://localhost:<port>/swagger
       7. Test these scenarios:
          - Login as admin (username: admin, password: gym@2026)
          - GET /api/Membership - should return memberships with correct data
          - GET /api/Invoice - should return invoices with MemberId populated
          - POST /api/Membership/purchase - create new membership as member
          - Verify auto-created invoice has MemberId populated (GET /api/Invoice/member/{memberId})
          - POST /api/Membership/{id}/cancel - cancel a membership
          - Verify membership EndDate is set to today
          - GET /api/Payment - should return payments with all columns
          - GET /api/Schedule - should return schedules with ClassName and MaxCapacity
          - GET /api/Session - should return sessions with ScheduleId and MemberId
          - GET /api/Checkin - should return checkins with MemberId only (no SessionId)
       
       **Files**: N/A (testing)  
       **Verify**: Document test results in .agents/tasks/integration-test-results.txt with all endpoints tested and their response status

---

## Key Design Decisions

1. **Schedules structure**: Removed MemberId from Schedules because schedules are class schedules (not personal to one member). Members register for schedules via Sessions table (many-to-many relationship).

2. **Checkins structure**: Removed SessionId because checkins are gym entry/exit tracking (not tied to specific class sessions). Members can check in to the gym without attending a specific class.

3. **Cancel membership approach**: Soft-cancel by setting EndDate to today rather than hard delete or adding Status column. This preserves history and works with existing queries that check `EndDate >= today` for active memberships.

4. **Invoice.MemberId**: Made required (NOT NULL) because every invoice must be for a specific member, even if it's not tied to a membership (could be for other services in the future).

5. **Payment.InvoiceId**: Made nullable to support direct payments that aren't tied to invoices (e.g., member pays cash for day pass).

6. **Schema fix order**: Schema changes must complete before seed data because seed data depends on correct column names and types.

---

## Verification Commands

- **Build project**: `dotnet build`
- **Run project**: `dotnet run`
- **Run SQL script**: `sqlcmd -S localhost -d GymDb -i SQL2\COMPLETE_SCHEMA_FIX.sql`
- **Check table schema**: In SSMS: `sp_help Memberships` (repeat for each table)
- **Count records**: `SELECT COUNT(*) FROM Memberships WHERE IsDeleted = 0`

---

## Expected Outcomes

After completing all steps:
1. Database schema matches C# entity definitions exactly
2. All repository SQL statements work without errors
3. Membership purchase creates invoice with correct MemberId
4. Members can cancel their own memberships via API and frontend
5. Admin can view all data correctly (no missing fields)
6. All CRUD operations work for all entities
7. Test data is comprehensive (>500 total records across all tables)

