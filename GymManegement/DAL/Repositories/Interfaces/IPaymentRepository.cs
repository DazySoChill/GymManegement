using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface IPaymentRepository : IRepository<Payment>
    {
        Task<IEnumerable<Payment>> GetByInvoiceIdAsync(int invoiceId);
        Task<IEnumerable<Payment>> GetByStatusAsync(string status);
    }
}
