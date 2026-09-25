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
            var rows = await conn.QueryAsync("sp_Report_ActiveMembers", commandType: System.Data.CommandType.StoredProcedure);
            return new { Data = rows, Total = rows.Count() };
        }

        public async Task<object> GetRevenueAsync(int month, int year)
        {
            using var conn = _db.CreateConnection();
            var row = await conn.QuerySingleAsync("sp_Report_Revenue", new { Month = month, Year = year }, commandType: System.Data.CommandType.StoredProcedure);
            return row;
        }

        public async Task<object> GetRevenueDetailAsync(int month, int year)
        {
            using var conn = _db.CreateConnection();
            var rows = await conn.QueryAsync("sp_Report_RevenueDetail", new { Month = month, Year = year }, commandType: System.Data.CommandType.StoredProcedure);
            return new { Month = month, Year = year, Data = rows };
        }

        public async Task<object> GetExpiringSoonAsync(int daysAhead = 7)
        {
            var rows = await _membershipRepo.GetExpiringSoonAsync(daysAhead);
            return new { DaysAhead = daysAhead, Data = rows };
        }
    }
}
