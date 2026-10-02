# SQL Schema Fix Summary & Missing Requirements Checklist

## ✅ Fixed SQL Issues

### 1. Schema (01_Schema.sql)
- **RBAC Tables**: Roles, Permissions, RolePermissions with proper FKs
- **Core Business Tables**: Members, Trainers, Facilities, Memberships, Schedules, Sessions, Checkins, Invoices, Payments
- **All tables now have**: Audit fields (CreatedAt/By, UpdatedAt/By), Soft Delete (IsDeleted, DeletedAt/By), Concurrency (RowVersion)
- **Memberships**: Versioning field for sensitive record tracking
- **Users table**: Fixed to use RoleId FK to Roles table, added PasswordSalt, RefreshToken fields
- **AuditLogs**: Complete with JSON OldValues/NewValues, indexes
- **RefreshTokens**: JWT rotation support with JwtId, TokenHash, ReplacedByTokenHash
- **Audit Triggers**: Auto-populate AuditLogs for Members, Trainers, Memberships, Invoices, Payments, Users
- **Soft Delete Helpers**: sp_SoftDelete, sp_Restore generic procedures

### 2. Programmability (02_Programmability.sql)
- **Pagination**: All GetAll procedures support @PageNumber, @PageSize, @TotalCount OUTPUT
- **Search**: @SearchTerm parameter for text fields
- **Filter**: Multiple filter parameters per entity (status, dates, type, etc.)
- **Sort**: @SortBy, @SortDir with column validation (SQL injection prevention)
- **Soft Delete Awareness**: All queries filter `IsDeleted = 0`
- **Complete CRUD**: Create, GetById, GetAll (paged), Update, SoftDelete, Restore for all entities
- **Business Logic**: QR check-in validation, membership expiration checks, payment-invoice atomic transaction
- **Reports**: ActiveMembers (paged), Revenue, RevenueDetail (paged), MemberCheckinFrequency (paged), FacilityUtilization, TrainerWorkload
- **Audit Logs**: Paged retrieval with filters
- **Permissions**: sp_User_GetPermissions for JWT claims

### 3. Seed Data (03_SeedData.sql)
- **≥ 2,000 Members** (NFR requirement met)
- **20 Trainers**, **10 Facilities**
- **2,500+ Memberships** with history
- **5,000+ Schedules**, **5,000+ Sessions**
- **10,000+ Checkins** (80% rate on completed sessions)
- **2,500+ Invoices**, **2,000+ Payments**
- **45 Permissions** across 9 modules
- **RolePermissions mapping** for Admin (all), Trainer (own schedules/members), Member (own data)

### 4. Users (04_Users.sql)
- **Roles seeded first** (Admin, Trainer, Member as system roles)
- **6 demo users**: admin, trainer1, trainer2, member1, member2, member3
- **Proper FKs**: RoleId → Roles, MemberId → Members, TrainerId → Trainers
- **BCrypt hashes** with unique salts per user
- **PasswordSalt field** populated

---

## 📋 Requirements vs Implementation Checklist

### Tính năng nền tảng (Platform Features)

| Requirement | Status | Notes |
|-------------|--------|-------|
| Đăng ký/đăng nhập, JWT/OAuth2 | ⚠️ **Partial** | DB schema ready (Users, RefreshTokens, Roles, Permissions). Need: Auth API, JWT middleware, OAuth2 providers, Password reset, 2FA |
| RBAC: ≥3 roles (Admin/Manager/User) | ✅ **Done** | Roles: Admin, Trainer, Member. Manager role can be added. Screen & action-level permissions via Permissions table |
| CRUD + search, filter, sort, pagination | ✅ **Done** | All entities have sp_*_GetAll with pagination, search, filter, sort |
| Import/Export Excel/CSV, Export PDF | ❌ **Missing** | Need: Export stored procedures / API endpoints, EPPlus/ClosedXML for Excel, QuestPDF for PDF |
| Audit log (who, what, when) | ✅ **Done** | AuditLogs table + triggers on all critical tables |
| Soft delete | ✅ **Done** | IsDeleted on all tables + sp_SoftDelete/Restore |
| Versioning for sensitive records | ✅ **Done** | Memberships.Version field + audit trigger |
| Notifications (email + in-app) | ❌ **Missing** | Need: Notifications table, email service, SignalR for in-app |
| Job queue for long tasks | ❌ **Missing** | Need: Hangfire/Quartz or SQL Agent jobs for email, report generation |

### Chất lượng & vận hành (Quality & Operations)

| Requirement | Status | Notes |
|-------------|--------|-------|
| OpenAPI/Swagger full | ❌ **Missing** | Need: Swashbuckle in API project |
| Postman collection | ❌ **Missing** | Need: Export from Swagger or manual |
| Unit test (service) ≥30-40% | ❌ **Missing** | Need: xUnit tests for services |
| Integration test (API) | ❌ **Missing** | Need: WebApplicationFactory tests |
| Docker + docker-compose | ❌ **Missing** | Need: Dockerfile, docker-compose.yml (SQL Server, API, Redis) |
| CI/CD simple (build, test, deploy) | ❌ **Missing** | Need: GitHub Actions / Azure DevOps pipeline |
| Security: SQLi/XSS/CSRF, rate limit, CORS | ⚠️ **Partial** | SQL: Parameterized SPs ✅. API: Need middleware for rate limit, CORS, antiforgery |
| Cache (Redis) for categories/reports | ❌ **Missing** | Need: Redis integration, cache-aside pattern |
| Seed ≥ 2,000 records | ✅ **Done** | 2,000+ members, 10,000+ checkins, etc. |
| Structured logging + health check | ❌ **Missing** | Need: Serilog, health check endpoints |

