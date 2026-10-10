# GymManagement Database SQL Scripts

## Overview
This folder contains SQL scripts to rebuild the GymDb database with schema and seed data that **exactly matches** the backend DAL entities.

## Files

### 00_REBUILD_DATABASE.sql
**Master script** that completely rebuilds the database:
1. Drops existing GymDb database (if exists)
2. Creates new GymDb database
3. Creates all 12 tables with proper schema
4. Seeds data for testing
5. Runs verification queries

**Usage:**
```sql
-- Run in SQL Server Management Studio or Azure Data Studio
-- Make sure you're connected to the SQL Server instance
-- The script will handle USE master and USE GymDb automatically
```

### 01_CREATE_SCHEMA.sql
Creates 12 tables matching backend entities:
- Users
- Members
- Trainers
- Facilities
- Memberships
- Invoices
- Payments
- Schedules
- Sessions
- Checkins
- AuditLogs
- MemberSchedulePreferences

All foreign key constraints and indexes are included.

### 02_SEED_DATA.sql
Inserts realistic Vietnamese test data:
- **1 Admin user**: username=`admin`, password=`password`
- **5 Trainer users**: username=`trainer1` through `trainer5`, password=`password`
- **20 Member users**: username=`member01` through `member20`, password=`password`
- **5 Trainers** (matching trainer users)
- **20 Members** (matching member users) with QR codes M000001-M000020
- **10 Facilities** (Phòng Gym, Phòng Yoga, etc.)
- **20 Memberships** (various packages)
- **20 Invoices** (mix of Paid/Pending)
- **15 Payments** (various payment methods)
- **20 Schedules** (spread across Jan 2025)
- **26 Sessions** (various statuses)
- **19 Checkins** (with realistic times)
- **10 Member Schedule Preferences**
- **5 Audit Logs** (samples)

## Key Features

### ✅ Backend Compatibility
- Schema **exactly matches** DAL/Entities/*.cs files
- All column names, types, and nullability match entity properties
- Foreign key relationships match navigation properties

### ✅ Data Integrity
- All foreign key constraints properly defined
- Seed data inserted in FK-safe order
- No orphaned records
- Referential integrity verified

### ✅ Authentication
- All passwords use BCrypt hash: `$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi`
- This is the bcrypt hash for plaintext password: `password`
- Hash is exactly 60 characters (valid BCrypt format)

### ✅ Testing Ready
- Realistic Vietnamese names and data
- Mix of statuses (Active/Inactive, Paid/Pending, etc.)
- Sample data for all entity relationships
- Some NULL values to test nullable fields

## Verification

The rebuild script includes automatic verification:
- Row counts for all 12 tables
- Sample data from Users, Members, Trainers
- Foreign key integrity checks
- Confirms zero orphaned records

## Usage Instructions

### Option 1: Full Rebuild (Recommended)
```sql
-- Open and run 00_REBUILD_DATABASE.sql
-- This will drop and recreate everything
```

### Option 2: Separate Scripts
```sql
-- 1. Manually drop/create database
DROP DATABASE IF EXISTS GymDb;
CREATE DATABASE GymDb;
GO
USE GymDb;
GO

-- 2. Run schema script
-- Execute 01_CREATE_SCHEMA.sql

-- 3. Run seed data script
-- Execute 02_SEED_DATA.sql
```

## Credentials

After running the scripts, you can log in with:

| Username | Password | Role |
|----------|----------|------|
| admin | password | Admin |
| trainer1 | password | Trainer |
| trainer2 | password | Trainer |
| trainer3 | password | Trainer |
| trainer4 | password | Trainer |
| trainer5 | password | Trainer |
| member01 | password | Member |
| member02 | password | Member |
| ... | ... | ... |
| member20 | password | Member |

## Technical Details

### Table Structure
All tables include:
- Primary key with IDENTITY(1,1)
- CreatedAt (DATETIME NOT NULL DEFAULT GETDATE())
- UpdatedAt (DATETIME NOT NULL/NULL depending on entity)
- IsDeleted (BIT NOT NULL DEFAULT 0)
- DeletedAt (DATETIME NULL)

### Foreign Keys
- Memberships → Members
- Invoices → Members, Memberships
- Payments → Invoices, Members
- Schedules → Trainers, Facilities
- Sessions → Schedules, Members
- Checkins → Members
- MemberSchedulePreferences → Members

### Indexes
Indexes created on:
- All foreign key columns
- Frequently queried columns (Email, Username, Status, etc.)
- IsDeleted columns for soft delete queries

## Compatibility Matrix

| Entity | Table | Columns Match | FKs Match | Navigation Match |
|--------|-------|---------------|-----------|------------------|
| User | Users | ✅ | N/A | ✅ |
| Member | Members | ✅ | ✅ | ✅ |
| Trainer | Trainers | ✅ | ✅ | ✅ |
| Facility | Facilities | ✅ | ✅ | ✅ |
| Membership | Memberships | ✅ | ✅ | ✅ |
| Invoice | Invoices | ✅ | ✅ | ✅ |
| Payment | Payments | ✅ | ✅ | ✅ |
| Schedule | Schedules | ✅ | ✅ | ✅ |
| Session | Sessions | ✅ | ✅ | ✅ |
| Checkin | Checkins | ✅ | ✅ | ✅ |
| AuditLog | AuditLogs | ✅ | N/A | ✅ |
| MemberSchedulePreference | MemberSchedulePreferences | ✅ | ✅ | ✅ |

---

**Last Updated:** 2025-01-18  
**Backend Version:** Current (as of last entity read)  
**Status:** ✅ Production Ready
