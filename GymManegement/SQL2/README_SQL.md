# GymDb SQL Scripts - Documentation

## Overview

This directory contains organized SQL scripts for the Gym Management System database. The monolithic `COMPLETE_GYM_MANAGEMENT_SYSTEM.sql` file has been split into logical, maintainable components.

## File Structure

| File | Purpose | Contains |
|------|---------|----------|
| `00_CREATE_DATABASE.sql` | Database initialization | Drops existing GymDb, creates new database with Vietnamese_CI_AS collation |
| `01_CREATE_TABLES.sql` | Schema creation | 12 tables with constraints, foreign keys, and indexes |
| `02_CREATE_STORED_PROCEDURES_USERS.sql` | Users operations | 11 stored procedures for user CRUD operations |
| `03_CREATE_STORED_PROCEDURES_MEMBERS.sql` | Members operations | 9 stored procedures for member CRUD operations |
| `04_CREATE_STORED_PROCEDURES_TRAINERS.sql` | Trainers operations | 8 stored procedures for trainer CRUD operations |
| `05_CREATE_STORED_PROCEDURES_SCHEDULES.sql` | Schedules operations | 10 stored procedures for schedule management |
| `06_CREATE_STORED_PROCEDURES_CHECKINS.sql` | Check-ins operations | 8 stored procedures for check-in/check-out tracking |
| `07_CREATE_STORED_PROCEDURES_MEMBERSHIPS.sql` | Memberships operations | 10 stored procedures for membership management |
| `08_CREATE_STORED_PROCEDURES_INVOICES.sql` | Invoices operations | 10 stored procedures for invoice management |
| `09_CREATE_STORED_PROCEDURES_PAYMENTS.sql` | Payments operations | 8 stored procedures for payment processing |
| `10_CREATE_STORED_PROCEDURES_FACILITIES.sql` | Facilities operations | 7 stored procedures for facility management |
| `11_CREATE_STORED_PROCEDURES_SESSIONS.sql` | Sessions operations | 8 stored procedures for session management |
| `12_CREATE_STORED_PROCEDURES_PREFERENCES.sql` | Preferences operations | 6 stored procedures for member schedule preferences |
| `13_CREATE_STORED_PROCEDURES_AUDITLOGS.sql` | Audit logging | 2 stored procedures for audit trail |
| `14_SEED_DATA.sql` | Test data | Sample data for all tables (26 users, 5 trainers, 25 members, etc.) |
| `RUN_ALL.sql` | Master execution script | Runs all files in correct order using SQLCMD mode |
| `COMPLETE_GYM_MANAGEMENT_SYSTEM.sql` | Monolithic backup | Original complete SQL file (kept for reference) |

## Execution Order

The files are numbered to indicate the correct execution order:

```
00 → Database Creation
01 → Tables & Constraints
02-13 → Stored Procedures (by domain)
14 → Seed Data
```

## How to Run

### Option 1: Use RUN_ALL.sql (Recommended)

1. Open `RUN_ALL.sql` in SQL Server Management Studio (SSMS)
2. Enable SQLCMD Mode: **Query menu → SQLCMD Mode** (check it)
3. Press **F5** or click **Execute**
4. All files will run automatically in the correct sequence

### Option 2: Run Files Individually

Execute each file in numerical order (00 through 14) in SSMS.

### Option 3: Command Line (sqlcmd)

```bash
sqlcmd -S localhost -E -i RUN_ALL.sql
```

## Database Schema

### Tables (12 total)

1. **Users** - User accounts (Admin, Trainer, Member roles)
2. **Members** - Member profiles with QR codes for check-in
3. **Trainers** - Trainer profiles with specializations
4. **Facilities** - Gym facilities/rooms (Available, Maintenance)
5. **Memberships** - Membership packages for members
6. **Invoices** - Billing invoices (Pending, Paid, Unpaid)
7. **Payments** - Payment transactions (Cash, Card, BankTransfer)
8. **Schedules** - Training class schedules created by trainers
9. **Sessions** - Member registrations for schedules
10. **Checkins** - Member and trainer check-in/check-out records
11. **AuditLogs** - Audit trail for data changes
12. **MemberSchedulePreferences** - Member preferred time slots

### Stored Procedures (97 total)

- **Users**: 11 procedures (GetAll, GetById, GetByUsername, GetByEmail, Create, Update, UpdatePassword, UpdateLastLogin, SetActive, UsernameExists, EmailExists)
- **Members**: 9 procedures (GetAll, GetById, GetByEmail, GetByQRCode, GetByIds, Create, Update, Delete, EmailExists)
- **Trainers**: 8 procedures (GetAll, GetById, GetByEmail, GetByIds, GetWithSchedules, Create, Update, Delete)
- **Schedules**: 10 procedures (GetAll, GetById, GetByTrainerId, GetByFacilityId, GetByDate, GetByIds, HasConflict, Create, Update, Delete)
- **Checkins**: 8 procedures (GetAll, GetById, GetByMemberId, GetByDate, GetByDateRange, GetByQRCode, Create, Update)
- **Memberships**: 10 procedures (GetAll, GetById, GetByMemberId, GetByIds, GetActiveMembership, GetExpiringSoon, GetActive, Create, Update, Delete)
- **Invoices**: 10 procedures (GetAll, GetById, GetByMemberId, GetByStatus, GetOverdue, GetUnpaid, GetTotalRevenue, Create, Update, Delete)
- **Payments**: 8 procedures (GetAll, GetById, GetByInvoiceId, GetByMemberId, GetByStatus, Create, Update, Delete)
- **Facilities**: 7 procedures (GetAll, GetById, GetByIds, GetActive, Create, Update, Delete)
- **Sessions**: 8 procedures (GetAll, GetById, GetByScheduleId, GetByMemberId, GetByStatus, Create, Update, Delete)
- **MemberSchedulePreferences**: 6 procedures (GetAll, GetById, GetByMemberId, GetByDayOfWeek, Create, Update)
- **AuditLogs**: 2 procedures (Create, GetByRecord)

