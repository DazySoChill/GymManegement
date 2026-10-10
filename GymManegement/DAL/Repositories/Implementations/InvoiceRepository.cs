using Dapper;
using GymManegement.API.DTOs.Common;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Helper;
using GymManegement.DAL.Repositories.Interfaces;

namespace GymManegement.DAL.Repositories.Implementations
{
    public class InvoiceRepository : IInvoiceRepository
    {
        private readonly DapperContext _db;
        public InvoiceRepository(DapperContext db) => _db = db;

        public async Task<IEnumerable<Invoice>> GetAllAsync()
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Invoice>("SELECT * FROM Invoices WHERE IsDeleted = 0 ORDER BY InvoiceId");
        }

        public async Task<PagedResult<Invoice>> GetAllAsync(int pageNumber, int pageSize, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            using var conn = _db.CreateConnection();
            sortBy ??= "InvoiceId";
            sortDir = sortDir?.ToUpper() == "DESC" ? "DESC" : "ASC";

            var whereClauses = new List<string> { "IsDeleted = 0" };
            if (!string.IsNullOrWhiteSpace(searchTerm))
                whereClauses.Add("(Status LIKE @Search OR Description LIKE @Search)");

            var where = string.Join(" AND ", whereClauses);
            var countSql = $"SELECT COUNT(*) FROM Invoices WHERE {where}";
            var dataSql = $@"
                SELECT * FROM Invoices WHERE {where}
                ORDER BY {sortBy} {sortDir}
                OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY";

            var total = await conn.ExecuteScalarAsync<int>(countSql, new { Search = $"%{searchTerm}%" });
            var data = await conn.QueryAsync<Invoice>(dataSql, new
            {
                Search = $"%{searchTerm}%",
                Offset = (pageNumber - 1) * pageSize,
                PageSize = pageSize
            });

            return new PagedResult<Invoice>
            {
                Data = data.ToList(),
                Total = total,
                PageNumber = pageNumber,
                PageSize = pageSize
            };
        }
        public async Task<Invoice?> GetByIdAsync(int id)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<Invoice>(
                "SELECT * FROM Invoices WHERE InvoiceId = @Id AND IsDeleted = 0",
                new { Id = id });
        }

        public async Task<IEnumerable<Invoice>> GetByMemberIdAsync(int memberId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Invoice>(@"
                SELECT i.* FROM Invoices i
                INNER JOIN Memberships m ON i.MembershipId = m.MembershipId
                WHERE m.MemberId = @MemberId AND i.IsDeleted = 0
                ORDER BY i.InvoiceDate DESC",
                new { MemberId = memberId });
        }
        public async Task<IEnumerable<Invoice>> GetByStatusAsync(string status)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Invoice>(
                "SELECT * FROM Invoices WHERE Status = @Status AND IsDeleted = 0 ORDER BY InvoiceDate DESC",
                new { Status = status });
        }

        public async Task<IEnumerable<Invoice>> GetOverdueAsync()
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Invoice>(
                "SELECT * FROM Invoices WHERE Status = 'Pending' AND DueDate < GETDATE() AND IsDeleted = 0 ORDER BY DueDate");
        }

        public async Task<IEnumerable<Invoice>> GetUnpaidAsync()
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT * FROM Invoices 
                WHERE Status IN ('Unpaid', 'Pending')
                  AND IsDeleted = 0
                ORDER BY DueDate ASC";
            return await conn.QueryAsync<Invoice>(sql);
        }

        public async Task<decimal> GetTotalRevenueAsync(int month, int year)
        {
            using var conn = _db.CreateConnection();
            return await conn.QuerySingleAsync<decimal>(@"
                SELECT ISNULL(SUM(TotalAmount), 0)
                FROM Invoices
                WHERE Status = 'Paid' AND MONTH(InvoiceDate) = @Month AND YEAR(InvoiceDate) = @Year AND IsDeleted = 0",
                new { Month = month, Year = year });
        }

        public async Task<Invoice> CreateAsync(Invoice entity)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                INSERT INTO Invoices (MembershipId, TotalAmount, InvoiceDate, DueDate, Status, Description, CreatedAt, UpdatedAt, IsDeleted)
                VALUES (@MembershipId, @TotalAmount, @InvoiceDate, @DueDate, @Status, @Description, GETDATE(), GETDATE(), 0);
                SELECT CAST(SCOPE_IDENTITY() AS INT);";
            var id = await conn.QuerySingleAsync<int>(sql, new
            {
                entity.MembershipId,
                entity.TotalAmount,
                entity.InvoiceDate,
                entity.DueDate,
                entity.Status,
                entity.Description
            });
            entity.InvoiceId = id;
            return entity;
        }

        public async Task<Invoice> UpdateAsync(Invoice entity)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE Invoices
                SET Status = @Status, UpdatedAt = GETDATE()
                WHERE InvoiceId = @InvoiceId AND IsDeleted = 0";
            await conn.ExecuteAsync(sql, new { entity.InvoiceId, entity.Status });
            return entity;
        }

        public async Task DeleteAsync(int id)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync(
                "UPDATE Invoices SET IsDeleted = 1, UpdatedAt = GETDATE() WHERE InvoiceId = @Id",
                new { Id = id });
        }
    }
}
