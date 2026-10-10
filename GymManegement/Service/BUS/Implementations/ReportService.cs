using Dapper;
using GymManegement.DAL.Helper;
using GymManegement.DAL.Repositories.Interfaces;
using GymManegement.Service.BUS.Interfaces;

namespace GymManegement.Service.BUS.Implementations
{
    public class ReportService : IReportService
    {
        private readonly DapperContext _db;
        private readonly IMembershipRepository _membershipRepo;
        public ReportService(DapperContext db, IMembershipRepository membershipRepo)
        { _db = db; _membershipRepo = membershipRepo; }

        public async Task<object> GetActiveMembersAsync()
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT COUNT(DISTINCT m.MemberId) AS ActiveMemberCount
                FROM Members m
                INNER JOIN Memberships ms ON m.MemberId = ms.MemberId
                WHERE ms.EndDate >= GETDATE() AND m.IsDeleted = 0 AND ms.IsDeleted = 0";
            
            var count = await conn.ExecuteScalarAsync<int>(sql);
            return new { ActiveMemberCount = count };
        }

        public async Task<object> GetRevenueAsync(int month, int year)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT 
                    ISNULL(SUM(TotalAmount), 0) AS TotalRevenue,
                    COUNT(*) AS InvoiceCount
                FROM Invoices
                WHERE Status = 'Paid' 
                    AND MONTH(InvoiceDate) = @Month 
                    AND YEAR(InvoiceDate) = @Year
                    AND IsDeleted = 0";
            
            var result = await conn.QuerySingleAsync(sql, new { Month = month, Year = year });
            return result;
        }

        public async Task<object> GetRevenueDetailAsync(int month, int year)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT 
                    i.InvoiceId,
                    i.InvoiceDate,
                    i.TotalAmount,
                    i.Status,
                    ms.PackageName,
                    m.FullName AS MemberName
                FROM Invoices i
                INNER JOIN Memberships ms ON i.MembershipId = ms.MembershipId
                INNER JOIN Members m ON ms.MemberId = m.MemberId
                WHERE MONTH(i.InvoiceDate) = @Month 
                    AND YEAR(i.InvoiceDate) = @Year
                    AND i.IsDeleted = 0
                ORDER BY i.InvoiceDate DESC";
            
            var rows = await conn.QueryAsync(sql, new { Month = month, Year = year });
            return new { Month = month, Year = year, Data = rows };
        }

        public async Task<object> GetExpiringSoonAsync(int daysAhead = 7)
        {
            var rows = await _membershipRepo.GetExpiringSoonAsync(daysAhead);
            return new { DaysAhead = daysAhead, Data = rows };
        }

        public async Task<object> GetMembersReportAsync()
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT 
                    COUNT(*) AS TotalMembers,
                    SUM(CASE WHEN IsDeleted = 0 THEN 1 ELSE 0 END) AS ActiveMembers,
                    SUM(CASE WHEN IsDeleted = 1 THEN 1 ELSE 0 END) AS InactiveMembers
                FROM Members";
            return await conn.QueryFirstOrDefaultAsync(sql);
        }
    }
}
