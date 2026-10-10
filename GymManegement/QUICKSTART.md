# 🚀 GYM MANAGEMENT - QUICK START GUIDE

**Last Updated:** 2026-10-09  
**Status:** ✅ Ready for Testing

---

## 🎯 Quick Start (3 Steps)

### 1️⃣ Start Server
```powershell
cd "d:\Workspace\Độ án 2\GymManegement\GymManegement"
dotnet run
```

**Server URL:** http://localhost:5250  
**Swagger:** http://localhost:5250/swagger

### 2️⃣ Open Web UI
Open browser to: http://localhost:5250/login.html

### 3️⃣ Login
**Admin Account:**
- Username: `testmember2`
- Password: `Test@123`

---

## 📊 What's Working

### ✅ Core Features (6/6 Required)
1. ✅ Member registration with QR code
2. ✅ Membership management (Monthly/Quarterly/Annual)
3. ✅ Schedule with Trainer & Facilities
4. ✅ Check-in (Manual + QR Code)
5. ✅ Invoice & Payment with auto-status
6. ✅ Reports (Active members, Revenue)

### ✅ Additional Features
- Status updates (Invoice, Payment, Session)
- Membership renewal
- Facility active filter
- JWT Authentication
- Soft delete
- Pagination & Search

---

## 📁 Project Structure

```
GymManegement/
├── Controllers/        # 11 API controllers
├── DAL/
│   ├── Entities/      # 10 database entities (SQL2 schema)
│   └── Repositories/  # 4 repositories (Dapper)
├── Service/
│   └── BUS/           # 5 business services
├── API/DTOs/          # 16 DTO groups
├── SQL2/              # Database scripts
│   └── REBUILD_DATABASE.sql  # Full database rebuild
├── wwwroot/           # Web UI (HTML/CSS/JS)
│   ├── index.html     # Dashboard
│   ├── login.html     # Login page
│   └── js/
│       ├── api.js     # API client
│       └── pages/     # Page modules
└── Project PHASE/     # Documentation
```

---

## 🗄️ Database

**Server:** DAZY\SQLEXPRESS  
**Database:** GymDb  
**Connection String:** See `appsettings.json`

**Tables (10):**
- Users (Auth)
- Members (with QRCode)
- Trainers
- Facilities
- Schedules (Classes)
- Sessions (Member registrations)
- Memberships (Packages)
- Checkins (with CheckoutTime)
- Invoices
- Payments

**Test Data:** 2000+ records pre-seeded

---

## 🧪 Testing

### Via Web UI
1. **Login** → http://localhost:5250/login.html
2. **Dashboard** → View stats & charts
3. **Members** → CRUD operations
4. **Memberships** → Create/Renew packages
5. **Checkin** → Manual or QR Code
6. **Reports** → Active members, Revenue

### Via Swagger
1. Open http://localhost:5250/swagger
2. Authorize with JWT token (from login)
3. Test all endpoints

### Test Accounts
```
Admin:
- testmember2 / Test@123

Members (500 total):
- testmember1 / Test@123
- testmember3 / Test@123
... testmember500 / Test@123

Trainers (50 total):
- testtrainer1 / Trainer@123
... testtrainer50 / Trainer@123
```

---

## 📚 Documentation

### Main Docs
1. **PROJECT_ROADMAP.md** - Complete project overview
2. **WEB_UI_AUDIT_REPORT.md** - Frontend/Backend compatibility audit
3. **WEB_UI_OPTION3_COMPLETED.md** - Implementation details
4. **PHASE6_MANUAL_TEST_GUIDE.md** - Testing guide

### Database Docs
1. **SQL2/README.md** - Database schema
2. **SQL2/CHANGES_FOR_CODE.md** - Code impact analysis
3. **SQL2/REBUILD_DATABASE.sql** - Database rebuild script

### Testing Docs
1. **PHASE6_TESTING_RESULTS.md** - Test results
2. **ADMIN_LOGIN_FIX.md** - Admin account fix guide

---

## 🔧 Common Tasks

### Rebuild Database
```sql
-- Run in SSMS on DAZY\SQLEXPRESS
-- File: SQL2/REBUILD_DATABASE.sql
```

### Change Admin Password
```sql
-- Promote any member to Admin
UPDATE Users SET Role='Admin' WHERE Username='testmember2';
```

### Stop Server
Press `Ctrl+C` in terminal where `dotnet run` is running

### View Logs
Check console output where `dotnet run` is running

---

## ⚠️ Known Limitations

### Not Implemented (By Design)
- ❌ Export features (Excel/PDF) - can add later
- ❌ Forgot/Reset password via email - simplified per SQL2
- ❌ Expiring-soon report - can add later
- ❌ Email notifications - future enhancement
- ❌ Unit tests - optional

### Technical Constraints
- Single database (no read replicas)
- No Docker/CI-CD (per requirements)
- Basic CORS (localhost only)
- JWT tokens (no refresh mechanism yet)

---

## 🐛 Troubleshooting

### Port Already in Use
```powershell
# Find process using port 5250
netstat -ano | findstr :5250

# Kill process by PID
taskkill /PID <PID> /F
```

### Database Connection Error
1. Check SQL Server is running
2. Verify connection string in `appsettings.json`
3. Run `REBUILD_DATABASE.sql` if schema mismatch

### 401 Unauthorized
1. Login again to get new token
2. Check token in localStorage (browser DevTools)
3. Verify user role in database

### 500 Internal Server Error
1. Check console logs where `dotnet run` is running
2. Verify database schema matches code
3. Check for missing required fields in request

---

## 📞 Quick Reference

### API Base URL
```
http://localhost:5250/api
```

### Common Endpoints
```
POST   /api/auth/login          # Login
POST   /api/auth/register       # Register (auto creates Member)
GET    /api/auth/profile        # Get current user
GET    /api/members             # List members
POST   /api/checkins/qr         # QR Check-in
GET    /api/reports/revenue     # Revenue report
```

### QR Code Format
```
M000001 ... M000500  (for Members 1-500)
```

---

## 🎓 Learning Resources

### SQL2 Schema
See `SQL2/README.md` for:
- Table relationships
- Field definitions
- Constraints
- Sample queries

### API Documentation
See `Swagger UI` at http://localhost:5250/swagger for:
- All endpoints
- Request/Response schemas
- Try-it-out examples

### Code Structure
See `Project PHASE/PROJECT_ROADMAP.md` for:
- Architecture overview
- Layer responsibilities
- Data flow
- Design decisions

---

## ✅ Health Check

**Is Everything Working?**

1. ✅ Server starts without errors
2. ✅ Swagger loads at `/swagger`
3. ✅ Can login with testmember2
4. ✅ Dashboard shows data
5. ✅ Can create/edit members
6. ✅ Can check-in with QR code
7. ✅ Reports show data

**If all ✅ → You're good to go! 🎉**

---

## 🚀 Next Steps

### For Development
1. Review `WEB_UI_AUDIT_REPORT.md` for feature status
2. Test all CRUD operations via Web UI
3. Test business flows via Swagger
4. Add export features if needed (see `WEB_UI_OPTION3_COMPLETED.md`)

### For Deployment
1. Update connection string for production database
2. Change JWT secret in `appsettings.json`
3. Enable HTTPS in production
4. Set up proper CORS policy
5. Add rate limiting (optional)

### For Testing
1. Follow `PHASE6_MANUAL_TEST_GUIDE.md`
2. Test all 6 required features
3. Document results in `PHASE6_TESTING_RESULTS.md`

---

**Ready to test! 🎯**

**Questions?** Check `Project PHASE/` folder for detailed documentation.
