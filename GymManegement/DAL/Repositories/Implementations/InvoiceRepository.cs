using Dapper;
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
            return await conn.QueryAsync<Invoice>("sp_Invoice_GetAll", commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<Invoice?> GetByIdAsync(int id)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<Invoice>("sp_Invoice_GetById", new { InvoiceId = id }, commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<IEnumerable<Invoice>> GetByMemberIdAsync(int memberId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Invoice>("sp_Invoice_GetByMember", new { MemberId = memberId }, commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<IEnumerable<Invoice>> GetByStatusAsync(string status)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Invoice>("SELECT * FROM Invoices WHERE Status = @Status", new { Status = status });
        }
        public async Task<IEnumerable<Invoice>> GetOverdueAsync()
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Invoice>("sp_Invoice_GetOverdue", commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<decimal> GetTotalRevenueAsync(int month, int year)
        {
            using var conn = _db.CreateConnection();
            return await conn.QuerySingleAsync<decimal>(
                "SELECT ISNULL(SUM(TotalAmount),0) FROM Invoices WHERE Status='Paid' AND MONTH(InvoiceDate)=@Month AND YEAR(InvoiceDate)=@Year",
                new { Month = month, Year = year });
        }
        public async Task<Invoice> CreateAsync(Invoice entity)
        {
            using var conn = _db.CreateConnection();
            var id = await conn.QuerySingleAsync<int>("sp_Invoice_Create",
                new { entity.MemberId, entity.TotalAmount, entity.InvoiceDate, entity.DueDate },
                commandType: System.Data.CommandType.StoredProcedure);
            entity.InvoiceId = id;
            return entity;
        }
        public async Task<Invoice> UpdateAsync(Invoice entity)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_Invoice_UpdateStatus", new { entity.InvoiceId, entity.Status }, commandType: System.Data.CommandType.StoredProcedure);
            return entity;
        }
        public async Task DeleteAsync(int id)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("DELETE FROM Invoices WHERE InvoiceId = @InvoiceId", new { InvoiceId = id });
        }
    }
}