### Seed Data

The `14_SEED_DATA.sql` file populates the database with test data:

- **26 Users**: 1 Admin, 5 Trainers, 20 Members (all passwords: `password`)
- **5 Trainers**: Each with specializations (Gym, Yoga, Cardio, Aerobic, Boxing)
- **25 Members**: 20 regular members + 5 trainer-members (for check-in support)
- **10 Facilities**: Various gym rooms and areas
- **20 Memberships**: Monthly, quarterly, semi-annual, and annual packages
- **20 Schedules**: Training classes created by trainers
- **26 Sessions**: Member registrations for classes
- **29 Check-ins**: 19 member check-ins + 10 trainer check-ins
- **20 Invoices**: Billing records with various statuses
- **15 Payments**: Payment transactions
- **10 MemberSchedulePreferences**: Member preferred time slots
- **5 AuditLogs**: Sample audit trail entries

## Vietnamese Text Support

**CRITICAL**: All Vietnamese text uses `NVARCHAR` columns with `N'...'` prefixes in SQL literals.

### Examples:
```sql
-- CORRECT ✓
INSERT INTO Users (Username, FullName) VALUES (N'admin', N'Quản Trị Viên');

-- INCORRECT ✗ (Vietnamese characters will be corrupted)
INSERT INTO Users (Username, FullName) VALUES ('admin', 'Quản Trị Viên');
```

The database collation is `Vietnamese_CI_AS` (case-insensitive, accent-sensitive).

## Key Features

### Trainer Check-In Support
Trainers have records in **both** `Trainers` and `Members` tables:
- `Trainers` table: Professional info (specialization, etc.)
- `Members` table: Enables check-in functionality (QR code: M000021-M000025)

This design allows trainers to check in as employees without needing a separate check-in system.

### Soft Delete Pattern
All tables use soft delete (except `MemberSchedulePreferences`):
- `IsDeleted` BIT column (default: 0)
- `DeletedAt` DATETIME column (nullable)
- Stored procedures filter by `IsDeleted = 0`

### Role-Based Access
Users have three roles:
- **Admin**: Full system access
- **Trainer**: Can create schedules, view own schedules, check in
- **Member**: Can register for sessions, view own data, check in

## Test Credentials

All user passwords are hashed with BCrypt (workFactor 11). Plain password: `password`

| Role | Username | Password | Email |
|------|----------|----------|-------|
| Admin | admin | password | admin@gymmanagement.vn |
| Trainer | trainer1 | password | an.nguyen@gymmanagement.vn |
| Trainer | trainer2 | password | binh.tran@gymmanagement.vn |
| Member | member01 | password | mai.nguyen@gmail.com |
| Member | member02 | password | nam.tran@gmail.com |

## Connection String

Update your `appsettings.json` with:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=.;Database=GymDb;Trusted_Connection=True;TrustServerCertificate=True;"
  }
}
```

Or for SQL Server Authentication:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=.;Database=GymDb;User Id=sa;Password=YourPassword;TrustServerCertificate=True;"
  }
}
```

## Troubleshooting

### SQLCMD Mode Not Enabled
If you see errors about `:r` commands not recognized:
1. In SSMS, go to **Query** menu
2. Check **SQLCMD Mode**
3. Re-run the script

### Vietnamese Characters Display as ???
- Ensure the database collation is `Vietnamese_CI_AS`
- Verify all string literals use `N'...'` prefix
- Check that all text columns are `NVARCHAR`, not `VARCHAR`

### Permission Denied
Run SSMS as Administrator or ensure your SQL Server user has `sysadmin` or `dbcreator` role.

### Database Already Exists
The `00_CREATE_DATABASE.sql` file drops the existing `GymDb` database before creating a new one. Ensure you have backups if needed.

## Maintenance

### Adding New Stored Procedures
1. Add procedures to the appropriate `0X_CREATE_STORED_PROCEDURES_*.sql` file
2. Update procedure count in this README
3. Update the summary in `RUN_ALL.sql`

### Modifying Tables
1. Update `01_CREATE_TABLES.sql`
2. Create migration scripts for existing databases
3. Update affected stored procedures

### Adding New Seed Data
1. Add INSERT statements to `14_SEED_DATA.sql`
2. Maintain `N'...'` prefixes for Vietnamese text
3. Respect foreign key constraints (order matters!)

## Backup Strategy

Keep `COMPLETE_GYM_MANAGEMENT_SYSTEM.sql` as a monolithic backup. Regenerate it when making significant changes:

```sql
-- Generate from SSMS: Right-click database → Tasks → Generate Scripts
```

## Version History

- **v1.0** (2025-01-18): Initial split from monolithic file
  - 12 tables, 97 stored procedures
  - Vietnamese support with N'...' prefixes
  - Trainer check-in support
  - Comprehensive seed data

## Support

For issues or questions about the database schema:
1. Check this README first
2. Review stored procedure comments
3. Examine seed data for examples
4. Consult the monolithic backup file

---

**Note**: This SQL structure is designed for SQL Server 2016+ and uses features like `STRING_SPLIT` (SQL Server 2016+) and soft delete patterns.