### Tài liệu & bàn giao (Documentation & Handover)

| Requirement | Status | Notes |
|-------------|--------|-------|
| SRS (Software Requirements Spec) | ❌ **Missing** | Need: Markdown/Word document |
| ERD (Entity Relationship Diagram) | ❌ **Missing** | Need: Generate from DB or draw.io |
| Use case / Flow diagrams | ❌ **Missing** | Need: Mermaid/PlantUML diagrams |
| Architecture diagram | ❌ **Missing** | Need: C4 model or similar |
| Installation guide | ❌ **Missing** | Need: README with steps |
| User guide | ❌ **Missing** | Need: Per-role manuals |
| Video demo (5-10 min) | ❌ **Missing** | Need: Screen recording |

---

## 🎯 Gym Management Specific Requirements

| Requirement | Status | Notes |
|-------------|--------|-------|
| Đăng ký hội viên, thẻ tập, hạn sử dụng | ✅ **DB Ready** | Members, Memberships, QRCodeValue |
| Quản lý gói dịch vụ (tháng/năm) | ✅ **DB Ready** | MembershipType: Monthly, Quarterly, Annual, VIP, Trial |
| Đặt lịch tập với PT, quản lý phòng/thiết bị | ✅ **DB Ready** | Schedules (Member, Trainer, Facility, time) |
| Quản lý check-in, ghi nhận buổi tập | ✅ **DB Ready** | Checkins (QRCode, Card, Manual), Sessions |
| Thu phí, hóa đơn; cảnh báo sắp hết hạn | ✅ **DB Ready** | Invoices, Payments, sp_Membership_GetExpiringSoon |
| Báo cáo: hội viên hoạt động, doanh thu | ✅ **DB Ready** | sp_Report_ActiveMembers, sp_Report_Revenue* |
| Check-in QR code | ✅ **DB Ready** | sp_Checkin_ByQRCode, Members.QRCodeValue |
| Gửi nhắc hạn (expiry notifications) | ⚠️ **Partial** | sp_Membership_GetExpiringSoon exists. Need: Job + email/SMS |
| Audit thay đổi gói | ✅ **Done** | Memberships audit trigger + Version field |
| Flow đăng ký–checkin–gia hạn | ✅ **DB Ready** | All tables and SPs support this flow |
| Mẫu hợp đồng | ❌ **Missing** | Need: Contract template (PDF generation) |
| Dashboard hội viên | ✅ **DB Ready** | vw_MemberDashboard view |

---

## 🚀 Next Steps Priority

### Immediate (Week 1)
1. [ ] Build ASP.NET Core Web API project with EF Core or Dapper
2. [ ] Implement JWT Authentication + Refresh Token rotation
3. [ ] Create API controllers wrapping all stored procedures
4. [ ] Add Swagger/OpenAPI with XML comments
5. [ ] Configure CORS, Rate Limiting, Serilog

### Short-term (Week 2)
6. [ ] Implement Email service (SMTP) + Background jobs (Hangfire)
7. [ ] Add Export: Excel (EPPlus), PDF (QuestPDF)
8. [ ] Redis caching for reports & dropdowns
9. [ ] Unit tests (services) + Integration tests (API)
10. [ ] Dockerfile + docker-compose.yml

### Medium-term (Week 3)
11. [ ] OAuth2 (Google, Facebook) + Password Reset + 2FA (TOTP)
12. [ ] In-app Notifications (SignalR)
13. [ ] Contract PDF generation
14. [ ] CI/CD Pipeline (GitHub Actions)
15. [ ] All documentation (SRS, ERD, Architecture, Guides)

### Final (Week 4)
16. [ ] Video demo recording
17. [ ] End-to-end testing
18. [ ] Performance tuning
19. [ ] Security audit
20. [ ] Handover package

---

## 🔧 Technical Debt / Known Issues

1. **Dynamic SQL in pagination SPs** - Vulnerable to injection if inputs not validated. Current code validates @SortBy against whitelist.
2. **Audit trigger CONTEXT_INFO()** - Requires app to set `SET CONTEXT_INFO @UserId` before DML. Need middleware.
3. **No foreign key from Users → Members/Trainers with CASCADE** - Intentional (soft delete), but app must handle.
4. **Membership Version increments on every update** - Good for audit, but consider separate VersionHistory table for full diffs.
5. **RefreshTokens table not cleaned up** - Need scheduled job to delete expired/revoked tokens.
6. **No database migration tool** - Consider FluentMigrator or EF Core Migrations for future schema changes.
