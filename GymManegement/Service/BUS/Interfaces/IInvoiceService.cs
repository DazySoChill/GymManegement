using GymManegement.API.DTOs.Common;
using GymManegement.API.DTOs.Invoice;

namespace GymManegement.Service.BUS.Interfaces
{
    public interface IInvoiceService
    {
        Task<PagedResult<InvoiceResponse>> GetAllAsync(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, string? sortBy = null, string? sortDir = null);
        Task<InvoiceResponse?> GetByIdAsync(int id);
        Task<IEnumerable<InvoiceResponse>> GetByMemberIdAsync(int memberId);
        Task<IEnumerable<InvoiceResponse>> GetByStatusAsync(string status);
        Task<IEnumerable<InvoiceResponse>> GetOverdueAsync();
        Task<IEnumerable<InvoiceResponse>> GetUnpaidAsync();
        Task<decimal> GetTotalRevenueAsync(int month, int year);
        Task<InvoiceResponse> CreateAsync(CreateInvoiceRequest request);
        Task<InvoiceResponse?> UpdateAsync(int id, UpdateInvoiceRequest request);
        Task<bool> DeleteAsync(int id);
    }
}
