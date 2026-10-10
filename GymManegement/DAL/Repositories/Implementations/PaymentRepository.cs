using Dapper;
using GymManegement.API.DTOs.Common;
using GymManegement.DAL.Entities;
using GymManegement.DAL.Helper;
using GymManegement.DAL.Repositories.Interfaces;

namespace GymManegement.DAL.Repositories.Implementations
{
    public class PaymentRepository : IPaymentRepository
    {
        private readonly DapperContext _db;
        public PaymentRepository(DapperContext db) => _db = db;

        public async Task<IEnumerable<Payment>> GetAllAsync()
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Payment>("SELECT * FROM Payments WHERE IsDeleted = 0 ORDER BY PaymentDate DESC");
        }

        public async Task<PagedResult<Payment>> GetAllAsync(int pageNumber, int pageSize, string? searchTerm = null, string? sortBy = null, string? sortDir = null)
        {
            using var conn = _db.CreateConnection();
            sortBy ??= "PaymentId";
            sortDir = sortDir?.ToUpper() == "DESC" ? "DESC" : "ASC";

            var whereClauses = new List<string> { "IsDeleted = 0" };
            if (!string.IsNullOrWhiteSpace(searchTerm))
                whereClauses.Add("(PaymentMethod LIKE @Search)");

            var where = string.Join(" AND ", whereClauses);
            var countSql = $"SELECT COUNT(*) FROM Payments WHERE {where}";
            var dataSql = $@"
                SELECT * FROM Payments WHERE {where}
                ORDER BY {sortBy} {sortDir}
                OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY";

            var total = await conn.ExecuteScalarAsync<int>(countSql, new { Search = $"%{searchTerm}%" });
            var data = await conn.QueryAsync<Payment>(dataSql, new
            {
                Search = $"%{searchTerm}%",
                Offset = (pageNumber - 1) * pageSize,
                PageSize = pageSize
            });

            return new PagedResult<Payment>
            {
                Data = data.ToList(),
                Total = total,
                PageNumber = pageNumber,
                PageSize = pageSize
            };
        }
        public async Task<Payment?> GetByIdAsync(int id)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<Payment>(
                "SELECT * FROM Payments WHERE PaymentId = @Id AND IsDeleted = 0",
                new { Id = id });
        }

        public async Task<IEnumerable<Payment>> GetByInvoiceIdAsync(int invoiceId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Payment>(
                "SELECT * FROM Payments WHERE InvoiceId = @InvoiceId AND IsDeleted = 0 ORDER BY PaymentDate DESC",
                new { InvoiceId = invoiceId });
        }

        public async Task<IEnumerable<Payment>> GetByMemberIdAsync(int memberId)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                SELECT p.* FROM Payments p
                INNER JOIN Invoices i ON p.InvoiceId = i.InvoiceId
                INNER JOIN Memberships m ON i.MembershipId = m.MembershipId
                WHERE m.MemberId = @MemberId
                  AND p.IsDeleted = 0
                ORDER BY p.PaymentDate DESC";
            return await conn.QueryAsync<Payment>(sql, new { MemberId = memberId });
        }

        public async Task<IEnumerable<Payment>> GetByStatusAsync(string status)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Payment>(
                "SELECT * FROM Payments WHERE IsDeleted = 0 ORDER BY PaymentDate DESC");
        }

        public async Task<Payment> CreateAsync(Payment entity)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                INSERT INTO Payments (InvoiceId, Amount, PaymentDate, PaymentMethod, CreatedAt, UpdatedAt, IsDeleted)
                VALUES (@InvoiceId, @Amount, @PaymentDate, @PaymentMethod, GETDATE(), GETDATE(), 0);
                SELECT CAST(SCOPE_IDENTITY() AS INT);";
            var id = await conn.QuerySingleAsync<int>(sql, new
            {
                entity.InvoiceId,
                entity.Amount,
                entity.PaymentDate,
                entity.PaymentMethod
            });
            entity.PaymentId = id;
            return entity;
        }

        public async Task<Payment> UpdateAsync(Payment entity)
        {
            using var conn = _db.CreateConnection();
            var sql = @"
                UPDATE Payments
                SET Amount = @Amount, PaymentDate = @PaymentDate, PaymentMethod = @PaymentMethod, UpdatedAt = GETDATE()
                WHERE PaymentId = @PaymentId AND IsDeleted = 0";
            await conn.ExecuteAsync(sql, new
            {
                entity.PaymentId,
                entity.Amount,
                entity.PaymentDate,
                entity.PaymentMethod
            });
            return entity;
        }

        public async Task DeleteAsync(int id)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync(
                "UPDATE Payments SET IsDeleted = 1, UpdatedAt = GETDATE() WHERE PaymentId = @Id",
                new { Id = id });
        }
    }
}
