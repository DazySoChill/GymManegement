using Dapper;
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
            return await conn.QueryAsync<Payment>("SELECT * FROM Payments ORDER BY PaymentDate DESC");
        }
        public async Task<Payment?> GetByIdAsync(int id)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<Payment>("sp_Payment_GetById", new { PaymentId = id }, commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<IEnumerable<Payment>> GetByInvoiceIdAsync(int invoiceId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Payment>("sp_Payment_GetByInvoice", new { InvoiceId = invoiceId }, commandType: System.Data.CommandType.StoredProcedure);
        }
        public async Task<IEnumerable<Payment>> GetByStatusAsync(string status)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryAsync<Payment>("SELECT * FROM Payments WHERE Status = @Status", new { Status = status });
        }
        public async Task<Payment> CreateAsync(Payment entity)
        {
            using var conn = _db.CreateConnection();
            var id = await conn.QuerySingleAsync<int>("sp_Payment_Create",
                new { entity.InvoiceId, entity.Amount, entity.PaymentDate, entity.PaymentMethod },
                commandType: System.Data.CommandType.StoredProcedure);
            entity.PaymentId = id;
            return entity;
        }
        public async Task<Payment> UpdateAsync(Payment entity)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_Payment_UpdateStatus", new { entity.PaymentId, entity.Status }, commandType: System.Data.CommandType.StoredProcedure);
            return entity;
        }
        public async Task DeleteAsync(int id)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("DELETE FROM Payments WHERE PaymentId = @PaymentId", new { PaymentId = id });
        }
    }
}
