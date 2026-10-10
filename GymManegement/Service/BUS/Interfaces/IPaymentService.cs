using GymManegement.API.DTOs.Common;
using GymManegement.API.DTOs.Payment;

namespace GymManegement.Service.BUS.Interfaces
{
    public interface IPaymentService
    {
        Task<PagedResult<PaymentResponse>> GetAllAsync(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, string? sortBy = null, string? sortDir = null);
        Task<PaymentResponse?> GetByIdAsync(int id);
        Task<IEnumerable<PaymentResponse>> GetByInvoiceIdAsync(int invoiceId);
        Task<IEnumerable<PaymentResponse>> GetByMemberIdAsync(int memberId);
        Task<IEnumerable<PaymentResponse>> GetByStatusAsync(string status);
        Task<PaymentResponse> CreateAsync(CreatePaymentRequest request);
        Task<PaymentResponse?> UpdateAsync(int id, UpdatePaymentRequest request);
        Task<bool> DeleteAsync(int id);
    }
}
