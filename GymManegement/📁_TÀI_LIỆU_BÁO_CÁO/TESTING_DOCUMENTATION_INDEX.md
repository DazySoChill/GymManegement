# Testing Documentation Index

## 📚 Overview

This folder contains comprehensive manual testing documentation for the Gym Management System's Role-Based Access Control (RBAC) implementation.

**Purpose:** Verify that Admin and Member roles have correct permissions and UI visibility.

---

## 📖 Available Documents

### 1. **QUICK_TEST_CHECKLIST.md** ⚡
- **Use for:** Quick 15-minute verification
- **Best for:** Daily checks, smoke testing
- **Format:** Simple checklist with pass/fail checkboxes
- **Sections:**
  - Admin quick test (5 min)
  - Member quick test (5 min)
  - Access control test (3 min)
  - Comparison table

**Start here if:** You need to quickly verify RBAC is working.

---

### 2. **VISUAL_TEST_GUIDE.md** 📸
- **Use for:** Screenshot-based verification
- **Best for:** Visual learners, creating test evidence
- **Format:** Visual diagrams showing what to look for
- **Sections:**
  - Admin screenshots (8 examples)
  - Member screenshots (8 examples)
  - Side-by-side comparisons
  - DevTools inspection guide
  - Screenshot naming convention

**Start here if:** You want to know exactly what the UI should look like.

---

### 3. **STEP_BY_STEP_TEST_GUIDE.md** 📋
- **Use for:** Detailed test execution with expected results
- **Best for:** First-time testers, formal testing
- **Format:** Table-based step-by-step instructions
- **Sections:**
  - Part 1: Admin testing (10 min)
  - Part 2: Member account creation (3 min)
  - Part 3: Member testing (10 min)
  - Each step has: Action → Expected Result → Checkbox

**Start here if:** You're testing for the first time or need detailed guidance.

---

### 4. **MANUAL_TEST_RESULTS.md** 📄
- **Use for:** Comprehensive test plan and results documentation
- **Best for:** Complete testing sessions, formal QA
- **Format:** Full test specification with all scenarios
- **Sections:**
  - Test environment setup
  - Complete test plan (40+ test cases)
  - Expected vs actual results tables
  - Issues tracking section
  - Test sign-off section

**Start here if:** You need a complete test specification document.

---

## 🎯 Which Document Should I Use?

### Quick Decision Tree:

```
┌─────────────────────────────────────┐
│ How much time do you have?          │
└─────────────────────────────────────┘
           │
           ├─ 15 minutes ─────────────> QUICK_TEST_CHECKLIST.md
           │
           ├─ 30 minutes ─────────────> VISUAL_TEST_GUIDE.md
           │
           └─ 1 hour+ ───────────────> STEP_BY_STEP_TEST_GUIDE.md
                                        + MANUAL_TEST_RESULTS.md

┌─────────────────────────────────────┐
│ What's your goal?                   │
└─────────────────────────────────────┘
           │
           ├─ Verify it works ────────> QUICK_TEST_CHECKLIST.md
           │
           ├─ Create screenshots ─────> VISUAL_TEST_GUIDE.md
           │
           ├─ First time testing ─────> STEP_BY_STEP_TEST_GUIDE.md
           │
           └─ Formal QA / Documentation ─> MANUAL_TEST_RESULTS.md
```

---

## 🚀 Quick Start Guide

### Option A: Fast Track (15 minutes)
1. Open **QUICK_TEST_CHECKLIST.md**
2. Start server: `dotnet run`
3. Follow checklist section by section
4. Mark checkboxes as you go
5. Done!

### Option B: Visual Verification (30 minutes)
1. Open **VISUAL_TEST_GUIDE.md**
2. Open browser to http://localhost:5250/login.html
3. Take screenshots matching the guide
4. Compare your screenshots with expected images
5. Document any differences

### Option C: Complete Testing (1 hour)
1. Open **STEP_BY_STEP_TEST_GUIDE.md**
2. Start at Part 1: Admin Role Testing
3. Follow each step, checking expected results
4. Continue through all parts
5. Fill in **MANUAL_TEST_RESULTS.md** with findings
6. Sign off at the end

---

## 📊 Test Coverage

All documents cover these critical areas:

### ✅ Admin Role
- 9 navigation menu items
- Full system access
- Create/edit/delete permissions
- System-wide data visibility
- Manual + QR checkin
- Reports and invoices access

### ✅ Member Role
- 4 navigation menu items only
- Limited access (Dashboard, Schedules, Memberships, Checkins)
- Personal data only
- QR checkin only (no manual)
- Blocked from admin pages with error message

