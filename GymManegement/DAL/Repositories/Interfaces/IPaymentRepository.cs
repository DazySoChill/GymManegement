using GymManegement.API.DTOs.Common;
using GymManegement.DAL.Entities;

namespace GymManegement.DAL.Repositories.Interfaces
{
    public interface IPaymentRepository : IRepository<Payment>
    {
        Task<IEnumerable<Payment>> GetByInvoiceIdAsync(int invoiceId);
        Task<IEnumerable<Payment>> GetByMemberIdAsync(int memberId);
        Task<IEnumerable<Payment>> GetByStatusAsync(string status);
        Task<PagedResult<Payment>> GetAllAsync(int pageNumber, int pageSize, string? searchTerm = null, string? sortBy = null, string? sortDir = null);
    }
}
