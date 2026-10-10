# Quick Test - Register Endpoint

## Test Register (Creates User + Auto-creates Member)

**Endpoint**: `POST /api/Auth/register`

**Request Body**:
```json
{
  "username": "testuser1",
  "password": "Test@123",
  "fullName": "Test User One",
  "email": "testuser1@test.com"
}
```

**Expected**:
- ✅ User created with correct BCrypt hash
- ✅ Member auto-created with QRCode
- ✅ Can login immediately

---

## Then Login with New User

**Endpoint**: `POST /api/Auth/login`

**Request Body**:
```json
{
  "username": "testuser1",
  "password": "Test@123"
}
```

**Expected**:
- ✅ Returns JWT token
- ✅ MemberId present
- ✅ FullName, Email present

---

## Fix Seed Data

The seed data has wrong BCrypt hash. To fix, we can:

### Option 1: Use API to create test accounts (Recommended)
Register new accounts via API - passwords will be hashed correctly.

### Option 2: Update seed data with correct hash
Need to generate correct BCrypt hash and update SQL2/REBUILD_DATABASE.sql.

### Option 3: Reset password via SQL
```sql
-- This won't work directly in SQL because BCrypt hashing requires .NET library
-- Use Option 1 instead
```

---

## Current Status

**Seed data passwords don't work** because the BCrypt hash in SQL is wrong/fake.

**Solution**: Use Register endpoint to create new users for testing.