### ✅ Access Control
- URL-based access prevention
- Error toast on unauthorized access
- Auto-redirect to dashboard
- Frontend route protection
- Backend API authorization

### ✅ Security Verification
- Token storage (localStorage)
- Role verification (DevTools)
- API authorization headers
- 401/403 error handling

---

## 🔧 Prerequisites

Before using any document, ensure:

1. **Server running:**
   ```bash
   dotnet run --project "GymManegement.csproj"
   ```

2. **Browser ready:**
   - Chrome or Edge (recommended)
   - DevTools open (F12)
   - Network tab recording

3. **Test accounts:**
   - Admin: `gymadmin` / `Gym@2026`
   - Member: Create via registration form

4. **Clean state:**
   - Clear browser cache if needed
   - Clear localStorage if retesting
   - Database has some sample data

---

## 📝 Test Accounts Reference

### Pre-configured Accounts (from seed data):

| Username | Password | Role | Purpose |
|----------|----------|------|---------|
| `admin` or `gymadmin` | `gym@2026` or `Gym@2026` | Admin/SuperAdmin | Full system access |
| `trainer1` | `gym@2026` | Trainer | Trainer role testing (optional) |
| `member1` | `gym@2026` | Member | Existing member test (optional) |

### Test Account (to be created):

| Username | Password | Email | Role | Purpose |
|----------|----------|-------|------|---------|
| `testmember` | `Test@2026` | `testmember@gym.com` | Member | Member role verification |

---

## 🎯 Critical Test Points

### Must Verify:

1. **Navigation Menu Count**
   - Admin: **9 items** ✓
   - Member: **4 items** ✓

2. **Checkin Buttons**
   - Admin: **2 buttons** (Manual + QR) ✓
   - Member: **1 button** (QR only) ✓

3. **Access Control**
   - Member tries `#members` → **Error + Redirect** ✓
   - Member tries `#invoices` → **Error + Redirect** ✓
   - Member tries `#reports` → **Error + Redirect** ✓

4. **Role in localStorage**
   - Admin: `role: "Admin"` or `"SuperAdmin"` ✓
   - Member: `role: "Member"` ✓

5. **Data Scope**
   - Admin dashboard: System-wide stats ✓
   - Member dashboard: Personal stats only ✓

---

## ✅ Pass/Fail Criteria

### ✅ PASS if:
- Admin sees 9 menu items
- Member sees 4 menu items (and 5 are hidden)
- Member **cannot** access admin pages (blocked with error)
- Checkin buttons correct (Admin=2, Member=1)
- Role in localStorage matches expected value
- No console errors during normal operation

### ❌ FAIL if:
- Menu item counts are wrong
- Member can see or access admin pages
- No error message on blocked access
- Buttons are incorrect
- Role value is wrong or missing
- System crashes or shows errors

---

## 🐛 Common Issues and Solutions

### Issue: "Server not responding"
**Solution:**
```bash
# Check if server is running
netstat -ano | findstr :5250

# If not running, start it:
dotnet run --project "GymManegement.csproj"
```

### Issue: "Login fails with 401"
**Solution:**
- Check database connection
- Verify user exists in database
- Check password is correct
- Clear localStorage and retry

### Issue: "Menu items not hiding for Member"
**Solution:**
- Check `wwwroot/js/app.js` → `initNavigation()` function
- Verify `isAllowedPage()` returns correct values
- Clear browser cache
- Hard refresh (Ctrl+Shift+R)

### Issue: "Member can access admin pages"
**Solution:**
- Check `wwwroot/js/app.js` → `navigateTo()` function
- Verify access control check happens before page load
- Check browser console for JavaScript errors

### Issue: "Role is null or undefined"
**Solution:**
- Check login API response includes role
- Check localStorage after login
- Verify JWT token is valid
- Re-login to get fresh token

---

## 📸 Screenshot Guidelines

### Recommended Screenshots:

**Admin (8 screenshots):**
1. Navigation sidebar (9 items)
2. Dashboard with stats
3. Members page (with create button)
4. Checkins page (2 buttons)
5. Invoices page
6. Reports page
7. DevTools - localStorage
8. DevTools - Network API call

**Member (8 screenshots):**
1. Navigation sidebar (4 items only)
2. Dashboard (personal view)
3. Schedules page (own schedules)
4. Checkins page (1 button only)
5. Memberships page (own memberships)
6. Access denied error toast
7. DevTools - localStorage (role=Member)
8. DevTools - Console (blocked access)

### Naming Convention:
```
screenshots/
  ├── admin/
  │   ├── 01_navigation_9items.png
  │   ├── 02_dashboard_stats.png
  │   └── ...
  └── member/
      ├── 01_navigation_4items.png
      ├── 02_dashboard_personal.png
      └── ...
```

---

## 📈 Progress Tracking

### Testing Checklist:

- [ ] Read **QUICK_TEST_CHECKLIST.md**
- [ ] Complete Admin quick test
- [ ] Create Member account
- [ ] Complete Member quick test
- [ ] Verify access control (critical!)
- [ ] Take screenshots (optional)
- [ ] Document results in **MANUAL_TEST_RESULTS.md**
- [ ] Sign off test completion

### Test Sessions Log:

| Date | Tester | Document Used | Result | Notes |
|------|--------|---------------|--------|-------|
| 2026-10-09 | _________ | ___________ | _____ | _____ |
| __________ | _________ | ___________ | _____ | _____ |
| __________ | _________ | ___________ | _____ | _____ |

---

## 🎓 For New Testers

If this is your first time testing:

1. **Read this index first** ✓ (you're here!)
2. **Start with QUICK_TEST_CHECKLIST.md** to get familiar
3. **Then use VISUAL_TEST_GUIDE.md** to see what to expect
4. **Finally use STEP_BY_STEP_TEST_GUIDE.md** for detailed testing
5. **Document everything in MANUAL_TEST_RESULTS.md**

**Estimated time for first complete test:** 45-60 minutes

---

## 📞 Questions?

### Common Questions:

**Q: Do I need to test all 4 documents?**  
A: No! Use the decision tree above to pick the right document for your needs.

**Q: Can I just run automated tests?**  
A: These are manual UI tests. Automated tests (if available) test different aspects.

**Q: What if I find a bug?**  
A: Document it in the "Issues Found" section of **MANUAL_TEST_RESULTS.md** with severity level.

**Q: How often should I run these tests?**  
A: 
- Quick test: After any RBAC or auth changes
- Full test: Before production deployment
- Visual test: When UI changes are made

**Q: Can Member role create new members?**  
A: No, only Admin can create members. Member can only register themselves.

---

## 🔄 Document Updates

### Version History:

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-10-09 | Initial documentation created |

### Maintenance:

These documents should be updated when:
- RBAC rules change
- New roles are added
- UI structure changes
- API endpoints change
- New features are added

---

## ✨ Tips for Success

### Before Testing:
1. ✅ Read the full document first (don't skip ahead)
2. ✅ Prepare test accounts
3. ✅ Ensure server is running
4. ✅ Open DevTools before starting
5. ✅ Have a notepad ready for notes

### During Testing:
1. ✅ Follow steps exactly as written
2. ✅ Check every expected result
3. ✅ Take screenshots of failures
4. ✅ Note any differences from expected
5. ✅ Test access control thoroughly (critical!)

### After Testing:
1. ✅ Fill in all result checkboxes
2. ✅ Document any issues found
3. ✅ Calculate pass rate
4. ✅ Sign off on test completion
5. ✅ Share results with team

---

## 🎯 Success Criteria

### Minimum Requirements for Production:

- [ ] Admin role: 100% pass rate
- [ ] Member role: 100% pass rate
- [ ] Access control: 100% pass rate (NO failures allowed!)
- [ ] Critical tests: All passed
- [ ] No HIGH severity bugs

### Recommended Goals:

- [ ] 95%+ overall pass rate
- [ ] All critical functionality working
- [ ] Screenshots documented
- [ ] Issues logged and prioritized
- [ ] Test results reviewed by team

---

## 📚 Related Documentation

- **Backend API Documentation:** See `/api/swagger`
- **Frontend Code:** `wwwroot/js/app.js`, `auth.js`
- **Database Schema:** Check entity models
- **Requirements:** Project requirements document

---

## 🙏 Acknowledgments

These testing documents were created to ensure the Gym Management System's security and user experience meet requirements.

**Remember:** Proper role-based access control is critical for system security. Take time to test thoroughly!

---

**Last Updated:** 2026-10-09  
**Created by:** Kiro AI Development Assistant  
**Status:** ✅ Ready for use

---

## 🚀 Ready to Start?

Choose your document:
- **Quick test:** → QUICK_TEST_CHECKLIST.md
- **Visual guide:** → VISUAL_TEST_GUIDE.md
- **Detailed test:** → STEP_BY_STEP_TEST_GUIDE.md
- **Complete doc:** → MANUAL_TEST_RESULTS.md

**Happy Testing! 🎉**
